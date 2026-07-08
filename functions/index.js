const fs = require("fs");
const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const Stripe = require("stripe");
const cors = require("cors")({origin: true});

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || "";

if (credentialsPath) {
  if (credentialsPath.includes("path\\to\\your-service-account-file.json")) {
    throw new Error(
        "GOOGLE_APPLICATION_CREDENTIALS is still set to the placeholder path. " +
        "Point it to a real Firebase service-account JSON or clear the variable before running Functions locally.",
    );
  }

  if (!fs.existsSync(credentialsPath)) {
    throw new Error(
        `GOOGLE_APPLICATION_CREDENTIALS points to a missing file: ${credentialsPath}. ` +
        "Point it to a real Firebase service-account JSON or clear the variable before running Functions locally.",
    );
  }
}

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const Timestamp = admin.firestore.Timestamp;

const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "";

function getStripeClient() {
  if (!stripeSecretKey) {
    throw new Error(
        "Missing STRIPE_SECRET_KEY. Set a real Stripe secret key before testing payment intents.",
    );
  }

  return new Stripe(stripeSecretKey);
}

const ORDER_STATUS_LABELS = {
  confirmed: "Order placed",
  processing: "Order received",
  received: "Order received",
  preparing: "Preparing order",
  ready: "Ready for pickup",
  finding_rider: "Rider assigned",
  picked_up: "Picked up",
  on_the_way: "On the way",
  delivered: "Delivered",
  cancelled: "Cancelled",
  rejected: "Rejected",
};

const ADMIN_MUTABLE_ORDER_STATUSES = new Set([
  "confirmed",
  "preparing",
  "ready",
  "finding_rider",
  "picked_up",
  "on_the_way",
  "delivered",
  "cancelled",
  "rejected",
]);

function getRolesMap(data) {
  if (!data || typeof data !== "object") {
    return {};
  }

  const roles = data.roles;
  if (!roles || typeof roles !== "object") {
    return {};
  }

  return roles;
}

function userHasRole(data, role) {
  if (!data || typeof data !== "object") {
    return false;
  }

  const roles = getRolesMap(data);
  if (roles[role] === true) {
    return true;
  }

  return data.user_category === role || data.role === role;
}

function normalizePhoneNumber(input) {
  const cleaned = String(input || "").trim().replace(/[\s\-()]/g, "");
  if (!cleaned) return "";

  if (cleaned.startsWith("+94")) return cleaned;
  if (cleaned.startsWith("94")) return `+${cleaned}`;
  if (cleaned.startsWith("0")) return `+94${cleaned.slice(1)}`;
  return `+94${cleaned}`;
}

function isTemporaryEmail(email) {
  return String(email || "").trim().toLowerCase().endsWith("@temp.com");
}

function maskEmail(email) {
  const trimmed = String(email || "").trim().toLowerCase();
  const parts = trimmed.split("@");
  if (parts.length !== 2) {
    return trimmed;
  }

  const [localPart, domain] = parts;
  if (!localPart) {
    return `***@${domain}`;
  }

  const visiblePrefix = localPart.slice(0, Math.min(2, localPart.length));
  const hiddenCount = Math.max(
      1,
      Math.min(6, localPart.length - visiblePrefix.length),
  );
  return `${visiblePrefix}${"*".repeat(hiddenCount)}@${domain}`;
}

function notificationTitleForStatus(status) {
  return ORDER_STATUS_LABELS[status] || "Order update";
}

function notificationBodyForStatus(status, orderId) {
  const shortId = orderId ? `#${orderId}` : "your order";
  switch (status) {
    case "confirmed":
      return `${shortId} was sent to the restaurant.`;
    case "preparing":
      return `${shortId} was accepted and is now being prepared.`;
    case "ready":
      return `${shortId} is ready for pickup.`;
    case "finding_rider":
      return `A rider has been assigned to ${shortId}.`;
    case "picked_up":
      return `${shortId} was picked up by the rider.`;
    case "on_the_way":
      return `${shortId} is on the way.`;
    case "delivered":
      return `${shortId} was delivered successfully.`;
    case "cancelled":
      return `${shortId} was cancelled.`;
    case "rejected":
      return `${shortId} was rejected by the restaurant.`;
    default:
      return `${shortId} was updated.`;
  }
}

function statusHistoryEntry(status, actorType, actorId, note) {
  return {
    status,
    actorType,
    actorId: actorId || null,
    note: note || null,
    at: Timestamp.now(),
  };
}

function actorForStatus(status, order) {
  switch (status) {
    case "confirmed":
    case "processing":
    case "received":
      return {type: "user", id: order.userId || null};
    case "preparing":
    case "ready":
    case "rejected":
      return {type: "restaurant", id: order.restaurantId || null};
    case "finding_rider":
      return {type: "system", id: "dispatch"};
    case "picked_up":
    case "on_the_way":
    case "delivered":
      return {type: "rider", id: order.assignedRiderId || null};
    case "cancelled":
      return {type: "user", id: order.userId || null};
    default:
      return {type: "system", id: "workflow"};
  }
}

function riderSnapshotFromData(riderId, rider) {
  return {
    riderId,
    name: rider.name || rider.fullName || "Rider",
    phone: rider.phone || "",
    vehicle:
      rider.vehicle ||
      rider.vehicleNumber ||
      rider.vehicleType ||
      rider.bikeNumber ||
      "",
    rating: typeof rider.rating === "number" ? rider.rating : 4.8,
  };
}

async function addUserNotification(userId, payload) {
  if (!userId) return;
  await db.collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        ...payload,
        read: false,
        createdAt: FieldValue.serverTimestamp(),
      });
  await sendUserPushNotification(userId, payload);
}

async function sendUserPushNotification(userId, payload) {
  const userSnap = await db.collection("users").doc(userId).get();
  if (!userSnap.exists) return;

  const user = userSnap.data() || {};
  const settings = user.notificationSettings || {};
  if (settings.deliveryRequests === false) return;

  const tokens = new Set();
  if (typeof user.fcmToken === "string" && user.fcmToken) {
    tokens.add(user.fcmToken);
  }
  if (Array.isArray(user.fcmTokens)) {
    user.fcmTokens
        .filter((token) => typeof token === "string" && token)
        .forEach((token) => tokens.add(token));
  }
  if (!tokens.size) return;

  await admin.messaging().sendEachForMulticast({
    tokens: Array.from(tokens),
    notification: {
      title: payload.title || "Nico Mart Rider",
      body: payload.body || "You have a new update.",
    },
    data: {
      type: String(payload.type || "notification"),
      orderId: String(payload.orderId || ""),
      riderId: String(payload.riderId || ""),
      restaurantId: String(payload.restaurantId || ""),
    },
    android: {
      priority: "high",
      notification: {
        sound: "default",
        priority: "high",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  });
}

async function addAdminNotification(payload) {
  await db.collection("admin_notifications").add({
    ...payload,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function syncUserOrderMirror(orderId, orderData) {
  if (!orderData.userId) return;
  await db.collection("users")
      .doc(orderData.userId)
      .collection("orders")
      .doc(orderId)
      .set({
        orderId,
        orderDate: orderData.orderDate || orderData.createdAt || FieldValue.serverTimestamp(),
        totalAmount: orderData.totalAmount || 0,
        orderStatus: orderData.orderStatus || "confirmed",
        restaurantId: orderData.restaurantId || "",
        restaurantName: orderData.restaurantName || "",
        paymentMethod: orderData.paymentMethod || "",
        paymentStatus: orderData.paymentStatus || "pending",
        assignedRiderId: orderData.assignedRiderId || null,
        assignedRider: orderData.assignedRider || null,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
}

async function releaseAssignedRider(orderData) {
  if (!orderData.assignedRiderId) return;
  const batch = db.batch();
  batch.set(db.collection("riders").doc(orderData.assignedRiderId), {
    availability: "available",
    currentOrderId: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  batch.set(db.collection("users").doc(orderData.assignedRiderId), {
    riderAvailability: "available",
    currentOrderId: FieldValue.delete(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  await batch.commit();
}

async function assignOrderToSpecificRider(orderId, orderData, riderId, riderData) {
  const orderRef = db.collection("orders_sl").doc(orderId);
  const riderRef = db.collection("riders").doc(riderId);
  const riderUserRef = db.collection("users").doc(riderId);
  const assignmentRef = riderRef.collection("assignments").doc(orderId);
  let finalOrderData = orderData;
  let finalRiderData = riderData;
  let assignedRider = null;

  await db.runTransaction(async (tx) => {
    const [orderSnap, riderSnap] = await Promise.all([
      tx.get(orderRef),
      tx.get(riderRef),
    ]);

    if (!orderSnap.exists || !riderSnap.exists) {
      return;
    }

    const currentOrder = orderSnap.data() || {};
    const currentRider = riderSnap.data() || {};

    if (currentOrder.orderStatus !== "ready" || currentOrder.assignedRiderId) {
      return;
    }

    if (
      currentRider.approvalStatus !== "approved" ||
      currentRider.availability !== "available"
    ) {
      return;
    }

    finalOrderData = currentOrder;
    finalRiderData = currentRider;
    assignedRider = riderSnapshotFromData(riderId, currentRider);

    tx.set(orderRef, {
      orderStatus: "finding_rider",
      assignedRiderId: riderId,
      assignedRider,
      assignmentStatus: "assigned",
      riderAssignedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.set(riderRef, {
      availability: "busy",
      currentOrderId: orderId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.set(riderUserRef, {
      riderAvailability: "busy",
      currentOrderId: orderId,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.set(assignmentRef, {
      orderId,
      userId: currentOrder.userId || "",
      restaurantId: currentOrder.restaurantId || "",
      totalAmount: currentOrder.totalAmount || 0,
      status: "assigned",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });

  if (!assignedRider || !finalOrderData || !finalRiderData) {
    return null;
  }

  await Promise.all([
    addUserNotification(riderId, {
      type: "rider_assignment",
      title: "New delivery assigned",
      body: `Order #${orderId} is ready for pickup.`,
      orderId,
    }),
    addUserNotification(finalOrderData.userId, {
      type: "order_status",
      title: "Rider assigned",
      body: notificationBodyForStatus("finding_rider", orderId),
      orderId,
    }),
    addUserNotification(finalOrderData.restaurantId, {
      type: "restaurant_dispatch",
      title: "Rider assigned",
      body: `A rider was assigned to order #${orderId}.`,
      orderId,
    }),
  ]);

  console.log("Assigned ready order to rider", {
    orderId,
    riderId,
    restaurantId: finalOrderData.restaurantId || null,
  });

  return assignedRider;
}

async function assignOrderToAvailableRider(orderId, orderData) {
  if (orderData.assignedRiderId) return null;

  const availableRiders = await db.collection("riders")
      .where("approvalStatus", "==", "approved")
      .where("availability", "==", "available")
      .orderBy("updatedAt", "asc")
      .limit(20)
      .get();

  if (availableRiders.empty) {
    await db.collection("orders_sl").doc(orderId).set({
      assignmentStatus: "searching",
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return null;
  }

  for (const riderDoc of availableRiders.docs) {
    const assignedRider = await assignOrderToSpecificRider(
        orderId,
        orderData,
        riderDoc.id,
        riderDoc.data(),
    );

    if (assignedRider) {
      return assignedRider;
    }
  }

  await db.collection("orders_sl").doc(orderId).set({
    assignmentStatus: "searching",
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return null;
}

async function assignOldestReadyOrderToRider(riderId, riderData) {
  const readyOrders = await db.collection("orders_sl")
      .where("orderStatus", "==", "ready")
      .orderBy("createdAt", "asc")
      .limit(20)
      .get();

  for (const orderDoc of readyOrders.docs) {
    const order = orderDoc.data() || {};
    if (order.assignedRiderId) {
      continue;
    }

    const assignedRider = await assignOrderToSpecificRider(
        orderDoc.id,
        order,
        riderId,
        riderData,
    );

    if (assignedRider) {
      return assignedRider;
    }
  }

  return null;
}

async function isAdminUser(uid) {
  if (!uid) return false;
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) return false;
  const data = userSnap.data() || {};
  return userHasRole(data, "admin");
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function demoRoutePoints(start, end, steps = 40) {
  const points = [];
  for (let index = 0; index <= steps; index++) {
    const t = index / steps;
    const bend = Math.sin(t * Math.PI) * 0.0012;
    points.push({
      latitude: start.latitude + ((end.latitude - start.latitude) * t) - bend,
      longitude:
        start.longitude + ((end.longitude - start.longitude) * t) +
        (bend * 0.55),
    });
  }
  return points;
}

function bearingBetween(from, to) {
  const lat1 = from.latitude * Math.PI / 180;
  const lat2 = to.latitude * Math.PI / 180;
  const dLng = (to.longitude - from.longitude) * Math.PI / 180;
  const y = Math.sin(dLng) * Math.cos(lat2);
  const x =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(dLng);
  return ((Math.atan2(y, x) * 180 / Math.PI) + 360) % 360;
}

async function isDemoOrderActive(orderId) {
  const snap = await db.collection("orders_sl").doc(orderId).get();
  if (!snap.exists) return false;

  const status = (snap.data() || {}).orderStatus || "";
  return status !== "cancelled" && status !== "delivered";
}

async function updateDemoOrderState(userId, orderId, status, extra = {}) {
  const patch = {
    orderStatus: status,
    updatedAt: FieldValue.serverTimestamp(),
    ...extra,
  };

  const batch = db.batch();
  batch.set(db.collection("orders_sl").doc(orderId), patch, {merge: true});
  batch.set(
      db.collection("users").doc(userId).collection("orders").doc(orderId),
      {
        orderStatus: status,
        updatedAt: FieldValue.serverTimestamp(),
      },
      {merge: true},
  );
  await batch.commit();
}

exports.startDemoOrderFlow = functions
    .runWith({timeoutSeconds: 180, memory: "256MB"})
    .https.onCall(async (data, context) => {
      if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "You must be signed in to start the demo order flow.",
        );
      }

      const orderId = data && data.orderId ? String(data.orderId).trim() : "";
      if (!orderId) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "A valid orderId is required.",
        );
      }

      const orderRef = db.collection("orders_sl").doc(orderId);
      const orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        throw new functions.https.HttpsError(
            "not-found",
            "Order was not found.",
        );
      }

      const order = orderSnap.data() || {};
      if (order.userId !== context.auth.uid) {
        throw new functions.https.HttpsError(
            "permission-denied",
            "Only the customer can start this demo flow.",
        );
      }

      if (order.demoFlowStartedAt) {
        return {success: true, alreadyStarted: true};
      }

      const deliveryAddress = order.deliveryAddress || {};
      const latitude = Number(deliveryAddress.latitude);
      const longitude = Number(deliveryAddress.longitude);
      if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        throw new functions.https.HttpsError(
            "failed-precondition",
            "Order delivery coordinates are missing.",
        );
      }

      await orderRef.set({
        demoFlow: true,
        demoFlowStartedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      const deliveryPoint = {latitude, longitude};
      const restaurantPoint = {
        latitude: latitude + 0.011,
        longitude: longitude + 0.011,
      };
      const assignedRider = {
        name: "Nico Rider",
        phone: "+94 71 234 5678",
        vehicle: "Bike LK-2456",
        rating: 4.9,
      };

      await sleep(3000);
      if (!await isDemoOrderActive(orderId)) return {success: true};
      await updateDemoOrderState(order.userId, orderId, "ready");

      await sleep(3000);
      if (!await isDemoOrderActive(orderId)) return {success: true};
      await updateDemoOrderState(order.userId, orderId, "picked_up", {
        assignedRider,
        riderLocation: {
          latitude: restaurantPoint.latitude,
          longitude: restaurantPoint.longitude,
          bearing: bearingBetween(restaurantPoint, deliveryPoint),
        },
      });

      const routePoints = demoRoutePoints(restaurantPoint, deliveryPoint);
      const travelDelay = Math.floor(120000 / (routePoints.length - 1));

      for (let index = 1; index < routePoints.length; index++) {
        await sleep(travelDelay);
        if (!await isDemoOrderActive(orderId)) return {success: true};

        const previousPoint = routePoints[index - 1];
        const nextPoint = routePoints[index];
        await updateDemoOrderState(order.userId, orderId, "on_the_way", {
          assignedRider,
          riderLocation: {
            latitude: nextPoint.latitude,
            longitude: nextPoint.longitude,
            bearing: bearingBetween(previousPoint, nextPoint),
          },
        });
      }

      await sleep(1000);
      if (!await isDemoOrderActive(orderId)) return {success: true};
      await updateDemoOrderState(order.userId, orderId, "delivered", {
        paymentStatus: "paid",
        deliveredAt: FieldValue.serverTimestamp(),
        demoFlowCompletedAt: FieldValue.serverTimestamp(),
      });

      return {success: true};
    });

exports.lookupAuthEmailByPhone = functions.https.onCall(async (data) => {
  const rawPhone = data && data.phone ? String(data.phone) : "";
  const phone = normalizePhoneNumber(rawPhone);

  if (!phone) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid phone number is required.",
    );
  }

  const userSnap = await db.collection("users")
      .where("phone", "==", phone)
      .limit(1)
      .get();

  if (userSnap.empty) {
    throw new functions.https.HttpsError(
        "not-found",
        "No account found with this phone number.",
    );
  }

  const userData = userSnap.docs[0].data() || {};
  const authEmail = String(userData.email || "").trim().toLowerCase();

  if (!authEmail) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "This account does not have a valid sign-in email.",
    );
  }

  const temporaryEmail = isTemporaryEmail(authEmail);

  return {
    authEmail,
    maskedEmail: maskEmail(authEmail),
    canResetPassword: !temporaryEmail,
    isTemporaryEmail: temporaryEmail,
  };
});

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const {amount, currency, metadata} = req.body || {};
      const stripe = getStripeClient();

      if (!amount || amount <= 0) {
        return res.status(400).send({error: "Invalid amount"});
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency: currency || "eur",
        metadata: metadata || {},
        automatic_payment_methods: {enabled: true},
      });

      return res.status(200).send({
        clientSecret: paymentIntent.client_secret,
        id: paymentIntent.id,
      });
    } catch (error) {
      console.error("Stripe Error:", error);
      return res.status(500).send({error: error.message});
    }
  });
});

exports.syncOrderLifecycle = functions.firestore
    .document("orders_sl/{orderId}")
    .onWrite(async (change, context) => {
      const orderId = context.params.orderId;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;

      if (!after) {
        if (before) {
          await releaseAssignedRider(before);
        }
        return null;
      }

      const updates = {};
      const isCreate = !before;
      const statusBefore = before ? before.orderStatus : null;
      const statusAfter = after.orderStatus || "confirmed";

      if (isCreate) {
        if (!after.orderStatus) {
          updates.orderStatus = "confirmed";
        }
        if (!Array.isArray(after.statusHistory) || !after.statusHistory.length) {
          const actor = actorForStatus(statusAfter, after);
          updates.statusHistory = [
            statusHistoryEntry(
                statusAfter,
                actor.type,
                actor.id,
                "Order created",
            ),
          ];
        }
        if (!after.createdAt) {
          updates.createdAt = FieldValue.serverTimestamp();
        }
        updates.updatedAt = FieldValue.serverTimestamp();
      } else if (statusBefore !== statusAfter) {
        const actor = actorForStatus(statusAfter, after);
        updates.statusHistory = FieldValue.arrayUnion(
            statusHistoryEntry(
                statusAfter,
                actor.type,
                actor.id,
                notificationTitleForStatus(statusAfter),
            ),
        );
        updates.updatedAt = FieldValue.serverTimestamp();
      }

      if (Object.keys(updates).length) {
        await change.after.ref.set(updates, {merge: true});
      }

      const orderForMirror = {
        ...after,
        orderStatus: updates.orderStatus || after.orderStatus || "confirmed",
      };
      await syncUserOrderMirror(orderId, orderForMirror);

      if (isCreate) {
        await Promise.all([
          addUserNotification(after.userId, {
            type: "order_status",
            title: notificationTitleForStatus(statusAfter),
            body: notificationBodyForStatus(statusAfter, orderId),
            orderId,
          }),
          addUserNotification(after.restaurantId, {
            type: "restaurant_new_order",
            title: "New order received",
            body: `Order #${orderId} is waiting for restaurant action.`,
            orderId,
          }),
        ]);
        return null;
      }

      if (statusBefore !== statusAfter) {
        await Promise.all([
          addUserNotification(after.userId, {
            type: "order_status",
            title: notificationTitleForStatus(statusAfter),
            body: notificationBodyForStatus(statusAfter, orderId),
            orderId,
          }),
          addUserNotification(after.restaurantId, {
            type: "restaurant_order_status",
            title: notificationTitleForStatus(statusAfter),
            body: `Order #${orderId} moved to ${notificationTitleForStatus(statusAfter)}.`,
            orderId,
          }),
        ]);

        if (statusAfter === "ready" && !after.assignedRiderId &&
            !after.demoFlow) {
          await assignOrderToAvailableRider(orderId, after);
        }

        if (["cancelled", "rejected", "delivered"].includes(statusAfter)) {
          await releaseAssignedRider(after);
        }
      }

      return null;
    });

exports.syncRiderProfile = functions.firestore
    .document("users/{userId}")
    .onWrite(async (change, context) => {
      if (!change.after.exists) return null;

      const userId = context.params.userId;
      const after = change.after.data() || {};
      if (!userHasRole(after, "rider")) return null;

      const approvalStatus =
        after.riderApprovalStatus || after.approvalStatus || "pending";
      const riderDoc = {
        uid: userId,
        name: after.name || after.fullName || "",
        phone: after.phone || "",
        approvalStatus,
        availability:
          approvalStatus === "approved" ?
            (after.riderAvailability || "available") :
            "pending",
        vehicle:
          after.vehicle ||
          after.vehicleNumber ||
          after.vehicleType ||
          "",
        updatedAt: FieldValue.serverTimestamp(),
      };

      await db.collection("riders").doc(userId).set(riderDoc, {merge: true});

      if (!after.riderApprovalStatus || !after.riderAvailability) {
        await change.after.ref.set({
          riderApprovalStatus: approvalStatus,
          riderAvailability: riderDoc.availability,
        }, {merge: true});
      }

      return null;
    });

exports.assignWaitingOrderToAvailableRider = functions.firestore
    .document("riders/{riderId}")
    .onWrite(async (change, context) => {
      if (!change.after.exists) return null;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.data() || {};

      const becameAvailable =
        (!before || before.availability !== "available") &&
        after.availability === "available" &&
        after.approvalStatus === "approved";

      if (!becameAvailable) return null;

      await assignOldestReadyOrderToRider(context.params.riderId, after);
      return null;
    });

exports.registerRiderProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required.",
    );
  }

  const uid = context.auth.uid;
  const profile = data || {};
  const userSnap = await db.collection("users").doc(uid).get();
  const existingUser = userSnap.exists ? userSnap.data() || {} : {};
  const roles = getRolesMap(existingUser);
  roles.rider = true;
  const riderProfile = {
    user_category: existingUser.user_category || "rider",
    roles,
    name: profile.name || "",
    phone: profile.phone || "",
    vehicle: profile.vehicle || profile.vehicleNumber || "",
    licenseNumber: profile.licenseNumber || "",
    riderApprovalStatus: "pending",
    riderAvailability: "pending",
    updatedAt: FieldValue.serverTimestamp(),
  };

  const batch = db.batch();
  batch.set(db.collection("users").doc(uid), riderProfile, {merge: true});
  batch.set(db.collection("riders").doc(uid), {
    uid,
    name: riderProfile.name,
    phone: riderProfile.phone,
    vehicle: riderProfile.vehicle,
    licenseNumber: riderProfile.licenseNumber,
    approvalStatus: "pending",
    availability: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  await batch.commit();

  await addAdminNotification({
    type: "rider_review_required",
    title: "Rider approval pending",
    body: `${riderProfile.name || "A rider"} is waiting for admin approval.`,
    riderId: uid,
  });

  return {success: true, approvalStatus: "pending"};
});

exports.reviewRiderApproval = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required.",
    );
  }

  const isAdmin = await isAdminUser(context.auth.uid);
  if (!isAdmin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access is required.",
    );
  }

  const riderId = data && data.riderId ? String(data.riderId) : "";
  const decision = data && data.decision ? String(data.decision) : "";
  const reason = data && data.reason ? String(data.reason) : "";

  if (!riderId || !["approved", "rejected"].includes(decision)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid riderId and decision are required.",
    );
  }

  const availability = decision === "approved" ? "available" : "rejected";
  const batch = db.batch();
  batch.set(db.collection("users").doc(riderId), {
    riderApprovalStatus: decision,
    riderAvailability: availability,
    reviewedBy: context.auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    reviewReason: reason,
  }, {merge: true});
  batch.set(db.collection("riders").doc(riderId), {
    approvalStatus: decision,
    availability,
    reviewedBy: context.auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    reviewReason: reason,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  await batch.commit();

  await addUserNotification(riderId, {
    type: "rider_review",
    title:
      decision === "approved" ? "Rider account approved" : "Rider account rejected",
    body:
      decision === "approved" ?
        "Your rider account is approved. You can now receive delivery jobs." :
        (reason || "Your rider account was rejected by the admin."),
    riderId,
  });

  return {success: true, riderId, decision};
});

exports.reviewRestaurantApproval = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required.",
    );
  }

  const isAdmin = await isAdminUser(context.auth.uid);
  if (!isAdmin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access is required.",
    );
  }

  const restaurantId = data && data.restaurantId ? String(data.restaurantId) : "";
  const decision = data && data.decision ? String(data.decision) : "";
  const reason = data && data.reason ? String(data.reason) : "";

  if (!restaurantId || !["approved", "rejected"].includes(decision)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid restaurantId and decision are required.",
    );
  }

  const onlineStatus = decision === "approved";
  await db.collection("users").doc(restaurantId).set({
    restaurantApprovalStatus: decision,
    onlineStatus,
    reviewedBy: context.auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    reviewReason: reason,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  await addUserNotification(restaurantId, {
    type: "restaurant_review",
    title:
      decision === "approved" ?
        "Restaurant account approved" :
        "Restaurant account rejected",
    body:
      decision === "approved" ?
        "Your restaurant account is approved. You can now start receiving orders." :
        (reason || "Your restaurant account was rejected by the admin."),
    restaurantId,
  });

  return {success: true, restaurantId, decision};
});

exports.adminSetRestaurantLiveStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required.",
    );
  }

  const isAdmin = await isAdminUser(context.auth.uid);
  if (!isAdmin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access is required.",
    );
  }

  const restaurantId = data && data.restaurantId ? String(data.restaurantId) : "";
  const online = Boolean(data && data.online);

  if (!restaurantId) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid restaurantId is required.",
    );
  }

  const restaurantSnap = await db.collection("users").doc(restaurantId).get();
  const restaurantData = restaurantSnap.exists ? restaurantSnap.data() || {} : {};
  const restaurantApprovalStatus =
    restaurantData.restaurantApprovalStatus ||
    (restaurantData.onlineStatus ? "approved" : "pending");
  if (restaurantApprovalStatus !== "approved") {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "The restaurant must be approved before its live status can be changed.",
    );
  }

  await db.collection("users").doc(restaurantId).set({
    onlineStatus: online,
    updatedAt: FieldValue.serverTimestamp(),
    reviewedBy: context.auth.uid,
  }, {merge: true});

  return {success: true, restaurantId, online};
});

exports.adminUpdateOrderStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required.",
    );
  }

  const isAdmin = await isAdminUser(context.auth.uid);
  if (!isAdmin) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Admin access is required.",
    );
  }

  const orderId = data && data.orderId ? String(data.orderId) : "";
  const status = data && data.status ? String(data.status) : "";
  const note = data && data.note ? String(data.note) : "";

  if (!orderId || !ADMIN_MUTABLE_ORDER_STATUSES.has(status)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid orderId and status are required.",
    );
  }

  await db.collection("orders_sl").doc(orderId).set({
    orderStatus: status,
    adminUpdatedAt: FieldValue.serverTimestamp(),
    adminUpdatedBy: context.auth.uid,
    adminNote: note,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  return {success: true, orderId, status};
});
