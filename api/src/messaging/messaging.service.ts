import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';

import { ConversationType, NotificationType } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { SendMessageDto, StartConversationDto } from './messaging.dto.js';

@Injectable()
export class MessagingService {
  constructor(private readonly prisma: PrismaService) {}

  async listConversations(userId: string) {
    const conversations = await this.prisma.conversation.findMany({
      where: { members: { some: { userId } } },
      orderBy: { updatedAt: 'desc' },
      include: {
        listing: { select: { id: true, title: true, kind: true, images: true } },
        members: {
          include: {
            user: {
              select: { id: true, name: true, avatarUrl: true, verified: true },
            },
          },
        },
        messages: { take: 1, orderBy: { sentAt: 'desc' } },
      },
    });

    return conversations.map((conversation) => ({
      ...conversation,
      unreadCount: conversation.messages.length
        ? conversation.members.find((member) => member.userId === userId)?.lastReadAt == null
          ? 1
          : 0
        : 0,
    }));
  }

  async start(userId: string, dto: StartConversationDto) {
    if (dto.participantId === userId) {
      throw new ForbiddenException('You cannot start a conversation with yourself');
    }

    const participant = await this.prisma.user.findUnique({
      where: { id: dto.participantId },
      select: { id: true },
    });
    if (!participant) throw new NotFoundException('Participant not found');

    const existing = await this.prisma.conversation.findFirst({
      where: {
        listingId: dto.listingId ?? null,
        members: {
          every: { userId: { in: [userId, dto.participantId] } },
        },
        AND: [
          { members: { some: { userId } } },
          { members: { some: { userId: dto.participantId } } },
        ],
      },
      include: {
        members: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        listing: { select: { id: true, title: true, kind: true } },
      },
    });
    if (existing) return existing;

    return this.prisma.conversation.create({
      data: {
        type: dto.listingId ? ConversationType.LISTING : ConversationType.DIRECT,
        listingId: dto.listingId,
        members: {
          create: [{ userId }, { userId: dto.participantId }],
        },
      },
      include: {
        members: { include: { user: { select: { id: true, name: true, avatarUrl: true } } } },
        listing: { select: { id: true, title: true, kind: true } },
      },
    });
  }

  async messages(userId: string, conversationId: string, cursor?: string, take = 50) {
    await this.assertMember(userId, conversationId);
    const limit = Math.min(Math.max(take, 1), 100);
    const rows = await this.prisma.message.findMany({
      where: { conversationId },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      orderBy: { sentAt: 'desc' },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
    });

    const hasMore = rows.length > limit;
    const data = hasMore ? rows.slice(0, limit) : rows;
    return {
      data: [...data].reverse(),
      nextCursor: hasMore ? data.at(-1)?.id ?? null : null,
    };
  }

  async send(userId: string, conversationId: string, dto: SendMessageDto) {
    await this.assertMember(userId, conversationId);

    const existing = await this.prisma.message.findUnique({ where: { clientId: dto.clientId } });
    if (existing) return existing;

    return this.prisma.$transaction(async (tx) => {
      const message = await tx.message.create({
        data: {
          clientId: dto.clientId,
          conversationId,
          senderId: userId,
          body: dto.body.trim(),
          attachmentUrl: dto.attachmentUrl,
          attachmentType: dto.attachmentType,
          deliveredAt: new Date(),
        },
        include: { sender: { select: { id: true, name: true, avatarUrl: true } } },
      });

      await tx.conversation.update({
        where: { id: conversationId },
        data: { updatedAt: new Date() },
      });

      const recipients = await tx.conversationMember.findMany({
        where: { conversationId, userId: { not: userId } },
        select: { userId: true },
      });
      if (recipients.length > 0) {
        await tx.notification.createMany({
          data: recipients.map((recipient) => ({
            userId: recipient.userId,
            type: NotificationType.MESSAGE,
            title: `New message from ${message.sender.name}`,
            body: message.body.length > 120 ? `${message.body.slice(0, 117)}...` : message.body,
            data: { conversationId, messageId: message.id },
          })),
        });
      }

      return message;
    });
  }

  async markRead(userId: string, conversationId: string) {
    await this.assertMember(userId, conversationId);
    const now = new Date();
    await this.prisma.$transaction([
      this.prisma.conversationMember.update({
        where: { conversationId_userId: { conversationId, userId } },
        data: { lastReadAt: now },
      }),
      this.prisma.message.updateMany({
        where: { conversationId, senderId: { not: userId }, readAt: null },
        data: { readAt: now },
      }),
    ]);
    return { readAt: now };
  }

  async isMember(userId: string, conversationId: string): Promise<boolean> {
    return Boolean(
      await this.prisma.conversationMember.findUnique({
        where: { conversationId_userId: { conversationId, userId } },
        select: { userId: true },
      }),
    );
  }

  private async assertMember(userId: string, conversationId: string): Promise<void> {
    if (!(await this.isMember(userId, conversationId))) {
      throw new ForbiddenException('You are not a member of this conversation');
    }
  }
}
