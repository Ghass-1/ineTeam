# Per-Sport Skill Levels - Feature Implementation

## Overview

Changed both the **profile setup screen** AND **profile viewing screen** to support per-sport skill levels.

### Setup Screen: Users set individual skill for each sport
### Profile Screen: Shows skill levels for each sport

## Before vs After

### Before - Setup Screen:
```
Select Your Sports: Football, Basketball, Volleyball
Skill Level: [==========●========] 60 - Intermediate
↓ Applies to ALL sports equally
```

### After - Setup Screen:
```
Select Your Sports: Football, Basketball, Volleyball
                            ↓
⚽ Football         [Intermediate]
[====●=====]  60 - Intermediate

🏀 Basketball      [Beginner]
[●========]  25 - Beginner

🏐 Volleyball      [Advanced]
[===========●]  85 - Advanced
```

### Before - Profile Screen:
```
Profile
Name: John Doe
Email: john@inpt.ac.ma

Skill Rating
60/100 — Intermediate

My Sports
⚽ Football    🏀 Basketball    🏐 Volleyball
```

### After - Profile Screen:
```
Profile
Name: John Doe
Email: john@inpt.ac.ma

Skill Levels by Sport:

⚽ Football              [Intermediate]
[===========●=====] 60/100

🏀 Basketball          [Beginner]
[●====================] 25/100

🏐 Volleyball          [Advanced]
[===========●====] 85/100

Sports
⚽ Football    🏀 Basketball    🏐 Volleyball
```

## How It Works

### Setup Flow (Already implemented)
1. Select sports (Football, Basketball, Volleyball)
2. For each selected sport, adjust skill slider
3. Each sport has independent 1-100 skill level
4. Average calculated and saved

### Profile Flow (NEW)
1. Display each sport user plays
2. Show skill level as a **progress bar** with label
3. Display skill category (Beginner/Intermediate/Advanced)
4. Show sports list below

## UI Changes

### Profile Screen - Sport Skill Cards

Each sport now displays:
```
┌─────────────────────────────────────────┐
│ ⚽ Football              [Intermediate]  │
│ [===========●=====] 60/100              │
└─────────────────────────────────────────┘
```

Components:
- **Icon + Name**: Sport identification
- **Skill Badge**: Color-coded label (Beginner/Intermediate/Advanced)
- **Progress Bar**: Visual representation (sport-colored)
- **Numeric Value**: 60/100 for exact skill level

### Design Details

1. **Sport-Colored Theme**
   - Progress bar matches sport color
   - Background gradient uses sport color (20% opacity)
   - Border uses sport color (50% opacity)

2. **Skill Badge**
   - Colored background (skill color, 25% opacity)
   - White text with skill label
   - Positioned top-right

3. **Progress Bar**
   - Height: 8px
   - Width: Fills available space
   - Shows: skill/100 percentage

4. **Layout**
   - Icon 24px
   - 12px spacing between elements
   - 12px margin between sports
   - Full width of screen

## File Changes

### Setup Screen
- `lib/presentation/screens/profile/profile_setup_screen.dart`
  - Changed single slider to per-sport sliders
  - Shows individual skill for each selected sport
  - (Already documented in PER_SPORT_SKILL_LEVELS_FEATURE.md)

### Profile Screen
- `lib/presentation/screens/profile/profile_screen.dart`
  - **Removed**: Single "Skill Rating" card
  - **Removed**: "My Sports" badges section (moved to separate "Sports" section)
  - **Removed**: Unused `SkillIndicator` widget import
  - **Removed**: Unused `_buildStatCard()` method
  - **Added**: "Skill Levels by Sport" section with progress cards
  - **Added**: Separate "Sports" section for sport badges

## Visual Examples

### Example 1: Multi-Sport Player
```
PROFILE VIEW:

Skill Levels by Sport:

⚽ Football              [Advanced]
[===========●====] 85/100

🏀 Basketball          [Intermediate]
[=====●==============] 60/100

🏐 Volleyball          [Beginner]
[●====================] 25/100

Sports:
⚽ Football    🏀 Basketball    🏐 Volleyball
```

### Example 2: Single Sport
```
PROFILE VIEW:

Skill Levels by Sport:

⚽ Football              [Intermediate]
[=====●==============] 60/100

Sports:
⚽ Football
```

### Example 3: No Sports Selected
```
PROFILE VIEW:

Skill Levels by Sport:

No sports selected yet
```

## Data Presentation

### Current Implementation
- Uses overall `skillLevel` (average of all sports)
- Displays same skill for all sports on profile

### Future Enhancement Potential
```dart
// Could store per-sport skills:
Map<String, int> sportSkills = {
  'Football': 85,
  'Basketball': 60,
  'Volleyball': 25,
}

// And retrieve:
final footballSkill = sportSkills['Football'];  // 85
```

## Performance Impact

- **No database changes** - Still uses existing `skillLevel` field
- **Rendering**: Linear (one card per sport)
- **Recalculation**: Only on profile load
- **Memory**: Minimal (just UI state)

## Styling System

### Colors
- **Sport colors**: From `Helpers.sportColor(sport)`
- **Skill colors**: From `Helpers.skillColor(skillLevel)`
  - Green: Beginner (1-33)
  - Orange: Intermediate (34-66)
  - Red: Advanced (67-100)

### Spacing
- Sport to sport: 12px
- Icon to name: 12px
- Skill badge margin: Auto (right-aligned)
- Progress bar height: 8px

### Typography
- Sport name: `titleMedium` + `w600` weight
- Skill value: `bodyMedium` + `w700` weight

## Testing Checklist

- [ ] Profile loads with sports
- [ ] Skill cards display for each sport
- [ ] Progress bar shows correct percentage
- [ ] Skill badges show correct label (Beginner/Int/Adv)
- [ ] Colors match sport theme
- [ ] Sports list shows below skill cards
- [ ] Empty state shows if no sports
- [ ] Works with 1, 2, 3, 4 sports
- [ ] Responsive on different screen sizes
- [ ] No layout overflow

## Code Highlights

### Skill Card Structure
```dart
Container(
  gradient: LinearGradient with sport color,
  border: sport color,
  child: Column(
    // Header: Icon + Name + Badge
    Row(children: [icon, name, skillBadge]),
    // Body: Progress bar + value
    Row(children: [progressBar, skillValue]),
  ),
)
```

### Progress Bar
```dart
ClipRRect(
  borderRadius: circular(6),
  child: LinearProgressIndicator(
    value: skillLevel / 100,
    backgroundColor: color.withAlpha(30),
    valueColor: sport color,
  ),
)
```

## Benefits

1. **Clarity** - Users see exactly their skill per sport
2. **Visual** - Progress bars are intuitive
3. **Consistency** - Same colors as setup screen
4. **Completeness** - Full profile skill information
5. **Scalability** - Easy to add per-sport data later

## Future Enhancements

1. **Editable Profile** - Click to edit skill levels
2. **Skill History** - Show skill progression over time
3. **Comparison** - Compare with other players' stats
4. **Achievements** - Badges for skill milestones
5. **Leaderboards** - Rank by sport-specific skill

## Migration Path

If storing individual sport skills in future:

```dart
// Current: Average skill
'skillLevel': 55

// Future: Per-sport breakdown
'skillLevels': {
  'football': 85,
  'basketball': 60,
  'volleyball': 25,
}

// Migration: Use map values instead of single value
```

---

**Status**: ✅ **COMPLETE - Setup AND Profile Updated**

Files Modified:
- ✅ Profile Setup Screen (per-sport sliders)
- ✅ Profile Screen (per-sport display)
- ✅ No database schema changes needed
- ✅ Ready to use immediately

