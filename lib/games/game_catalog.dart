import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../ui/smriti_ui.dart';

/// How a game is presented to the elder: its name, a one-line description,
/// the ability it exercises, and its icon and colour.
class GameInfo {
  const GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.domain,
    required this.icon,
    this.image,
    required this.color,
    required this.tier,
  });

  final String id;
  final String name;
  final String description;
  final String domain;
  final IconData icon;

  /// Photo in assets/images/photos/, if one exists.
  final String? image;
  final Color color;
  final int tier; // 1 = must ship, 2 = if schedule holds, 3 = if you can
}

/// All 9 games in the roster, in the order they are offered.
const gameCatalog = <GameInfo>[
  // Tier 1: must ship
  GameInfo(
    id: 'faces_of_family',
    name: 'Faces of My Family',
    description: 'Recognise your family members',
    domain: 'Memory',
    icon: Icons.people_alt_rounded,
    image: familyHomeGlyph,
    color: AppColors.terracotta,
    tier: 1,
  ),
  GameInfo(
    id: 'market_basket',
    name: 'Market Basket',
    description: 'Remember items from a shopping list',
    domain: 'Memory',
    icon: Icons.shopping_basket_rounded,
    image: 'game_market.jpg',
    color: AppColors.marigoldDark,
    tier: 1,
  ),
  GameInfo(
    id: 'sort_harvest',
    name: 'Sort the Harvest',
    description: 'Put each item in its basket',
    domain: 'Thinking',
    icon: Icons.category_rounded,
    image: 'game_sort.jpg',
    color: AppColors.bamboo,
    tier: 1,
  ),
  GameInfo(
    id: 'trace_path',
    name: 'Trace the Path',
    description: 'Tap the stones in order',
    domain: 'Seeing',
    icon: Icons.route_rounded,
    image: 'game_trace.jpg',
    color: AppColors.indigo,
    tier: 1,
  ),
  GameInfo(
    id: 'my_day',
    name: 'My Day',
    description: 'Put the day in order',
    domain: 'Orientation',
    icon: Icons.wb_sunny_rounded,
    image: 'game_myday.jpg',
    color: AppColors.riverTeal,
    tier: 1,
  ),
  // Tier 2: build if schedule holds
  GameInfo(
    id: 'lamps_festival',
    name: 'Lamps of the Festival',
    description: 'Remember which lamps lit up',
    domain: 'Memory',
    icon: Icons.emoji_objects_rounded,
    image: 'game_lamps.jpg',
    color: AppColors.teaBrown,
    tier: 2,
  ),
  GameInfo(
    id: 'name_harvest',
    name: 'Name the Harvest',
    description: 'Name as many things as you can',
    domain: 'Words',
    icon: Icons.record_voice_over_rounded,
    image: 'game_words.jpg',
    color: AppColors.orchid,
    tier: 2,
  ),
  // Tier 3: ship if you can
  GameInfo(
    id: 'weaving_patterns',
    name: 'Weaving Patterns',
    description: 'Find the matching pattern',
    domain: 'Seeing',
    icon: Icons.texture_rounded,
    image: 'game_weaving.jpg',
    color: AppColors.gamosaRed,
    tier: 3,
  ),
  GameInfo(
    id: 'sounds_home',
    name: 'Sounds of Home',
    description: 'Tap the drum when you hear the bird',
    domain: 'Listening',
    icon: Icons.hearing_rounded,
    image: 'game_sounds.jpg',
    color: AppColors.leafGreen,
    tier: 3,
  ),
];

GameInfo? gameInfoFor(String id) {
  for (final g in gameCatalog) {
    if (g.id == id) return g;
  }
  return null;
}
