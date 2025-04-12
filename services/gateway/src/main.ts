import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Configuração global do ValidationPipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Remove propriedades não definidas nos DTOs
      transform: true, // Transforma automaticamente os tipos
      forbidNonWhitelisted: true, // Rejeita requisições com propriedades não permitidas
    }),
  );

  await app.listen(3000);
}
bootstrap();
