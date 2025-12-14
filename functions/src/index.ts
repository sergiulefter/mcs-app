/**
 * Medical Correct Solution - Cloud Functions
 *
 * This module exports all Cloud Functions for the MCS app.
 * Functions are organized by category (admin operations, etc.)
 */

import { initializeApp } from "firebase-admin/app";

// Initialize Firebase Admin SDK
initializeApp();

// Admin functions - require admin privileges to call
export { createDoctor } from "./admin/createDoctor";
export { deleteDoctor } from "./admin/deleteDoctor";
export { deleteUser } from "./admin/deleteUser";
export { setAdminClaim } from "./admin/setAdminClaim";
