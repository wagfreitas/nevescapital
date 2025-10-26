import { Module } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { UserTransactionService } from './user-transaction.service';
import { UserTransactionController } from './user-transaction.controller';
import { EncryptionService } from '../common/services/encryption.service';

@Module({
  controllers: [UsersController, UserTransactionController],
  providers: [UsersService, UserTransactionService, EncryptionService],
  exports: [UsersService, UserTransactionService],
})
export class UsersModule {}

