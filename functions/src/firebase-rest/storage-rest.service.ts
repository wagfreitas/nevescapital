import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class StorageRestService {
  private readonly logger = new Logger(StorageRestService.name);
  private readonly bucket: string;
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.bucket = this.configService.get<string>(
      'FIREBASE_STORAGE_BUCKET',
      'pagpagapp.appspot.com',
    );
    this.apiKey = this.configService.get<string>('FIREBASE_WEB_API_KEY', '');
    this.baseUrl = `https://storage.googleapis.com/storage/v1/b/${this.bucket}/o`;

    this.logger.log(`StorageRestService initialized (bucket: ${this.bucket})`);
  }

  /**
   * List files in a storage path prefix.
   * (Replaces admin.storage().bucket().getFiles({ prefix }))
   */
  async listFiles(prefix: string): Promise<Array<{ name: string }>> {
    try {
      const res = await axios.get(this.baseUrl, {
        params: {
          prefix,
          key: this.apiKey,
        },
      });
      return res.data.items || [];
    } catch (error: any) {
      this.logger.error(`listFiles(${prefix}) failed: ${error.message}`);
      return [];
    }
  }

  /**
   * Delete a file from storage.
   * (Replaces file.delete())
   */
  async deleteFile(fileName: string): Promise<boolean> {
    try {
      const encodedName = encodeURIComponent(fileName);
      await axios.delete(`${this.baseUrl}/${encodedName}`, {
        params: { key: this.apiKey },
      });
      return true;
    } catch (error: any) {
      if (error.response?.status === 404) return true; // Already deleted
      this.logger.error(`deleteFile(${fileName}) failed: ${error.message}`);
      return false;
    }
  }

  /**
   * Delete all files under a prefix (folder).
   * (Replaces the loop in deleteUserDataComplete)
   */
  async deleteFolder(prefix: string): Promise<number> {
    const files = await this.listFiles(prefix);
    let deleted = 0;
    for (const file of files) {
      if (await this.deleteFile(file.name)) {
        deleted++;
      }
    }
    this.logger.log(`Deleted ${deleted}/${files.length} files from ${prefix}`);
    return deleted;
  }
}
