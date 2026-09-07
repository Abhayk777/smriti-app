import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'game_screen.dart';

/// Game data for display.
class _GameInfo {
  const _GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.icon,
    required this.color,
    required this.tier,
    required this.emoji,
  });

  final String id;
  final String name;
  final String description;
  final String domain;
  final IconData icon;
  final Color color;
  final int tier; // 1 = must ship, 2 = if schedule holds, 3 = if you can
  final String emoji;
}

/// All 9 games in the roster.
const _games = <_GameInfo>[
  // Tier 1 — must ship
  _GameInfo(
    id: 'faces_of_family',
    name: 'Faces of My Family',
    description: 'Recognise your family members',
    domain: 'Memory',
    icon: Icons.family_restroom,
    color: AppColors.terracotta,
    tier: 1,
    emoji: '👨‍👩‍👧‍👦',
  ),
  _GameInfo(
    id: 'market_basket',
    name: 'Market Basket',
    description: 'Remember items from a shopping list',
    domain: 'Memory',
    icon: Icons.shopping_basket,
    color: AppColors.marigold,
    tier: 1,
    emoji: '🧺',
  ),
  _GameInfo(
    id: 'sort_harvest',
    name: 'Sort the Harvest',
    description: 'Sort produce by type, colour, or size',
    domain: 'Executive',
    icon: Icons.agriculture,
    color: AppColors.leafGreen,
    tier: 1,
    emoji: '🌾',
  ),
  _GameInfo(
    id: 'trace_path',
    name: 'Trace the Path',
    description: 'Connect the stones in order',
    domain: 'Visuospatial',
    icon: Icons.route,
    color: AppColors.indigo,
    tier: 1,
    emoji: '🗺️',
  ),
  _GameInfo(
    id: 'my_day',
    name: 'My Day',
    description: 'Order daily events and answer questions',
    domain: 'Orientation',
    icon: Icons.wb_sunny,
    color: AppColors.marigoldDark,
    tier: 1,
    emoji: '☀️',
  ),
  // Tier 2 — build if schedule holds
  _GameInfo(
    id: 'lamps_festival',
    name: 'Lamps of the Festival',
    description: 'Remember the lamp sequence',
    domain: 'Spatial Memory',
    icon: Icons.local_fire_department,
    color: Color(0xFFE67E22),
    tier: 2,
    emoji: '🪔',
  ),
  _GameInfo(
    id: 'name_harvest',
    name: 'Name the Harvest',
    description: 'Name as many items as you can',
    domain: 'Language',
    icon: Icons.record_voice_over,
    color: AppColors.leafGreenDark,
    tier: 2,
    emoji: '🗣️',
  ),
  // Tier 3 — ship if you can
  _GameInfo(
    id: 'weaving_patterns',
    name: 'Weaving Patterns',
    description: 'Match the textile pattern',
    domain: 'Visual Perception',
    icon: Icons.grid_on,
    color: AppColors.terracottaDark,
    tier: 3,
    emoji: '🧶',
  ),
  _GameInfo(
    id: 'sounds_home',
    name: 'Sounds of Home',
    description: 'Tap the drum when you hear the bird',
    domain: 'Attention',
    icon: Icons.hearing,
    color: Color(0xFF2C5F2D),
    tier: 3,
    emoji: '🐦',
  ),
];

/// Game selection screen with all 9 cognitive games.
///
/// Shows tier-grouped game cards with cultural icons and domain labels.
/// Large touch targets for elderly users.
class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 28, color: AppColors.primaryText),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Choose a Game',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Game grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _games.length,
                  itemBuilder: (context, index) {
                    return _GameCard(
                      info: _games[index],
                      onTap: () => _launchGame(context, _games[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchGame(BuildContext context, _GameInfo info) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(gameId: info.id),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({required this.info, required this.onTap});

  final _GameInfo info;
  final VoidCallback onTap;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                info.color,
                info.color.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: info.color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji
                Text(
                  info.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 10),

                // Game name
                Text(
                  info.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Domain tag
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info.domain,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
