import { Controller } from '@nestjs/common';
import { MessagePattern } from '@nestjs/microservices';
import { AuthService } from './auth.service';
import { AUTH_PATTERNS } from './auth.constants';

@Controller()
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @MessagePattern(AUTH_PATTERNS.REGISTER)
  async register(data: any) {
    return this.authService.register(data);
  }

  @MessagePattern(AUTH_PATTERNS.LOGIN)
  async login(data: any) {
    return this.authService.login(data);
  }
}
