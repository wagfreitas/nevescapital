import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios, { AxiosInstance } from 'axios';
import {
  encodeFields,
  decodeFields,
  decodeValue,
  encodeValue,
  extractDocId,
  FirestoreValue,
} from './firestore-rest.utils';

export interface FirestoreDocument {
  id: string;
  data: Record<string, any>;
  ref: { path: string };
}

@Injectable()
export class FirestoreRestService {
  private readonly logger = new Logger(FirestoreRestService.name);
  private readonly http: AxiosInstance;
  private readonly baseUrl: string;
  private readonly projectId: string;

  constructor(private readonly configService: ConfigService) {
    this.projectId = this.configService.get<string>('FIREBASE_PROJECT_ID', 'pagpagapp');
    const apiKey = this.configService.get<string>('FIREBASE_WEB_API_KEY', '');

    this.baseUrl = `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents`;

    this.http = axios.create({
      baseURL: this.baseUrl,
      params: apiKey ? { key: apiKey } : {},
      headers: { 'Content-Type': 'application/json' },
      timeout: 15000,
    });

    this.logger.log(`FirestoreRestService initialized (project: ${this.projectId})`);
  }

  // ─── GET DOCUMENT ──────────────────────────────────────────────

  async getDocument(collection: string, docId: string): Promise<FirestoreDocument | null> {
    try {
      const res = await this.http.get(`/${collection}/${docId}`);
      if (!res.data.fields) return null;
      return {
        id: extractDocId(res.data.name),
        data: decodeFields(res.data.fields),
        ref: { path: `${collection}/${docId}` },
      };
    } catch (error: any) {
      if (error.response?.status === 404) return null;
      this.logger.error(`getDocument(${collection}/${docId}) failed: ${error.message}`);
      throw error;
    }
  }

  // ─── ADD DOCUMENT (auto ID) ────────────────────────────────────

  async addDocument(collection: string, data: Record<string, any>): Promise<FirestoreDocument> {
    const { fields, transforms } = this.separateTransforms(collection, '', data);

    // If we have transforms, use commit API
    if (transforms.length > 0) {
      const docPath = `${this.baseUrl}/${collection}`; // Auto-generate ID
      const writes: any[] = [];

      // First write: update with fields
      const tempDocName = `projects/${this.projectId}/databases/(default)/documents/${collection}/__temp__`;

      // Use commit with a create + transforms
      const commitUrl = `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents:commit`;
      const apiKey = this.configService.get<string>('FIREBASE_WEB_API_KEY', '');

      const res = await axios.post(
        commitUrl,
        {
          writes: [
            {
              update: {
                fields,
              },
              currentDocument: { exists: false },
              updateTransforms: transforms,
            },
          ],
        },
        { params: apiKey ? { key: apiKey } : {} },
      );

      const docName = res.data.writeResults[0]?.updateTime
        ? res.data.commitTime
        : '';

      // Fallback: create without transforms, then update with transforms
      // Actually, for addDocument we need a simpler approach
    }

    // Simple add without transforms
    const res = await this.http.post(`/${collection}`, { fields });
    const docId = extractDocId(res.data.name);
    return {
      id: docId,
      data: { ...data, id: docId },
      ref: { path: `${collection}/${docId}` },
    };
  }

  // ─── SET DOCUMENT (with merge) ─────────────────────────────────

  async setDocument(
    collection: string,
    docId: string,
    data: Record<string, any>,
    merge = false,
  ): Promise<void> {
    const { fields, transforms } = this.separateTransforms(collection, docId, data);

    if (transforms.length > 0) {
      await this.commitWrites([
        {
          update: {
            name: `projects/${this.projectId}/databases/(default)/documents/${collection}/${docId}`,
            fields,
          },
          updateTransforms: transforms,
        },
      ]);
    } else {
      const params: any = {};
      if (merge) {
        // When merging, specify which fields to update
        Object.keys(data).forEach((key, i) => {
          params[`updateMask.fieldPaths`] = params[`updateMask.fieldPaths`]
            ? [...(Array.isArray(params[`updateMask.fieldPaths`]) ? params[`updateMask.fieldPaths`] : [params[`updateMask.fieldPaths`]]), key]
            : key;
        });
      }
      await this.http.patch(`/${collection}/${docId}`, { fields }, { params });
    }
  }

  // ─── UPDATE DOCUMENT ───────────────────────────────────────────

  async updateDocument(
    collection: string,
    docId: string,
    data: Record<string, any>,
  ): Promise<void> {
    const { fields, transforms } = this.separateTransforms(collection, docId, data);
    const fieldPaths = Object.keys(fields);

    if (transforms.length > 0) {
      const write: any = {
        update: {
          name: `projects/${this.projectId}/databases/(default)/documents/${collection}/${docId}`,
          fields,
        },
        updateMask: { fieldPaths },
        updateTransforms: transforms,
      };
      await this.commitWrites([write]);
    } else {
      // Build updateMask query params
      const updateMask = fieldPaths.map((f) => `updateMask.fieldPaths=${f}`).join('&');
      await this.http.patch(`/${collection}/${docId}?${updateMask}`, { fields });
    }
  }

  // ─── DELETE DOCUMENT ───────────────────────────────────────────

  async deleteDocument(collection: string, docId: string): Promise<void> {
    try {
      await this.http.delete(`/${collection}/${docId}`);
    } catch (error: any) {
      if (error.response?.status === 404) return; // Already deleted
      throw error;
    }
  }

  // ─── QUERY DOCUMENTS ──────────────────────────────────────────

  async query(
    collection: string,
    options: {
      where?: Array<{ field: string; op: string; value: any }>;
      orderBy?: string;
      orderDirection?: 'ASCENDING' | 'DESCENDING';
      limit?: number;
    } = {},
  ): Promise<FirestoreDocument[]> {
    const structuredQuery: any = {
      from: [{ collectionId: collection }],
    };

    // Build WHERE filters
    if (options.where && options.where.length > 0) {
      const filters = options.where.map((w) => ({
        fieldFilter: {
          field: { fieldPath: w.field },
          op: this.mapOperator(w.op),
          value: encodeValue(w.value),
        },
      }));

      if (filters.length === 1) {
        structuredQuery.where = filters[0];
      } else {
        structuredQuery.where = {
          compositeFilter: { op: 'AND', filters },
        };
      }
    }

    // ORDER BY
    if (options.orderBy) {
      structuredQuery.orderBy = [
        {
          field: { fieldPath: options.orderBy },
          direction: options.orderDirection || 'ASCENDING',
        },
      ];
    }

    // LIMIT
    if (options.limit) {
      structuredQuery.limit = options.limit;
    }

    try {
      const res = await this.http.post(':runQuery', { structuredQuery });

      // Firestore returns [{ document: {...} }] or [{ readTime: "..." }] if empty
      if (!Array.isArray(res.data)) return [];

      return res.data
        .filter((r: any) => r.document)
        .map((r: any) => ({
          id: extractDocId(r.document.name),
          data: decodeFields(r.document.fields || {}),
          ref: { path: r.document.name.split('/documents/')[1] },
        }));
    } catch (error: any) {
      this.logger.error(`query(${collection}) failed: ${error.message}`);
      throw error;
    }
  }

  // ─── BATCH DELETE ──────────────────────────────────────────────

  async batchDelete(paths: string[]): Promise<void> {
    if (paths.length === 0) return;

    const writes = paths.map((p) => ({
      delete: `projects/${this.projectId}/databases/(default)/documents/${p}`,
    }));

    // Firestore batch limit is 500 writes
    for (let i = 0; i < writes.length; i += 500) {
      const chunk = writes.slice(i, i + 500);
      await this.commitWrites(chunk);
    }
  }

  // ─── COMMIT (batch writes) ─────────────────────────────────────

  private async commitWrites(writes: any[]): Promise<any> {
    const apiKey = this.configService.get<string>('FIREBASE_WEB_API_KEY', '');
    const commitUrl = `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents:commit`;
    return axios.post(commitUrl, { writes }, { params: apiKey ? { key: apiKey } : {} });
  }

  // ─── HELPERS ───────────────────────────────────────────────────

  /**
   * Separate regular fields from transform operations (serverTimestamp, increment).
   */
  private separateTransforms(
    collection: string,
    docId: string,
    data: Record<string, any>,
  ): { fields: Record<string, FirestoreValue>; transforms: any[] } {
    const fields: Record<string, FirestoreValue> = {};
    const transforms: any[] = [];

    for (const [key, value] of Object.entries(data)) {
      if (value && typeof value === 'object' && value.__type === 'serverTimestamp') {
        transforms.push({
          fieldPath: key,
          setToServerValue: 'REQUEST_TIME',
        });
      } else if (value && typeof value === 'object' && value.__type === 'increment') {
        transforms.push({
          fieldPath: key,
          increment: { integerValue: String(value.amount) },
        });
      } else if (value !== undefined) {
        fields[key] = encodeValue(value);
      }
    }

    return { fields, transforms };
  }

  private mapOperator(op: string): string {
    const map: Record<string, string> = {
      '==': 'EQUAL',
      '!=': 'NOT_EQUAL',
      '<': 'LESS_THAN',
      '<=': 'LESS_THAN_OR_EQUAL',
      '>': 'GREATER_THAN',
      '>=': 'GREATER_THAN_OR_EQUAL',
      'array-contains': 'ARRAY_CONTAINS',
      in: 'IN',
      'array-contains-any': 'ARRAY_CONTAINS_ANY',
      'not-in': 'NOT_IN',
    };
    return map[op] || op;
  }
}
