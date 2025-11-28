// lib/models/inventory_item.dart
import 'package:renegade_dungeon/game/renegade_dungeon_game.dart';
import 'package:renegade_dungeon/models/item_rarity.dart';

// La definición base de cualquier objeto en el juego.
class InventoryItem {
  final String id; // Un identificador único, ej: 'potion_hp_small'
  final String name;
  final String description;
  final ItemRarity rarity; // ← NUEVO: Rareza del item
  final int value; // ← NUEVO: Valor en gold
  final int levelRequirement; // ← NUEVO: Nivel mínimo para usar
  final void Function(RenegadeDungeonGame game) effect;
  final bool isUsable;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    this.rarity = ItemRarity.common, // Por defecto común
    this.value = 10,
    this.levelRequirement = 1,
    // El efecto por defecto no hace nada.
    this.effect = _doNothing,
    this.isUsable = false,
  });

  static void doNothing(RenegadeDungeonGame game) {}
}

enum EquipmentSlot {
  weapon,
  armor,
  // En el futuro, podríamos añadir: relic, ring, etc.
}

class EquipmentItem extends InventoryItem {
  final EquipmentSlot slot;
  final int attackBonus;
  final int defenseBonus;
  final int speedBonus;
  final List<UniquePassive> uniquePassives; // ← NUEVO: Efectos pasivos únicos

  const EquipmentItem({
    required super.id,
    required super.name,
    required super.description,
    required this.slot,
    this.attackBonus = 0,
    this.defenseBonus = 0,
    this.speedBonus = 0,
    this.uniquePassives = const [], // Por defecto sin pasivos
    super.rarity = ItemRarity.common,
    super.value = 10,
    super.levelRequirement = 1,
  }) : super(
            isUsable:
                false); // Un objeto de equipo no es "usable" como una poción.

  /// Helper para verificar si tiene un pasivo específico
  bool hasPassive(PassiveType type) {
    return uniquePassives.any((p) => p.type == type);
  }

  /// Obtener valor de un pasivo específico
  double? getPassiveValue(PassiveType type) {
    try {
      return uniquePassives.firstWhere((p) => p.type == type).value;
    } catch (e) {
      return null;
    }
  }
}

void _doNothing(RenegadeDungeonGame game) {
  // No hace nada
}

// Una clase para representar un "slot" o espacio en el inventario.
// Guarda el objeto y la cantidad que tenemos de él.
class InventorySlot {
  final InventoryItem item;
  int quantity;

  InventorySlot({required this.item, this.quantity = 1});
}

// --- Definiciones de Objetos Específicos ---
// Aquí es donde crearías todos los objetos de tu juego.

class ItemDatabase {
  // ==================== CONSUMABLES ====================

  static final InventoryItem potion = InventoryItem(
    id: 'potion_hp_small',
    name: 'Poción Pequeña',
    description: 'Restaura 25 puntos de HP.',
    rarity: ItemRarity.common,
    value: 15,
    isUsable: true,
    effect: (game) {
      game.player.stats.restoreHealth(25);
      print('¡Usaste una poción! HP restaurado.');
    },
  );

  static final InventoryItem potionMedium = InventoryItem(
    id: 'potion_hp_medium',
    name: 'Poción Mediana',
    description: 'Restaura 50 puntos de HP.',
    rarity: ItemRarity.uncommon,
    value: 40,
    isUsable: true,
    effect: (game) {
      game.player.stats.restoreHealth(50);
    },
  );

  static final InventoryItem potionLarge = InventoryItem(
    id: 'potion_hp_large',
    name: 'Poción Grande',
    description: 'Restaura 100 puntos de HP.',
    rarity: ItemRarity.rare,
    value: 100,
    levelRequirement: 5,
    isUsable: true,
    effect: (game) {
      game.player.stats.restoreHealth(100);
    },
  );

  static final InventoryItem slimeResidue = const InventoryItem(
    id: 'residue_slime',
    name: 'Residuo de Slime',
    description: 'Una sustancia pegajosa. Material de crafting.',
    rarity: ItemRarity.common,
    value: 5,
  );

  // ==================== COMMON WEAPONS ====================

  static final EquipmentItem rustySword = const EquipmentItem(
    id: 'sword_rusty',
    name: 'Espada Oxidada',
    description: 'Un trozo de metal apenas afilado. Es mejor que nada.',
    slot: EquipmentSlot.weapon,
    attackBonus: 2,
    rarity: ItemRarity.common,
    value: 10,
  );

  static final EquipmentItem woodenClub = const EquipmentItem(
    id: 'weapon_club',
    name: 'Garrote de Madera',
    description: 'Un palo pesado. Simple pero efectivo.',
    slot: EquipmentSlot.weapon,
    attackBonus: 3,
    rarity: ItemRarity.common,
    value: 15,
  );

  static final EquipmentItem huntingBow = const EquipmentItem(
    id: 'weapon_bow_hunting',
    name: 'Arco de Caza',
    description: 'Un arco simple para cazar.',
    slot: EquipmentSlot.weapon,
    attackBonus: 2,
    speedBonus: 1,
    rarity: ItemRarity.common,
    value: 20,
  );

  // ==================== UNCOMMON WEAPONS ====================

  static final EquipmentItem goblinScimitar = const EquipmentItem(
    id: 'weapon_goblin_scimitar',
    name: 'Cimitarra Goblin',
    description: 'Una hoja curva y dentada. Sorprendentemente efectiva.',
    slot: EquipmentSlot.weapon,
    attackBonus: 5,
    speedBonus: 2,
    rarity: ItemRarity.uncommon,
    value: 50,
    levelRequirement: 2,
  );

  static final EquipmentItem steelSword = const EquipmentItem(
    id: 'sword_steel',
    name: 'Espada de Acero',
    description: 'Una espada bien forjada. Equilibrada y confiable.',
    slot: EquipmentSlot.weapon,
    attackBonus: 6,
    defenseBonus: 1,
    rarity: ItemRarity.uncommon,
    value: 60,
    levelRequirement: 3,
  );

  static final EquipmentItem battleAxe = const EquipmentItem(
    id: 'weapon_axe_battle',
    name: 'Hacha de Batalla',
    description: 'Un arma pesada que golpea con fuerza brutal.',
    slot: EquipmentSlot.weapon,
    attackBonus: 8,
    speedBonus: -1, // Más lenta
    rarity: ItemRarity.uncommon,
    value: 70,
    levelRequirement: 4,
  );

  // ==================== RARE WEAPONS ====================

  static final EquipmentItem vampiricBlade = const EquipmentItem(
    id: 'sword_vampiric',
    name: 'Hoja Vampírica',
    description: 'Una espada maldita que se alimenta de sangre.',
    slot: EquipmentSlot.weapon,
    attackBonus: 10,
    speedBonus: 2,
    rarity: ItemRarity.rare,
    value: 200,
    levelRequirement: 6,
    uniquePassives: [UniquePassive.lifeSteal10],
  );

  static final EquipmentItem flameTongue = const EquipmentItem(
    id: 'sword_flame',
    name: 'Lengua de Fuego',
    description: 'Una espada envuelta en llamas eternas.',
    slot: EquipmentSlot.weapon,
    attackBonus: 12,
    rarity: ItemRarity.rare,
    value: 250,
    levelRequirement: 7,
    uniquePassives: [UniquePassive.critBonus50],
  );

  static final EquipmentItem shadowDagger = const EquipmentItem(
    id: 'weapon_dagger_shadow',
    name: 'Daga de las Sombras',
    description: 'Se dice que esta daga ataca antes de ser vista.',
    slot: EquipmentSlot.weapon,
    attackBonus: 8,
    speedBonus: 5,
    rarity: ItemRarity.rare,
    value: 220,
    levelRequirement: 8,
    uniquePassives: [UniquePassive.firstStrike],
  );

  // ==================== EPIC WEAPONS ====================

  static final EquipmentItem reapersScythe = const EquipmentItem(
    id: 'weapon_scythe_reaper',
    name: 'Guadaña del Segador',
    description:
        'La muerte misma forjó esta arma. Cada muerte te hace más fuerte.',
    slot: EquipmentSlot.weapon,
    attackBonus: 15,
    speedBonus: 3,
    rarity: ItemRarity.epic,
    value: 500,
    levelRequirement: 10,
    uniquePassives: [
      UniquePassive.lifeSteal10,
      UniquePassive.ultOnKill30,
    ],
  );

  // ==================== LEGENDARY WEAPONS ====================

  static final EquipmentItem bladeOfEternity = const EquipmentItem(
    id: 'sword_eternal',
    name: 'Hoja de la Eternidad',
    description:
        'Forjada por los dioses. Se dice que nunca ha sido vencida en batalla.',
    slot: EquipmentSlot.weapon,
    attackBonus: 25,
    speedBonus: 5,
    defenseBonus: 3,
    rarity: ItemRarity.legendary,
    value: 9999,
    levelRequirement: 15,
    uniquePassives: [
      UniquePassive.lifeSteal25,
      UniquePassive.critBonus50,
      UniquePassive.ultOnKill30,
      UniquePassive.firstStrike,
    ],
  );

  // ==================== COMMON ARMOR ====================

  static final EquipmentItem leatherTunic = const EquipmentItem(
    id: 'tunic_leather',
    name: 'Túnica de Cuero',
    description: 'Ofrece una protección modesta contra los golpes.',
    slot: EquipmentSlot.armor,
    defenseBonus: 1,
    rarity: ItemRarity.common,
    value: 12,
  );

  static final EquipmentItem clothRobe = const EquipmentItem(
    id: 'armor_robe_cloth',
    name: 'Túnica de Tela',
    description: 'Liviana y cómoda, pero ofrece poca protección.',
    slot: EquipmentSlot.armor,
    defenseBonus: 1,
    speedBonus: 1,
    rarity: ItemRarity.common,
    value: 15,
  );

  // ==================== UNCOMMON ARMOR ====================

  static final EquipmentItem chainmail = const EquipmentItem(
    id: 'armor_chainmail',
    name: 'Cota de Malla',
    description: 'Anillos de acero entrelazados. Protección sólida.',
    slot: EquipmentSlot.armor,
    defenseBonus: 3,
    speedBonus: -1,
    rarity: ItemRarity.uncommon,
    value: 80,
    levelRequirement: 3,
  );

  static final EquipmentItem studledLeather = const EquipmentItem(
    id: 'armor_leather_studded',
    name: 'Cuero Tachonado',
    description: 'Cuero reforzado con tachuelas de metal.',
    slot: EquipmentSlot.armor,
    defenseBonus: 2,
    speedBonus: 1,
    rarity: ItemRarity.uncommon,
    value: 70,
    levelRequirement: 2,
  );

  // ==================== RARE ARMOR ====================

  static final EquipmentItem thornmail = const EquipmentItem(
    id: 'armor_thornmail',
    name: 'Armadura de Espinas',
    description: 'Púas cubren esta armadura. Quien te ataque lo lamentará.',
    slot: EquipmentSlot.armor,
    defenseBonus: 4,
    rarity: ItemRarity.rare,
    value: 300,
    levelRequirement: 7,
    uniquePassives: [UniquePassive.thorns15],
  );

  static final EquipmentItem dragonscale = const EquipmentItem(
    id: 'armor_dragonscale',
    name: 'Escamas de Dragón',
    description: 'Armadura hecha de escamas de dragón. Casi impenetrable.',
    slot: EquipmentSlot.armor,
    defenseBonus: 6,
    speedBonus: 2,
    rarity: ItemRarity.rare,
    value: 350,
    levelRequirement: 8,
  );

  // NEW: Regen armor balanceado (Raro)
  static const hpRegen15 = UniquePassive(
    id: 'hp_regen_15',
    name: 'Regeneración Menor',
    description: 'Regenera 1.5% HP máximo por turno',
    type: PassiveType.hpRegen,
    value: 0.015,
  );

  static final EquipmentItem monkRobes = const EquipmentItem(
    id: 'armor_monk_robes',
    name: 'Túnica de Monje',
    description: 'Túnica sagrada que rejuvenece a su portador lentamente.',
    slot: EquipmentSlot.armor,
    defenseBonus: 3,
    speedBonus: 3,
    rarity: ItemRarity.rare,
    value: 280,
    levelRequirement: 6,
    uniquePassives: [hpRegen15],
  );

  // ==================== EPIC ARMOR ====================

  // NEW: Regen armor balanceado (Épico)
  static const hpRegen2 = UniquePassive(
    id: 'hp_regen_2',
    name: 'Regeneración',
    description: 'Regenera 2% HP máximo por turno',
    type: PassiveType.hpRegen,
    value: 0.02,
  );

  static const mpRegen3 = UniquePassive(
    id: 'mp_regen_3',
    name: 'Meditación Menor',
    description: 'Regenera 3 MP por turno',
    type: PassiveType.mpRegen,
    value: 3.0,
  );

  static final EquipmentItem archmageVestments = const EquipmentItem(
    id: 'armor_archmage_vest',
    name: 'Vestiduras del Archimago',
    description:
        'Túnicas místicas que restauran la vitalidad y el maná de su portador.',
    slot: EquipmentSlot.armor,
    defenseBonus: 4,
    speedBonus: 2,
    rarity: ItemRarity.epic,
    value: 600,
    levelRequirement: 9,
    uniquePassives: [hpRegen2, mpRegen3],
  );

  // ==================== EPIC ARMOR ====================

  static final EquipmentItem etherealPlate = const EquipmentItem(
    id: 'armor_ethereal',
    name: 'Placa Etérea',
    description:
        'Esta armadura parece existir entre planos. Los ataques la atraviesan.',
    slot: EquipmentSlot.armor,
    defenseBonus: 5,
    speedBonus: 3,
    rarity: ItemRarity.epic,
    value: 600,
    levelRequirement: 11,
    uniquePassives: [
      UniquePassive.dodge15,
      UniquePassive.hpRegen3,
    ],
  );

  // ==================== LEGENDARY ARMOR ====================

  // ==================== LEGENDARY ARMOR ====================

  static final EquipmentItem armorOfTheAncients = const EquipmentItem(
    id: 'armor_ancient',
    name: 'Armadura de los Ancestros',
    description: 'La armadura de los héroes olvidados. Irradia poder antiguo.',
    slot: EquipmentSlot.armor,
    defenseBonus: 10,
    speedBonus: 5,
    rarity: ItemRarity.legendary,
    value: 9999,
    levelRequirement: 15,
    uniquePassives: [
      UniquePassive.dodge15,
      UniquePassive.hpRegen3,
      UniquePassive.counter20,
      UniquePassive.mpRegen5,
    ],
  );

  // --- REGISTRY FOR LOOKUP ---
  static final List<InventoryItem> allItems = [
    potion,
    potionMedium,
    potionLarge,
    slimeResidue,
    rustySword,
    woodenClub,
    huntingBow,
    goblinScimitar,
    steelSword,
    battleAxe,
    vampiricBlade,
    flameTongue,
    shadowDagger,
    reapersScythe,
    bladeOfEternity,
    leatherTunic,
    clothRobe,
    chainmail,
    studledLeather,
    thornmail,
    dragonscale,
    monkRobes,
    archmageVestments,
    etherealPlate,
    armorOfTheAncients,
  ];

  static InventoryItem? getItemById(String id) {
    try {
      return allItems.firstWhere((item) => item.id == id);
    } catch (e) {
      print('⚠️ Item ID not found: $id');
      return null;
    }
  }
}
