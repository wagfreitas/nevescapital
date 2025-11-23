import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { UserTransactionService } from './user-transaction.service';
import { UserTransactionController } from './user-transaction.controller';
import { EncryptionService } from '../common/services/encryption.service';
import { PixValidationService } from './services/pix-validation.service';

@Module({
  imports: [ConfigModule],
  controllers: [UsersController, UserTransactionController],
  providers: [UsersService, UserTransactionService, EncryptionService, PixValidationService],
  exports: [UsersService, UserTransactionService],
})
export class UsersModule {}

