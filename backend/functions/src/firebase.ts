declare function require(module: string): any;

const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

export const auth = admin.auth();
