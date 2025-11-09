import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import helmet from 'helmet';
import * as compression from 'compression';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);

  // Security
  app.use(helmet());
  app.enableCors({
    origin: configService.get('FRONTEND_URL'),
    credentials: true,
  });

  // Compression
  app.use(compression());

  // Global prefix
  app.setGlobalPrefix(configService.get('API_PREFIX') || 'api/v1');

  // Validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger Documentation
  if (configService.get('NODE_ENV') !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('AI Ads Manager API')
      .setDescription('API for AI-powered advertising automation platform')
      .setVersion('1.0')
      .addBearerAuth()
      .addTag('auth', 'Authentication endpoints')
      .addTag('companies', 'Company management')
      .addTag('products', 'Product management')
      .addTag('campaigns', 'Campaign management')
      .addTag('analytics', 'Analytics and reporting')
      .addTag('integrations', 'Ad platform integrations')
      .addTag('billing', 'Billing and subscriptions')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = configService.get('PORT') || 3001;
  await app.listen(port);

  console.log(`
  ╔════════════════════════════════════════════════════════╗
  ║                                                        ║
  ║   🚀 AI Ads Manager API is running!                   ║
  ║                                                        ║
  ║   📍 URL: http://localhost:${port}                         ║
  ║   📚 API Docs: http://localhost:${port}/api/docs           ║
  ║   🌍 Environment: ${configService.get('NODE_ENV')}                    ║
  ║                                                        ║
  ╚════════════════════════════════════════════════════════╝
  `);
}

bootstrap();
