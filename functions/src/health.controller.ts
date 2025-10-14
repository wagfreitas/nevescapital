import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  check() {
    return {
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'Neves Capital API',
      version: '1.0.0',
    };
  }
}

