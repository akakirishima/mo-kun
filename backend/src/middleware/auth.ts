import { NextFunction, Request, Response } from "express";
import { DecodedIdToken } from "firebase-admin/auth";
import { getAuthClient } from "../lib/firebase.js";

export type AuthedRequest = Request & {
  user: DecodedIdToken;
};

export async function requireAuth(
  request: Request,
  response: Response,
  next: NextFunction,
) {
  try {
    const token = extractBearerToken(request.header("authorization"));
    if (!token) {
      response.status(401).json({ error: "missing_bearer_token" });
      return;
    }

    const decoded = await verifyBearerToken(token);
    (request as AuthedRequest).user = decoded;
    next();
  } catch (error) {
    response.status(401).json({
      error: "invalid_bearer_token",
      detail: error instanceof Error ? error.message : "unknown_error",
    });
  }
}

export function extractBearerToken(header?: string | null): string | null {
  return header?.startsWith("Bearer ") ? header.slice(7) : null;
}

export async function verifyBearerToken(token: string) {
  return getAuthClient().verifyIdToken(token);
}
