# Split Matches into Upcoming & Past - Feature Implementation

## Overview

The "My Matches" screen has been split into two tabs with **icons and badge counts**:
- **Upcoming** - Matches scheduled for the future (⏰ icon, shows count)
- **Past** - Matches that have already happened (⏱️ icon, shows count)

## User Experience

### Visual Design

```
My Matches
┌─────────────────┬────────────────┐
│ ⏰ Upcoming (3) │ ⏱️ Past (5)    │
├─────────────────┴────────────────┤
│                                  │
│  Football - Today 3:00 PM        │
│  Volleyball - Tomorrow 4:00 PM   │
│  Tennis - Next week              │
│                                  │
└──────────────────────────────────┘
```

### Tab Information

**Upcoming Tab:**
- ✅ Icon: ⏰ Schedule (clock icon)
- ✅ Shows: Number of upcoming matches (e.g., "Upcoming (3)")
- 📊 Sorted: Chronologically (earliest first)
- 🎯 Use: Quick reference of games coming up

**Past Tab:**
- ✅ Icon: ⏱️ History (stopwatch icon)
- ✅ Shows: Number of past matches (e.g., "Past (5)")
- 📊 Sorted: Reverse chronological (newest first)
- 🎯 Use: View completed games and history

## Implementation Details

### UI Enhancements

1. **Icons in Tabs**
   - Upcoming: `Icons.schedule` (clock icon)
   - Past: `Icons.history` (stopwatch icon)

2. **Badge Counts**
   - Shows count only if > 0
   - Automatically updates when matches change
   - Format: "Upcoming (3)" or just "Upcoming"

3. **State Management**
   - `_upcomingCount` - Stored in widget state
   - `_pastCount` - Stored in widget state
   - `_updateCounts()` - Called when data changes

### Code Structure

```dart
class _MyMatchesScreenState extends State<MyMatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _upcomingCount = 0;      // ← Stores upcoming count
  int _pastCount = 0;          // ← Stores past count
  
  void _updateCounts(List<MatchModel> combined) {
    // Recalculates counts and updates UI if changed
  }
  
  build() {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          tabs: [
            Tab(
              icon: const Icon(Icons.schedule),
              text: _upcomingCount > 0 
                  ? 'Upcoming ($_upcomingCount)' 
                  : 'Upcoming',
            ),
            // Similar for Past tab
          ],
        ),
      ),
      body: // ... match lists
    );
  }
}
```

## Examples

### Example 1: With Multiple Matches
```
┌────────────────────┬──────────────────┐
│ ⏰ Upcoming (3)    │ ⏱️ Past (5)      │
└────────────────────┴──────────────────┘

UPCOMING TAB:
├─ Football (3/10 players) - Today 3:00 PM
├─ Volleyball (6/10 players) - Tomorrow 4:00 PM
└─ Basketball (8/10 players) - Next week

PAST TAB (click to switch):
├─ Tennis (2/4 players) - Yesterday 2:00 PM
├─ Badminton (3/4 players) - 3 days ago
├─ Cricket (11/12 players) - Last week
├─ Hockey (6/8 players) - 2 weeks ago
└─ Squash (2/2 players) - Last month
```

### Example 2: No Upcoming Matches
```
┌────────────────────┬──────────────────┐
│ ⏰ Upcoming        │ ⏱️ Past (2)      │
└────────────────────┴──────────────────┘

UPCOMING TAB:
"No Upcoming Matches"
"Join a match or create your own!"

PAST TAB (click to switch):
├─ Football - Yesterday
└─ Basketball - Last week
```

### Example 3: No Past Matches
```
┌────────────────────┬──────────────────┐
│ ⏰ Upcoming (1)    │ ⏱️ Past          │
└────────────────────┴──────────────────┘

UPCOMING TAB:
├─ Volleyball - Tomorrow 4:00 PM

PAST TAB (click to switch):
"No Match History"
"Your completed matches will appear here."
```

## Features

✅ **Visual Icons**
- Clear visual identification
- Standardized Material Design icons
- Easy to scan quickly

✅ **Badge Counts**
- Shows number of matches in each category
- Updates automatically
- Hidden if count is 0 (cleaner look)

✅ **Smart Sorting**
- Upcoming: Chronological (earliest first)
- Past: Reverse chronological (newest first)

✅ **Appropriate Empty States**
- Upcoming: "No Upcoming Matches"
- Past: "No Match History"

✅ **Real-time Updates**
- Counts update when new matches created
- Matches move between tabs as time passes

## Icon Reference

| Icon | Name | Meaning |
|------|------|---------|
| ⏰ | `Icons.schedule` | Upcoming/Future |
| ⏱️ | `Icons.history` | Past/History |

## Badge Count Logic

```dart
final upcomingCount = combined
    .where((m) => m.dateTime.isAfter(now))
    .length;

// Display logic
text: _upcomingCount > 0 
    ? 'Upcoming ($_upcomingCount)' 
    : 'Upcoming'

// Result:
// If 3 upcoming: "Upcoming (3)"
// If 0 upcoming: "Upcoming"
```

## Performance

- **No additional queries** - Uses existing match lists
- **Efficient counting** - O(n) where n = number of user matches
- **Smart updates** - Only updates UI when counts change
- **Memory efficient** - Just stores two integers

## State Management

```dart
class _MyMatchesScreenState extends State<MyMatchesScreen> {
  int _upcomingCount = 0;  // ← Persists across rebuilds
  int _pastCount = 0;      // ← Only UI state
  
  void _updateCounts(combined) {
    // Only calls setState if counts changed
    if (_upcomingCount != upcoming || _pastCount != past) {
      setState(() {
        _upcomingCount = upcoming;
        _pastCount = past;
      });
    }
  }
}
```

## File Changed

- `lib/presentation/screens/match/my_matches_screen.dart`
  - Added icon to each tab
  - Added badge count display
  - Added state variables for counts
  - Added `_updateCounts()` helper method

## Testing Checklist

- [ ] Tabs show correct icons (⏰ and ⏱️)
- [ ] Counts display correctly (e.g., "Upcoming (3)")
- [ ] Counts hide when 0 (just shows "Upcoming")
- [ ] Counts update when creating new match
- [ ] Matches move between tabs as time passes
- [ ] Tab switching is smooth
- [ ] Empty states still work
- [ ] Works on different screen sizes

## Customization Options

### Change Icon Styles
```dart
// With labels only (current)
Tab(
  icon: const Icon(Icons.schedule),
  text: 'Upcoming',
)

// Icon only (compact)
Tab(icon: const Icon(Icons.schedule))

// Alternative icons
Icons.event_note        // Upcoming alternative
Icons.calendar_today    // Calendar style
Icons.event_busy        // Past alternative
Icons.task_alt          // Check mark style
```

### Change Count Display
```dart
// Current format
'Upcoming ($_upcomingCount)'

// Alternative: Just number
'Upcoming $_upcomingCount'

// Alternative: Custom badge
Tab(
  icon: Badge(
    label: Text('$_upcomingCount'),
    child: Icon(Icons.schedule),
  ),
  text: 'Upcoming',
)
```

## Future Enhancements

1. **Custom Badge Widget** - More stylized count display
2. **Color Coding** - Different colors for urgent matches
3. **Swipe Navigation** - Swipe to switch tabs
4. **Statistics** - Show stats in Past tab
5. **Filters** - Filter by sport within each tab

---

**Status**: ✅ **COMPLETE & READY TO USE**

Features:
- ✅ Icons added
- ✅ Badge counts added
- ✅ Auto-updating
- ✅ No setup needed

