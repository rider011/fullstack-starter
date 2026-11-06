import { ServiceUnavailableException } from '@nestjs/common';
import { AppService } from './app.service.js';
import type { PrismaService } from './prisma/prisma.service.js';

describe('AppService', () => {
  const queryRaw = vi.fn();
  const prisma = { $queryRaw: queryRaw } as unknown as PrismaService;
  const service = new AppService(prisma);

  beforeEach(() => {
    queryRaw.mockReset();
  });

  it('reports a healthy database', async () => {
    queryRaw.mockResolvedValue([{ '?column?': 1 }]);

    await expect(service.checkHealth()).resolves.toEqual({
      api: 'ok',
      database: 'ok',
    });
  });

  it('returns a 503 when the database query fails', async () => {
    queryRaw.mockRejectedValue(new Error('database offline'));

    await expect(service.checkHealth()).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
