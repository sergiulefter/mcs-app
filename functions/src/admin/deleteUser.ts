import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { verifyAdmin } from "../utils/auth";

interface DeleteUserRequest {
  userId: string;
}

interface DeleteUserResponse {
  success: boolean;
}

/**
 * Cloud Function to delete a user (patient) account.
 *
 * This function:
 * 1. Verifies the caller is an admin
 * 2. Verifies the target user is not an admin (prevent admin self-deletion)
 * 3. Deletes the Firebase Auth account
 * 4. Deletes the Firestore user document
 *
 * Note: Consultations created by this user are NOT deleted - they remain
 * in the database with their original patientId reference.
 */
export const deleteUser = onCall<DeleteUserRequest, Promise<DeleteUserResponse>>(
  { region: "europe-west1" },
  async (request) => {
    // Verify caller is admin
    verifyAdmin(request);

    const { userId } = request.data;

    // Validate required fields
    if (!userId) {
      throw new HttpsError(
        "invalid-argument",
        "User ID is required."
      );
    }

    // Prevent self-deletion
    if (request.auth?.uid === userId) {
      throw new HttpsError(
        "failed-precondition",
        "Cannot delete your own account."
      );
    }

    const firestore = getFirestore();

    try {
      // Check if user exists in Firestore
      const userDoc = await firestore.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw new HttpsError(
          "not-found",
          "User not found."
        );
      }

      // Prevent deletion of admin users
      const userData = userDoc.data();
      if (userData?.userType === "admin") {
        throw new HttpsError(
          "failed-precondition",
          "Cannot delete admin users through this function."
        );
      }

      // Delete Firebase Auth account
      try {
        await getAuth().deleteUser(userId);
      } catch (authError) {
        const error = authError as { code?: string };
        // If the auth account doesn't exist, continue with Firestore deletion
        if (error.code !== "auth/user-not-found") {
          throw authError;
        }
      }

      // Delete Firestore user document
      await firestore.collection("users").doc(userId).delete();

      return {
        success: true,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      const firebaseError = error as { message?: string };
      throw new HttpsError(
        "internal",
        `Failed to delete user: ${firebaseError.message || "Unknown error"}`
      );
    }
  }
);
