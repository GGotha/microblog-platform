import { Controller, Res } from '@nestjs/common';
import { MessagePattern } from '@nestjs/microservices';
import { Response } from 'express';
import { register } from 'prom-client';
import { AUTH_PATTERNS } from 'src/auth/auth.constants';

@Controller()
export class MetricsController {
  @MessagePattern(AUTH_PATTERNS.GET_METRICS)
  async getMetrics(@Res() res: Response) {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  }
}
