import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/profile/user_provider.dart';
import '../../widgets/loading_overlay.dart';

/// Profile setup screen shown after first signup.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final List<String> _selectedSports = [];
  final Map<String, double> _sportSkillLevels = {}; // Per-sport skill levels
  String _frequency = 'casual';
  bool _isSubmitting = false;

  Future<String?> _waitForUserId(AuthProvider auth) async {
    if (auth.userId.isNotEmpty) return auth.userId;

    for (var attempt = 0; attempt < 10; attempt++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return null;
      if (auth.userId.isNotEmpty) return auth.userId;
    }

    return auth.userId.isNotEmpty ? auth.userId : null;
  }

  Future<void> _handleComplete() async {
    if (_selectedSports.isEmpty) {
      Helpers.showSnackBar(context, 'Please select at least one sport',
          isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final userId = await _waitForUserId(auth);

    if (!mounted) return;

    if (userId == null) {
      Helpers.showSnackBar(
        context,
        'Your account is still loading. Please try again in a moment.',
        isError: true,
      );
      setState(() => _isSubmitting = false);
      return;
    }

    // Calculate average skill level across all sports
    final averageSkill = (_sportSkillLevels.values.fold<int>(0, (a, b) => a + b.round()) 
        / _selectedSports.length).round();

    // Convert sport skills from double to int for storage
    final sportSkillsInt = _sportSkillLevels.map(
      (sport, skill) => MapEntry(sport, skill.round()),
    );

    final success = await userProvider.updateProfile(
      uid: userId,
      sports: _selectedSports,
      skillLevel: averageSkill,
      sportSkills: sportSkillsInt,
      frequency: _frequency,
    );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      Helpers.showSnackBar(
        context,
        userProvider.errorMessage ?? 'Failed to save profile',
        isError: true,
      );
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Header
                Text(
                  'Set Up Your Profile',
                  style: theme.textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us about your sports preferences',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // ── Sport Selection ──
                Text(
                  'Select Your Sports',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose one or more sports you play',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SportType.values.map((sport) {
                    final isSelected = _selectedSports.contains(sport.label);
                    final color = Helpers.sportColor(sport.label);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Helpers.sportIcon(sport.label),
                            size: 18,
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface.withAlpha(150),
                          ),
                          const SizedBox(width: 6),
                          Text(sport.label),
                        ],
                      ),
                      selectedColor: color.withAlpha(40),
                      checkmarkColor: color,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSports.add(sport.label);
                          } else {
                            _selectedSports.remove(sport.label);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 36),

                // ── Per-Sport Skill Levels ──
                if (_selectedSports.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Skill Level by Sport',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rate your skill for each sport you selected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ..._selectedSports.map((sport) {
                        // Initialize skill level if not set
                        _sportSkillLevels.putIfAbsent(sport, () => 50);
                        final skillLevel = _sportSkillLevels[sport]!;
                        final sportColor = Helpers.sportColor(sport);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sport name and icon
                              Row(
                                children: [
                                  Icon(
                                    Helpers.sportIcon(sport),
                                    color: sportColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      sport,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  // Skill badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Helpers.skillColor(skillLevel.round())
                                          .withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      Helpers.skillLabel(skillLevel.round()),
                                      style: TextStyle(
                                        color: Helpers.skillColor(skillLevel.round()),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Skill labels
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSkillLabel('Beginner',
                                      const Color(0xFF2ECC71)),
                                  _buildSkillLabel('Intermediate',
                                      const Color(0xFFF39C12)),
                                  _buildSkillLabel('Advanced',
                                      const Color(0xFFE74C3C)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Slider for this sport
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 6,
                                  activeTrackColor: sportColor,
                                  inactiveTrackColor:
                                      sportColor.withAlpha(50),
                                ),
                                child: Slider(
                                  value: skillLevel,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  activeColor: Helpers.skillColor(
                                      skillLevel.round()),
                                  label:
                                      '${skillLevel.round()} — ${Helpers.skillLabel(skillLevel.round())}',
                                  onChanged: (val) {
                                    setState(() {
                                      _sportSkillLevels[sport] = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(40),
                      ),
                    ),
                    child: Text(
                      'Select sports above to set skill levels',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 36),

                // ── Play Frequency ──
                Text(
                  'How Often Do You Play?',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...PlayFrequency.values.map((freq) {
                  final isSelected = _frequency == freq.name;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() => _frequency = freq.name);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withAlpha(15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withAlpha(40),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface.withAlpha(100),
                                size: 22,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                freq.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 40),

                // Complete button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (_isSubmitting || auth.userId.isEmpty || auth.isProfileLoading)
                            ? null
                            : _handleComplete,
                    child: Text(
                      auth.userId.isEmpty || auth.isProfileLoading
                          ? 'Preparing account...'
                          : 'Complete Setup',
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

  Widget _buildSkillLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
