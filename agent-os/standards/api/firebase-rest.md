# Firebase REST API (No Admin SDK)

Backend uses Firebase REST APIs instead of `firebase-admin` SDK. This avoids service account credential issues on Railway deployment.

## Services

### FirestoreRestService

Wraps Firestore REST API (`firestore.googleapis.com/v1`). Located at `functions/src/firebase-rest/firestore-rest.service.ts`.

```typescript
@Injectable()
export class FirestoreRestService {
  // CRUD operations
  async getDocument(collection: string, docId: string): Promise<FirestoreDocument | null>
  async addDocument(collection: string, data: Record<string, any>): Promise<FirestoreDocument>
  async setDocument(collection: string, docId: string, data: Record<string, any>, merge?: boolean): Promise<void>
  async updateDocument(collection: string, docId: string, data: Record<string, any>): Promise<void>
  async deleteDocument(collection: string, docId: string): Promise<void>
  async query(collection: string, options: QueryOptions): Promise<FirestoreDocument[]>
  async batchDelete(paths: string[]): Promise<void>
}
```

Key details:
- Uses `FIREBASE_WEB_API_KEY` for authentication (not service account)
- `serverTimestamp()` and `fieldIncrement()` helpers for field transforms
- Transforms handled via separate `commitWrites` batch API
- Batch limit: 500 writes per commit

### AuthJwtService

Replaces `admin.auth()` with standard JWT + Firebase Identity Toolkit REST API:

```typescript
@Injectable()
export class AuthJwtService {
  signToken(payload: { sub: string; phone?: string }): string     // JWT sign
  verifyToken(token: string): JwtPayload                          // JWT verify
  async sendPasswordResetEmail(email: string): Promise<string>    // Identity Toolkit REST
  async lookupUserByEmail(email: string): Promise<any | null>     // Identity Toolkit REST
}
```

JWT config:
- Secret: `JWT_SECRET` env var
- Expiry: `JWT_EXPIRES_IN` (default: 7d)
- Issuer: `neves-capital-api`
- Audience: `pagpag-app`

### StorageRestService

Firebase Storage REST API for file operations.

## Environment Variables

```
FIREBASE_PROJECT_ID=pagpagapp
FIREBASE_WEB_API_KEY=<web api key>
JWT_SECRET=<strong secret>
JWT_EXPIRES_IN=7d
```

## Rules

- Never use `firebase-admin` SDK -- always use REST APIs
- All Firestore values go through `encodeValue` / `decodeValue` helpers
- `serverTimestamp()` returns `{ __type: 'serverTimestamp' }` marker object
- Query operators: `==`, `!=`, `<`, `<=`, `>`, `>=`, `array-contains`, `in`
