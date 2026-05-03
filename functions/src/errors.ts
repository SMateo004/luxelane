import { HttpsError } from 'firebase-functions/v2/https';

export function unauthenticated(msg = 'Unauthenticated'): HttpsError {
  return new HttpsError('unauthenticated', msg);
}

export function permissionDenied(msg = 'You don\'t have access'): HttpsError {
  return new HttpsError('permission-denied', msg);
}

export function invalidArgument(msg: string): HttpsError {
  return new HttpsError('invalid-argument', msg);
}

export function notFound(msg = 'Resource not found'): HttpsError {
  return new HttpsError('not-found', msg);
}

export function failedPrecondition(msg: string): HttpsError {
  return new HttpsError('failed-precondition', msg);
}

export function internal(msg = 'Something went wrong. Try again'): HttpsError {
  return new HttpsError('internal', msg);
}

export function paymentFailed(msg: string): HttpsError {
  return new HttpsError('internal', `payment/capture-failed: ${msg}`);
}
