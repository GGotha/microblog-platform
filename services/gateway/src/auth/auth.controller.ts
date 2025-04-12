import {
  Controller,
  Post,
  Body,
  Inject,
  Get,
  UsePipes,
  ValidationPipe,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AUTH_SERVICE } from './auth.constants';

@Controller('auth')
@UsePipes(new ValidationPipe())
export class AuthController {
  constructor(@Inject(AUTH_SERVICE) private readonly authClient: ClientProxy) {}

  @Get('health')
  async checkHealth() {
    return this.authClient.send('health', {});
  }

  @Post('register')
  async register(@Body() userData: RegisterDto) {
    try {
      return await this.authClient.send('register', userData).toPromise();
    } catch (error) {
      throw new HttpException(
        error.message,
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('login')
  async login(@Body() credentials: LoginDto) {
    try {
      return await this.authClient.send('login', credentials).toPromise();
    } catch (error) {
      throw new HttpException(
        error.message,
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
