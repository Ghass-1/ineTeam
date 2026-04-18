const admin = require("firebase-admin");
const functions = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: Scheduled job that runs every hour to delete expired matches
 * with insufficient players (fewer than required maxPlayers).
 * 
 * Triggers: Every hour at minute 0
 * Returns: Number of matches deleted
 */
exports.autoDeleteExpiredMatches = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async (context) => {
    console.log("Starting auto-delete expired matches job...");

    const now = new Date();
    const batch = db.batch();
    let deletedCount = 0;

    try {
      // Query all non-completed matches with dateTime in the past
      const expiredMatches = await db.collection("matches")
        .where("dateTime", "<=", now)
        .where("status", "in", ["open", "full"])
        .get();

      console.log(`Found ${expiredMatches.docs.length} expired matches`);

      for (const doc of expiredMatches.docs) {
        const match = doc.data();
        const playerCount = (match.playerIds || []).length;
        const maxPlayers = match.maxPlayers || 0;

        // Delete if fewer players than required
        if (playerCount < maxPlayers) {
          console.log(
            `Deleting match ${doc.id} (${playerCount}/${maxPlayers} players)`
          );

          batch.delete(db.collection("matches").doc(doc.id));
          deletedCount++;

          // Optionally: Store a notification for each player
          const playerIds = match.playerIds || [];
          for (const playerId of playerIds) {
            batch.set(
              db.collection("users").doc(playerId).collection("notifications").doc(),
              {
                type: "match_cancelled",
                matchId: doc.id,
                matchSport: match.sport,
                matchLocation: match.location,
                matchDateTime: match.dateTime,
                reason: "Not enough players joined",
                createdAt: now,
                read: false,
              },
              { merge: false }
            );
          }
        }
      }

      // Commit all deletions and notifications
      await batch.commit();

      console.log(`Successfully deleted ${deletedCount} expired matches`);
      return { success: true, deletedCount };
    } catch (error) {
      console.error("Error in auto-delete function:", error);
      throw error;
    }
  });

/**
 * Optional: HTTP endpoint to manually trigger the auto-delete
 * (useful for testing or manual triggers)
 */
exports.manualDeleteExpiredMatches = functions.https.onCall(
  async (data, context) => {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    console.log(`Manual trigger by user: ${context.auth.uid}`);

    const now = new Date();
    const batch = db.batch();
    let deletedCount = 0;

    try {
      const expiredMatches = await db.collection("matches")
        .where("dateTime", "<=", now)
        .where("status", "in", ["open", "full"])
        .get();

      for (const doc of expiredMatches.docs) {
        const match = doc.data();
        const playerCount = (match.playerIds || []).length;
        const maxPlayers = match.maxPlayers || 0;

        if (playerCount < maxPlayers) {
          batch.delete(db.collection("matches").doc(doc.id));
          deletedCount++;

          // Notify players
          const playerIds = match.playerIds || [];
          for (const playerId of playerIds) {
            batch.set(
              db.collection("users").doc(playerId).collection("notifications").doc(),
              {
                type: "match_cancelled",
                matchId: doc.id,
                matchSport: match.sport,
                matchLocation: match.location,
                matchDateTime: match.dateTime,
                reason: "Not enough players joined",
                createdAt: now,
                read: false,
              }
            );
          }
        }
      }

      await batch.commit();

      return {
        success: true,
        message: `Deleted ${deletedCount} expired matches`,
        deletedCount,
      };
    } catch (error) {
      console.error("Error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);
