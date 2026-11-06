import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service.js';

export interface HealthResponse {
  api: 'ok';
  database: 'ok';
}

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  async checkHealth(): Promise<HealthResponse> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { api: 'ok', database: 'ok' };
    } catch {
      throw new ServiceUnavailableException({
        api: 'ok',
        database: 'error',
      });
    }
  }
}
