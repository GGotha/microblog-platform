import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JsonWebTokenError, JwtService } from '@nestjs/jwt';
import { RpcException } from '@nestjs/microservices';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async validateUser(email: string, password: string): Promise<any> {
    const user = await this.userRepository.findOne({ where: { email } });
    if (user && (await bcrypt.compare(password, user.password))) {
      delete user.password;
      return user;
    }
    return null;
  }

  async login(credentials: { email: string; password: string }) {
    const user = await this.validateUser(
      credentials.email,
      credentials.password,
    );
    if (!user) {
      throw new UnauthorizedException();
    }
    return user;
  }

  async register(userData: Partial<User>) {
    const isEmailAvailable = await this.isEmailAvailable(userData.email);
    if (!isEmailAvailable) {
      throw new RpcException({
        status: 400,
        message: 'Email already in use',
        error: 'Bad Request',
      });
    }

    const hashedPassword = await bcrypt.hash(userData.password, 10);
    userData.password = hashedPassword;

    const user = this.userRepository.create(userData);
    return this.userRepository.save(user);
  }

  async validateToken(token: string): Promise<User> {
    try {
      const payload = this.jwtService.verify(token);
      const user = await this.userRepository.findOne({
        where: { id: payload.sub },
      });
      if (!user) {
        throw new UnauthorizedException();
      }
      return user;
    } catch (error) {
      if (error instanceof JsonWebTokenError) {
        throw new UnauthorizedException();
      }

      throw error;
    }
  }

  private async isEmailAvailable(email: string): Promise<boolean> {
    const existingUser = await this.userRepository.findOne({
      where: { email },
    });
    return !existingUser;
  }

  async health() {
    const userCount = await this.userRepository.count();
    return { status: 'ok', users: userCount };
  }
}
