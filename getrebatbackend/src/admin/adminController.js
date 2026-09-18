import userModel from "../../Database/models/userModel.js";
import zipCodeModel from "../../Database/models/zipcodeModel.js";
import listings from "../../Database/models/listingModel.js";
import WaitingListModel from "../../Database/models/WaitingListModel.js";
import {
  PLATFORM_ZIP_TARGET,
  ZIP_POTENTIAL_BY_STATE,
  REBATE_ALLOWED_STATES,
} from "./zipPotentialByState.js";

const formatDate = (date) => {
  const d = new Date(date);
  return `${d.getMonth() + 1}-${d.getDate()}-${d.getFullYear()}`;
};

export const verifyUser = async (req, res) => {
  try {
    const { userId, userIds, verified, userType } = req.body;

    if (verified === undefined || verified === null) {
      return res.status(400).json({
        success: false,
        message: "verified field is required in request body (true/false)",
      });
    }

    const isSingleOperation = userId !== undefined;
    const isBulkOperation =
      userIds !== undefined && Array.isArray(userIds) && userIds.length > 0;

    if (!isSingleOperation && !isBulkOperation) {
      return res.status(400).json({
        success: false,
        message: "Either userId (single) or userIds array (bulk) is required",
      });
    }

    let allowedRoles = ["agent", "loanofficer"];
    if (userType) {
      if (!["agent", "loanofficer", "both"].includes(userType)) {
        return res.status(400).json({
          success: false,
          message: "userType must be one of: agent, loanofficer, both",
        });
      }
      if (userType === "agent") allowedRoles = ["agent"];
      if (userType === "loanofficer") allowedRoles = ["loanofficer"];
    }

    let updatedUsers;

    if (isSingleOperation) {
      const user = await userModel.findById(userId);

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User not found",
        });
      }

      if (!allowedRoles.includes(user.role)) {
        return res.status(400).json({
          success: false,
          message: `User must be one of: ${allowedRoles.join(", ")}`,
        });
      }

      const updatedUser = await userModel
        .findByIdAndUpdate(
          userId,
          { verified: Boolean(verified) },
          { new: true }
        )
        .select("-password -__v");

      return res.status(200).json({
        success: true,
        message: `${user.role} ${
          verified ? "verified" : "unverified"
        } successfully`,
        operation: "single",
        verified: updatedUser.verified,
        user: updatedUser,
      });
    } else {
      const users = await userModel.find({
        _id: { $in: userIds },
        role: { $in: allowedRoles },
      });

      if (users.length === 0) {
        return res.status(404).json({
          success: false,
          message: "No valid users found with the provided IDs",
        });
      }

      const validUserIds = users.map((user) => user._id);

      const result = await userModel.updateMany(
        { _id: { $in: validUserIds } },
        { verified: Boolean(verified) }
      );

      updatedUsers = await userModel
        .find({
          _id: { $in: validUserIds },
        })
        .select("-password -__v");

      return res.status(200).json({
        success: true,
        message: `${result.modifiedCount} users ${
          verified ? "verified" : "unverified"
        } successfully`,
        operation: "bulk",
        modifiedCount: result.modifiedCount,
        verified: Boolean(verified),
        users: updatedUsers,
      });
    }
  } catch (error) {
    console.error("Error in verifyUser:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

export const getUsersByType = async (req, res) => {
  try {
    const { userType, verified, search } = req.query;

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    if (page < 1) {
      return res.status(400).json({
        success: false,
        message: "Page must be greater than 0",
      });
    }
    if (limit < 1 || limit > 100) {
      return res.status(400).json({
        success: false,
        message: "Limit must be between 1 and 100",
      });
    }

    if (!userType || !["agent", "loanofficer", "both"].includes(userType)) {
      return res.status(400).json({
        success: false,
        message:
          "userType is required and must be one of: agent, loanofficer, both",
      });
    }

    let query = {};

    if (userType === "both") {
      query.role = { $in: ["agent", "loanofficer"] };
    } else {
      query.role = userType;
    }

    if (verified !== undefined) {
      query.verified = verified === "true";
    }

    if (search) {
      query.$or = [
        { fullname: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
        { phone: { $regex: search, $options: "i" } },
        { liscenceNumber: { $regex: search, $options: "i" } },
      ];
    }

    const totalUsers = await userModel.countDocuments(query);
    const totalPages = Math.ceil(totalUsers / limit);

    const users = await userModel
      .find(query)
      .select("-password -__v")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.status(200).json({
      success: true,
      count: users.length,
      total: totalUsers,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1,
      nextPage: page < totalPages ? page + 1 : null,
      prevPage: page > 1 ? page - 1 : null,
      filters: {
        userType,
        verified: verified !== undefined ? verified === "true" : "all",
        search: search || "none",
      },
      users,
    });
  } catch (error) {
    console.error("Error in getUsersByType:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getRecentUsers = async (req, res) => {
  try {
    const fromDate = new Date();
    fromDate.setDate(fromDate.getDate() - 15);
    fromDate.setHours(0, 0, 0, 0);

    const users = await userModel
      .find({ createdAt: { $gte: fromDate } })
      .select("fullname email role createdAt")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: users.length,
      fromDate: formatDate(fromDate),
      toDate: formatDate(new Date()),
      users: users.map((user) => ({
        name: user.fullname,
        email: user.email,
        role: user.role,
        createdAt: formatDate(user.createdAt),
      })),
    });
  } catch (error) {
    console.error("Error in getRecentUsers:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAllUsersContacts = async (req, res) => {
  try {
    const users = await userModel
      .find({})
      .select("fullname email role")
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: users.length,
      users: users.map((user) => ({
        name: user.fullname,
        email: user.email,
        role: user.role,
      })),
    });
  } catch (error) {
    console.error("Error in getAllUsersContacts:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAllAccountHolders = async (req, res) => {
  try {
    const { role, search } = req.query;

    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    if (page < 1) {
      return res.status(400).json({
        success: false,
        message: "Page must be greater than 0",
      });
    }
    if (limit < 1 || limit > 100) {
      return res.status(400).json({
        success: false,
        message: "Limit must be between 1 and 100",
      });
    }

    const allowedRoles = ["buyer/seller", "agent", "loanofficer"];
    const query = { role: { $in: allowedRoles } };

    if (role) {
      if (!allowedRoles.includes(role)) {
        return res.status(400).json({
          success: false,
          message: `role must be one of: ${allowedRoles.join(", ")}`,
        });
      }
      query.role = role;
    }

    if (search) {
      query.$or = [
        { fullname: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }

    const totalUsers = await userModel.countDocuments(query);
    const totalPages = Math.ceil(totalUsers / limit);

    const users = await userModel
      .find(query)
      .select("fullname email role verified createdAt")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    res.status(200).json({
      success: true,
      count: users.length,
      total: totalUsers,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1,
      nextPage: page < totalPages ? page + 1 : null,
      prevPage: page > 1 ? page - 1 : null,
      filters: {
        role: role || "all",
        search: search || "none",
      },
      users: users.map((user) => ({
        _id: user._id,
        name: user.fullname,
        email: user.email,
        role: user.role,
        verified: user.verified,
        createdAt: user.createdAt,
      })),
    });
  } catch (error) {
    console.error("Error in getAllAccountHolders:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getVerificationStats = async (req, res) => {
  try {
    const stats = await userModel.aggregate([
      {
        $facet: {
          overall: [
            {
              $group: {
                _id: null,
                totalUsers: { $sum: 1 },
                totalVerified: {
                  $sum: { $cond: [{ $eq: ["$verified", true] }, 1, 0] },
                },
                totalAgents: {
                  $sum: { $cond: [{ $eq: ["$role", "agent"] }, 1, 0] },
                },
                totalLoanOfficers: {
                  $sum: { $cond: [{ $eq: ["$role", "loanofficer"] }, 1, 0] },
                },
                verifiedAgents: {
                  $sum: {
                    $cond: [
                      {
                        $and: [
                          { $eq: ["$role", "agent"] },
                          { $eq: ["$verified", true] },
                        ],
                      },
                      1,
                      0,
                    ],
                  },
                },
                verifiedLoanOfficers: {
                  $sum: {
                    $cond: [
                      {
                        $and: [
                          { $eq: ["$role", "loanofficer"] },
                          { $eq: ["$verified", true] },
                        ],
                      },
                      1,
                      0,
                    ],
                  },
                },
                totalBuyers: {
                  $sum: {
                    $cond: [{ $eq: ["$role", "buyer/seller"] }, 1, 0],
                  },
                },
              },
            },
          ],
          latestUnverified: [
            {
              $match: {
                role: { $in: ["agent", "loanofficer"] },
                verified: false,
              },
            },
            { $sort: { createdAt: -1 } },
            { $limit: 5 },
            {
              $project: {
                _id: 1,
                fullname: 1,
                email: 1,
                role: 1,
                createdAt: 1,
              },
            },
          ],
          verificationByDate: [
            {
              $match: {
                role: { $in: ["agent", "loanofficer"] },
                verified: true,
              },
            },
            {
              $group: {
                _id: {
                  $dateToString: { format: "%Y-%m-%d", date: "$updatedAt" },
                },
                count: { $sum: 1 },
              },
            },
            { $sort: { _id: -1 } },
            { $limit: 30 },
          ],
        },
      },
    ]);

    const overall = stats[0].overall[0] || {
      totalUsers: 0,
      totalVerified: 0,
      totalAgents: 0,
      totalLoanOfficers: 0,
      verifiedAgents: 0,
      verifiedLoanOfficers: 0,
      totalBuyers: 0,
    };

    const agentVerificationRate =
      overall.totalAgents > 0
        ? ((overall.verifiedAgents / overall.totalAgents) * 100).toFixed(2)
        : "0.00";

    const loanOfficerVerificationRate =
      overall.totalLoanOfficers > 0
        ? (
            (overall.verifiedLoanOfficers / overall.totalLoanOfficers) *
            100
          ).toFixed(2)
        : "0.00";

    const overallVerificationRate =
      overall.totalAgents + overall.totalLoanOfficers > 0
        ? (
            ((overall.verifiedAgents + overall.verifiedLoanOfficers) /
              (overall.totalAgents + overall.totalLoanOfficers)) *
            100
          ).toFixed(2)
        : "0.00";

    res.status(200).json({
      success: true,
      stats: {
        overall: {
          totalUsers: overall.totalUsers,
          totalBuyers: overall.totalBuyers || 0,
          totalProfessionals: overall.totalAgents + overall.totalLoanOfficers,
          totalVerifiedProfessionals:
            overall.verifiedAgents + overall.verifiedLoanOfficers,
          verificationRate: overallVerificationRate + "%",
        },
        agents: {
          total: overall.totalAgents,
          verified: overall.verifiedAgents,
          unverified: overall.totalAgents - overall.verifiedAgents,
          verificationRate: agentVerificationRate + "%",
        },
        loanOfficers: {
          total: overall.totalLoanOfficers,
          verified: overall.verifiedLoanOfficers,
          unverified: overall.totalLoanOfficers - overall.verifiedLoanOfficers,
          verificationRate: loanOfficerVerificationRate + "%",
        },
      },
      recentActivity: {
        latestUnverified: stats[0].latestUnverified,
        verificationTrend: stats[0].verificationByDate,
      },
    });
  } catch (error) {
    console.error("Error fetching verification stats:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const toggleVerification = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "userId is required in URL parameters",
      });
    }

    const user = await userModel.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    if (!["agent", "loanofficer"].includes(user.role)) {
      return res.status(400).json({
        success: false,
        message: "Only agents and loan officers can be verified",
      });
    }

    const newVerifiedStatus = !user.verified;

    const updatedUser = await userModel
      .findByIdAndUpdate(userId, { verified: newVerifiedStatus }, { new: true })
      .select("-password -__v");

    return res.status(200).json({
      success: true,
      message: `${user.role} ${
        newVerifiedStatus ? "verified" : "unverified"
      } successfully`,
      verified: updatedUser.verified,
      user: updatedUser,
    });
  } catch (error) {
    console.error("Error in toggleVerification:", error);
    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};

/**
 * ZIP inventory vs potential coverage for rebate-allowed states.
 * Answers: what's loaded today, what's payable (has population), what's left vs ~27k target.
 */
export const getZipCoverage = async (req, res) => {
  try {
    const byStateAgg = await zipCodeModel.aggregate([
      {
        $group: {
          _id: { $toUpper: "$state" },
          loaded: { $sum: 1 },
          withPopulation: {
            $sum: {
              $cond: [{ $gt: [{ $ifNull: ["$population", 0] }, 0] }, 1, 0],
            },
          },
          withoutPopulation: {
            $sum: {
              $cond: [
                {
                  $or: [
                    { $eq: [{ $ifNull: ["$population", 0] }, 0] },
                    { $eq: ["$population", null] },
                  ],
                },
                1,
                0,
              ],
            },
          },
          claimedByAgent: {
            $sum: { $cond: [{ $eq: ["$claimedByAgent", true] }, 1, 0] },
          },
          claimedByOfficer: {
            $sum: { $cond: [{ $eq: ["$claimedByOfficer", true] }, 1, 0] },
          },
          totalPopulation: { $sum: { $ifNull: ["$population", 0] } },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    const loadedMap = Object.fromEntries(
      byStateAgg.map((row) => [row._id, row])
    );

    const states = REBATE_ALLOWED_STATES.map((code) => {
      const loaded = loadedMap[code] || {
        loaded: 0,
        withPopulation: 0,
        withoutPopulation: 0,
        claimedByAgent: 0,
        claimedByOfficer: 0,
        totalPopulation: 0,
      };
      const potential = ZIP_POTENTIAL_BY_STATE[code] || 0;
      const loadedCount = loaded.loaded || 0;
      const withPop = loaded.withPopulation || 0;
      return {
        state: code,
        potential,
        loaded: loadedCount,
        withPopulation: withPop,
        withoutPopulation: loaded.withoutPopulation || 0,
        remainingToLoad: Math.max(0, potential - loadedCount),
        remainingPayable: Math.max(0, potential - withPop),
        claimedByAgent: loaded.claimedByAgent || 0,
        claimedByOfficer: loaded.claimedByOfficer || 0,
        availableForAgent: Math.max(
          0,
          withPop - (loaded.claimedByAgent || 0)
        ),
        availableForOfficer: Math.max(
          0,
          withPop - (loaded.claimedByOfficer || 0)
        ),
        totalPopulation: loaded.totalPopulation || 0,
        coveragePct:
          potential > 0
            ? Number(((loadedCount / potential) * 100).toFixed(1))
            : 0,
      };
    });

    const totals = states.reduce(
      (acc, s) => {
        acc.potential += s.potential;
        acc.loaded += s.loaded;
        acc.withPopulation += s.withPopulation;
        acc.withoutPopulation += s.withoutPopulation;
        acc.remainingToLoad += s.remainingToLoad;
        acc.claimedByAgent += s.claimedByAgent;
        acc.claimedByOfficer += s.claimedByOfficer;
        return acc;
      },
      {
        potential: 0,
        loaded: 0,
        withPopulation: 0,
        withoutPopulation: 0,
        remainingToLoad: 0,
        claimedByAgent: 0,
        claimedByOfficer: 0,
      }
    );

    res.status(200).json({
      success: true,
      summary: {
        platformTarget: PLATFORM_ZIP_TARGET,
        potentialInRebateStates: totals.potential,
        loadedToday: totals.loaded,
        payableToday: totals.withPopulation,
        loadedWithoutPopulation: totals.withoutPopulation,
        remainingToLoad: totals.remainingToLoad,
        claimedByAgent: totals.claimedByAgent,
        claimedByOfficer: totals.claimedByOfficer,
        coveragePct:
          totals.potential > 0
            ? Number(((totals.loaded / totals.potential) * 100).toFixed(1))
            : 0,
      },
      explanation: {
        availableToday:
          "ZIPs currently stored in MongoDB. Payable ZIPs also have Census population > 0 (needed for pricing).",
        potentialTarget:
          "Estimated residential ZIP territories across rebate-allowed states (~27,000+). These are planning targets until the full catalog is imported.",
        whatBlocksRemaining:
          "Remaining ZIPs are not yet loaded (or lack population). State lists are seeded from GeoNames (max 500 per first fetch) and only when a state has zero cached rows; Census ACS enrichment is required before a ZIP is offered as payable.",
        etaNote:
          "No hard ship date is stored in the API. Full coverage requires a bulk ZIP + population import for each rebate-allowed state, then deploy.",
      },
      states,
    });
  } catch (error) {
    console.error("Error in getZipCoverage:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Platform payment / subscription overview from user.subscriptions[].
 */
export const getPaymentsOverview = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 25, 100);
    const skip = (page - 1) * limit;
    const statusFilter = req.query.status;
    const search = req.query.search;

    const matchStage = {
      "subscriptions.0": { $exists: true },
    };
    if (search) {
      matchStage.$or = [
        { fullname: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }

    const pipeline = [
      { $match: matchStage },
      { $unwind: "$subscriptions" },
    ];

    if (statusFilter) {
      pipeline.push({
        $match: { "subscriptions.subscriptionStatus": statusFilter },
      });
    }

    const summaryPipeline = [
      ...pipeline,
      {
        $group: {
          _id: null,
          totalSubscriptions: { $sum: 1 },
          active: {
            $sum: {
              $cond: [
                {
                  $in: [
                    "$subscriptions.subscriptionStatus",
                    ["active", "trialing", "paid"],
                  ],
                },
                1,
                0,
              ],
            },
          },
          cancelled: {
            $sum: {
              $cond: [
                {
                  $in: [
                    "$subscriptions.subscriptionStatus",
                    ["cancelled", "expired"],
                  ],
                },
                1,
                0,
              ],
            },
          },
          pastDue: {
            $sum: {
              $cond: [
                { $eq: ["$subscriptions.subscriptionStatus", "past_due"] },
                1,
                0,
              ],
            },
          },
          revenueRecorded: {
            $sum: { $ifNull: ["$subscriptions.amountPaid", 0] },
          },
          agentSubs: {
            $sum: {
              $cond: [
                { $eq: ["$subscriptions.subscriptionRole", "agent"] },
                1,
                0,
              ],
            },
          },
          loanOfficerSubs: {
            $sum: {
              $cond: [
                { $eq: ["$subscriptions.subscriptionRole", "loanofficer"] },
                1,
                0,
              ],
            },
          },
        },
      },
    ];

    const listPipeline = [
      ...pipeline,
      { $sort: { "subscriptions.createdAt": -1 } },
      {
        $facet: {
          total: [{ $count: "count" }],
          rows: [
            { $skip: skip },
            { $limit: limit },
            {
              $project: {
                _id: 0,
                userId: "$_id",
                name: "$fullname",
                email: "$email",
                role: "$role",
                zipcode: "$subscriptions.zipcode",
                population: "$subscriptions.population",
                status: "$subscriptions.subscriptionStatus",
                subscriptionRole: "$subscriptions.subscriptionRole",
                amountPaid: "$subscriptions.amountPaid",
                stripeSubscriptionId: "$subscriptions.stripeSubscriptionId",
                subscriptionStart: "$subscriptions.subscriptionStart",
                subscriptionEnd: "$subscriptions.subscriptionEnd",
                createdAt: "$subscriptions.createdAt",
              },
            },
          ],
        },
      },
    ];

    const [summaryRows, listResult] = await Promise.all([
      userModel.aggregate(summaryPipeline),
      userModel.aggregate(listPipeline),
    ]);

    const summary = summaryRows[0] || {
      totalSubscriptions: 0,
      active: 0,
      cancelled: 0,
      pastDue: 0,
      revenueRecorded: 0,
      agentSubs: 0,
      loanOfficerSubs: 0,
    };

    const total =
      listResult[0]?.total?.[0]?.count || 0;
    const totalPages = Math.ceil(total / limit) || 1;

    res.status(200).json({
      success: true,
      summary: {
        totalSubscriptions: summary.totalSubscriptions,
        active: summary.active,
        cancelled: summary.cancelled,
        pastDue: summary.pastDue,
        revenueRecorded: summary.revenueRecorded,
        agentSubs: summary.agentSubs,
        loanOfficerSubs: summary.loanOfficerSubs,
      },
      count: listResult[0]?.rows?.length || 0,
      total,
      totalPages,
      currentPage: page,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1,
      payments: listResult[0]?.rows || [],
    });
  } catch (error) {
    console.error("Error in getPaymentsOverview:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * High-level platform analytics for the admin dashboard.
 */
export const getAnalytics = async (req, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const [
      userStats,
      zipStats,
      listingCount,
      waitlistCount,
      signupsByDay,
      paymentSummary,
    ] = await Promise.all([
      userModel.aggregate([
        {
          $group: {
            _id: "$role",
            count: { $sum: 1 },
            verified: {
              $sum: { $cond: [{ $eq: ["$verified", true] }, 1, 0] },
            },
          },
        },
      ]),
      zipCodeModel.aggregate([
        {
          $group: {
            _id: null,
            loaded: { $sum: 1 },
            withPopulation: {
              $sum: {
                $cond: [{ $gt: [{ $ifNull: ["$population", 0] }, 0] }, 1, 0],
              },
            },
            claimedByAgent: {
              $sum: { $cond: [{ $eq: ["$claimedByAgent", true] }, 1, 0] },
            },
            claimedByOfficer: {
              $sum: { $cond: [{ $eq: ["$claimedByOfficer", true] }, 1, 0] },
            },
          },
        },
      ]),
      listings.countDocuments({}),
      WaitingListModel.countDocuments({}).catch(() => 0),
      userModel.aggregate([
        { $match: { createdAt: { $gte: thirtyDaysAgo } } },
        {
          $group: {
            _id: {
              $dateToString: { format: "%Y-%m-%d", date: "$createdAt" },
            },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      userModel.aggregate([
        { $unwind: { path: "$subscriptions", preserveNullAndEmptyArrays: false } },
        {
          $group: {
            _id: null,
            active: {
              $sum: {
                $cond: [
                  {
                    $in: [
                      "$subscriptions.subscriptionStatus",
                      ["active", "trialing", "paid"],
                    ],
                  },
                  1,
                  0,
                ],
              },
            },
            revenueRecorded: {
              $sum: { $ifNull: ["$subscriptions.amountPaid", 0] },
            },
          },
        },
      ]),
    ]);

    const roles = Object.fromEntries(
      userStats.map((r) => [r._id || "unknown", r])
    );
    const zips = zipStats[0] || {
      loaded: 0,
      withPopulation: 0,
      claimedByAgent: 0,
      claimedByOfficer: 0,
    };
    const payments = paymentSummary[0] || { active: 0, revenueRecorded: 0 };

    res.status(200).json({
      success: true,
      analytics: {
        users: {
          total: userStats.reduce((s, r) => s + r.count, 0),
          buyers: roles["buyer/seller"]?.count || 0,
          agents: roles.agent?.count || 0,
          loanOfficers: roles.loanofficer?.count || 0,
          admins:
            (roles.admin?.count || 0) + (roles.mainadmin?.count || 0),
          verifiedAgents: roles.agent?.verified || 0,
          verifiedLoanOfficers: roles.loanofficer?.verified || 0,
        },
        zips: {
          platformTarget: PLATFORM_ZIP_TARGET,
          loaded: zips.loaded,
          payable: zips.withPopulation,
          claimedByAgent: zips.claimedByAgent,
          claimedByOfficer: zips.claimedByOfficer,
          remainingVsTarget: Math.max(0, PLATFORM_ZIP_TARGET - zips.loaded),
        },
        listings: { total: listingCount },
        waitlist: { total: waitlistCount },
        payments: {
          activeSubscriptions: payments.active,
          revenueRecorded: payments.revenueRecorded,
        },
        signupsLast30Days: signupsByDay,
      },
    });
  } catch (error) {
    console.error("Error in getAnalytics:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};
