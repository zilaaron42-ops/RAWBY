// ============================================================
// RAWBY — Gear & Subscription Models
// ============================================================
import 'package:hive/hive.dart';

@HiveType(typeId: 8)
class GearItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String category; // 'filming', 'editing', 'digital'

  @HiveField(3)
  String brand;

  @HiveField(4)
  String ownership; // 'new_purchase', 'already_owned', 'shared_access'

  @HiveField(5)
  int costHuf;

  @HiveField(6)
  int pointsCost; // deducted from totalScore if new_purchase

  @HiveField(7)
  String owner; // who you borrowed from (shared_access only)

  @HiveField(8)
  String notes;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  String usageState; // 'active', 'rested', 'retired'

  @HiveField(11)
  int outsideUses;

  @HiveField(12)
  DateTime? lastOutsideUseAt;

  @HiveField(13)
  List<String> usedInProjectIds;

  GearItem({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.ownership,
    required this.costHuf,
    required this.pointsCost,
    required this.owner,
    required this.notes,
    required this.createdAt,
    this.usageState = 'active',
    this.outsideUses = 0,
    this.lastOutsideUseAt,
    this.usedInProjectIds = const [],
  });

  /// Returns true if gear has been used but idle for 30+ days
  bool get shouldSuggestRest {
    if (usageState == 'rested' || usageState == 'retired') return false;
    if (usedInProjectIds.isEmpty && outsideUses == 0) return false;
    final lastUse = lastOutsideUseAt ??
      (usedInProjectIds.isEmpty ? null : DateTime.now());
    if (lastUse == null) return false;
    final daysSinceUse = DateTime.now().difference(lastUse).inDays;
    return daysSinceUse >= 30;
  }

  int get pointCost => pointsCost;

  GearItem copyWith({
    String? id,
    String? name,
    String? category,
    String? brand,
    String? ownership,
    int? costHuf,
    int? pointsCost,
    String? owner,
    String? notes,
    DateTime? createdAt,
    String? usageState,
    int? outsideUses,
    DateTime? lastOutsideUseAt,
    List<String>? usedInProjectIds,
  }) {
    return GearItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      ownership: ownership ?? this.ownership,
      costHuf: costHuf ?? this.costHuf,
      pointsCost: pointsCost ?? this.pointsCost,
      owner: owner ?? this.owner,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      usageState: usageState ?? this.usageState,
      outsideUses: outsideUses ?? this.outsideUses,
      lastOutsideUseAt: lastOutsideUseAt ?? this.lastOutsideUseAt,
      usedInProjectIds: usedInProjectIds ?? this.usedInProjectIds,
    );
  }

  factory GearItem.fromJson(Map<String, dynamic> json) => GearItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? json['label'] as String? ?? '',
        category: json['category'] as String? ?? 'filming',
        brand: json['brand'] as String? ?? '',
        ownership: json['ownership'] as String? ?? 'already_owned',
        costHuf: (json['costHuf'] as num?)?.toInt() ?? 0,
        pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
        owner: json['owner'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        usageState: json['usageState'] as String? ?? 'active',
        outsideUses: (json['outsideUses'] as num?)?.toInt() ?? 0,
        lastOutsideUseAt: json['lastOutsideUseAt'] != null
            ? DateTime.tryParse(json['lastOutsideUseAt'] as String)
            : null,
        usedInProjectIds: (json['usedInProjectIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'brand': brand,
        'ownership': ownership,
        'costHuf': costHuf,
        'pointsCost': pointsCost,
        'owner': owner,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'usageState': usageState,
        'outsideUses': outsideUses,
        'lastOutsideUseAt': lastOutsideUseAt?.toIso8601String(),
        'usedInProjectIds': usedInProjectIds,
      };
}

@HiveType(typeId: 9)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double costHuf; // cost in Hungarian Forint

  @HiveField(3)
  String frequency; // 'monthly' or 'yearly'

  @HiveField(4)
  String category; // 'filming', 'editing', 'digital'

  @HiveField(5)
  DateTime addedAt;

  @HiveField(6)
  bool isActive;

  Subscription({
    required this.id,
    required this.name,
    required this.costHuf,
    required this.frequency,
    required this.category,
    required this.addedAt,
    this.isActive = true,
  });

  /// Annual cost in HUF
  double get annualCostHuf {
    if (frequency == 'yearly') return costHuf;
    return costHuf * 12;
  }

  Subscription copyWith({
    String? id,
    String? name,
    double? costHuf,
    String? frequency,
    String? category,
    DateTime? addedAt,
    bool? isActive,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      costHuf: costHuf ?? this.costHuf,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        costHuf: (json['costHuf'] as num?)?.toDouble() ?? 0.0,
        frequency: json['frequency'] as String? ?? 'monthly',
        category: json['category'] as String? ?? 'digital',
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'] as String)
            : DateTime.now(),
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'costHuf': costHuf,
        'frequency': frequency,
        'category': category,
        'addedAt': addedAt.toIso8601String(),
        'isActive': isActive,
      };
}
