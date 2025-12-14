import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { verifyAdmin } from "../utils/auth";

interface SetAdminClaimRequest {
  targetUserId: string;
  isAdmin: boolean;
}

interface SetAdminClaimResponse {
  success: boolean;
}

/**
 * Cloud Function to set or remove admin custom claim on a user.
 *
 * This function:
 * 1. Verifies the caller is an admin
 * 2. Sets the isAdmin custom claim on the target user
 *
 * The target user will need to re-authenticate (or refresh their token)
 * for the claim to take effect.
 *
 * Note: This should NOT be used to bootstrap the first admin.
 * Use the bootstrapAdmin function for that purpose.
 */
export const setAdminClaim = onCall<SetAdminClaimRequest, Promise<SetAdminClaimResponse>>(
  { region: "europe-west1" },
  async (request) => {
    // Verify caller is admin
    verifyAdmin(request);

    const { targetUserId, isAdmin } = request.data;

    // Validate required fields
    if (!targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Target user ID is required."
      );
    }

    if (typeof isAdmin !== "boolean") {
      throw new HttpsError(
        "invalid-argument",
        "isAdmin must be a boolean value."
      );
    }

    // Prevent removing admin from yourself
    if (request.auth?.uid === targetUserId && !isAdmin) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot remove admin privileges from yourself."
      );
    }

    try {
      // Verify target user exists
      await getAuth().getUser(targetUserId);

      // Set custom claims
      await getAuth().setCustomUserClaims(targetUserId, { isAdmin });

      return {
        success: true,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const firebaseError = error as { code?: string; message?: string };

      if (firebaseError.code === "auth/user-not-found") {
        throw new HttpsError(
          "not-found",
          "Target user not found."
        );
      }

      throw new HttpsError(
        "internal",
        `Failed to set admin claim: ${firebaseError.message || "Unknown error"}`
      );
    }
  }
);
