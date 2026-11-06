import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service.js';
import type { HealthResponse } from './app.service.js';

@Controller('health')
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  checkHealth(): Promise<HealthResponse> {
    return this.appService.checkHealth();
  }
}
