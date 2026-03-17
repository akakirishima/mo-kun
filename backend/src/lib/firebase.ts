import { App, applicationDefault, cert, getApps, initializeApp } from "firebase-admin/app";
import { Auth, getAuth } from "firebase-admin/auth";
import { Firestore, getFirestore, Timestamp } from "firebase-admin/firestore";

let cachedApp: App | null = null;

function parseServiceAccount() {
  const raw = process.env.SERVICE_ACCOUNT_JSON;
  if (!raw) {
    return null;
  }
  return JSON.parse(raw) as Record<string, string>;
}

export function getFirebaseApp(): App {
  if (cachedApp) {
    return cachedApp;
  }

  if (getApps().length > 0) {
    cachedApp = getApps()[0]!;
    return cachedApp;
  }

  const serviceAccount = parseServiceAccount();
  cachedApp = initializeApp(
    serviceAccount
      ? { credential: cert(serviceAccount) }
      : { credential: applicationDefault() },
  );
  return cachedApp;
}

export function getAuthClient(): Auth {
  return getAuth(getFirebaseApp());
}

export function getDb(): Firestore {
  return getFirestore(getFirebaseApp());
}

export { Timestamp };

