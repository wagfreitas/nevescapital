/**
 * Utility functions for encoding/decoding Firestore REST API value format.
 *
 * Firestore REST API uses typed wrappers like:
 *   { stringValue: "hello" }
 *   { integerValue: "42" }
 *   { timestampValue: "2024-01-01T00:00:00Z" }
 *   { mapValue: { fields: { key: { stringValue: "val" } } } }
 *   { arrayValue: { values: [ { stringValue: "a" } ] } }
 */

/** Firestore REST value type */
export type FirestoreValue =
  | { nullValue: null }
  | { booleanValue: boolean }
  | { integerValue: string }
  | { doubleValue: number }
  | { stringValue: string }
  | { timestampValue: string }
  | { mapValue: { fields: Record<string, FirestoreValue> } }
  | { arrayValue: { values: FirestoreValue[] } }
  | { referenceValue: string }
  | { geoPointValue: { latitude: number; longitude: number } };

/**
 * Encode a JS value into Firestore REST format.
 */
export function encodeValue(value: any): FirestoreValue {
  if (value === null || value === undefined) {
    return { nullValue: null };
  }
  if (typeof value === 'boolean') {
    return { booleanValue: value };
  }
  if (typeof value === 'number') {
    if (Number.isInteger(value)) {
      return { integerValue: String(value) };
    }
    return { doubleValue: value };
  }
  if (typeof value === 'string') {
    return { stringValue: value };
  }
  if (value instanceof Date) {
    return { timestampValue: value.toISOString() };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(encodeValue) } };
  }
  if (typeof value === 'object') {
    // Special marker for server timestamp transform (handled separately in writes)
    if (value.__type === 'serverTimestamp') {
      // Will be handled by the write logic as a transform
      return { stringValue: '__SERVER_TIMESTAMP__' };
    }
    const fields: Record<string, FirestoreValue> = {};
    for (const [k, v] of Object.entries(value)) {
      if (v !== undefined) {
        fields[k] = encodeValue(v);
      }
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

/**
 * Decode a Firestore REST value into a plain JS value.
 */
export function decodeValue(val: FirestoreValue): any {
  if ('nullValue' in val) return null;
  if ('booleanValue' in val) return val.booleanValue;
  if ('integerValue' in val) return parseInt(val.integerValue, 10);
  if ('doubleValue' in val) return val.doubleValue;
  if ('stringValue' in val) return val.stringValue;
  if ('timestampValue' in val) return new Date(val.timestampValue);
  if ('referenceValue' in val) return val.referenceValue;
  if ('geoPointValue' in val) return val.geoPointValue;
  if ('arrayValue' in val) {
    return (val.arrayValue.values || []).map(decodeValue);
  }
  if ('mapValue' in val) {
    return decodeFields(val.mapValue.fields || {});
  }
  return null;
}

/**
 * Decode Firestore document fields into a plain JS object.
 */
export function decodeFields(fields: Record<string, FirestoreValue>): Record<string, any> {
  const result: Record<string, any> = {};
  for (const [key, val] of Object.entries(fields)) {
    result[key] = decodeValue(val);
  }
  return result;
}

/**
 * Encode a plain JS object into Firestore document fields.
 */
export function encodeFields(obj: Record<string, any>): Record<string, FirestoreValue> {
  const fields: Record<string, FirestoreValue> = {};
  for (const [key, val] of Object.entries(obj)) {
    if (val !== undefined) {
      fields[key] = encodeValue(val);
    }
  }
  return fields;
}

/**
 * Extract document ID from a Firestore document name.
 * e.g., "projects/proj/databases/(default)/documents/users/abc123" → "abc123"
 */
export function extractDocId(name: string): string {
  const parts = name.split('/');
  return parts[parts.length - 1];
}

/**
 * Build a Firestore structured query filter for WHERE clauses.
 */
export function buildFieldFilter(
  field: string,
  op: 'EQUAL' | 'NOT_EQUAL' | 'LESS_THAN' | 'LESS_THAN_OR_EQUAL' | 'GREATER_THAN' | 'GREATER_THAN_OR_EQUAL' | 'ARRAY_CONTAINS' | 'IN' | 'ARRAY_CONTAINS_ANY' | 'NOT_IN',
  value: any,
): any {
  return {
    fieldFilter: {
      field: { fieldPath: field },
      op,
      value: encodeValue(value),
    },
  };
}

/**
 * Sentinel value for server timestamp (used in writes).
 */
export function serverTimestamp(): { __type: string } {
  return { __type: 'serverTimestamp' };
}

/**
 * Sentinel value for field increment (used in writes).
 */
export function fieldIncrement(amount: number): { __type: string; amount: number } {
  return { __type: 'increment', amount };
}
