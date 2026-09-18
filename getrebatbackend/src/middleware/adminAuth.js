import jwt from "jsonwebtoken";
import userModel from "../../Database/models/userModel.js";

/**
 * Protect admin routes. Accepts Authorization: Bearer <token> or x-auth-token.
 * Requires role admin or mainadmin.
 */
export async function requireAdmin(req, res, next) {
  try {
    const header = req.header("Authorization") || "";
    const bearer = header.startsWith("Bearer ") ? header.slice(7).trim() : null;
    const token = bearer || req.header("x-auth-token");

    if (!token) {
      return res.status(401).json({
        success: false,
        message: "No token, authorization denied",
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET_KEY);
    } catch {
      return res.status(401).json({
        success: false,
        message: "Token is not valid",
      });
    }

    const userId = decoded?.id || decoded?._id || decoded?.userId;
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Invalid token payload",
      });
    }

    const user = await userModel.findById(userId).select("-password -__v");
    if (!user) {
      return res.status(401).json({
        success: false,
        message: "User not found",
      });
    }

    const role = String(user.role || "").toLowerCase();
    if (!["admin", "mainadmin"].includes(role)) {
      return res.status(403).json({
        success: false,
        message: "Admin access required",
      });
    }

    req.user = user;
    req.adminRole = role;
    next();
  } catch (error) {
    console.error("requireAdmin error:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
}

export default requireAdmin;
