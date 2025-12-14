import { HttpsError, CallableRequest } from "firebase-functions/v2/https";

/**
 * Verifies that the caller is authenticated and has admin privileges.
 * Throws an HttpsError if not authorized.
 *
 * @param request - The callable request from Cloud Functions v2
 * @throws HttpsError if user is not authenticated or not an admin
 */
export function verifyAdmin(request: CallableRequest): void {
  // Check if user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to perform this action."
    );
  }

  // Check if user has admin custom claim
  if (!request.auth.token.isAdmin) {
    throw new HttpsError(
      "permission-denied",
      "You must be an admin to perform this action."
    );
  }
}

/**
 * Verifies that the caller is authenticated.
 * Throws an HttpsError if not authenticated.
 *
 * @param request - The callable request from Cloud Functions v2
 * @throws HttpsError if user is not authenticated
 */
export function verifyAuthenticated(request: CallableRequest): void {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to perform this action."
    );
  }
}
