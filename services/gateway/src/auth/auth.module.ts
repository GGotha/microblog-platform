import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { AuthController } from './auth.controller';
import { AUTH_SERVICE } from './auth.constants';

@Module({
  imports: [
    ClientsModule.register([
      {
        name: AUTH_SERVICE,
        transport: Transport.TCP,
        options: {
          host: process.env.AUTH_SERVICE_HOST || 'auth-service',
          port: parseInt(process.env.AUTH_SERVICE_PORT) || 3001,
        },
      },
    ]),
  ],
  controllers: [AuthController],
  exports: [ClientsModule],
})
export class AuthModule {}
