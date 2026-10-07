// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FuelSourcesTable extends FuelSources
    with TableInfo<$FuelSourcesTable, FuelSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FuelSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    false,
    check: () => fuelType.isIn(fuelTypeKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    check: () => unit.isIn(fuelUnitKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitWeightKgMeta = const VerificationMeta(
    'unitWeightKg',
  );
  @override
  late final GeneratedColumn<double> unitWeightKg = GeneratedColumn<double>(
    'unit_weight_kg',
    aliasedName,
    true,
    check: () => ComparableExpr(unitWeightKg).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tankCapacityMeta = const VerificationMeta(
    'tankCapacity',
  );
  @override
  late final GeneratedColumn<double> tankCapacity = GeneratedColumn<double>(
    'tank_capacity',
    aliasedName,
    true,
    check: () => ComparableExpr(tankCapacity).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usableFractionMeta = const VerificationMeta(
    'usableFraction',
  );
  @override
  late final GeneratedColumn<double> usableFraction = GeneratedColumn<double>(
    'usable_fraction',
    aliasedName,
    false,
    check: () =>
        ComparableExpr(usableFraction).isBiggerThanValue(0) &
        ComparableExpr(usableFraction).isSmallerOrEqualValue(1),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningDaysMeta = const VerificationMeta(
    'warningDays',
  );
  @override
  late final GeneratedColumn<int> warningDays = GeneratedColumn<int>(
    'warning_days',
    aliasedName,
    false,
    check: () => ComparableExpr(warningDays).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(FuelType.defaultWarningDays),
  );
  static const VerificationMeta _costPerUnitCentsMeta = const VerificationMeta(
    'costPerUnitCents',
  );
  @override
  late final GeneratedColumn<int> costPerUnitCents = GeneratedColumn<int>(
    'cost_per_unit_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(costPerUnitCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    fuelType,
    unit,
    unitWeightKg,
    tankCapacity,
    usableFraction,
    warningDays,
    costPerUnitCents,
    active,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fuel_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<FuelSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelTypeMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_weight_kg')) {
      context.handle(
        _unitWeightKgMeta,
        unitWeightKg.isAcceptableOrUnknown(
          data['unit_weight_kg']!,
          _unitWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('tank_capacity')) {
      context.handle(
        _tankCapacityMeta,
        tankCapacity.isAcceptableOrUnknown(
          data['tank_capacity']!,
          _tankCapacityMeta,
        ),
      );
    }
    if (data.containsKey('usable_fraction')) {
      context.handle(
        _usableFractionMeta,
        usableFraction.isAcceptableOrUnknown(
          data['usable_fraction']!,
          _usableFractionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_usableFractionMeta);
    }
    if (data.containsKey('warning_days')) {
      context.handle(
        _warningDaysMeta,
        warningDays.isAcceptableOrUnknown(
          data['warning_days']!,
          _warningDaysMeta,
        ),
      );
    }
    if (data.containsKey('cost_per_unit_cents')) {
      context.handle(
        _costPerUnitCentsMeta,
        costPerUnitCents.isAcceptableOrUnknown(
          data['cost_per_unit_cents']!,
          _costPerUnitCentsMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FuelSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FuelSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_weight_kg'],
      ),
      tankCapacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tank_capacity'],
      ),
      usableFraction: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}usable_fraction'],
      )!,
      warningDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}warning_days'],
      )!,
      costPerUnitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_per_unit_cents'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FuelSourcesTable createAlias(String alias) {
    return $FuelSourcesTable(attachedDatabase, alias);
  }
}

class FuelSource extends DataClass implements Insertable<FuelSource> {
  final int id;

  /// Il nome dato dall'utente. E' un dato, non un testo dell'app.
  final String name;

  /// `FuelType.key`: `pellet` | `lpg` | `diesel` | `wood` | `biomass`.
  final String fuelType;

  /// Chiave in `FuelUnits`. ⚑ Il CHECK accetta tutte le unita' del catalogo; che l'unita' sia
  /// ammessa **per quel combustibile** (niente "litri di pellet") lo controlla
  /// `ScorteRepository` con `FuelUnits.isAllowed`: un CHECK che incrocia due colonne con
  /// una mappa del dominio sarebbe illeggibile e andrebbe migrato a ogni unita' nuova.
  final String unit;

  /// Peso in kg di un sacco/cesta. Opzionale, solo informativo (F5.4).
  final double? unitWeightKg;

  /// Capacita' **nominale** del serbatoio, in litri, per `lpg`/`diesel`. Il CHECK lascia
  /// passare NULL (in SQL `NULL > 0` e' sconosciuto, e un CHECK sconosciuto passa).
  final double? tankCapacity;

  /// Frazione della capacita' nominale davvero utilizzabile, in (0, 1].
  ///
  /// ☠ Il GPL non si riempie mai oltre l'80%: il manometro va moltiplicato per la capacita'
  /// **utile**, non per la nominale (F5.2). Nessun default SQL: il default dipende dal
  /// combustibile (`FuelType.defaultUsableFraction`) e lo mette il repository. Zero e'
  /// escluso: una fonte con capacita' utile nulla trasformerebbe ogni percentuale in 0.
  final double usableFraction;

  /// Giorni di anticipo del riordino rispetto all'esaurimento stimato.
  final int warningDays;
  final int? costPerUnitCents;

  /// Una fonte disattivata (stufa dismessa) sparisce da dashboard, notifiche e widget ma
  /// conserva lo storico. Cancellarla invece porta via tutto (cascade).
  final bool active;

  /// Ordine nella dashboard (trascinamento). Non e' nella tabella di F5.2: ⚑ aggiunto per
  /// coerenza con Full Freezer, dove l'ordine dei freezer e' dell'utente e non dell'id.
  final int sortOrder;
  final int createdAt;
  const FuelSource({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.unit,
    this.unitWeightKg,
    this.tankCapacity,
    required this.usableFraction,
    required this.warningDays,
    this.costPerUnitCents,
    required this.active,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['fuel_type'] = Variable<String>(fuelType);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || unitWeightKg != null) {
      map['unit_weight_kg'] = Variable<double>(unitWeightKg);
    }
    if (!nullToAbsent || tankCapacity != null) {
      map['tank_capacity'] = Variable<double>(tankCapacity);
    }
    map['usable_fraction'] = Variable<double>(usableFraction);
    map['warning_days'] = Variable<int>(warningDays);
    if (!nullToAbsent || costPerUnitCents != null) {
      map['cost_per_unit_cents'] = Variable<int>(costPerUnitCents);
    }
    map['active'] = Variable<bool>(active);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FuelSourcesCompanion toCompanion(bool nullToAbsent) {
    return FuelSourcesCompanion(
      id: Value(id),
      name: Value(name),
      fuelType: Value(fuelType),
      unit: Value(unit),
      unitWeightKg: unitWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(unitWeightKg),
      tankCapacity: tankCapacity == null && nullToAbsent
          ? const Value.absent()
          : Value(tankCapacity),
      usableFraction: Value(usableFraction),
      warningDays: Value(warningDays),
      costPerUnitCents: costPerUnitCents == null && nullToAbsent
          ? const Value.absent()
          : Value(costPerUnitCents),
      active: Value(active),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory FuelSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FuelSource(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fuelType: serializer.fromJson<String>(json['fuelType']),
      unit: serializer.fromJson<String>(json['unit']),
      unitWeightKg: serializer.fromJson<double?>(json['unitWeightKg']),
      tankCapacity: serializer.fromJson<double?>(json['tankCapacity']),
      usableFraction: serializer.fromJson<double>(json['usableFraction']),
      warningDays: serializer.fromJson<int>(json['warningDays']),
      costPerUnitCents: serializer.fromJson<int?>(json['costPerUnitCents']),
      active: serializer.fromJson<bool>(json['active']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'fuelType': serializer.toJson<String>(fuelType),
      'unit': serializer.toJson<String>(unit),
      'unitWeightKg': serializer.toJson<double?>(unitWeightKg),
      'tankCapacity': serializer.toJson<double?>(tankCapacity),
      'usableFraction': serializer.toJson<double>(usableFraction),
      'warningDays': serializer.toJson<int>(warningDays),
      'costPerUnitCents': serializer.toJson<int?>(costPerUnitCents),
      'active': serializer.toJson<bool>(active),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FuelSource copyWith({
    int? id,
    String? name,
    String? fuelType,
    String? unit,
    Value<double?> unitWeightKg = const Value.absent(),
    Value<double?> tankCapacity = const Value.absent(),
    double? usableFraction,
    int? warningDays,
    Value<int?> costPerUnitCents = const Value.absent(),
    bool? active,
    int? sortOrder,
    int? createdAt,
  }) => FuelSource(
    id: id ?? this.id,
    name: name ?? this.name,
    fuelType: fuelType ?? this.fuelType,
    unit: unit ?? this.unit,
    unitWeightKg: unitWeightKg.present ? unitWeightKg.value : this.unitWeightKg,
    tankCapacity: tankCapacity.present ? tankCapacity.value : this.tankCapacity,
    usableFraction: usableFraction ?? this.usableFraction,
    warningDays: warningDays ?? this.warningDays,
    costPerUnitCents: costPerUnitCents.present
        ? costPerUnitCents.value
        : this.costPerUnitCents,
    active: active ?? this.active,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  FuelSource copyWithCompanion(FuelSourcesCompanion data) {
    return FuelSource(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitWeightKg: data.unitWeightKg.present
          ? data.unitWeightKg.value
          : this.unitWeightKg,
      tankCapacity: data.tankCapacity.present
          ? data.tankCapacity.value
          : this.tankCapacity,
      usableFraction: data.usableFraction.present
          ? data.usableFraction.value
          : this.usableFraction,
      warningDays: data.warningDays.present
          ? data.warningDays.value
          : this.warningDays,
      costPerUnitCents: data.costPerUnitCents.present
          ? data.costPerUnitCents.value
          : this.costPerUnitCents,
      active: data.active.present ? data.active.value : this.active,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FuelSource(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fuelType: $fuelType, ')
          ..write('unit: $unit, ')
          ..write('unitWeightKg: $unitWeightKg, ')
          ..write('tankCapacity: $tankCapacity, ')
          ..write('usableFraction: $usableFraction, ')
          ..write('warningDays: $warningDays, ')
          ..write('costPerUnitCents: $costPerUnitCents, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fuelType,
    unit,
    unitWeightKg,
    tankCapacity,
    usableFraction,
    warningDays,
    costPerUnitCents,
    active,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FuelSource &&
          other.id == this.id &&
          other.name == this.name &&
          other.fuelType == this.fuelType &&
          other.unit == this.unit &&
          other.unitWeightKg == this.unitWeightKg &&
          other.tankCapacity == this.tankCapacity &&
          other.usableFraction == this.usableFraction &&
          other.warningDays == this.warningDays &&
          other.costPerUnitCents == this.costPerUnitCents &&
          other.active == this.active &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FuelSourcesCompanion extends UpdateCompanion<FuelSource> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> fuelType;
  final Value<String> unit;
  final Value<double?> unitWeightKg;
  final Value<double?> tankCapacity;
  final Value<double> usableFraction;
  final Value<int> warningDays;
  final Value<int?> costPerUnitCents;
  final Value<bool> active;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const FuelSourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitWeightKg = const Value.absent(),
    this.tankCapacity = const Value.absent(),
    this.usableFraction = const Value.absent(),
    this.warningDays = const Value.absent(),
    this.costPerUnitCents = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FuelSourcesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String fuelType,
    required String unit,
    this.unitWeightKg = const Value.absent(),
    this.tankCapacity = const Value.absent(),
    required double usableFraction,
    this.warningDays = const Value.absent(),
    this.costPerUnitCents = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       fuelType = Value(fuelType),
       unit = Value(unit),
       usableFraction = Value(usableFraction),
       createdAt = Value(createdAt);
  static Insertable<FuelSource> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? fuelType,
    Expression<String>? unit,
    Expression<double>? unitWeightKg,
    Expression<double>? tankCapacity,
    Expression<double>? usableFraction,
    Expression<int>? warningDays,
    Expression<int>? costPerUnitCents,
    Expression<bool>? active,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fuelType != null) 'fuel_type': fuelType,
      if (unit != null) 'unit': unit,
      if (unitWeightKg != null) 'unit_weight_kg': unitWeightKg,
      if (tankCapacity != null) 'tank_capacity': tankCapacity,
      if (usableFraction != null) 'usable_fraction': usableFraction,
      if (warningDays != null) 'warning_days': warningDays,
      if (costPerUnitCents != null) 'cost_per_unit_cents': costPerUnitCents,
      if (active != null) 'active': active,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FuelSourcesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? fuelType,
    Value<String>? unit,
    Value<double?>? unitWeightKg,
    Value<double?>? tankCapacity,
    Value<double>? usableFraction,
    Value<int>? warningDays,
    Value<int?>? costPerUnitCents,
    Value<bool>? active,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return FuelSourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fuelType: fuelType ?? this.fuelType,
      unit: unit ?? this.unit,
      unitWeightKg: unitWeightKg ?? this.unitWeightKg,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      usableFraction: usableFraction ?? this.usableFraction,
      warningDays: warningDays ?? this.warningDays,
      costPerUnitCents: costPerUnitCents ?? this.costPerUnitCents,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitWeightKg.present) {
      map['unit_weight_kg'] = Variable<double>(unitWeightKg.value);
    }
    if (tankCapacity.present) {
      map['tank_capacity'] = Variable<double>(tankCapacity.value);
    }
    if (usableFraction.present) {
      map['usable_fraction'] = Variable<double>(usableFraction.value);
    }
    if (warningDays.present) {
      map['warning_days'] = Variable<int>(warningDays.value);
    }
    if (costPerUnitCents.present) {
      map['cost_per_unit_cents'] = Variable<int>(costPerUnitCents.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FuelSourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fuelType: $fuelType, ')
          ..write('unit: $unit, ')
          ..write('unitWeightKg: $unitWeightKg, ')
          ..write('tankCapacity: $tankCapacity, ')
          ..write('usableFraction: $usableFraction, ')
          ..write('warningDays: $warningDays, ')
          ..write('costPerUnitCents: $costPerUnitCents, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StockMeasurementsTable extends StockMeasurements
    with TableInfo<$StockMeasurementsTable, StockMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fuelSourceIdMeta = const VerificationMeta(
    'fuelSourceId',
  );
  @override
  late final GeneratedColumn<int> fuelSourceId = GeneratedColumn<int>(
    'fuel_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fuel_sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    check: () => ComparableExpr(quantity).isBiggerOrEqualValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enteredAsMeta = const VerificationMeta(
    'enteredAs',
  );
  @override
  late final GeneratedColumn<String> enteredAs = GeneratedColumn<String>(
    'entered_as',
    aliasedName,
    false,
    check: () => enteredAs.isIn(enteredAsKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawInputMeta = const VerificationMeta(
    'rawInput',
  );
  @override
  late final GeneratedColumn<double> rawInput = GeneratedColumn<double>(
    'raw_input',
    aliasedName,
    false,
    check: () =>
        ComparableExpr(rawInput).isBiggerOrEqualValue(0) &
        (enteredAs.equals(EnteredAs.absolute.key) |
            ComparableExpr(rawInput).isSmallerOrEqualValue(100)),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fuelSourceId,
    date,
    quantity,
    enteredAs,
    rawInput,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_measurements';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockMeasurement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fuel_source_id')) {
      context.handle(
        _fuelSourceIdMeta,
        fuelSourceId.isAcceptableOrUnknown(
          data['fuel_source_id']!,
          _fuelSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fuelSourceIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('entered_as')) {
      context.handle(
        _enteredAsMeta,
        enteredAs.isAcceptableOrUnknown(data['entered_as']!, _enteredAsMeta),
      );
    } else if (isInserting) {
      context.missing(_enteredAsMeta);
    }
    if (data.containsKey('raw_input')) {
      context.handle(
        _rawInputMeta,
        rawInput.isAcceptableOrUnknown(data['raw_input']!, _rawInputMeta),
      );
    } else if (isInserting) {
      context.missing(_rawInputMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {fuelSourceId, date},
  ];
  @override
  StockMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockMeasurement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fuelSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fuel_source_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      enteredAs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entered_as'],
      )!,
      rawInput: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}raw_input'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $StockMeasurementsTable createAlias(String alias) {
    return $StockMeasurementsTable(attachedDatabase, alias);
  }
}

class StockMeasurement extends DataClass
    implements Insertable<StockMeasurement> {
  final int id;
  final int fuelSourceId;

  /// `YYYY-MM-DD` (ADR-008). Il formato a larghezza fissa fa coincidere l'ordine del testo
  /// con quello cronologico: `ORDER BY date` e `date >= ?` funzionano senza conversioni.
  final String date;

  /// Nell'unita' della fonte, gia' convertita. Zero e' ammesso: la stufa a secco esiste.
  final double quantity;

  /// `absolute` | `percentage`: cosa ha digitato l'utente.
  final String enteredAs;

  /// Il valore digitato, prima della conversione.
  ///
  /// ⚑ **Perche' si conserva** (F5.2): se l'utente cambia capacita' o frazione utile dopo
  /// dieci misure in percentuale, le quantita' si ricalcolano da qui
  /// (`ScorteRepository.recomputeMeasurements`). Una lettura di manometro sopra il 100% non
  /// esiste: il CHECK la rifiuta solo per `percentage`.
  final double rawInput;
  final String? note;
  const StockMeasurement({
    required this.id,
    required this.fuelSourceId,
    required this.date,
    required this.quantity,
    required this.enteredAs,
    required this.rawInput,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fuel_source_id'] = Variable<int>(fuelSourceId);
    map['date'] = Variable<String>(date);
    map['quantity'] = Variable<double>(quantity);
    map['entered_as'] = Variable<String>(enteredAs);
    map['raw_input'] = Variable<double>(rawInput);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  StockMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return StockMeasurementsCompanion(
      id: Value(id),
      fuelSourceId: Value(fuelSourceId),
      date: Value(date),
      quantity: Value(quantity),
      enteredAs: Value(enteredAs),
      rawInput: Value(rawInput),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory StockMeasurement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockMeasurement(
      id: serializer.fromJson<int>(json['id']),
      fuelSourceId: serializer.fromJson<int>(json['fuelSourceId']),
      date: serializer.fromJson<String>(json['date']),
      quantity: serializer.fromJson<double>(json['quantity']),
      enteredAs: serializer.fromJson<String>(json['enteredAs']),
      rawInput: serializer.fromJson<double>(json['rawInput']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fuelSourceId': serializer.toJson<int>(fuelSourceId),
      'date': serializer.toJson<String>(date),
      'quantity': serializer.toJson<double>(quantity),
      'enteredAs': serializer.toJson<String>(enteredAs),
      'rawInput': serializer.toJson<double>(rawInput),
      'note': serializer.toJson<String?>(note),
    };
  }

  StockMeasurement copyWith({
    int? id,
    int? fuelSourceId,
    String? date,
    double? quantity,
    String? enteredAs,
    double? rawInput,
    Value<String?> note = const Value.absent(),
  }) => StockMeasurement(
    id: id ?? this.id,
    fuelSourceId: fuelSourceId ?? this.fuelSourceId,
    date: date ?? this.date,
    quantity: quantity ?? this.quantity,
    enteredAs: enteredAs ?? this.enteredAs,
    rawInput: rawInput ?? this.rawInput,
    note: note.present ? note.value : this.note,
  );
  StockMeasurement copyWithCompanion(StockMeasurementsCompanion data) {
    return StockMeasurement(
      id: data.id.present ? data.id.value : this.id,
      fuelSourceId: data.fuelSourceId.present
          ? data.fuelSourceId.value
          : this.fuelSourceId,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      enteredAs: data.enteredAs.present ? data.enteredAs.value : this.enteredAs,
      rawInput: data.rawInput.present ? data.rawInput.value : this.rawInput,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockMeasurement(')
          ..write('id: $id, ')
          ..write('fuelSourceId: $fuelSourceId, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('enteredAs: $enteredAs, ')
          ..write('rawInput: $rawInput, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fuelSourceId, date, quantity, enteredAs, rawInput, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockMeasurement &&
          other.id == this.id &&
          other.fuelSourceId == this.fuelSourceId &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.enteredAs == this.enteredAs &&
          other.rawInput == this.rawInput &&
          other.note == this.note);
}

class StockMeasurementsCompanion extends UpdateCompanion<StockMeasurement> {
  final Value<int> id;
  final Value<int> fuelSourceId;
  final Value<String> date;
  final Value<double> quantity;
  final Value<String> enteredAs;
  final Value<double> rawInput;
  final Value<String?> note;
  const StockMeasurementsCompanion({
    this.id = const Value.absent(),
    this.fuelSourceId = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.enteredAs = const Value.absent(),
    this.rawInput = const Value.absent(),
    this.note = const Value.absent(),
  });
  StockMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    required int fuelSourceId,
    required String date,
    required double quantity,
    required String enteredAs,
    required double rawInput,
    this.note = const Value.absent(),
  }) : fuelSourceId = Value(fuelSourceId),
       date = Value(date),
       quantity = Value(quantity),
       enteredAs = Value(enteredAs),
       rawInput = Value(rawInput);
  static Insertable<StockMeasurement> custom({
    Expression<int>? id,
    Expression<int>? fuelSourceId,
    Expression<String>? date,
    Expression<double>? quantity,
    Expression<String>? enteredAs,
    Expression<double>? rawInput,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fuelSourceId != null) 'fuel_source_id': fuelSourceId,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (enteredAs != null) 'entered_as': enteredAs,
      if (rawInput != null) 'raw_input': rawInput,
      if (note != null) 'note': note,
    });
  }

  StockMeasurementsCompanion copyWith({
    Value<int>? id,
    Value<int>? fuelSourceId,
    Value<String>? date,
    Value<double>? quantity,
    Value<String>? enteredAs,
    Value<double>? rawInput,
    Value<String?>? note,
  }) {
    return StockMeasurementsCompanion(
      id: id ?? this.id,
      fuelSourceId: fuelSourceId ?? this.fuelSourceId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      enteredAs: enteredAs ?? this.enteredAs,
      rawInput: rawInput ?? this.rawInput,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fuelSourceId.present) {
      map['fuel_source_id'] = Variable<int>(fuelSourceId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (enteredAs.present) {
      map['entered_as'] = Variable<String>(enteredAs.value);
    }
    if (rawInput.present) {
      map['raw_input'] = Variable<double>(rawInput.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('fuelSourceId: $fuelSourceId, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('enteredAs: $enteredAs, ')
          ..write('rawInput: $rawInput, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases
    with TableInfo<$PurchasesTable, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fuelSourceIdMeta = const VerificationMeta(
    'fuelSourceId',
  );
  @override
  late final GeneratedColumn<int> fuelSourceId = GeneratedColumn<int>(
    'fuel_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES fuel_sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    check: () => ComparableExpr(quantity).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCostCentsMeta = const VerificationMeta(
    'totalCostCents',
  );
  @override
  late final GeneratedColumn<int> totalCostCents = GeneratedColumn<int>(
    'total_cost_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(totalCostCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supplierMeta = const VerificationMeta(
    'supplier',
  );
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
    'supplier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fuelSourceId,
    date,
    quantity,
    totalCostCents,
    supplier,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<Purchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fuel_source_id')) {
      context.handle(
        _fuelSourceIdMeta,
        fuelSourceId.isAcceptableOrUnknown(
          data['fuel_source_id']!,
          _fuelSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fuelSourceIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('total_cost_cents')) {
      context.handle(
        _totalCostCentsMeta,
        totalCostCents.isAcceptableOrUnknown(
          data['total_cost_cents']!,
          _totalCostCentsMeta,
        ),
      );
    }
    if (data.containsKey('supplier')) {
      context.handle(
        _supplierMeta,
        supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fuelSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fuel_source_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      totalCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cost_cents'],
      ),
      supplier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final int id;
  final int fuelSourceId;

  /// `YYYY-MM-DD` (ADR-008).
  final String date;

  /// Nell'unita' della fonte. ⚑ Strettamente positiva, a differenza della scorta: un
  /// acquisto di zero non e' un acquisto, e falserebbe il costo medio per unita'.
  final double quantity;

  /// ⚑ Nullable, anche se F5.2 non lo dice: la legna regalata dal vicino o lo scontrino
  /// perso non devono impedire di registrare l'acquisto. Il costo medio conta solo gli
  /// acquisti con un costo.
  final int? totalCostCents;
  final String? supplier;
  final String? note;
  const Purchase({
    required this.id,
    required this.fuelSourceId,
    required this.date,
    required this.quantity,
    this.totalCostCents,
    this.supplier,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fuel_source_id'] = Variable<int>(fuelSourceId);
    map['date'] = Variable<String>(date);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || totalCostCents != null) {
      map['total_cost_cents'] = Variable<int>(totalCostCents);
    }
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      fuelSourceId: Value(fuelSourceId),
      date: Value(date),
      quantity: Value(quantity),
      totalCostCents: totalCostCents == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCostCents),
      supplier: supplier == null && nullToAbsent
          ? const Value.absent()
          : Value(supplier),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Purchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<int>(json['id']),
      fuelSourceId: serializer.fromJson<int>(json['fuelSourceId']),
      date: serializer.fromJson<String>(json['date']),
      quantity: serializer.fromJson<double>(json['quantity']),
      totalCostCents: serializer.fromJson<int?>(json['totalCostCents']),
      supplier: serializer.fromJson<String?>(json['supplier']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fuelSourceId': serializer.toJson<int>(fuelSourceId),
      'date': serializer.toJson<String>(date),
      'quantity': serializer.toJson<double>(quantity),
      'totalCostCents': serializer.toJson<int?>(totalCostCents),
      'supplier': serializer.toJson<String?>(supplier),
      'note': serializer.toJson<String?>(note),
    };
  }

  Purchase copyWith({
    int? id,
    int? fuelSourceId,
    String? date,
    double? quantity,
    Value<int?> totalCostCents = const Value.absent(),
    Value<String?> supplier = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Purchase(
    id: id ?? this.id,
    fuelSourceId: fuelSourceId ?? this.fuelSourceId,
    date: date ?? this.date,
    quantity: quantity ?? this.quantity,
    totalCostCents: totalCostCents.present
        ? totalCostCents.value
        : this.totalCostCents,
    supplier: supplier.present ? supplier.value : this.supplier,
    note: note.present ? note.value : this.note,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      fuelSourceId: data.fuelSourceId.present
          ? data.fuelSourceId.value
          : this.fuelSourceId,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      totalCostCents: data.totalCostCents.present
          ? data.totalCostCents.value
          : this.totalCostCents,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('fuelSourceId: $fuelSourceId, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('totalCostCents: $totalCostCents, ')
          ..write('supplier: $supplier, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fuelSourceId,
    date,
    quantity,
    totalCostCents,
    supplier,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.fuelSourceId == this.fuelSourceId &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.totalCostCents == this.totalCostCents &&
          other.supplier == this.supplier &&
          other.note == this.note);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<int> id;
  final Value<int> fuelSourceId;
  final Value<String> date;
  final Value<double> quantity;
  final Value<int?> totalCostCents;
  final Value<String?> supplier;
  final Value<String?> note;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.fuelSourceId = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.totalCostCents = const Value.absent(),
    this.supplier = const Value.absent(),
    this.note = const Value.absent(),
  });
  PurchasesCompanion.insert({
    this.id = const Value.absent(),
    required int fuelSourceId,
    required String date,
    required double quantity,
    this.totalCostCents = const Value.absent(),
    this.supplier = const Value.absent(),
    this.note = const Value.absent(),
  }) : fuelSourceId = Value(fuelSourceId),
       date = Value(date),
       quantity = Value(quantity);
  static Insertable<Purchase> custom({
    Expression<int>? id,
    Expression<int>? fuelSourceId,
    Expression<String>? date,
    Expression<double>? quantity,
    Expression<int>? totalCostCents,
    Expression<String>? supplier,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fuelSourceId != null) 'fuel_source_id': fuelSourceId,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (totalCostCents != null) 'total_cost_cents': totalCostCents,
      if (supplier != null) 'supplier': supplier,
      if (note != null) 'note': note,
    });
  }

  PurchasesCompanion copyWith({
    Value<int>? id,
    Value<int>? fuelSourceId,
    Value<String>? date,
    Value<double>? quantity,
    Value<int?>? totalCostCents,
    Value<String?>? supplier,
    Value<String?>? note,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      fuelSourceId: fuelSourceId ?? this.fuelSourceId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      totalCostCents: totalCostCents ?? this.totalCostCents,
      supplier: supplier ?? this.supplier,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fuelSourceId.present) {
      map['fuel_source_id'] = Variable<int>(fuelSourceId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (totalCostCents.present) {
      map['total_cost_cents'] = Variable<int>(totalCostCents.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('fuelSourceId: $fuelSourceId, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('totalCostCents: $totalCostCents, ')
          ..write('supplier: $supplier, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $CalendarRemindersTable extends CalendarReminders
    with TableInfo<$CalendarRemindersTable, CalendarReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fuelSourceIdMeta = const VerificationMeta(
    'fuelSourceId',
  );
  @override
  late final GeneratedColumn<int> fuelSourceId = GeneratedColumn<int>(
    'fuel_source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES fuel_sources (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalEventIdMeta = const VerificationMeta(
    'externalEventId',
  );
  @override
  late final GeneratedColumn<String> externalEventId = GeneratedColumn<String>(
    'external_event_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calculatedDateMeta = const VerificationMeta(
    'calculatedDate',
  );
  @override
  late final GeneratedColumn<String> calculatedDate = GeneratedColumn<String>(
    'calculated_date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncedAt = GeneratedColumn<int>(
    'last_synced_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fuelSourceId,
    calendarId,
    externalEventId,
    calculatedDate,
    createdAt,
    lastSyncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fuel_source_id')) {
      context.handle(
        _fuelSourceIdMeta,
        fuelSourceId.isAcceptableOrUnknown(
          data['fuel_source_id']!,
          _fuelSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fuelSourceIdMeta);
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('external_event_id')) {
      context.handle(
        _externalEventIdMeta,
        externalEventId.isAcceptableOrUnknown(
          data['external_event_id']!,
          _externalEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_externalEventIdMeta);
    }
    if (data.containsKey('calculated_date')) {
      context.handle(
        _calculatedDateMeta,
        calculatedDate.isAcceptableOrUnknown(
          data['calculated_date']!,
          _calculatedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_calculatedDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarReminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fuelSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fuel_source_id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calendar_id'],
      )!,
      externalEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_event_id'],
      )!,
      calculatedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}calculated_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_synced_at'],
      )!,
    );
  }

  @override
  $CalendarRemindersTable createAlias(String alias) {
    return $CalendarRemindersTable(attachedDatabase, alias);
  }
}

class CalendarReminder extends DataClass
    implements Insertable<CalendarReminder> {
  final int id;
  final int fuelSourceId;

  /// Il calendario che contiene l'evento. ⚑ Non e' nella tabella di F5.2, ma
  /// `CalendarSyncService.deleteEvent(calendarId, eventId)` e `upsertReorderEvent` lo
  /// chiedono: senza, un evento creato non si potrebbe piu' aggiornare ne' cancellare.
  final String calendarId;

  /// L'id dell'evento restituito da `device_calendar`.
  final String externalEventId;

  /// La `reorderDate` con cui l'evento e' stato scritto, `YYYY-MM-DD`. Serve a capire se la
  /// stima e' cambiata di piu' di 3 giorni e va **proposto** l'aggiornamento (F5.10).
  final String calculatedDate;
  final int createdAt;
  final int lastSyncedAt;
  const CalendarReminder({
    required this.id,
    required this.fuelSourceId,
    required this.calendarId,
    required this.externalEventId,
    required this.calculatedDate,
    required this.createdAt,
    required this.lastSyncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fuel_source_id'] = Variable<int>(fuelSourceId);
    map['calendar_id'] = Variable<String>(calendarId);
    map['external_event_id'] = Variable<String>(externalEventId);
    map['calculated_date'] = Variable<String>(calculatedDate);
    map['created_at'] = Variable<int>(createdAt);
    map['last_synced_at'] = Variable<int>(lastSyncedAt);
    return map;
  }

  CalendarRemindersCompanion toCompanion(bool nullToAbsent) {
    return CalendarRemindersCompanion(
      id: Value(id),
      fuelSourceId: Value(fuelSourceId),
      calendarId: Value(calendarId),
      externalEventId: Value(externalEventId),
      calculatedDate: Value(calculatedDate),
      createdAt: Value(createdAt),
      lastSyncedAt: Value(lastSyncedAt),
    );
  }

  factory CalendarReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarReminder(
      id: serializer.fromJson<int>(json['id']),
      fuelSourceId: serializer.fromJson<int>(json['fuelSourceId']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      externalEventId: serializer.fromJson<String>(json['externalEventId']),
      calculatedDate: serializer.fromJson<String>(json['calculatedDate']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastSyncedAt: serializer.fromJson<int>(json['lastSyncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fuelSourceId': serializer.toJson<int>(fuelSourceId),
      'calendarId': serializer.toJson<String>(calendarId),
      'externalEventId': serializer.toJson<String>(externalEventId),
      'calculatedDate': serializer.toJson<String>(calculatedDate),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastSyncedAt': serializer.toJson<int>(lastSyncedAt),
    };
  }

  CalendarReminder copyWith({
    int? id,
    int? fuelSourceId,
    String? calendarId,
    String? externalEventId,
    String? calculatedDate,
    int? createdAt,
    int? lastSyncedAt,
  }) => CalendarReminder(
    id: id ?? this.id,
    fuelSourceId: fuelSourceId ?? this.fuelSourceId,
    calendarId: calendarId ?? this.calendarId,
    externalEventId: externalEventId ?? this.externalEventId,
    calculatedDate: calculatedDate ?? this.calculatedDate,
    createdAt: createdAt ?? this.createdAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
  CalendarReminder copyWithCompanion(CalendarRemindersCompanion data) {
    return CalendarReminder(
      id: data.id.present ? data.id.value : this.id,
      fuelSourceId: data.fuelSourceId.present
          ? data.fuelSourceId.value
          : this.fuelSourceId,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      externalEventId: data.externalEventId.present
          ? data.externalEventId.value
          : this.externalEventId,
      calculatedDate: data.calculatedDate.present
          ? data.calculatedDate.value
          : this.calculatedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarReminder(')
          ..write('id: $id, ')
          ..write('fuelSourceId: $fuelSourceId, ')
          ..write('calendarId: $calendarId, ')
          ..write('externalEventId: $externalEventId, ')
          ..write('calculatedDate: $calculatedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fuelSourceId,
    calendarId,
    externalEventId,
    calculatedDate,
    createdAt,
    lastSyncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarReminder &&
          other.id == this.id &&
          other.fuelSourceId == this.fuelSourceId &&
          other.calendarId == this.calendarId &&
          other.externalEventId == this.externalEventId &&
          other.calculatedDate == this.calculatedDate &&
          other.createdAt == this.createdAt &&
          other.lastSyncedAt == this.lastSyncedAt);
}

class CalendarRemindersCompanion extends UpdateCompanion<CalendarReminder> {
  final Value<int> id;
  final Value<int> fuelSourceId;
  final Value<String> calendarId;
  final Value<String> externalEventId;
  final Value<String> calculatedDate;
  final Value<int> createdAt;
  final Value<int> lastSyncedAt;
  const CalendarRemindersCompanion({
    this.id = const Value.absent(),
    this.fuelSourceId = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.externalEventId = const Value.absent(),
    this.calculatedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
  });
  CalendarRemindersCompanion.insert({
    this.id = const Value.absent(),
    required int fuelSourceId,
    required String calendarId,
    required String externalEventId,
    required String calculatedDate,
    required int createdAt,
    required int lastSyncedAt,
  }) : fuelSourceId = Value(fuelSourceId),
       calendarId = Value(calendarId),
       externalEventId = Value(externalEventId),
       calculatedDate = Value(calculatedDate),
       createdAt = Value(createdAt),
       lastSyncedAt = Value(lastSyncedAt);
  static Insertable<CalendarReminder> custom({
    Expression<int>? id,
    Expression<int>? fuelSourceId,
    Expression<String>? calendarId,
    Expression<String>? externalEventId,
    Expression<String>? calculatedDate,
    Expression<int>? createdAt,
    Expression<int>? lastSyncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fuelSourceId != null) 'fuel_source_id': fuelSourceId,
      if (calendarId != null) 'calendar_id': calendarId,
      if (externalEventId != null) 'external_event_id': externalEventId,
      if (calculatedDate != null) 'calculated_date': calculatedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
    });
  }

  CalendarRemindersCompanion copyWith({
    Value<int>? id,
    Value<int>? fuelSourceId,
    Value<String>? calendarId,
    Value<String>? externalEventId,
    Value<String>? calculatedDate,
    Value<int>? createdAt,
    Value<int>? lastSyncedAt,
  }) {
    return CalendarRemindersCompanion(
      id: id ?? this.id,
      fuelSourceId: fuelSourceId ?? this.fuelSourceId,
      calendarId: calendarId ?? this.calendarId,
      externalEventId: externalEventId ?? this.externalEventId,
      calculatedDate: calculatedDate ?? this.calculatedDate,
      createdAt: createdAt ?? this.createdAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fuelSourceId.present) {
      map['fuel_source_id'] = Variable<int>(fuelSourceId.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (externalEventId.present) {
      map['external_event_id'] = Variable<String>(externalEventId.value);
    }
    if (calculatedDate.present) {
      map['calculated_date'] = Variable<String>(calculatedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<int>(lastSyncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarRemindersCompanion(')
          ..write('id: $id, ')
          ..write('fuelSourceId: $fuelSourceId, ')
          ..write('calendarId: $calendarId, ')
          ..write('externalEventId: $externalEventId, ')
          ..write('calculatedDate: $calculatedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastSyncedAt: $lastSyncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FuelSourcesTable fuelSources = $FuelSourcesTable(this);
  late final $StockMeasurementsTable stockMeasurements =
      $StockMeasurementsTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $CalendarRemindersTable calendarReminders =
      $CalendarRemindersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    fuelSources,
    stockMeasurements,
    purchases,
    calendarReminders,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'fuel_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stock_measurements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'fuel_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('purchases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'fuel_sources',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_reminders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FuelSourcesTableCreateCompanionBuilder =
    FuelSourcesCompanion Function({
      Value<int> id,
      required String name,
      required String fuelType,
      required String unit,
      Value<double?> unitWeightKg,
      Value<double?> tankCapacity,
      required double usableFraction,
      Value<int> warningDays,
      Value<int?> costPerUnitCents,
      Value<bool> active,
      Value<int> sortOrder,
      required int createdAt,
    });
typedef $$FuelSourcesTableUpdateCompanionBuilder =
    FuelSourcesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> fuelType,
      Value<String> unit,
      Value<double?> unitWeightKg,
      Value<double?> tankCapacity,
      Value<double> usableFraction,
      Value<int> warningDays,
      Value<int?> costPerUnitCents,
      Value<bool> active,
      Value<int> sortOrder,
      Value<int> createdAt,
    });

final class $$FuelSourcesTableReferences
    extends BaseReferences<_$AppDatabase, $FuelSourcesTable, FuelSource> {
  $$FuelSourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockMeasurementsTable, List<StockMeasurement>>
  _stockMeasurementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stockMeasurements,
        aliasName: 'fuel_sources__id__stock_measurements__fuel_source_id',
      );

  $$StockMeasurementsTableProcessedTableManager get stockMeasurementsRefs {
    final manager = $$StockMeasurementsTableTableManager(
      $_db,
      $_db.stockMeasurements,
    ).filter((f) => f.fuelSourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stockMeasurementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PurchasesTable, List<Purchase>>
  _purchasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.purchases,
    aliasName: 'fuel_sources__id__purchases__fuel_source_id',
  );

  $$PurchasesTableProcessedTableManager get purchasesRefs {
    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.fuelSourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CalendarRemindersTable, List<CalendarReminder>>
  _calendarRemindersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.calendarReminders,
        aliasName: 'fuel_sources__id__calendar_reminders__fuel_source_id',
      );

  $$CalendarRemindersTableProcessedTableManager get calendarRemindersRefs {
    final manager = $$CalendarRemindersTableTableManager(
      $_db,
      $_db.calendarReminders,
    ).filter((f) => f.fuelSourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _calendarRemindersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FuelSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $FuelSourcesTable> {
  $$FuelSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitWeightKg => $composableBuilder(
    column: $table.unitWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tankCapacity => $composableBuilder(
    column: $table.tankCapacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get usableFraction => $composableBuilder(
    column: $table.usableFraction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get warningDays => $composableBuilder(
    column: $table.warningDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costPerUnitCents => $composableBuilder(
    column: $table.costPerUnitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stockMeasurementsRefs(
    Expression<bool> Function($$StockMeasurementsTableFilterComposer f) f,
  ) {
    final $$StockMeasurementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockMeasurements,
      getReferencedColumn: (t) => t.fuelSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockMeasurementsTableFilterComposer(
            $db: $db,
            $table: $db.stockMeasurements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchasesRefs(
    Expression<bool> Function($$PurchasesTableFilterComposer f) f,
  ) {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.fuelSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableFilterComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> calendarRemindersRefs(
    Expression<bool> Function($$CalendarRemindersTableFilterComposer f) f,
  ) {
    final $$CalendarRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarReminders,
      getReferencedColumn: (t) => t.fuelSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarRemindersTableFilterComposer(
            $db: $db,
            $table: $db.calendarReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FuelSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $FuelSourcesTable> {
  $$FuelSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitWeightKg => $composableBuilder(
    column: $table.unitWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tankCapacity => $composableBuilder(
    column: $table.tankCapacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get usableFraction => $composableBuilder(
    column: $table.usableFraction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get warningDays => $composableBuilder(
    column: $table.warningDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costPerUnitCents => $composableBuilder(
    column: $table.costPerUnitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FuelSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FuelSourcesTable> {
  $$FuelSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get unitWeightKg => $composableBuilder(
    column: $table.unitWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get tankCapacity => $composableBuilder(
    column: $table.tankCapacity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get usableFraction => $composableBuilder(
    column: $table.usableFraction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get warningDays => $composableBuilder(
    column: $table.warningDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costPerUnitCents => $composableBuilder(
    column: $table.costPerUnitCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> stockMeasurementsRefs<T extends Object>(
    Expression<T> Function($$StockMeasurementsTableAnnotationComposer a) f,
  ) {
    final $$StockMeasurementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stockMeasurements,
          getReferencedColumn: (t) => t.fuelSourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StockMeasurementsTableAnnotationComposer(
                $db: $db,
                $table: $db.stockMeasurements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> purchasesRefs<T extends Object>(
    Expression<T> Function($$PurchasesTableAnnotationComposer a) f,
  ) {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.fuelSourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableAnnotationComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> calendarRemindersRefs<T extends Object>(
    Expression<T> Function($$CalendarRemindersTableAnnotationComposer a) f,
  ) {
    final $$CalendarRemindersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.calendarReminders,
          getReferencedColumn: (t) => t.fuelSourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CalendarRemindersTableAnnotationComposer(
                $db: $db,
                $table: $db.calendarReminders,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$FuelSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FuelSourcesTable,
          FuelSource,
          $$FuelSourcesTableFilterComposer,
          $$FuelSourcesTableOrderingComposer,
          $$FuelSourcesTableAnnotationComposer,
          $$FuelSourcesTableCreateCompanionBuilder,
          $$FuelSourcesTableUpdateCompanionBuilder,
          (FuelSource, $$FuelSourcesTableReferences),
          FuelSource,
          PrefetchHooks Function({
            bool stockMeasurementsRefs,
            bool purchasesRefs,
            bool calendarRemindersRefs,
          })
        > {
  $$FuelSourcesTableTableManager(_$AppDatabase db, $FuelSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FuelSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FuelSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FuelSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fuelType = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> unitWeightKg = const Value.absent(),
                Value<double?> tankCapacity = const Value.absent(),
                Value<double> usableFraction = const Value.absent(),
                Value<int> warningDays = const Value.absent(),
                Value<int?> costPerUnitCents = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => FuelSourcesCompanion(
                id: id,
                name: name,
                fuelType: fuelType,
                unit: unit,
                unitWeightKg: unitWeightKg,
                tankCapacity: tankCapacity,
                usableFraction: usableFraction,
                warningDays: warningDays,
                costPerUnitCents: costPerUnitCents,
                active: active,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String fuelType,
                required String unit,
                Value<double?> unitWeightKg = const Value.absent(),
                Value<double?> tankCapacity = const Value.absent(),
                required double usableFraction,
                Value<int> warningDays = const Value.absent(),
                Value<int?> costPerUnitCents = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => FuelSourcesCompanion.insert(
                id: id,
                name: name,
                fuelType: fuelType,
                unit: unit,
                unitWeightKg: unitWeightKg,
                tankCapacity: tankCapacity,
                usableFraction: usableFraction,
                warningDays: warningDays,
                costPerUnitCents: costPerUnitCents,
                active: active,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FuelSourcesTable, FuelSource>(table),
                  $$FuelSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                stockMeasurementsRefs = false,
                purchasesRefs = false,
                calendarRemindersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (stockMeasurementsRefs) db.stockMeasurements,
                    if (purchasesRefs) db.purchases,
                    if (calendarRemindersRefs) db.calendarReminders,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (stockMeasurementsRefs)
                        await $_getPrefetchedData<
                          FuelSource,
                          $FuelSourcesTable,
                          StockMeasurement
                        >(
                          currentTable: table,
                          referencedTable: $$FuelSourcesTableReferences
                              ._stockMeasurementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FuelSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).stockMeasurementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fuelSourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (purchasesRefs)
                        await $_getPrefetchedData<
                          FuelSource,
                          $FuelSourcesTable,
                          Purchase
                        >(
                          currentTable: table,
                          referencedTable: $$FuelSourcesTableReferences
                              ._purchasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FuelSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).purchasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fuelSourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (calendarRemindersRefs)
                        await $_getPrefetchedData<
                          FuelSource,
                          $FuelSourcesTable,
                          CalendarReminder
                        >(
                          currentTable: table,
                          referencedTable: $$FuelSourcesTableReferences
                              ._calendarRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FuelSourcesTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fuelSourceId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FuelSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FuelSourcesTable,
      FuelSource,
      $$FuelSourcesTableFilterComposer,
      $$FuelSourcesTableOrderingComposer,
      $$FuelSourcesTableAnnotationComposer,
      $$FuelSourcesTableCreateCompanionBuilder,
      $$FuelSourcesTableUpdateCompanionBuilder,
      (FuelSource, $$FuelSourcesTableReferences),
      FuelSource,
      PrefetchHooks Function({
        bool stockMeasurementsRefs,
        bool purchasesRefs,
        bool calendarRemindersRefs,
      })
    >;
typedef $$StockMeasurementsTableCreateCompanionBuilder =
    StockMeasurementsCompanion Function({
      Value<int> id,
      required int fuelSourceId,
      required String date,
      required double quantity,
      required String enteredAs,
      required double rawInput,
      Value<String?> note,
    });
typedef $$StockMeasurementsTableUpdateCompanionBuilder =
    StockMeasurementsCompanion Function({
      Value<int> id,
      Value<int> fuelSourceId,
      Value<String> date,
      Value<double> quantity,
      Value<String> enteredAs,
      Value<double> rawInput,
      Value<String?> note,
    });

final class $$StockMeasurementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StockMeasurementsTable,
          StockMeasurement
        > {
  $$StockMeasurementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FuelSourcesTable _fuelSourceIdTable(_$AppDatabase db) => db
      .fuelSources
      .createAlias('stock_measurements__fuel_source_id__fuel_sources__id');

  $$FuelSourcesTableProcessedTableManager get fuelSourceId {
    final $_column = $_itemColumn<int>('fuel_source_id')!;

    final manager = $$FuelSourcesTableTableManager(
      $_db,
      $_db.fuelSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fuelSourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockMeasurementsTableFilterComposer
    extends Composer<_$AppDatabase, $StockMeasurementsTable> {
  $$StockMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get enteredAs => $composableBuilder(
    column: $table.enteredAs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$FuelSourcesTableFilterComposer get fuelSourceId {
    final $$FuelSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableFilterComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMeasurementsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockMeasurementsTable> {
  $$StockMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get enteredAs => $composableBuilder(
    column: $table.enteredAs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rawInput => $composableBuilder(
    column: $table.rawInput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$FuelSourcesTableOrderingComposer get fuelSourceId {
    final $$FuelSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMeasurementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockMeasurementsTable> {
  $$StockMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get enteredAs =>
      $composableBuilder(column: $table.enteredAs, builder: (column) => column);

  GeneratedColumn<double> get rawInput =>
      $composableBuilder(column: $table.rawInput, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$FuelSourcesTableAnnotationComposer get fuelSourceId {
    final $$FuelSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockMeasurementsTable,
          StockMeasurement,
          $$StockMeasurementsTableFilterComposer,
          $$StockMeasurementsTableOrderingComposer,
          $$StockMeasurementsTableAnnotationComposer,
          $$StockMeasurementsTableCreateCompanionBuilder,
          $$StockMeasurementsTableUpdateCompanionBuilder,
          (StockMeasurement, $$StockMeasurementsTableReferences),
          StockMeasurement,
          PrefetchHooks Function({bool fuelSourceId})
        > {
  $$StockMeasurementsTableTableManager(
    _$AppDatabase db,
    $StockMeasurementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockMeasurementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fuelSourceId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> enteredAs = const Value.absent(),
                Value<double> rawInput = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => StockMeasurementsCompanion(
                id: id,
                fuelSourceId: fuelSourceId,
                date: date,
                quantity: quantity,
                enteredAs: enteredAs,
                rawInput: rawInput,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fuelSourceId,
                required String date,
                required double quantity,
                required String enteredAs,
                required double rawInput,
                Value<String?> note = const Value.absent(),
              }) => StockMeasurementsCompanion.insert(
                id: id,
                fuelSourceId: fuelSourceId,
                date: date,
                quantity: quantity,
                enteredAs: enteredAs,
                rawInput: rawInput,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockMeasurementsTable, StockMeasurement>(table),
                  $$StockMeasurementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fuelSourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fuelSourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fuelSourceId,
                        referencedTable: $$StockMeasurementsTableReferences
                            ._fuelSourceIdTable(db),
                        referencedColumn: $$StockMeasurementsTableReferences
                            ._fuelSourceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockMeasurementsTable,
      StockMeasurement,
      $$StockMeasurementsTableFilterComposer,
      $$StockMeasurementsTableOrderingComposer,
      $$StockMeasurementsTableAnnotationComposer,
      $$StockMeasurementsTableCreateCompanionBuilder,
      $$StockMeasurementsTableUpdateCompanionBuilder,
      (StockMeasurement, $$StockMeasurementsTableReferences),
      StockMeasurement,
      PrefetchHooks Function({bool fuelSourceId})
    >;
typedef $$PurchasesTableCreateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  required int fuelSourceId,
  required String date,
  required double quantity,
  Value<int?> totalCostCents,
  Value<String?> supplier,
  Value<String?> note,
});
typedef $$PurchasesTableUpdateCompanionBuilder = PurchasesCompanion Function({
  Value<int> id,
  Value<int> fuelSourceId,
  Value<String> date,
  Value<double> quantity,
  Value<int?> totalCostCents,
  Value<String?> supplier,
  Value<String?> note,
});

final class $$PurchasesTableReferences
    extends BaseReferences<_$AppDatabase, $PurchasesTable, Purchase> {
  $$PurchasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FuelSourcesTable _fuelSourceIdTable(_$AppDatabase db) =>
      db.fuelSources.createAlias('purchases__fuel_source_id__fuel_sources__id');

  $$FuelSourcesTableProcessedTableManager get fuelSourceId {
    final $_column = $_itemColumn<int>('fuel_source_id')!;

    final manager = $$FuelSourcesTableTableManager(
      $_db,
      $_db.fuelSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fuelSourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCostCents => $composableBuilder(
    column: $table.totalCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$FuelSourcesTableFilterComposer get fuelSourceId {
    final $$FuelSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableFilterComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCostCents => $composableBuilder(
    column: $table.totalCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supplier => $composableBuilder(
    column: $table.supplier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$FuelSourcesTableOrderingComposer get fuelSourceId {
    final $$FuelSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get totalCostCents => $composableBuilder(
    column: $table.totalCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supplier =>
      $composableBuilder(column: $table.supplier, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$FuelSourcesTableAnnotationComposer get fuelSourceId {
    final $$FuelSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchasesTable,
          Purchase,
          $$PurchasesTableFilterComposer,
          $$PurchasesTableOrderingComposer,
          $$PurchasesTableAnnotationComposer,
          $$PurchasesTableCreateCompanionBuilder,
          $$PurchasesTableUpdateCompanionBuilder,
          (Purchase, $$PurchasesTableReferences),
          Purchase,
          PrefetchHooks Function({bool fuelSourceId})
        > {
  $$PurchasesTableTableManager(_$AppDatabase db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fuelSourceId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<int?> totalCostCents = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                fuelSourceId: fuelSourceId,
                date: date,
                quantity: quantity,
                totalCostCents: totalCostCents,
                supplier: supplier,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fuelSourceId,
                required String date,
                required double quantity,
                Value<int?> totalCostCents = const Value.absent(),
                Value<String?> supplier = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                fuelSourceId: fuelSourceId,
                date: date,
                quantity: quantity,
                totalCostCents: totalCostCents,
                supplier: supplier,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PurchasesTable, Purchase>(table),
                  $$PurchasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fuelSourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fuelSourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fuelSourceId,
                        referencedTable: $$PurchasesTableReferences
                            ._fuelSourceIdTable(db),
                        referencedColumn: $$PurchasesTableReferences
                            ._fuelSourceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchasesTable,
      Purchase,
      $$PurchasesTableFilterComposer,
      $$PurchasesTableOrderingComposer,
      $$PurchasesTableAnnotationComposer,
      $$PurchasesTableCreateCompanionBuilder,
      $$PurchasesTableUpdateCompanionBuilder,
      (Purchase, $$PurchasesTableReferences),
      Purchase,
      PrefetchHooks Function({bool fuelSourceId})
    >;
typedef $$CalendarRemindersTableCreateCompanionBuilder =
    CalendarRemindersCompanion Function({
      Value<int> id,
      required int fuelSourceId,
      required String calendarId,
      required String externalEventId,
      required String calculatedDate,
      required int createdAt,
      required int lastSyncedAt,
    });
typedef $$CalendarRemindersTableUpdateCompanionBuilder =
    CalendarRemindersCompanion Function({
      Value<int> id,
      Value<int> fuelSourceId,
      Value<String> calendarId,
      Value<String> externalEventId,
      Value<String> calculatedDate,
      Value<int> createdAt,
      Value<int> lastSyncedAt,
    });

final class $$CalendarRemindersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CalendarRemindersTable,
          CalendarReminder
        > {
  $$CalendarRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FuelSourcesTable _fuelSourceIdTable(_$AppDatabase db) => db
      .fuelSources
      .createAlias('calendar_reminders__fuel_source_id__fuel_sources__id');

  $$FuelSourcesTableProcessedTableManager get fuelSourceId {
    final $_column = $_itemColumn<int>('fuel_source_id')!;

    final manager = $$FuelSourcesTableTableManager(
      $_db,
      $_db.fuelSources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fuelSourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarRemindersTable> {
  $$CalendarRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalEventId => $composableBuilder(
    column: $table.externalEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get calculatedDate => $composableBuilder(
    column: $table.calculatedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FuelSourcesTableFilterComposer get fuelSourceId {
    final $$FuelSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableFilterComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarRemindersTable> {
  $$CalendarRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalEventId => $composableBuilder(
    column: $table.externalEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get calculatedDate => $composableBuilder(
    column: $table.calculatedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FuelSourcesTableOrderingComposer get fuelSourceId {
    final $$FuelSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarRemindersTable> {
  $$CalendarRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get calendarId => $composableBuilder(
    column: $table.calendarId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalEventId => $composableBuilder(
    column: $table.externalEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get calculatedDate => $composableBuilder(
    column: $table.calculatedDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  $$FuelSourcesTableAnnotationComposer get fuelSourceId {
    final $$FuelSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fuelSourceId,
      referencedTable: $db.fuelSources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FuelSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.fuelSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarRemindersTable,
          CalendarReminder,
          $$CalendarRemindersTableFilterComposer,
          $$CalendarRemindersTableOrderingComposer,
          $$CalendarRemindersTableAnnotationComposer,
          $$CalendarRemindersTableCreateCompanionBuilder,
          $$CalendarRemindersTableUpdateCompanionBuilder,
          (CalendarReminder, $$CalendarRemindersTableReferences),
          CalendarReminder,
          PrefetchHooks Function({bool fuelSourceId})
        > {
  $$CalendarRemindersTableTableManager(
    _$AppDatabase db,
    $CalendarRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarRemindersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fuelSourceId = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<String> externalEventId = const Value.absent(),
                Value<String> calculatedDate = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastSyncedAt = const Value.absent(),
              }) => CalendarRemindersCompanion(
                id: id,
                fuelSourceId: fuelSourceId,
                calendarId: calendarId,
                externalEventId: externalEventId,
                calculatedDate: calculatedDate,
                createdAt: createdAt,
                lastSyncedAt: lastSyncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fuelSourceId,
                required String calendarId,
                required String externalEventId,
                required String calculatedDate,
                required int createdAt,
                required int lastSyncedAt,
              }) => CalendarRemindersCompanion.insert(
                id: id,
                fuelSourceId: fuelSourceId,
                calendarId: calendarId,
                externalEventId: externalEventId,
                calculatedDate: calculatedDate,
                createdAt: createdAt,
                lastSyncedAt: lastSyncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarRemindersTable, CalendarReminder>(table),
                  $$CalendarRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fuelSourceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fuelSourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fuelSourceId,
                        referencedTable: $$CalendarRemindersTableReferences
                            ._fuelSourceIdTable(db),
                        referencedColumn: $$CalendarRemindersTableReferences
                            ._fuelSourceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CalendarRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarRemindersTable,
      CalendarReminder,
      $$CalendarRemindersTableFilterComposer,
      $$CalendarRemindersTableOrderingComposer,
      $$CalendarRemindersTableAnnotationComposer,
      $$CalendarRemindersTableCreateCompanionBuilder,
      $$CalendarRemindersTableUpdateCompanionBuilder,
      (CalendarReminder, $$CalendarRemindersTableReferences),
      CalendarReminder,
      PrefetchHooks Function({bool fuelSourceId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FuelSourcesTableTableManager get fuelSources =>
      $$FuelSourcesTableTableManager(_db, _db.fuelSources);
  $$StockMeasurementsTableTableManager get stockMeasurements =>
      $$StockMeasurementsTableTableManager(_db, _db.stockMeasurements);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db, _db.purchases);
  $$CalendarRemindersTableTableManager get calendarReminders =>
      $$CalendarRemindersTableTableManager(_db, _db.calendarReminders);
}
