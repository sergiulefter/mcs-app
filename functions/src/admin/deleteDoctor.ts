import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { verifyAdmin } from "../utils/auth";

interface DeleteDoctorRequest {
  doctorId: string;
}

interface DeleteDoctorResponse {
  success: boolean;
}

/**
 * Cloud Function to delete a doctor account.
 *
 * This function:
 * 1. Verifies the caller is an admin
 * 2. Deletes the Firebase Auth account
 * 3. Deletes the Firestore doctor document
 *
 * Note: Consultations are NOT deleted - they remain in the database
 * with their original doctorId reference. The app should handle
 * displaying these appropriately (e.g., "Doctor no longer available").
 */
export const deleteDoctor = onCall<DeleteDoctorRequest, Promise<DeleteDoctorResponse>>(
  { region: "europe-west1" },
  async (request) => {
    // Verify caller is admin
    verifyAdmin(request);

    const { doctorId } = request.data;

    // Validate required fields
    if (!doctorId) {
      throw new HttpsError(
        "invalid-argument",
        "Doctor ID is required."
      );
    }

    const firestore = getFirestore();

    try {
      // Check if doctor exists in Firestore
      const doctorDoc = await firestore.collection("doctors").doc(doctorId).get();

      if (!doctorDoc.exists) {
        throw new HttpsError(
          "not-found",
          "Doctor not found."
        );
      }

      // Delete Firebase Auth account
      try {
        await getAuth().deleteUser(doctorId);
      } catch (authError) {
        const error = authError as { code?: string };
        // If the auth account doesn't exist, continue with Firestore deletion
        if (error.code !== "auth/user-not-found") {
          throw authError;
        }
      }

      // Delete Firestore doctor document
      await firestore.collection("doctors").doc(doctorId).delete();

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
        `Failed to delete doctor: ${firebaseError.message || "Unknown error"}`
      );
    }
  }
);
