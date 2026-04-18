# ineTeam Cloud Functions

Firebase Cloud Functions for ineTeam backend automation.

## Functions

### 1. `autoDeleteExpiredMatches` (Scheduled)
- **Trigger**: Runs every hour
- **Purpose**: Automatically deletes matches that have passed their scheduled time and don't have enough players
- **Deployment**: Automatic with `firebase deploy --only functions`

### 2. `manualDeleteExpiredMatches` (Callable)
- **Trigger**: Called from Flutter app
- **Purpose**: Manually trigger the deletion process (useful for testing)
- **Authentication**: Requires authenticated user
- **Usage**: Can be called from the Flutter app when needed

## Setup & Deployment

### Prerequisites
- Node.js 20 or higher
- Firebase CLI installed
- Authenticated with Firebase project

### Installation
```bash
cd functions
npm install
```

### Local Testing
```bash
cd functions
npm run serve
```

### Deploy to Firebase
```bash
firebase deploy --only functions
```

### View Logs
```bash
firebase functions:log
```

## How It Works

### Auto-Delete Process
1. Function queries all matches with `dateTime` <= now and status in ["open", "full"]
2. For each expired match, checks if `playerIds.length < maxPlayers`
3. If incomplete, deletes the match and creates a notification for each player
4. Notifications stored in `users/{userId}/notifications` subcollection

### Notifications
When a match is deleted, each player receives a notification with:
- Match details (sport, location, time)
- Reason: "Not enough players joined"
- Timestamp of deletion

## Firestore Rules

Ensure these rules allow Cloud Functions to write notifications:

```javascript
match /users/{uid}/notifications/{notificationId} {
  allow read: if request.auth.uid == uid;
  allow write: if request.auth.uid == uid || request.auth == null;  // Allow server writes
}
```

## Future Enhancements

- Push notifications via Firebase Cloud Messaging (FCM)
- Email notifications to players
- Configurable deletion schedules per sport
- Automatic match rescheduling if enough players join
