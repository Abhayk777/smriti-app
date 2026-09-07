import 'package:flutter/material.dart';

import '../app_colors.dart';

/// Game selection screen for choosing which cognitive game to play.
///
/// Shows visual representation of available games with:
/// - Large, colorful game icons
/// - Minimal text
/// - Animation/preview of each game
/// - Adaptive difficulty display
class GameSelectScreen extends StatelessWidget {
  const GameSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        title: const Text('Choose a Game'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a game to play',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.secondaryText,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Games grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: const [
                    _GameCard(
                      id: 'market_basket',
                      icon: Icons.shopping_basket,
                      label: 'Market Basket',
                      description: 'Remember items from a shopping list',
                      domain: 'Memory',
                      color: AppColors.terracotta,
                    ),
                    
                    _GameCard(
                      id: 'picture_match',
                      icon: Icons.image,
                      label: 'Picture Match',
                      description: 'Find matching pictures',
                      domain: 'Visual Memory',
                      color: AppColors.leafGreen,
                    ),
                    
                    _GameCard(
                      id: 'attention',
                      icon: Icons.focus_mode,
                      label: 'Attention',
                      description: 'Follow visual cues',
                      domain: 'Attention',
                      color: AppColors.terracottaDark,
                    ),
                    
                    _GameCard(
                      id: 'planning',
                      icon: Icons.assignment,
                      label: 'Planning',
                      description: 'Complete multi-step tasks',
                      domain: 'Executive',
                      color: AppColors.wovenMat,
                    ),
                    
                    _GameCard(
                      id: 'language',
                      icon: Icons.text_fields,
                      label: 'Language',
                      description: 'Identify and categorize items',
                      domain: 'Language',
                      color: AppColors.leafGreenDark,
                    ),
                    
                    _GameCard(
                      id: 'puzzle',
                      icon: Icons.analytics,
                      label: 'Puzzle',
                      description: 'Solve spatial puzzles',
                      domain: 'Visuospatial',
                      color: AppColors.border,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Game card widget for the game selection screen.
class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
    required this.domain,
    required this.color,
  });

  final String id;
  final IconData icon;
  final String label;
  final String description;
  final String domain;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to game screen
        Navigator.of(context).pop(id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            
            // Game icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Game name
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // Domain
            Text(
              domain,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
