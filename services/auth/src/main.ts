import { NestFactory } from '@nestjs/core';
import { Transport } from '@nestjs/microservices';
import { AppModule } from './app.module';

async function bootstrap() {
  const httpApp = await NestFactory.create(AppModule);

  httpApp.enableCors();

  await httpApp.listen(3002);
  console.log('Auth HTTP server (observability) is listening on port 3002');

  const microservice = await NestFactory.createMicroservice(AppModule, {
    transport: Transport.TCP,
    options: {
      host: '0.0.0.0',
      port: 3001,
    },
  });

  await microservice.listen();
  console.log('Auth microservice (TCP) is listening on port 3001');
}

bootstrap();
