import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/matches/match_provider.dart';
import '../../../features/profile/user_provider.dart';
import '../../../data/services/match_service.dart';
import '../../widgets/loading_overlay.dart';

/// Screen for creating a new match.
class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  static const Set<String> _genericCreatorNames = {
    '',
    'player',
    'unknown',
  };

  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teamAController = TextEditingController(text: 'Team A');
  final _teamBController = TextEditingController(text: 'Team B');

  String _selectedSport = SportType.football.label;
  String _selectedLocation = SportType.football.availableLocations.first;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 30);
  int _maxPlayers = 10;
  bool _useSkillRange = false;
  RangeValues _skillRange = const RangeValues(1, 100);
  bool _isSubmitting = false;
  String? _creatorTeam; // 'A' or 'B' for team selection

  // Predefined times from 17:30 to 21:30
  final List<TimeOfDay> _availableTimes = [
    const TimeOfDay(hour: 17, minute: 30),
    const TimeOfDay(hour: 18, minute: 0),
    const TimeOfDay(hour: 18, minute: 30),
    const TimeOfDay(hour: 19, minute: 0),
    const TimeOfDay(hour: 19, minute: 30),
    const TimeOfDay(hour: 20, minute: 0),
    const TimeOfDay(hour: 20, minute: 30),
    const TimeOfDay(hour: 21, minute: 0),
    const TimeOfDay(hour: 21, minute: 30),
  ];

  List<TimeOfDay> _reservedTimes = [];

  @override
  void initState() {
    super.initState();
    _fetchReservedTimes();
  }

  Future<void> _fetchReservedTimes() async {
    final service = MatchService();
    final reserved = await service.getReservedTimesForDay(
      _selectedLocation,
      _selectedDate,
    );

    if (mounted) {
      setState(() {
        _reservedTimes = reserved
            .map((dt) => TimeOfDay.fromDateTime(dt))
            .toList();

        // Auto-select first available time
        if (_reservedTimes.any(
          (t) =>
              t.hour == _selectedTime.hour && t.minute == _selectedTime.minute,
        )) {
          for (final t in _availableTimes) {
            if (!_reservedTimes.any(
              (rt) => rt.hour == t.hour && rt.minute == t.minute,
            )) {
              _selectedTime = t;
              break;
            }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchReservedTimes();
    }
  }

  // Removed _pickTime since we now use predefined chips.

  bool _isGenericCreatorName(String? name) {
    return _genericCreatorNames.contains(name?.trim().toLowerCase() ?? '');
  }

  Future<String> _resolveCreatorName() async {
    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    final authProfileName = auth.userProfile?.name.trim();
    if (!_isGenericCreatorName(authProfileName) &&
        (authProfileName?.isNotEmpty ?? false)) {
      return authProfileName!;
    }

    final loadedProfileName = userProvider.currentUser?.name.trim();
    if (!_isGenericCreatorName(loadedProfileName) &&
        (loadedProfileName?.isNotEmpty ?? false)) {
      return loadedProfileName!;
    }

    final freshProfile = await userProvider.getUserById(auth.userId);
    final freshProfileName = freshProfile?.name.trim();
    if (!_isGenericCreatorName(freshProfileName) &&
        (freshProfileName?.isNotEmpty ?? false)) {
      return freshProfileName!;
    }

    final emailPrefix = auth.user?.email?.split('@').first.trim();
    if ((emailPrefix?.isNotEmpty ?? false)) {
      return emailPrefix!;
    }

    return 'Player';
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    // Table tennis must be 1v1
    if (_selectedSport == 'Table Tennis' && _maxPlayers != 2) {
      Helpers.showSnackBar(
        context,
        'Table Tennis must have exactly 2 players (1v1)',
        isError: true,
      );
      return;
    }

    // Non-table tennis sports require team selection
    if (_selectedSport != 'Table Tennis' && _creatorTeam == null) {
      Helpers.showSnackBar(
        context,
        'Please choose a team to join',
        isError: true,
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (dateTime.isBefore(DateTime.now())) {
      Helpers.showSnackBar(
        context,
        'Match must be in the future',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final matchProvider = context.read<MatchProvider>();
    final creatorName = await _resolveCreatorName();

    if (!mounted) return;

    final success = await matchProvider.createMatch(
      creatorId: auth.userId,
      creatorName: creatorName,
      sport: _selectedSport,
      location: _selectedLocation,
      dateTime: dateTime,
      maxPlayers: _maxPlayers,
      teamAName: _teamAController.text.trim().isEmpty
          ? 'Team A'
          : _teamAController.text.trim(),
      teamBName: _teamBController.text.trim().isEmpty
          ? 'Team B'
          : _teamBController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      minSkill: _useSkillRange ? _skillRange.start.round() : null,
      maxSkill: _useSkillRange ? _skillRange.end.round() : null,
      creatorTeam: _creatorTeam, // Pass selected team
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Helpers.showSnackBar(context, 'Match created! 🎉');
        context.pop();
      } else {
        Helpers.showSnackBar(
          context,
          matchProvider.errorMessage ?? 'Failed to create match',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportColor = Helpers.sportColor(_selectedSport);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Match')),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // ── Sport Selection ──
                Text('Sport', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SportType.values.map((sport) {
                    final isSelected = _selectedSport == sport.label;
                    final color = Helpers.sportColor(sport.label);
                    return ChoiceChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Helpers.sportIcon(sport.label),
                            size: 18,
                            color: isSelected ? color : null,
                          ),
                          const SizedBox(width: 6),
                          Text(sport.label),
                        ],
                      ),
                      selectedColor: color.withAlpha(40),
                      onSelected: (_) {
                        setState(() {
                          _selectedSport = sport.label;
                          // Reset location and team for this sport
                          _selectedLocation = sport.availableLocations.first;
                          _maxPlayers = sport.defaultMaxPlayers;
                          _creatorTeam = null; // Reset team selection
                        });
                        _fetchReservedTimes();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                Text('Location', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SportType.values
                      .firstWhere((s) => s.label == _selectedSport)
                      .availableLocations
                      .map((loc) {
                        final isSelected = _selectedLocation == loc;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(loc),
                          selectedColor: sportColor.withAlpha(40),
                          onSelected: (_) {
                            setState(() {
                              _selectedLocation = loc;
                            });
                            _fetchReservedTimes();
                          },
                        );
                      })
                      .toList(),
                ),

                const SizedBox(height: 20),

                // ── Date ──
                Text('Date & Time', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Select Date',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: sportColor,
                        size: 20,
                      ),
                    ),
                    child: Text(
                      Helpers.formatDate(_selectedDate),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Time Toggles ──
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableTimes.map((time) {
                    final isSelected =
                        _selectedTime.hour == time.hour &&
                        _selectedTime.minute == time.minute;
                    final isReserved = _reservedTimes.any(
                      (t) => t.hour == time.hour && t.minute == time.minute,
                    );

                    return ChoiceChip(
                      selected: isSelected && !isReserved,
                      label: Text(
                        time.format(context),
                        style: TextStyle(
                          decoration: isReserved
                              ? TextDecoration.lineThrough
                              : null,
                          color: isReserved
                              ? theme.colorScheme.onSurface.withAlpha(100)
                              : null,
                        ),
                      ),
                      selectedColor: sportColor.withAlpha(40),
                      backgroundColor: isReserved
                          ? theme.colorScheme.onSurface.withAlpha(10)
                          : null,
                      onSelected: isReserved
                          ? null // Disable selection if reserved
                          : (_) {
                              setState(() {
                                _selectedTime = time;
                              });
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // ── Max Players Stepper ──
                Text('Format (Players)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filled(
                      onPressed: _maxPlayers > 2
                          ? () => setState(() => _maxPlayers -= 2)
                          : null,
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(
                        backgroundColor: sportColor.withAlpha(30),
                        foregroundColor: sportColor,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          Helpers.formatPlayersVs(_maxPlayers),
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: sportColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _maxPlayers < 30
                          ? () => setState(() => _maxPlayers += 2)
                          : null,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: sportColor.withAlpha(30),
                        foregroundColor: sportColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Team Names ──
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _teamAController,
                        decoration: const InputDecoration(
                          labelText: 'Team A Name',
                          hintText: 'e.g. Red Squad',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _teamBController,
                        decoration: const InputDecoration(
                          labelText: 'Team B Name',
                          hintText: 'e.g. Blue Squad',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Description ──
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Any details about the match...',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 20),

                // ── Skill Range (Optional) ──
                SwitchListTile(
                  title: Text(
                    'Restrict Skill Range',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: const Text(
                    'Only allow players within a skill range',
                  ),
                  value: _useSkillRange,
                  activeThumbColor: sportColor,
                  onChanged: (val) {
                    setState(() => _useSkillRange = val);
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                if (_useSkillRange) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Min: ${_skillRange.start.round()}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Max: ${_skillRange.end.round()}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _skillRange,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    activeColor: sportColor,
                    labels: RangeLabels(
                      '${_skillRange.start.round()}',
                      '${_skillRange.end.round()}',
                    ),
                    onChanged: (val) {
                      setState(() => _skillRange = val);
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // ── Team Selection (except for Table Tennis) ──
                if (_selectedSport != 'Table Tennis') ...[
                  Text('Your Team', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected: _creatorTeam == 'A',
                          label: Text(
                            _teamAController.text.trim().isEmpty
                                ? 'Team A'
                                : _teamAController.text.trim(),
                          ),
                          selectedColor: Helpers.sportColor(_selectedSport)
                              .withAlpha(40),
                          onSelected: (_) {
                            setState(() => _creatorTeam = 'A');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          selected: _creatorTeam == 'B',
                          label: Text(
                            _teamBController.text.trim().isEmpty
                                ? 'Team B'
                                : _teamBController.text.trim(),
                          ),
                          selectedColor: Helpers.sportColor(_selectedSport)
                              .withAlpha(40),
                          onSelected: (_) {
                            setState(() => _creatorTeam = 'B');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Table Tennis info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sportColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sportColor.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: sportColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Table Tennis is 1v1 (2 players). No teams needed.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: sportColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),

                // ── Create Button ──
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleCreate,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Match'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sportColor,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
