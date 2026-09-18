import express from "express";
import {
  verifyUser,
  getUsersByType,
  getAllUsersContacts,
  getRecentUsers,
  getAllAccountHolders,
  getVerificationStats,
  toggleVerification,
  getZipCoverage,
  getPaymentsOverview,
  getAnalytics,
} from "./adminController.js";
import { requireAdmin } from "../middleware/adminAuth.js";

const router = express.Router();

router.use(requireAdmin);

router.post("/verify", verifyUser);
router.patch("/toggle-verification/:userId", toggleVerification);
router.get("/users", getUsersByType);
router.get("/all-users", getAllUsersContacts);
router.get("/recent-users", getRecentUsers);
router.get("/account-holders", getAllAccountHolders);
router.get("/stats", getVerificationStats);
router.get("/zip-coverage", getZipCoverage);
router.get("/payments", getPaymentsOverview);
router.get("/analytics", getAnalytics);

export default router;
