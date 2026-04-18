# Quick Setup Guide - Auto-Delete Matches

## What You Just Added

A feature that automatically deletes matches when:
1. ✅ Match scheduled time has passed
2. ✅ Match has fewer players than `maxPlayers`

Players will be notified when their match is deleted.

---

## Step 1: Deploy Cloud Functions

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy to Firebase
firebase deploy --only functions
```

**What this does:**
- Deploys a scheduled function that runs every hour
- Sets up automatic deletion on Firebase servers
- No manual intervention needed

---

## Step 2: Update Firestore Security Rules

In Firebase Console:
1. Go to **Firestore Database** → **Rules** tab
2. Update rules to allow notifications subcollection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      
      // Allow Cloud Functions to write notifications
      match /notifications/{notificationId} {
        allow read: if request.auth.uid == uid;
        allow write: if request.auth.uid == uid || request.auth == null;
      }
    }
    
    match /matches/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Step 3: Test the Feature

### On Your App:
1. Create a test match with:
   - **Date/Time**: Any time in the past (e.g., 1 hour ago)
   - **Max Players**: 10
   - **Current Players**: 5 (less than max)

2. Run the app and check:
   - ✅ Match appears in list initially
   - ✅ After a moment, it disappears (auto-deleted)
   - ✅ Check Firestore console - match document is gone

### Check Logs:
```bash
firebase functions:log
```

Look for:
```
Auto-deleting expired match: [match-id] (5/10 players)
```

---

## How It Works

### Timeline:

**5:00 PM** - Match created for 3:00 PM  
**6:00 PM** - Cloud Function runs:
```
- Finds match with dateTime = 3:00 PM (passed)
- Count players: 5/10 (incomplete)
- ❌ DELETE match
- ✉️ Notify all 5 players
```

**User Experience:**
- Players see notification in app
- Match disappears from their match list
- Reason: "Not enough players joined"

---

## Client-Side Auto-Delete

The Flutter app ALSO checks when:
- Match list loads
- Match details viewed
- Any match stream updates

This provides instant feedback even before the scheduled Cloud Function runs.

---

## Troubleshooting

### Matches not deleting?
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify Firestore rules allow notifications writes
3. Make sure match `dateTime` is in the past
4. Confirm match has `< maxPlayers` players

### Notifications not appearing?
1. Check `users/{userId}/notifications` collection in Firestore
2. Verify security rules allow reads
3. (Later) Set up Firebase Cloud Messaging for push notifications

### Want to test manually?
Create a match with:
- Past date
- Incomplete players
- Run app
- Auto-delete triggers within minutes

---

## What's Next?

The notifications are now stored in Firestore. To enhance:

### Option 1: Push Notifications
- Add `firebase_messaging` to pubspec.yaml
- Show push notification when match deleted
- User clicks → see full details

### Option 2: Email Notifications
- Add Cloud Function email service (SendGrid, Mailgun)
- Send emails to player accounts
- Include match details and reason

### Option 3: In-App Notification Panel
- Create notification UI screen
- Show history of deleted matches
- Allow marking as read

---

## Files Created/Modified

**New:**
- `functions/lib/index.js` - Cloud Function code
- `functions/package.json` - Dependencies
- `lib/data/services/cloud_functions_service.dart` - Flutter service

**Modified:**
- `lib/data/services/match_service.dart` - Added auto-delete logic
- `lib/data/repositories/match_repository.dart` - Added method
- `lib/features/matches/match_provider.dart` - Added trigger

---

## Important Notes

✅ **Both client and server deletion work independently**
- Client: Instant feedback
- Server: Reliable, runs even if app is closed

✅ **Matches are NOT recovered** after deletion
- Think of it like automatic cancellation
- Players are notified

✅ **Only incomplete matches are deleted**
- Full matches proceed (players can play)
- Ensures matches with enough players continue

---

## Need Help?

Check the detailed documentation:
- `AUTO_DELETE_FEATURE.md` - Full feature explanation
- `functions/README.md` - Cloud Functions details
- Firebase console logs - Debugging info
