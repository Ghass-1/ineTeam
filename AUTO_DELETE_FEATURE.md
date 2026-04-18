# Auto-Delete Expired Matches Feature

This feature automatically deletes matches when their scheduled time has passed and they don't have the required number of players.

## Implementation Overview

### 1. **Client-Side (Flutter)**
- `MatchService.autoDeleteExpiredMatches()` - Checks Firestore for expired incomplete matches
- `MatchProvider._autoDeleteExpiredMatches()` - Triggers auto-delete whenever match list updates
- Provides immediate feedback in the UI

### 2. **Server-Side (Cloud Functions)**
- **Scheduled Function** (`autoDeleteExpiredMatches`) - Runs every hour automatically
- **Manual Trigger** (`manualDeleteExpiredMatches`) - Can be called from the app for testing

### 3. **Notification System**
- When a match is deleted, notifications are created for all players
- Stored in `users/{userId}/notifications` subcollection
- Can be enhanced with push notifications later

## How It Works

### Deletion Logic
1. Query all matches with `dateTime` ≤ now and status in ["open", "full"]
2. For each match, check: `playerCount < maxPlayers`
3. If true, delete the match
4. Create notifications for all players in the deleted match

### Example
- Sport: Football
- Max Players: 10
- Current Players: 7
- Match Time: 2:00 PM (NOW PASSED)
- **Result**: ❌ DELETED (insufficient players)

---

- Match Time: 2:00 PM (NOW PASSED)  
- Current Players: 10
- Max Players: 10
- **Result**: ✅ KEPT (enough players - proceed with match)

## File Changes

### Flutter App
```
lib/data/services/
  ├── match_service.dart          (+ autoDeleteExpiredMatches method)
  └── cloud_functions_service.dart (new)

lib/data/repositories/
  └── match_repository.dart       (+ autoDeleteExpiredMatches method)

lib/features/matches/
  └── match_provider.dart         (+ _autoDeleteExpiredMatches call)
```

### Cloud Functions
```
functions/
├── lib/
│   └── index.js                 (Cloud Functions implementation)
├── package.json
├── .eslintrc.json
├── .gitignore
└── README.md
```

## Deployment Steps

### 1. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Update Firestore Security Rules
Make sure notifications subcollection is writable by Cloud Functions:

```javascript
match /users/{uid}/notifications/{notificationId} {
  allow read: if request.auth.uid == uid;
  allow write: if request.auth.uid == uid || request.auth == null;
}
```

### 3. Test the Feature
- Create a test match with past date and < max players
- Run the app and check:
  - Logs show deletion attempt
  - Match disappears from Firestore
  - Notifications created for players

## Testing Checklist

- [ ] Create match with past date and incomplete players → Auto-deleted ✅
- [ ] Create match with past date but full players → NOT deleted ✅
- [ ] Create match with future date → NOT deleted ✅
- [ ] Check notifications appear for deleted match players
- [ ] Verify logs show deletion attempts
- [ ] Test on web, iOS, and Android

## Future Enhancements

1. **Push Notifications** - Send FCM notifications when match deleted
2. **Email Notifications** - Email players about cancelled matches
3. **Auto-Reschedule** - Automatically reschedule if more players join
4. **Configurable Windows** - Different rules per sport
5. **Match Completion** - Auto-mark matches as completed if enough players
6. **Admin Dashboard** - View deleted matches and reasons

## Firestore Impact

### Before
```
matches/
  ├── match1 (3/10 players, time passed)  ← Still there
  ├── match2 (10/10 players, time passed) ← Still there
  └── match3 (5/8 players, future)        ← Still there
```

### After
```
matches/
  ├── match2 (10/10 players, time passed) ← Kept (full)
  └── match3 (5/8 players, future)        ← Kept (future)
  ✅ match1 deleted + notifications created
```

## Monitoring

View Cloud Function logs:
```bash
firebase functions:log
```

Look for messages like:
```
[MatchService] Auto-deleting expired match: abc123 (7/10 players)
[MatchService] Would notify 7 players about match deletion
```

## Notes

- Client-side deletion triggers when matches stream updates
- Server-side deletion runs hourly via Cloud Scheduler
- Both are independent and safe to run together
- Notifications stored but not yet sent (can add FCM later)
- All deletions logged for debugging
