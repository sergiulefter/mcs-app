import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { verifyAdmin } from "../utils/auth";

interface DoctorData {
  fullName: string;
  specialty: string;
  subspecialties?: string[];
  experienceYears: number;
  consultationPrice: number;
  languages: string[];
  bio?: string;
  education?: Array<{
    institution: string;
    degree: string;
    year: number;
  }>;
}

interface CreateDoctorRequest {
  email: string;
  password: string;
  doctorData: DoctorData;
}

interface CreateDoctorResponse {
  uid: string;
  success: boolean;
}

/**
 * Cloud Function to create a new doctor account.
 *
 * This function:
 * 1. Verifies the caller is an admin
 * 2. Creates a Firebase Auth account for the doctor
 * 3. Creates a Firestore document in the 'doctors' collection
 *
 * The doctor's email is set as verified since admin created the account.
 * The doctor is initially set as unavailable (isAvailable: false).
 */
export const createDoctor = onCall<CreateDoctorRequest, Promise<CreateDoctorResponse>>(
  { region: "europe-west1" },
  async (request) => {
    // Verify caller is admin
    verifyAdmin(request);

    const { email, password, doctorData } = request.data;

    // Validate required fields
    if (!email || !password) {
      throw new HttpsError(
        "invalid-argument",
        "Email and password are required."
      );
    }

    if (!doctorData || !doctorData.fullName || !doctorData.specialty) {
      throw new HttpsError(
        "invalid-argument",
        "Doctor data must include fullName and specialty."
      );
    }

    // Validate password strength
    if (password.length < 6) {
      throw new HttpsError(
        "invalid-argument",
        "Password must be at least 6 characters."
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid email format."
      );
    }

    let uid: string;

    try {
      // Create Firebase Auth account
      const userRecord = await getAuth().createUser({
        email: email,
        password: password,
        emailVerified: false,
        displayName: doctorData.fullName,
      });

      uid = userRecord.uid;

      // Create Firestore doctor document
      const firestore = getFirestore();
      await firestore.collection("doctors").doc(uid).set({
        uid: uid,
        email: email,
        fullName: doctorData.fullName,
        specialty: doctorData.specialty,
        subspecialties: doctorData.subspecialties || [],
        experienceYears: doctorData.experienceYears || 0,
        consultationPrice: doctorData.consultationPrice || 0,
        languages: doctorData.languages || ["RO"],
        bio: doctorData.bio || "",
        education: doctorData.education || [],
        isAvailable: false,
        vacationPeriods: [],
        createdAt: FieldValue.serverTimestamp(),
        lastActive: FieldValue.serverTimestamp(),
      });

      return {
        uid: uid,
        success: true,
      };
    } catch (error) {
      // If we created the auth account but Firestore failed, clean up
      if (uid!) {
        try {
          await getAuth().deleteUser(uid);
        } catch {
          // Ignore cleanup errors
        }
      }

      // Re-throw with appropriate error message
      if (error instanceof HttpsError) {
        throw error;
      }

      const firebaseError = error as { code?: string; message?: string };

      if (firebaseError.code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "A user with this email already exists."
        );
      }

      if (firebaseError.code === "auth/invalid-email") {
        throw new HttpsError(
          "invalid-argument",
          "The email address is invalid."
        );
      }

      if (firebaseError.code === "auth/weak-password") {
        throw new HttpsError(
          "invalid-argument",
          "The password is too weak."
        );
      }

      throw new HttpsError(
        "internal",
        `Failed to create doctor account: ${firebaseError.message || "Unknown error"}`
      );
    }
  }
);
