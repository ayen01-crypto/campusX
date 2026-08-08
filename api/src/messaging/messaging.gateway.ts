import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';

import { MessagingService } from './messaging.service.js';
import { SendMessageDto } from './messaging.dto.js';

type SocketUser = { sub: string; email: string; capabilities?: string[] };
type SendPayload = SendMessageDto & { conversationId: string };

@WebSocketGateway({
  namespace: '/chat',
  cors: { origin: true, credentials: true },
  transports: ['websocket', 'polling'],
})
export class MessagingGateway implements OnGatewayConnection {
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly messaging: MessagingService,
  ) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const authToken = client.handshake.auth?.token as string | undefined;
      const bearer = client.handshake.headers.authorization;
      const token = authToken ?? bearer?.replace(/^Bearer\s+/i, '');
      if (!token) throw new Error('Missing token');

      const payload = await this.jwt.verifyAsync<SocketUser>(token);
      client.data.userId = payload.sub;
      await client.join(`user:${payload.sub}`);
    } catch {
      client.disconnect(true);
    }
  }

  @SubscribeMessage('conversation:join')
  async joinConversation(
    @ConnectedSocket() client: Socket,
    @MessageBody() conversationId: string,
  ) {
    const userId = this.userId(client);
    if (!(await this.messaging.isMember(userId, conversationId))) {
      throw new WsException('Not a member of this conversation');
    }
    await client.join(`conversation:${conversationId}`);
    return { event: 'conversation:joined', data: { conversationId } };
  }

  @SubscribeMessage('message:send')
  async sendMessage(@ConnectedSocket() client: Socket, @MessageBody() payload: SendPayload) {
    const userId = this.userId(client);
    const message = await this.messaging.send(userId, payload.conversationId, payload);
    this.server.to(`conversation:${payload.conversationId}`).emit('message:new', message);
    return { event: 'message:ack', data: message };
  }

  @SubscribeMessage('conversation:read')
  async markRead(@ConnectedSocket() client: Socket, @MessageBody() conversationId: string) {
    const userId = this.userId(client);
    const result = await this.messaging.markRead(userId, conversationId);
    client.to(`conversation:${conversationId}`).emit('conversation:read', {
      conversationId,
      userId,
      ...result,
    });
    return { event: 'conversation:read:ack', data: result };
  }

  private userId(client: Socket): string {
    const userId = client.data.userId as string | undefined;
    if (!userId) throw new WsException('Unauthenticated socket');
    return userId;
  }
}
