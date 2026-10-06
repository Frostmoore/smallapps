// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FreezersTable extends Freezers with TableInfo<$FreezersTable, Freezer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FreezersTable(this.attachedDatabase, [this._alias]);
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
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelKeyMeta = const VerificationMeta(
    'modelKey',
  );
  @override
  late final GeneratedColumn<String> modelKey = GeneratedColumn<String>(
    'model_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capacityLitersMeta = const VerificationMeta(
    'capacityLiters',
  );
  @override
  late final GeneratedColumn<double> capacityLiters = GeneratedColumn<double>(
    'capacity_liters',
    aliasedName,
    false,
    check: () => ComparableExpr(capacityLiters).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _calibrationMeta = const VerificationMeta(
    'calibration',
  );
  @override
  late final GeneratedColumn<double> calibration = GeneratedColumn<double>(
    'calibration',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _lastAlertLevelMeta = const VerificationMeta(
    'lastAlertLevel',
  );
  @override
  late final GeneratedColumn<String> lastAlertLevel = GeneratedColumn<String>(
    'last_alert_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('empty'),
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
    modelKey,
    capacityLiters,
    calibration,
    lastAlertLevel,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'freezers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Freezer> instance, {
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
    if (data.containsKey('model_key')) {
      context.handle(
        _modelKeyMeta,
        modelKey.isAcceptableOrUnknown(data['model_key']!, _modelKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_modelKeyMeta);
    }
    if (data.containsKey('capacity_liters')) {
      context.handle(
        _capacityLitersMeta,
        capacityLiters.isAcceptableOrUnknown(
          data['capacity_liters']!,
          _capacityLitersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capacityLitersMeta);
    }
    if (data.containsKey('calibration')) {
      context.handle(
        _calibrationMeta,
        calibration.isAcceptableOrUnknown(
          data['calibration']!,
          _calibrationMeta,
        ),
      );
    }
    if (data.containsKey('last_alert_level')) {
      context.handle(
        _lastAlertLevelMeta,
        lastAlertLevel.isAcceptableOrUnknown(
          data['last_alert_level']!,
          _lastAlertLevelMeta,
        ),
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
  Freezer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Freezer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      modelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_key'],
      )!,
      capacityLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}capacity_liters'],
      )!,
      calibration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calibration'],
      )!,
      lastAlertLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_alert_level'],
      ),
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
  $FreezersTable createAlias(String alias) {
    return $FreezersTable(attachedDatabase, alias);
  }
}

class Freezer extends DataClass implements Insertable<Freezer> {
  final int id;
  final String name;

  /// Chiave in `FreezerModels` (F4.3b), oppure `custom` se i litri li ha scritti l'utente.
  final String modelKey;

  /// Litri **nominali** del vano congelatore. La capienza utile la calcola
  /// `CapacityEstimator` (80%).
  final double capacityLiters;

  /// Taratura da "quanto e' pieno davvero?" (F4.3b). 1.0 = la stima cosi' com'e'.
  final double calibration;

  /// L'ultimo avviso di capienza mandato: `full`, `empty` o null (F4.9, isteresi).
  ///
  /// ⚑ Parte da `empty` e non da null: un freezer appena creato e' vuoto, e non deve mai
  /// ricevere un "quasi vuoto" (develop_microapps.md F4.9).
  final String? lastAlertLevel;
  final int sortOrder;
  final int createdAt;
  const Freezer({
    required this.id,
    required this.name,
    required this.modelKey,
    required this.capacityLiters,
    required this.calibration,
    this.lastAlertLevel,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['model_key'] = Variable<String>(modelKey);
    map['capacity_liters'] = Variable<double>(capacityLiters);
    map['calibration'] = Variable<double>(calibration);
    if (!nullToAbsent || lastAlertLevel != null) {
      map['last_alert_level'] = Variable<String>(lastAlertLevel);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FreezersCompanion toCompanion(bool nullToAbsent) {
    return FreezersCompanion(
      id: Value(id),
      name: Value(name),
      modelKey: Value(modelKey),
      capacityLiters: Value(capacityLiters),
      calibration: Value(calibration),
      lastAlertLevel: lastAlertLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAlertLevel),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Freezer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Freezer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      modelKey: serializer.fromJson<String>(json['modelKey']),
      capacityLiters: serializer.fromJson<double>(json['capacityLiters']),
      calibration: serializer.fromJson<double>(json['calibration']),
      lastAlertLevel: serializer.fromJson<String?>(json['lastAlertLevel']),
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
      'modelKey': serializer.toJson<String>(modelKey),
      'capacityLiters': serializer.toJson<double>(capacityLiters),
      'calibration': serializer.toJson<double>(calibration),
      'lastAlertLevel': serializer.toJson<String?>(lastAlertLevel),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Freezer copyWith({
    int? id,
    String? name,
    String? modelKey,
    double? capacityLiters,
    double? calibration,
    Value<String?> lastAlertLevel = const Value.absent(),
    int? sortOrder,
    int? createdAt,
  }) => Freezer(
    id: id ?? this.id,
    name: name ?? this.name,
    modelKey: modelKey ?? this.modelKey,
    capacityLiters: capacityLiters ?? this.capacityLiters,
    calibration: calibration ?? this.calibration,
    lastAlertLevel: lastAlertLevel.present
        ? lastAlertLevel.value
        : this.lastAlertLevel,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Freezer copyWithCompanion(FreezersCompanion data) {
    return Freezer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      modelKey: data.modelKey.present ? data.modelKey.value : this.modelKey,
      capacityLiters: data.capacityLiters.present
          ? data.capacityLiters.value
          : this.capacityLiters,
      calibration: data.calibration.present
          ? data.calibration.value
          : this.calibration,
      lastAlertLevel: data.lastAlertLevel.present
          ? data.lastAlertLevel.value
          : this.lastAlertLevel,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Freezer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('modelKey: $modelKey, ')
          ..write('capacityLiters: $capacityLiters, ')
          ..write('calibration: $calibration, ')
          ..write('lastAlertLevel: $lastAlertLevel, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    modelKey,
    capacityLiters,
    calibration,
    lastAlertLevel,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Freezer &&
          other.id == this.id &&
          other.name == this.name &&
          other.modelKey == this.modelKey &&
          other.capacityLiters == this.capacityLiters &&
          other.calibration == this.calibration &&
          other.lastAlertLevel == this.lastAlertLevel &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FreezersCompanion extends UpdateCompanion<Freezer> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> modelKey;
  final Value<double> capacityLiters;
  final Value<double> calibration;
  final Value<String?> lastAlertLevel;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const FreezersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.modelKey = const Value.absent(),
    this.capacityLiters = const Value.absent(),
    this.calibration = const Value.absent(),
    this.lastAlertLevel = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FreezersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String modelKey,
    required double capacityLiters,
    this.calibration = const Value.absent(),
    this.lastAlertLevel = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       modelKey = Value(modelKey),
       capacityLiters = Value(capacityLiters),
       createdAt = Value(createdAt);
  static Insertable<Freezer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? modelKey,
    Expression<double>? capacityLiters,
    Expression<double>? calibration,
    Expression<String>? lastAlertLevel,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (modelKey != null) 'model_key': modelKey,
      if (capacityLiters != null) 'capacity_liters': capacityLiters,
      if (calibration != null) 'calibration': calibration,
      if (lastAlertLevel != null) 'last_alert_level': lastAlertLevel,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FreezersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? modelKey,
    Value<double>? capacityLiters,
    Value<double>? calibration,
    Value<String?>? lastAlertLevel,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return FreezersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      modelKey: modelKey ?? this.modelKey,
      capacityLiters: capacityLiters ?? this.capacityLiters,
      calibration: calibration ?? this.calibration,
      lastAlertLevel: lastAlertLevel ?? this.lastAlertLevel,
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
    if (modelKey.present) {
      map['model_key'] = Variable<String>(modelKey.value);
    }
    if (capacityLiters.present) {
      map['capacity_liters'] = Variable<double>(capacityLiters.value);
    }
    if (calibration.present) {
      map['calibration'] = Variable<double>(calibration.value);
    }
    if (lastAlertLevel.present) {
      map['last_alert_level'] = Variable<String>(lastAlertLevel.value);
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
    return (StringBuffer('FreezersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('modelKey: $modelKey, ')
          ..write('capacityLiters: $capacityLiters, ')
          ..write('calibration: $calibration, ')
          ..write('lastAlertLevel: $lastAlertLevel, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CompartmentsTable extends Compartments
    with TableInfo<$CompartmentsTable, Compartment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompartmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _freezerIdMeta = const VerificationMeta(
    'freezerId',
  );
  @override
  late final GeneratedColumn<int> freezerId = GeneratedColumn<int>(
    'freezer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES freezers (id) ON DELETE CASCADE',
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
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [id, freezerId, name, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'compartments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Compartment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('freezer_id')) {
      context.handle(
        _freezerIdMeta,
        freezerId.isAcceptableOrUnknown(data['freezer_id']!, _freezerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_freezerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Compartment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Compartment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      freezerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freezer_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CompartmentsTable createAlias(String alias) {
    return $CompartmentsTable(attachedDatabase, alias);
  }
}

class Compartment extends DataClass implements Insertable<Compartment> {
  final int id;
  final int freezerId;
  final String name;
  final int sortOrder;
  const Compartment({
    required this.id,
    required this.freezerId,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['freezer_id'] = Variable<int>(freezerId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CompartmentsCompanion toCompanion(bool nullToAbsent) {
    return CompartmentsCompanion(
      id: Value(id),
      freezerId: Value(freezerId),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory Compartment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Compartment(
      id: serializer.fromJson<int>(json['id']),
      freezerId: serializer.fromJson<int>(json['freezerId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'freezerId': serializer.toJson<int>(freezerId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Compartment copyWith({
    int? id,
    int? freezerId,
    String? name,
    int? sortOrder,
  }) => Compartment(
    id: id ?? this.id,
    freezerId: freezerId ?? this.freezerId,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Compartment copyWithCompanion(CompartmentsCompanion data) {
    return Compartment(
      id: data.id.present ? data.id.value : this.id,
      freezerId: data.freezerId.present ? data.freezerId.value : this.freezerId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Compartment(')
          ..write('id: $id, ')
          ..write('freezerId: $freezerId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, freezerId, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Compartment &&
          other.id == this.id &&
          other.freezerId == this.freezerId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class CompartmentsCompanion extends UpdateCompanion<Compartment> {
  final Value<int> id;
  final Value<int> freezerId;
  final Value<String> name;
  final Value<int> sortOrder;
  const CompartmentsCompanion({
    this.id = const Value.absent(),
    this.freezerId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CompartmentsCompanion.insert({
    this.id = const Value.absent(),
    required int freezerId,
    required String name,
    this.sortOrder = const Value.absent(),
  }) : freezerId = Value(freezerId),
       name = Value(name);
  static Insertable<Compartment> custom({
    Expression<int>? id,
    Expression<int>? freezerId,
    Expression<String>? name,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (freezerId != null) 'freezer_id': freezerId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CompartmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? freezerId,
    Value<String>? name,
    Value<int>? sortOrder,
  }) {
    return CompartmentsCompanion(
      id: id ?? this.id,
      freezerId: freezerId ?? this.freezerId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (freezerId.present) {
      map['freezer_id'] = Variable<int>(freezerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompartmentsCompanion(')
          ..write('id: $id, ')
          ..write('freezerId: $freezerId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _freezerIdMeta = const VerificationMeta(
    'freezerId',
  );
  @override
  late final GeneratedColumn<int> freezerId = GeneratedColumn<int>(
    'freezer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES freezers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _compartmentIdMeta = const VerificationMeta(
    'compartmentId',
  );
  @override
  late final GeneratedColumn<int> compartmentId = GeneratedColumn<int>(
    'compartment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES compartments (id) ON DELETE SET NULL',
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
  static const VerificationMeta _nameNormMeta = const VerificationMeta(
    'nameNorm',
  );
  @override
  late final GeneratedColumn<String> nameNorm = GeneratedColumn<String>(
    'name_norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frozenAtMeta = const VerificationMeta(
    'frozenAt',
  );
  @override
  late final GeneratedColumn<String> frozenAt = GeneratedColumn<String>(
    'frozen_at',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderAfterDaysMeta = const VerificationMeta(
    'reminderAfterDays',
  );
  @override
  late final GeneratedColumn<int> reminderAfterDays = GeneratedColumn<int>(
    'reminder_after_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _volumeLitersMeta = const VerificationMeta(
    'volumeLiters',
  );
  @override
  late final GeneratedColumn<double> volumeLiters = GeneratedColumn<double>(
    'volume_liters',
    aliasedName,
    false,
    check: () => ComparableExpr(volumeLiters).isBiggerThanValue(0),
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeManualMeta = const VerificationMeta(
    'volumeManual',
  );
  @override
  late final GeneratedColumn<bool> volumeManual = GeneratedColumn<bool>(
    'volume_manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("volume_manual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(const [
      ItemStatus.stored,
      ItemStatus.consumed,
      ItemStatus.discarded,
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(ItemStatus.stored),
  );
  static const VerificationMeta _removedAtMeta = const VerificationMeta(
    'removedAt',
  );
  @override
  late final GeneratedColumn<int> removedAt = GeneratedColumn<int>(
    'removed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    freezerId,
    compartmentId,
    name,
    nameNorm,
    category,
    quantity,
    unit,
    frozenAt,
    reminderAfterDays,
    volumeLiters,
    volumeManual,
    photoPath,
    note,
    status,
    removedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('freezer_id')) {
      context.handle(
        _freezerIdMeta,
        freezerId.isAcceptableOrUnknown(data['freezer_id']!, _freezerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_freezerIdMeta);
    }
    if (data.containsKey('compartment_id')) {
      context.handle(
        _compartmentIdMeta,
        compartmentId.isAcceptableOrUnknown(
          data['compartment_id']!,
          _compartmentIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_norm')) {
      context.handle(
        _nameNormMeta,
        nameNorm.isAcceptableOrUnknown(data['name_norm']!, _nameNormMeta),
      );
    } else if (isInserting) {
      context.missing(_nameNormMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('frozen_at')) {
      context.handle(
        _frozenAtMeta,
        frozenAt.isAcceptableOrUnknown(data['frozen_at']!, _frozenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_frozenAtMeta);
    }
    if (data.containsKey('reminder_after_days')) {
      context.handle(
        _reminderAfterDaysMeta,
        reminderAfterDays.isAcceptableOrUnknown(
          data['reminder_after_days']!,
          _reminderAfterDaysMeta,
        ),
      );
    }
    if (data.containsKey('volume_liters')) {
      context.handle(
        _volumeLitersMeta,
        volumeLiters.isAcceptableOrUnknown(
          data['volume_liters']!,
          _volumeLitersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_volumeLitersMeta);
    }
    if (data.containsKey('volume_manual')) {
      context.handle(
        _volumeManualMeta,
        volumeManual.isAcceptableOrUnknown(
          data['volume_manual']!,
          _volumeManualMeta,
        ),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('removed_at')) {
      context.handle(
        _removedAtMeta,
        removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta),
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
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      freezerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}freezer_id'],
      )!,
      compartmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}compartment_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_norm'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      frozenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frozen_at'],
      )!,
      reminderAfterDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_after_days'],
      ),
      volumeLiters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}volume_liters'],
      )!,
      volumeManual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}volume_manual'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      removedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final int id;

  /// ⚑ **Ridondante rispetto a `compartmentId`, e voluto** (F4.2): un alimento puo' stare in
  /// un freezer senza scomparti. Ricavarlo con una join costringerebbe a uno scomparto
  /// fittizio "Nessuno". La coerenza la garantisce `FreezerRepository`, che quando c'e' uno
  /// scomparto ne copia il freezer.
  final int freezerId;

  /// Cancellare uno scomparto non cancella gli alimenti: restano nel freezer, senza scomparto.
  final int? compartmentId;
  final String name;

  /// `name` normalizzato da `normalizeName` (minuscolo, senza accenti): la ricerca e
  /// l'autocompletamento lavorano su questa colonna (F4.8).
  final String nameNorm;

  /// Chiave in `ItemCategories`, o di una categoria personalizzata (`custom:<id>`).
  final String? category;
  final double quantity;

  /// Chiave in `Units`.
  final String unit;

  /// Data di congelamento, `YYYY-MM-DD` (ADR-008).
  final String frozenAt;

  /// Promemoria personalizzato in giorni; null = quello della categoria.
  final int? reminderAfterDays;

  /// Ingombro **dell'intera riga** (quantita' compresa), in litri (F4.3b).
  final double volumeLiters;

  /// True se l'utente ha corretto l'ingombro: da li' la stima non lo tocca piu'.
  final bool volumeManual;

  /// Percorso **relativo** della foto (F1.11): i percorsi assoluti cambiano fra un
  /// ripristino e l'altro, e su iOS a ogni aggiornamento dell'app.
  final String? photoPath;
  final String? note;

  /// `stored` | `consumed` | `discarded`. Gli alimenti usciti **non si cancellano**: servono
  /// allo storico e alle statistiche Pro (F4.7).
  final String status;

  /// Istante dell'uscita, ms UTC. Null finche' l'alimento e' nel freezer.
  final int? removedAt;
  final int createdAt;
  const Item({
    required this.id,
    required this.freezerId,
    this.compartmentId,
    required this.name,
    required this.nameNorm,
    this.category,
    required this.quantity,
    required this.unit,
    required this.frozenAt,
    this.reminderAfterDays,
    required this.volumeLiters,
    required this.volumeManual,
    this.photoPath,
    this.note,
    required this.status,
    this.removedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['freezer_id'] = Variable<int>(freezerId);
    if (!nullToAbsent || compartmentId != null) {
      map['compartment_id'] = Variable<int>(compartmentId);
    }
    map['name'] = Variable<String>(name);
    map['name_norm'] = Variable<String>(nameNorm);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<String>(unit);
    map['frozen_at'] = Variable<String>(frozenAt);
    if (!nullToAbsent || reminderAfterDays != null) {
      map['reminder_after_days'] = Variable<int>(reminderAfterDays);
    }
    map['volume_liters'] = Variable<double>(volumeLiters);
    map['volume_manual'] = Variable<bool>(volumeManual);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<int>(removedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      freezerId: Value(freezerId),
      compartmentId: compartmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(compartmentId),
      name: Value(name),
      nameNorm: Value(nameNorm),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      quantity: Value(quantity),
      unit: Value(unit),
      frozenAt: Value(frozenAt),
      reminderAfterDays: reminderAfterDays == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAfterDays),
      volumeLiters: Value(volumeLiters),
      volumeManual: Value(volumeManual),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      removedAt: removedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<int>(json['id']),
      freezerId: serializer.fromJson<int>(json['freezerId']),
      compartmentId: serializer.fromJson<int?>(json['compartmentId']),
      name: serializer.fromJson<String>(json['name']),
      nameNorm: serializer.fromJson<String>(json['nameNorm']),
      category: serializer.fromJson<String?>(json['category']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      frozenAt: serializer.fromJson<String>(json['frozenAt']),
      reminderAfterDays: serializer.fromJson<int?>(json['reminderAfterDays']),
      volumeLiters: serializer.fromJson<double>(json['volumeLiters']),
      volumeManual: serializer.fromJson<bool>(json['volumeManual']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      removedAt: serializer.fromJson<int?>(json['removedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'freezerId': serializer.toJson<int>(freezerId),
      'compartmentId': serializer.toJson<int?>(compartmentId),
      'name': serializer.toJson<String>(name),
      'nameNorm': serializer.toJson<String>(nameNorm),
      'category': serializer.toJson<String?>(category),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<String>(unit),
      'frozenAt': serializer.toJson<String>(frozenAt),
      'reminderAfterDays': serializer.toJson<int?>(reminderAfterDays),
      'volumeLiters': serializer.toJson<double>(volumeLiters),
      'volumeManual': serializer.toJson<bool>(volumeManual),
      'photoPath': serializer.toJson<String?>(photoPath),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'removedAt': serializer.toJson<int?>(removedAt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  Item copyWith({
    int? id,
    int? freezerId,
    Value<int?> compartmentId = const Value.absent(),
    String? name,
    String? nameNorm,
    Value<String?> category = const Value.absent(),
    double? quantity,
    String? unit,
    String? frozenAt,
    Value<int?> reminderAfterDays = const Value.absent(),
    double? volumeLiters,
    bool? volumeManual,
    Value<String?> photoPath = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? status,
    Value<int?> removedAt = const Value.absent(),
    int? createdAt,
  }) => Item(
    id: id ?? this.id,
    freezerId: freezerId ?? this.freezerId,
    compartmentId: compartmentId.present
        ? compartmentId.value
        : this.compartmentId,
    name: name ?? this.name,
    nameNorm: nameNorm ?? this.nameNorm,
    category: category.present ? category.value : this.category,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    frozenAt: frozenAt ?? this.frozenAt,
    reminderAfterDays: reminderAfterDays.present
        ? reminderAfterDays.value
        : this.reminderAfterDays,
    volumeLiters: volumeLiters ?? this.volumeLiters,
    volumeManual: volumeManual ?? this.volumeManual,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    note: note.present ? note.value : this.note,
    status: status ?? this.status,
    removedAt: removedAt.present ? removedAt.value : this.removedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      freezerId: data.freezerId.present ? data.freezerId.value : this.freezerId,
      compartmentId: data.compartmentId.present
          ? data.compartmentId.value
          : this.compartmentId,
      name: data.name.present ? data.name.value : this.name,
      nameNorm: data.nameNorm.present ? data.nameNorm.value : this.nameNorm,
      category: data.category.present ? data.category.value : this.category,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      frozenAt: data.frozenAt.present ? data.frozenAt.value : this.frozenAt,
      reminderAfterDays: data.reminderAfterDays.present
          ? data.reminderAfterDays.value
          : this.reminderAfterDays,
      volumeLiters: data.volumeLiters.present
          ? data.volumeLiters.value
          : this.volumeLiters,
      volumeManual: data.volumeManual.present
          ? data.volumeManual.value
          : this.volumeManual,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('freezerId: $freezerId, ')
          ..write('compartmentId: $compartmentId, ')
          ..write('name: $name, ')
          ..write('nameNorm: $nameNorm, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('frozenAt: $frozenAt, ')
          ..write('reminderAfterDays: $reminderAfterDays, ')
          ..write('volumeLiters: $volumeLiters, ')
          ..write('volumeManual: $volumeManual, ')
          ..write('photoPath: $photoPath, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('removedAt: $removedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    freezerId,
    compartmentId,
    name,
    nameNorm,
    category,
    quantity,
    unit,
    frozenAt,
    reminderAfterDays,
    volumeLiters,
    volumeManual,
    photoPath,
    note,
    status,
    removedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.freezerId == this.freezerId &&
          other.compartmentId == this.compartmentId &&
          other.name == this.name &&
          other.nameNorm == this.nameNorm &&
          other.category == this.category &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.frozenAt == this.frozenAt &&
          other.reminderAfterDays == this.reminderAfterDays &&
          other.volumeLiters == this.volumeLiters &&
          other.volumeManual == this.volumeManual &&
          other.photoPath == this.photoPath &&
          other.note == this.note &&
          other.status == this.status &&
          other.removedAt == this.removedAt &&
          other.createdAt == this.createdAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> id;
  final Value<int> freezerId;
  final Value<int?> compartmentId;
  final Value<String> name;
  final Value<String> nameNorm;
  final Value<String?> category;
  final Value<double> quantity;
  final Value<String> unit;
  final Value<String> frozenAt;
  final Value<int?> reminderAfterDays;
  final Value<double> volumeLiters;
  final Value<bool> volumeManual;
  final Value<String?> photoPath;
  final Value<String?> note;
  final Value<String> status;
  final Value<int?> removedAt;
  final Value<int> createdAt;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.freezerId = const Value.absent(),
    this.compartmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.nameNorm = const Value.absent(),
    this.category = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.frozenAt = const Value.absent(),
    this.reminderAfterDays = const Value.absent(),
    this.volumeLiters = const Value.absent(),
    this.volumeManual = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    required int freezerId,
    this.compartmentId = const Value.absent(),
    required String name,
    required String nameNorm,
    this.category = const Value.absent(),
    required double quantity,
    required String unit,
    required String frozenAt,
    this.reminderAfterDays = const Value.absent(),
    required double volumeLiters,
    this.volumeManual = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.removedAt = const Value.absent(),
    required int createdAt,
  }) : freezerId = Value(freezerId),
       name = Value(name),
       nameNorm = Value(nameNorm),
       quantity = Value(quantity),
       unit = Value(unit),
       frozenAt = Value(frozenAt),
       volumeLiters = Value(volumeLiters),
       createdAt = Value(createdAt);
  static Insertable<Item> custom({
    Expression<int>? id,
    Expression<int>? freezerId,
    Expression<int>? compartmentId,
    Expression<String>? name,
    Expression<String>? nameNorm,
    Expression<String>? category,
    Expression<double>? quantity,
    Expression<String>? unit,
    Expression<String>? frozenAt,
    Expression<int>? reminderAfterDays,
    Expression<double>? volumeLiters,
    Expression<bool>? volumeManual,
    Expression<String>? photoPath,
    Expression<String>? note,
    Expression<String>? status,
    Expression<int>? removedAt,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (freezerId != null) 'freezer_id': freezerId,
      if (compartmentId != null) 'compartment_id': compartmentId,
      if (name != null) 'name': name,
      if (nameNorm != null) 'name_norm': nameNorm,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (frozenAt != null) 'frozen_at': frozenAt,
      if (reminderAfterDays != null) 'reminder_after_days': reminderAfterDays,
      if (volumeLiters != null) 'volume_liters': volumeLiters,
      if (volumeManual != null) 'volume_manual': volumeManual,
      if (photoPath != null) 'photo_path': photoPath,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (removedAt != null) 'removed_at': removedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? freezerId,
    Value<int?>? compartmentId,
    Value<String>? name,
    Value<String>? nameNorm,
    Value<String?>? category,
    Value<double>? quantity,
    Value<String>? unit,
    Value<String>? frozenAt,
    Value<int?>? reminderAfterDays,
    Value<double>? volumeLiters,
    Value<bool>? volumeManual,
    Value<String?>? photoPath,
    Value<String?>? note,
    Value<String>? status,
    Value<int?>? removedAt,
    Value<int>? createdAt,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      freezerId: freezerId ?? this.freezerId,
      compartmentId: compartmentId ?? this.compartmentId,
      name: name ?? this.name,
      nameNorm: nameNorm ?? this.nameNorm,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      frozenAt: frozenAt ?? this.frozenAt,
      reminderAfterDays: reminderAfterDays ?? this.reminderAfterDays,
      volumeLiters: volumeLiters ?? this.volumeLiters,
      volumeManual: volumeManual ?? this.volumeManual,
      photoPath: photoPath ?? this.photoPath,
      note: note ?? this.note,
      status: status ?? this.status,
      removedAt: removedAt ?? this.removedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (freezerId.present) {
      map['freezer_id'] = Variable<int>(freezerId.value);
    }
    if (compartmentId.present) {
      map['compartment_id'] = Variable<int>(compartmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameNorm.present) {
      map['name_norm'] = Variable<String>(nameNorm.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (frozenAt.present) {
      map['frozen_at'] = Variable<String>(frozenAt.value);
    }
    if (reminderAfterDays.present) {
      map['reminder_after_days'] = Variable<int>(reminderAfterDays.value);
    }
    if (volumeLiters.present) {
      map['volume_liters'] = Variable<double>(volumeLiters.value);
    }
    if (volumeManual.present) {
      map['volume_manual'] = Variable<bool>(volumeManual.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<int>(removedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('freezerId: $freezerId, ')
          ..write('compartmentId: $compartmentId, ')
          ..write('name: $name, ')
          ..write('nameNorm: $nameNorm, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('frozenAt: $frozenAt, ')
          ..write('reminderAfterDays: $reminderAfterDays, ')
          ..write('volumeLiters: $volumeLiters, ')
          ..write('volumeManual: $volumeManual, ')
          ..write('photoPath: $photoPath, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('removedAt: $removedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ItemMovementsTable extends ItemMovements
    with TableInfo<$ItemMovementsTable, ItemMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemMovementsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 16,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromCompartmentIdMeta = const VerificationMeta(
    'fromCompartmentId',
  );
  @override
  late final GeneratedColumn<int> fromCompartmentId = GeneratedColumn<int>(
    'from_compartment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toCompartmentIdMeta = const VerificationMeta(
    'toCompartmentId',
  );
  @override
  late final GeneratedColumn<int> toCompartmentId = GeneratedColumn<int>(
    'to_compartment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    kind,
    at,
    fromCompartmentId,
    toCompartmentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('from_compartment_id')) {
      context.handle(
        _fromCompartmentIdMeta,
        fromCompartmentId.isAcceptableOrUnknown(
          data['from_compartment_id']!,
          _fromCompartmentIdMeta,
        ),
      );
    }
    if (data.containsKey('to_compartment_id')) {
      context.handle(
        _toCompartmentIdMeta,
        toCompartmentId.isAcceptableOrUnknown(
          data['to_compartment_id']!,
          _toCompartmentIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ItemMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemMovement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
      fromCompartmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_compartment_id'],
      ),
      toCompartmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_compartment_id'],
      ),
    );
  }

  @override
  $ItemMovementsTable createAlias(String alias) {
    return $ItemMovementsTable(attachedDatabase, alias);
  }
}

class ItemMovement extends DataClass implements Insertable<ItemMovement> {
  final int id;
  final int itemId;

  /// `stored` | `consumed` | `discarded` | `moved` | `restored` (uscita annullata).
  final String kind;
  final int at;
  final int? fromCompartmentId;
  final int? toCompartmentId;
  const ItemMovement({
    required this.id,
    required this.itemId,
    required this.kind,
    required this.at,
    this.fromCompartmentId,
    this.toCompartmentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<int>(itemId);
    map['kind'] = Variable<String>(kind);
    map['at'] = Variable<int>(at);
    if (!nullToAbsent || fromCompartmentId != null) {
      map['from_compartment_id'] = Variable<int>(fromCompartmentId);
    }
    if (!nullToAbsent || toCompartmentId != null) {
      map['to_compartment_id'] = Variable<int>(toCompartmentId);
    }
    return map;
  }

  ItemMovementsCompanion toCompanion(bool nullToAbsent) {
    return ItemMovementsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      kind: Value(kind),
      at: Value(at),
      fromCompartmentId: fromCompartmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromCompartmentId),
      toCompartmentId: toCompartmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(toCompartmentId),
    );
  }

  factory ItemMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemMovement(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<int>(json['itemId']),
      kind: serializer.fromJson<String>(json['kind']),
      at: serializer.fromJson<int>(json['at']),
      fromCompartmentId: serializer.fromJson<int?>(json['fromCompartmentId']),
      toCompartmentId: serializer.fromJson<int?>(json['toCompartmentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<int>(itemId),
      'kind': serializer.toJson<String>(kind),
      'at': serializer.toJson<int>(at),
      'fromCompartmentId': serializer.toJson<int?>(fromCompartmentId),
      'toCompartmentId': serializer.toJson<int?>(toCompartmentId),
    };
  }

  ItemMovement copyWith({
    int? id,
    int? itemId,
    String? kind,
    int? at,
    Value<int?> fromCompartmentId = const Value.absent(),
    Value<int?> toCompartmentId = const Value.absent(),
  }) => ItemMovement(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    kind: kind ?? this.kind,
    at: at ?? this.at,
    fromCompartmentId: fromCompartmentId.present
        ? fromCompartmentId.value
        : this.fromCompartmentId,
    toCompartmentId: toCompartmentId.present
        ? toCompartmentId.value
        : this.toCompartmentId,
  );
  ItemMovement copyWithCompanion(ItemMovementsCompanion data) {
    return ItemMovement(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      at: data.at.present ? data.at.value : this.at,
      fromCompartmentId: data.fromCompartmentId.present
          ? data.fromCompartmentId.value
          : this.fromCompartmentId,
      toCompartmentId: data.toCompartmentId.present
          ? data.toCompartmentId.value
          : this.toCompartmentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemMovement(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('fromCompartmentId: $fromCompartmentId, ')
          ..write('toCompartmentId: $toCompartmentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, itemId, kind, at, fromCompartmentId, toCompartmentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemMovement &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.kind == this.kind &&
          other.at == this.at &&
          other.fromCompartmentId == this.fromCompartmentId &&
          other.toCompartmentId == this.toCompartmentId);
}

class ItemMovementsCompanion extends UpdateCompanion<ItemMovement> {
  final Value<int> id;
  final Value<int> itemId;
  final Value<String> kind;
  final Value<int> at;
  final Value<int?> fromCompartmentId;
  final Value<int?> toCompartmentId;
  const ItemMovementsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.at = const Value.absent(),
    this.fromCompartmentId = const Value.absent(),
    this.toCompartmentId = const Value.absent(),
  });
  ItemMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int itemId,
    required String kind,
    required int at,
    this.fromCompartmentId = const Value.absent(),
    this.toCompartmentId = const Value.absent(),
  }) : itemId = Value(itemId),
       kind = Value(kind),
       at = Value(at);
  static Insertable<ItemMovement> custom({
    Expression<int>? id,
    Expression<int>? itemId,
    Expression<String>? kind,
    Expression<int>? at,
    Expression<int>? fromCompartmentId,
    Expression<int>? toCompartmentId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (kind != null) 'kind': kind,
      if (at != null) 'at': at,
      if (fromCompartmentId != null) 'from_compartment_id': fromCompartmentId,
      if (toCompartmentId != null) 'to_compartment_id': toCompartmentId,
    });
  }

  ItemMovementsCompanion copyWith({
    Value<int>? id,
    Value<int>? itemId,
    Value<String>? kind,
    Value<int>? at,
    Value<int?>? fromCompartmentId,
    Value<int?>? toCompartmentId,
  }) {
    return ItemMovementsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      kind: kind ?? this.kind,
      at: at ?? this.at,
      fromCompartmentId: fromCompartmentId ?? this.fromCompartmentId,
      toCompartmentId: toCompartmentId ?? this.toCompartmentId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (fromCompartmentId.present) {
      map['from_compartment_id'] = Variable<int>(fromCompartmentId.value);
    }
    if (toCompartmentId.present) {
      map['to_compartment_id'] = Variable<int>(toCompartmentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemMovementsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('kind: $kind, ')
          ..write('at: $at, ')
          ..write('fromCompartmentId: $fromCompartmentId, ')
          ..write('toCompartmentId: $toCompartmentId')
          ..write(')'))
        .toString();
  }
}

class $CustomCategoriesTable extends CustomCategories
    with TableInfo<$CustomCategoriesTable, CustomCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomCategoriesTable(this.attachedDatabase, [this._alias]);
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
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultReminderDaysMeta =
      const VerificationMeta('defaultReminderDays');
  @override
  late final GeneratedColumn<int> defaultReminderDays = GeneratedColumn<int>(
    'default_reminder_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconKey,
    colorValue,
    defaultReminderDays,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomCategory> instance, {
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
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('default_reminder_days')) {
      context.handle(
        _defaultReminderDaysMeta,
        defaultReminderDays.isAcceptableOrUnknown(
          data['default_reminder_days']!,
          _defaultReminderDaysMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      defaultReminderDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_reminder_days'],
      ),
    );
  }

  @override
  $CustomCategoriesTable createAlias(String alias) {
    return $CustomCategoriesTable(attachedDatabase, alias);
  }
}

class CustomCategory extends DataClass implements Insertable<CustomCategory> {
  final int id;
  final String name;
  final String iconKey;
  final int colorValue;
  final int? defaultReminderDays;
  const CustomCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.defaultReminderDays,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_value'] = Variable<int>(colorValue);
    if (!nullToAbsent || defaultReminderDays != null) {
      map['default_reminder_days'] = Variable<int>(defaultReminderDays);
    }
    return map;
  }

  CustomCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CustomCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: Value(iconKey),
      colorValue: Value(colorValue),
      defaultReminderDays: defaultReminderDays == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultReminderDays),
    );
  }

  factory CustomCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      defaultReminderDays: serializer.fromJson<int?>(
        json['defaultReminderDays'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorValue': serializer.toJson<int>(colorValue),
      'defaultReminderDays': serializer.toJson<int?>(defaultReminderDays),
    };
  }

  CustomCategory copyWith({
    int? id,
    String? name,
    String? iconKey,
    int? colorValue,
    Value<int?> defaultReminderDays = const Value.absent(),
  }) => CustomCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    defaultReminderDays: defaultReminderDays.present
        ? defaultReminderDays.value
        : this.defaultReminderDays,
  );
  CustomCategory copyWithCompanion(CustomCategoriesCompanion data) {
    return CustomCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      defaultReminderDays: data.defaultReminderDays.present
          ? data.defaultReminderDays.value
          : this.defaultReminderDays,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('defaultReminderDays: $defaultReminderDays')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, iconKey, colorValue, defaultReminderDays);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.colorValue == this.colorValue &&
          other.defaultReminderDays == this.defaultReminderDays);
}

class CustomCategoriesCompanion extends UpdateCompanion<CustomCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> colorValue;
  final Value<int?> defaultReminderDays;
  const CustomCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.defaultReminderDays = const Value.absent(),
  });
  CustomCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconKey,
    required int colorValue,
    this.defaultReminderDays = const Value.absent(),
  }) : name = Value(name),
       iconKey = Value(iconKey),
       colorValue = Value(colorValue);
  static Insertable<CustomCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? colorValue,
    Expression<int>? defaultReminderDays,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorValue != null) 'color_value': colorValue,
      if (defaultReminderDays != null)
        'default_reminder_days': defaultReminderDays,
    });
  }

  CustomCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? iconKey,
    Value<int>? colorValue,
    Value<int?>? defaultReminderDays,
  }) {
    return CustomCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      defaultReminderDays: defaultReminderDays ?? this.defaultReminderDays,
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
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (defaultReminderDays.present) {
      map['default_reminder_days'] = Variable<int>(defaultReminderDays.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('defaultReminderDays: $defaultReminderDays')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FreezersTable freezers = $FreezersTable(this);
  late final $CompartmentsTable compartments = $CompartmentsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ItemMovementsTable itemMovements = $ItemMovementsTable(this);
  late final $CustomCategoriesTable customCategories = $CustomCategoriesTable(
    this,
  );
  late final Index idxItemsStatusFrozen = Index(
    'idx_items_status_frozen',
    'CREATE INDEX idx_items_status_frozen ON items (status, frozen_at)',
  );
  late final Index idxItemsFreezer = Index(
    'idx_items_freezer',
    'CREATE INDEX idx_items_freezer ON items (freezer_id)',
  );
  late final Index idxItemsNameNorm = Index(
    'idx_items_name_norm',
    'CREATE INDEX idx_items_name_norm ON items (name_norm)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    freezers,
    compartments,
    items,
    itemMovements,
    customCategories,
    idxItemsStatusFrozen,
    idxItemsFreezer,
    idxItemsNameNorm,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'freezers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('compartments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'freezers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'compartments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('items', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_movements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FreezersTableCreateCompanionBuilder = FreezersCompanion Function({
  Value<int> id,
  required String name,
  required String modelKey,
  required double capacityLiters,
  Value<double> calibration,
  Value<String?> lastAlertLevel,
  Value<int> sortOrder,
  required int createdAt,
});
typedef $$FreezersTableUpdateCompanionBuilder = FreezersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> modelKey,
  Value<double> capacityLiters,
  Value<double> calibration,
  Value<String?> lastAlertLevel,
  Value<int> sortOrder,
  Value<int> createdAt,
});

final class $$FreezersTableReferences
    extends BaseReferences<_$AppDatabase, $FreezersTable, Freezer> {
  $$FreezersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CompartmentsTable, List<Compartment>>
  _compartmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.compartments,
    aliasName: 'freezers__id__compartments__freezer_id',
  );

  $$CompartmentsTableProcessedTableManager get compartmentsRefs {
    final manager = $$CompartmentsTableTableManager(
      $_db,
      $_db.compartments,
    ).filter((f) => f.freezerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_compartmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'freezers__id__items__freezer_id',
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.freezerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FreezersTableFilterComposer
    extends Composer<_$AppDatabase, $FreezersTable> {
  $$FreezersTableFilterComposer({
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

  ColumnFilters<String> get modelKey => $composableBuilder(
    column: $table.modelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get capacityLiters => $composableBuilder(
    column: $table.capacityLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calibration => $composableBuilder(
    column: $table.calibration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAlertLevel => $composableBuilder(
    column: $table.lastAlertLevel,
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

  Expression<bool> compartmentsRefs(
    Expression<bool> Function($$CompartmentsTableFilterComposer f) f,
  ) {
    final $$CompartmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compartments,
      getReferencedColumn: (t) => t.freezerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompartmentsTableFilterComposer(
            $db: $db,
            $table: $db.compartments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.freezerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FreezersTableOrderingComposer
    extends Composer<_$AppDatabase, $FreezersTable> {
  $$FreezersTableOrderingComposer({
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

  ColumnOrderings<String> get modelKey => $composableBuilder(
    column: $table.modelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get capacityLiters => $composableBuilder(
    column: $table.capacityLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calibration => $composableBuilder(
    column: $table.calibration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAlertLevel => $composableBuilder(
    column: $table.lastAlertLevel,
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

class $$FreezersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FreezersTable> {
  $$FreezersTableAnnotationComposer({
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

  GeneratedColumn<String> get modelKey =>
      $composableBuilder(column: $table.modelKey, builder: (column) => column);

  GeneratedColumn<double> get capacityLiters => $composableBuilder(
    column: $table.capacityLiters,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calibration => $composableBuilder(
    column: $table.calibration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastAlertLevel => $composableBuilder(
    column: $table.lastAlertLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> compartmentsRefs<T extends Object>(
    Expression<T> Function($$CompartmentsTableAnnotationComposer a) f,
  ) {
    final $$CompartmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.compartments,
      getReferencedColumn: (t) => t.freezerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompartmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.compartments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.freezerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FreezersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FreezersTable,
          Freezer,
          $$FreezersTableFilterComposer,
          $$FreezersTableOrderingComposer,
          $$FreezersTableAnnotationComposer,
          $$FreezersTableCreateCompanionBuilder,
          $$FreezersTableUpdateCompanionBuilder,
          (Freezer, $$FreezersTableReferences),
          Freezer,
          PrefetchHooks Function({bool compartmentsRefs, bool itemsRefs})
        > {
  $$FreezersTableTableManager(_$AppDatabase db, $FreezersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FreezersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FreezersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FreezersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> modelKey = const Value.absent(),
                Value<double> capacityLiters = const Value.absent(),
                Value<double> calibration = const Value.absent(),
                Value<String?> lastAlertLevel = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => FreezersCompanion(
                id: id,
                name: name,
                modelKey: modelKey,
                capacityLiters: capacityLiters,
                calibration: calibration,
                lastAlertLevel: lastAlertLevel,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String modelKey,
                required double capacityLiters,
                Value<double> calibration = const Value.absent(),
                Value<String?> lastAlertLevel = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => FreezersCompanion.insert(
                id: id,
                name: name,
                modelKey: modelKey,
                capacityLiters: capacityLiters,
                calibration: calibration,
                lastAlertLevel: lastAlertLevel,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FreezersTable, Freezer>(table),
                  $$FreezersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({compartmentsRefs = false, itemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (compartmentsRefs) db.compartments,
                    if (itemsRefs) db.items,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (compartmentsRefs)
                        await $_getPrefetchedData<
                          Freezer,
                          $FreezersTable,
                          Compartment
                        >(
                          currentTable: table,
                          referencedTable: $$FreezersTableReferences
                              ._compartmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FreezersTableReferences(
                                db,
                                table,
                                p0,
                              ).compartmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.freezerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemsRefs)
                        await $_getPrefetchedData<
                          Freezer,
                          $FreezersTable,
                          Item
                        >(
                          currentTable: table,
                          referencedTable: $$FreezersTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FreezersTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.freezerId == item.id,
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

typedef $$FreezersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FreezersTable,
      Freezer,
      $$FreezersTableFilterComposer,
      $$FreezersTableOrderingComposer,
      $$FreezersTableAnnotationComposer,
      $$FreezersTableCreateCompanionBuilder,
      $$FreezersTableUpdateCompanionBuilder,
      (Freezer, $$FreezersTableReferences),
      Freezer,
      PrefetchHooks Function({bool compartmentsRefs, bool itemsRefs})
    >;
typedef $$CompartmentsTableCreateCompanionBuilder =
    CompartmentsCompanion Function({
      Value<int> id,
      required int freezerId,
      required String name,
      Value<int> sortOrder,
    });
typedef $$CompartmentsTableUpdateCompanionBuilder =
    CompartmentsCompanion Function({
      Value<int> id,
      Value<int> freezerId,
      Value<String> name,
      Value<int> sortOrder,
    });

final class $$CompartmentsTableReferences
    extends BaseReferences<_$AppDatabase, $CompartmentsTable, Compartment> {
  $$CompartmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FreezersTable _freezerIdTable(_$AppDatabase db) =>
      db.freezers.createAlias('compartments__freezer_id__freezers__id');

  $$FreezersTableProcessedTableManager get freezerId {
    final $_column = $_itemColumn<int>('freezer_id')!;

    final manager = $$FreezersTableTableManager(
      $_db,
      $_db.freezers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_freezerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'compartments__id__items__compartment_id',
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.compartmentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompartmentsTableFilterComposer
    extends Composer<_$AppDatabase, $CompartmentsTable> {
  $$CompartmentsTableFilterComposer({
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

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$FreezersTableFilterComposer get freezerId {
    final $$FreezersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.freezerId,
      referencedTable: $db.freezers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FreezersTableFilterComposer(
            $db: $db,
            $table: $db.freezers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.compartmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompartmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompartmentsTable> {
  $$CompartmentsTableOrderingComposer({
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

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$FreezersTableOrderingComposer get freezerId {
    final $$FreezersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.freezerId,
      referencedTable: $db.freezers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FreezersTableOrderingComposer(
            $db: $db,
            $table: $db.freezers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompartmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompartmentsTable> {
  $$CompartmentsTableAnnotationComposer({
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

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$FreezersTableAnnotationComposer get freezerId {
    final $$FreezersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.freezerId,
      referencedTable: $db.freezers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FreezersTableAnnotationComposer(
            $db: $db,
            $table: $db.freezers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.compartmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CompartmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompartmentsTable,
          Compartment,
          $$CompartmentsTableFilterComposer,
          $$CompartmentsTableOrderingComposer,
          $$CompartmentsTableAnnotationComposer,
          $$CompartmentsTableCreateCompanionBuilder,
          $$CompartmentsTableUpdateCompanionBuilder,
          (Compartment, $$CompartmentsTableReferences),
          Compartment,
          PrefetchHooks Function({bool freezerId, bool itemsRefs})
        > {
  $$CompartmentsTableTableManager(_$AppDatabase db, $CompartmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompartmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompartmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompartmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> freezerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CompartmentsCompanion(
                id: id,
                freezerId: freezerId,
                name: name,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int freezerId,
                required String name,
                Value<int> sortOrder = const Value.absent(),
              }) => CompartmentsCompanion.insert(
                id: id,
                freezerId: freezerId,
                name: name,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompartmentsTable, Compartment>(table),
                  $$CompartmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({freezerId = false, itemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsRefs) db.items],
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
                    if (freezerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.freezerId,
                        referencedTable: $$CompartmentsTableReferences
                            ._freezerIdTable(db),
                        referencedColumn: $$CompartmentsTableReferences
                            ._freezerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsRefs)
                    await $_getPrefetchedData<
                      Compartment,
                      $CompartmentsTable,
                      Item
                    >(
                      currentTable: table,
                      referencedTable: $$CompartmentsTableReferences
                          ._itemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CompartmentsTableReferences(
                            db,
                            table,
                            p0,
                          ).itemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.compartmentId == item.id,
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

typedef $$CompartmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompartmentsTable,
      Compartment,
      $$CompartmentsTableFilterComposer,
      $$CompartmentsTableOrderingComposer,
      $$CompartmentsTableAnnotationComposer,
      $$CompartmentsTableCreateCompanionBuilder,
      $$CompartmentsTableUpdateCompanionBuilder,
      (Compartment, $$CompartmentsTableReferences),
      Compartment,
      PrefetchHooks Function({bool freezerId, bool itemsRefs})
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  required int freezerId,
  Value<int?> compartmentId,
  required String name,
  required String nameNorm,
  Value<String?> category,
  required double quantity,
  required String unit,
  required String frozenAt,
  Value<int?> reminderAfterDays,
  required double volumeLiters,
  Value<bool> volumeManual,
  Value<String?> photoPath,
  Value<String?> note,
  Value<String> status,
  Value<int?> removedAt,
  required int createdAt,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<int> freezerId,
  Value<int?> compartmentId,
  Value<String> name,
  Value<String> nameNorm,
  Value<String?> category,
  Value<double> quantity,
  Value<String> unit,
  Value<String> frozenAt,
  Value<int?> reminderAfterDays,
  Value<double> volumeLiters,
  Value<bool> volumeManual,
  Value<String?> photoPath,
  Value<String?> note,
  Value<String> status,
  Value<int?> removedAt,
  Value<int> createdAt,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FreezersTable _freezerIdTable(_$AppDatabase db) =>
      db.freezers.createAlias('items__freezer_id__freezers__id');

  $$FreezersTableProcessedTableManager get freezerId {
    final $_column = $_itemColumn<int>('freezer_id')!;

    final manager = $$FreezersTableTableManager(
      $_db,
      $_db.freezers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_freezerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CompartmentsTable _compartmentIdTable(_$AppDatabase db) =>
      db.compartments.createAlias('items__compartment_id__compartments__id');

  $$CompartmentsTableProcessedTableManager? get compartmentId {
    final $_column = $_itemColumn<int>('compartment_id');
    if ($_column == null) return null;
    final manager = $$CompartmentsTableTableManager(
      $_db,
      $_db.compartments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_compartmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemMovementsTable, List<ItemMovement>>
  _itemMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemMovements,
    aliasName: 'items__id__item_movements__item_id',
  );

  $$ItemMovementsTableProcessedTableManager get itemMovementsRefs {
    final manager = $$ItemMovementsTableTableManager(
      $_db,
      $_db.itemMovements,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get nameNorm => $composableBuilder(
    column: $table.nameNorm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frozenAt => $composableBuilder(
    column: $table.frozenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderAfterDays => $composableBuilder(
    column: $table.reminderAfterDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get volumeLiters => $composableBuilder(
    column: $table.volumeLiters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get volumeManual => $composableBuilder(
    column: $table.volumeManual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FreezersTableFilterComposer get freezerId {
    final $$FreezersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.freezerId,
      referencedTable: $db.freezers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FreezersTableFilterComposer(
            $db: $db,
            $table: $db.freezers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompartmentsTableFilterComposer get compartmentId {
    final $$CompartmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.compartmentId,
      referencedTable: $db.compartments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompartmentsTableFilterComposer(
            $db: $db,
            $table: $db.compartments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemMovementsRefs(
    Expression<bool> Function($$ItemMovementsTableFilterComposer f) f,
  ) {
    final $$ItemMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemMovements,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemMovementsTableFilterComposer(
            $db: $db,
            $table: $db.itemMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get nameNorm => $composableBuilder(
    column: $table.nameNorm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frozenAt => $composableBuilder(
    column: $table.frozenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderAfterDays => $composableBuilder(
    column: $table.reminderAfterDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get volumeLiters => $composableBuilder(
    column: $table.volumeLiters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get volumeManual => $composableBuilder(
    column: $table.volumeManual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FreezersTableOrderingComposer get freezerId {
    final $$FreezersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.freezerId,
      referencedTable: $db.freezers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FreezersTableOrderingComposer(
            $db: $db,
            $table: $db.freezers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompartmentsTableOrderingComposer get compartmentId {
    final $$CompartmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.compartmentId,
      referencedTable: $db.compartments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompartmentsTableOrderingComposer(
            $db: $db,
            $table: $db.compartments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get nameNorm =>
      $composableBuilder(column: $table.nameNorm, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get frozenAt =>
      $composableBuilder(column: $table.frozenAt, builder: (column) => column);

  GeneratedColumn<int> get reminderAfterDays => $composableBuilder(
    column: $table.reminderAfterDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get volumeLiters => $composableBuilder(
    column: $table.volumeLiters,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get volumeManual => $composableBuilder(
    column: $table.volumeManual,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FreezersTableAnnotationComposer get freezerId {
    final $$FreezersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.freezerId,
      referencedTable: $db.freezers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FreezersTableAnnotationComposer(
            $db: $db,
            $table: $db.freezers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CompartmentsTableAnnotationComposer get compartmentId {
    final $$CompartmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.compartmentId,
      referencedTable: $db.compartments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompartmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.compartments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemMovementsRefs<T extends Object>(
    Expression<T> Function($$ItemMovementsTableAnnotationComposer a) f,
  ) {
    final $$ItemMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemMovements,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool freezerId,
            bool compartmentId,
            bool itemMovementsRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> freezerId = const Value.absent(),
                Value<int?> compartmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameNorm = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> frozenAt = const Value.absent(),
                Value<int?> reminderAfterDays = const Value.absent(),
                Value<double> volumeLiters = const Value.absent(),
                Value<bool> volumeManual = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> removedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                freezerId: freezerId,
                compartmentId: compartmentId,
                name: name,
                nameNorm: nameNorm,
                category: category,
                quantity: quantity,
                unit: unit,
                frozenAt: frozenAt,
                reminderAfterDays: reminderAfterDays,
                volumeLiters: volumeLiters,
                volumeManual: volumeManual,
                photoPath: photoPath,
                note: note,
                status: status,
                removedAt: removedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int freezerId,
                Value<int?> compartmentId = const Value.absent(),
                required String name,
                required String nameNorm,
                Value<String?> category = const Value.absent(),
                required double quantity,
                required String unit,
                required String frozenAt,
                Value<int?> reminderAfterDays = const Value.absent(),
                required double volumeLiters,
                Value<bool> volumeManual = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> removedAt = const Value.absent(),
                required int createdAt,
              }) => ItemsCompanion.insert(
                id: id,
                freezerId: freezerId,
                compartmentId: compartmentId,
                name: name,
                nameNorm: nameNorm,
                category: category,
                quantity: quantity,
                unit: unit,
                frozenAt: frozenAt,
                reminderAfterDays: reminderAfterDays,
                volumeLiters: volumeLiters,
                volumeManual: volumeManual,
                photoPath: photoPath,
                note: note,
                status: status,
                removedAt: removedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                freezerId = false,
                compartmentId = false,
                itemMovementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemMovementsRefs) db.itemMovements,
                  ],
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
                        if (freezerId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.freezerId,
                            referencedTable: $$ItemsTableReferences
                                ._freezerIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._freezerIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (compartmentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.compartmentId,
                            referencedTable: $$ItemsTableReferences
                                ._compartmentIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._compartmentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemMovementsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          ItemMovement
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._itemMovementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemMovementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
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

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool freezerId,
        bool compartmentId,
        bool itemMovementsRefs,
      })
    >;
typedef $$ItemMovementsTableCreateCompanionBuilder =
    ItemMovementsCompanion Function({
      Value<int> id,
      required int itemId,
      required String kind,
      required int at,
      Value<int?> fromCompartmentId,
      Value<int?> toCompartmentId,
    });
typedef $$ItemMovementsTableUpdateCompanionBuilder =
    ItemMovementsCompanion Function({
      Value<int> id,
      Value<int> itemId,
      Value<String> kind,
      Value<int> at,
      Value<int?> fromCompartmentId,
      Value<int?> toCompartmentId,
    });

final class $$ItemMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemMovementsTable, ItemMovement> {
  $$ItemMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('item_movements__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemMovementsTable> {
  $$ItemMovementsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromCompartmentId => $composableBuilder(
    column: $table.fromCompartmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toCompartmentId => $composableBuilder(
    column: $table.toCompartmentId,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemMovementsTable> {
  $$ItemMovementsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromCompartmentId => $composableBuilder(
    column: $table.fromCompartmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toCompartmentId => $composableBuilder(
    column: $table.toCompartmentId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemMovementsTable> {
  $$ItemMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get fromCompartmentId => $composableBuilder(
    column: $table.fromCompartmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toCompartmentId => $composableBuilder(
    column: $table.toCompartmentId,
    builder: (column) => column,
  );

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemMovementsTable,
          ItemMovement,
          $$ItemMovementsTableFilterComposer,
          $$ItemMovementsTableOrderingComposer,
          $$ItemMovementsTableAnnotationComposer,
          $$ItemMovementsTableCreateCompanionBuilder,
          $$ItemMovementsTableUpdateCompanionBuilder,
          (ItemMovement, $$ItemMovementsTableReferences),
          ItemMovement,
          PrefetchHooks Function({bool itemId})
        > {
  $$ItemMovementsTableTableManager(_$AppDatabase db, $ItemMovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<int?> fromCompartmentId = const Value.absent(),
                Value<int?> toCompartmentId = const Value.absent(),
              }) => ItemMovementsCompanion(
                id: id,
                itemId: itemId,
                kind: kind,
                at: at,
                fromCompartmentId: fromCompartmentId,
                toCompartmentId: toCompartmentId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int itemId,
                required String kind,
                required int at,
                Value<int?> fromCompartmentId = const Value.absent(),
                Value<int?> toCompartmentId = const Value.absent(),
              }) => ItemMovementsCompanion.insert(
                id: id,
                itemId: itemId,
                kind: kind,
                at: at,
                fromCompartmentId: fromCompartmentId,
                toCompartmentId: toCompartmentId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemMovementsTable, ItemMovement>(table),
                  $$ItemMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ItemMovementsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ItemMovementsTableReferences
                            ._itemIdTable(db)
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

typedef $$ItemMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemMovementsTable,
      ItemMovement,
      $$ItemMovementsTableFilterComposer,
      $$ItemMovementsTableOrderingComposer,
      $$ItemMovementsTableAnnotationComposer,
      $$ItemMovementsTableCreateCompanionBuilder,
      $$ItemMovementsTableUpdateCompanionBuilder,
      (ItemMovement, $$ItemMovementsTableReferences),
      ItemMovement,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$CustomCategoriesTableCreateCompanionBuilder =
    CustomCategoriesCompanion Function({
      Value<int> id,
      required String name,
      required String iconKey,
      required int colorValue,
      Value<int?> defaultReminderDays,
    });
typedef $$CustomCategoriesTableUpdateCompanionBuilder =
    CustomCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> iconKey,
      Value<int> colorValue,
      Value<int?> defaultReminderDays,
    });

class $$CustomCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomCategoriesTable> {
  $$CustomCategoriesTableFilterComposer({
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

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultReminderDays => $composableBuilder(
    column: $table.defaultReminderDays,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomCategoriesTable> {
  $$CustomCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultReminderDays => $composableBuilder(
    column: $table.defaultReminderDays,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomCategoriesTable> {
  $$CustomCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultReminderDays => $composableBuilder(
    column: $table.defaultReminderDays,
    builder: (column) => column,
  );
}

class $$CustomCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomCategoriesTable,
          CustomCategory,
          $$CustomCategoriesTableFilterComposer,
          $$CustomCategoriesTableOrderingComposer,
          $$CustomCategoriesTableAnnotationComposer,
          $$CustomCategoriesTableCreateCompanionBuilder,
          $$CustomCategoriesTableUpdateCompanionBuilder,
          (
            CustomCategory,
            BaseReferences<
              _$AppDatabase,
              $CustomCategoriesTable,
              CustomCategory
            >,
          ),
          CustomCategory,
          PrefetchHooks Function()
        > {
  $$CustomCategoriesTableTableManager(
    _$AppDatabase db,
    $CustomCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<int?> defaultReminderDays = const Value.absent(),
              }) => CustomCategoriesCompanion(
                id: id,
                name: name,
                iconKey: iconKey,
                colorValue: colorValue,
                defaultReminderDays: defaultReminderDays,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String iconKey,
                required int colorValue,
                Value<int?> defaultReminderDays = const Value.absent(),
              }) => CustomCategoriesCompanion.insert(
                id: id,
                name: name,
                iconKey: iconKey,
                colorValue: colorValue,
                defaultReminderDays: defaultReminderDays,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomCategoriesTable, CustomCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CustomCategoriesTable,
                    CustomCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomCategoriesTable,
      CustomCategory,
      $$CustomCategoriesTableFilterComposer,
      $$CustomCategoriesTableOrderingComposer,
      $$CustomCategoriesTableAnnotationComposer,
      $$CustomCategoriesTableCreateCompanionBuilder,
      $$CustomCategoriesTableUpdateCompanionBuilder,
      (
        CustomCategory,
        BaseReferences<_$AppDatabase, $CustomCategoriesTable, CustomCategory>,
      ),
      CustomCategory,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FreezersTableTableManager get freezers =>
      $$FreezersTableTableManager(_db, _db.freezers);
  $$CompartmentsTableTableManager get compartments =>
      $$CompartmentsTableTableManager(_db, _db.compartments);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ItemMovementsTableTableManager get itemMovements =>
      $$ItemMovementsTableTableManager(_db, _db.itemMovements);
  $$CustomCategoriesTableTableManager get customCategories =>
      $$CustomCategoriesTableTableManager(_db, _db.customCategories);
}
