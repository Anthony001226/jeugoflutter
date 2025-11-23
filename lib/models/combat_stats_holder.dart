// lib/models/combat_stats_holder.dart

import 'combat_stats.dart';

/// Interface for entities that hold CombatStats
/// This allows polymorphic access to combat stats for different enemy types
abstract class CombatStatsHolder {
  CombatStats get combatStats;
}
