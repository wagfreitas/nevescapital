import { Global, Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FirestoreRestService } from './firestore-rest.service';
import { AuthJwtService } from './auth-jwt.service';
import { StorageRestService } from './storage-rest.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [FirestoreRestService, AuthJwtService, StorageRestService],
  exports: [FirestoreRestService, AuthJwtService, StorageRestService],
})
export class FirebaseRestModule {}
