import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';

describe('AppController', () => {
  let appController: AppController;
  const checkHealth = vi.fn();

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: AppService,
          useValue: { checkHealth },
        },
      ],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('health', () => {
    it('returns the API and database health', async () => {
      checkHealth.mockResolvedValue({ api: 'ok', database: 'ok' });

      await expect(appController.checkHealth()).resolves.toEqual({
        api: 'ok',
        database: 'ok',
      });
    });
  });
});
