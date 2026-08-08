import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import * as bcrypt from 'bcrypt';

import { PrismaClient } from '../src/generated/prisma/client.js';
import { ListingKind, UserCapability } from '../src/generated/prisma/enums.js';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error('DATABASE_URL is not configured');

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });

async function main(): Promise<void> {
  const universities = await Promise.all([
    prisma.university.upsert({
      where: { name: 'Kabale University' },
      update: {},
      create: { name: 'Kabale University', domain: 'kab.ac.ug', city: 'Kabale' },
    }),
    prisma.university.upsert({
      where: { name: 'Makerere University' },
      update: {},
      create: { name: 'Makerere University', domain: 'mak.ac.ug', city: 'Kampala' },
    }),
    prisma.university.upsert({
      where: { name: 'Mbarara University of Science and Technology' },
      update: {},
      create: { name: 'Mbarara University of Science and Technology', domain: 'must.ac.ug', city: 'Mbarara' },
    }),
    prisma.university.upsert({
      where: { name: 'Uganda Christian University' },
      update: {},
      create: { name: 'Uganda Christian University', domain: 'ucu.ac.ug', city: 'Mukono' },
    }),
    prisma.university.upsert({
      where: { name: 'Kyambogo University' },
      update: {},
      create: { name: 'Kyambogo University', domain: 'kyu.ac.ug', city: 'Kampala' },
    }),
  ]);

  const kabale = universities[0];
  const passwordHash = await bcrypt.hash('CampusX123!', 12);

  const student = await prisma.user.upsert({
    where: { email: 'student@campusx.local' },
    update: {},
    create: {
      email: 'student@campusx.local',
      passwordHash,
      name: 'CampusX Student',
      verified: true,
      universityId: kabale.id,
      capabilities: [UserCapability.STUDENT, UserCapability.SELLER],
    },
  });

  const provider = await prisma.user.upsert({
    where: { email: 'provider@campusx.local' },
    update: {},
    create: {
      email: 'provider@campusx.local',
      passwordHash,
      name: 'CampusX Provider',
      verified: true,
      universityId: kabale.id,
      capabilities: [
        UserCapability.STUDENT,
        UserCapability.LANDLORD,
        UserCapability.TUTOR,
        UserCapability.SERVICE_PROVIDER,
        UserCapability.BUSINESS,
        UserCapability.EVENT_ORGANIZER,
        UserCapability.EMPLOYER,
      ],
    },
  });

  const listingCount = await prisma.listing.count({ where: { universityId: kabale.id } });
  if (listingCount === 0) {
    await prisma.listing.createMany({
      data: [
        {
          kind: ListingKind.MARKETPLACE,
          title: 'HP Pavilion Laptop',
          subtitle: 'Clean student laptop',
          description: 'Reliable HP Pavilion in excellent condition, ideal for coding, assignments and everyday campus work.',
          price: 1700000,
          location: 'Kabale University',
          tags: ['laptop', 'electronics', 'computer'],
          ownerId: student.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.RENTAL,
          title: 'Executive Single Room',
          subtitle: '0.8 km from campus',
          description: 'Secure self-contained single room with water, power, private bathroom and easy campus access.',
          price: 300000,
          location: 'Kikungiri, Kabale',
          tags: ['single-room', 'self-contained', 'rental'],
          ownerId: provider.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.TUTOR,
          title: 'Physics & Mathematics Tutor',
          subtitle: 'In-person and online sessions',
          description: 'Structured support for calculus, mechanics, electricity and university foundation mathematics.',
          price: 15000,
          location: 'Kabale University',
          tags: ['physics', 'mathematics', 'tutor'],
          ownerId: provider.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.INTERNSHIP,
          title: 'Software Engineering Intern',
          subtitle: 'CampusX Technologies',
          description: 'Work with a product engineering team building student-centered mobile and backend systems.',
          location: 'Kabale / Hybrid',
          tags: ['flutter', 'typescript', 'internship'],
          ownerId: provider.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.EVENT,
          title: 'Kabale Campus Tech Fest',
          subtitle: 'Innovation, music and networking',
          description: 'A student technology and entrepreneurship event with demos, talks, networking and entertainment.',
          price: 20000,
          location: 'Kabale University Grounds',
          tags: ['event', 'technology', 'networking'],
          ownerId: provider.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.SERVICE,
          title: 'Laptop Diagnostics & Repair',
          subtitle: 'Student-friendly repair service',
          description: 'Diagnostics, software repair, storage upgrades, OS installation and general laptop maintenance.',
          price: 15000,
          location: 'Kabale',
          tags: ['repair', 'laptop', 'service'],
          ownerId: provider.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.BUSINESS,
          title: 'Campus Bites',
          subtitle: 'Student meals and quick bites',
          description: 'Affordable meals, snacks and drinks with student offers near campus.',
          location: 'Kabale',
          tags: ['food', 'restaurant', 'student-business'],
          ownerId: provider.id,
          universityId: kabale.id,
        },
        {
          kind: ListingKind.DEAL,
          title: '20% Off Student Lunch',
          subtitle: 'Campus Bites student deal',
          description: 'Claim this CampusX deal and present your claim code at Campus Bites for a student lunch discount.',
          location: 'Kabale',
          tags: ['deal', 'food', 'discount'],
          metadata: { expiresAt: '2026-12-31T23:59:59.000Z' },
          ownerId: provider.id,
          universityId: kabale.id,
        },
      ],
    });
  }

  console.log('CampusX seed complete');
  console.log('Student login: student@campusx.local / CampusX123!');
  console.log('Provider login: provider@campusx.local / CampusX123!');
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
