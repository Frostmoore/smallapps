// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CamerasTable extends Cameras with TableInfo<$CamerasTable, Camera> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CamerasTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _manufacturerMeta = const VerificationMeta(
    'manufacturer',
  );
  @override
  late final GeneratedColumn<String> manufacturer = GeneratedColumn<String>(
    'manufacturer',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    check: () => format.isIn(filmFormatKeys),
    type: DriftSqlType.string,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    manufacturer,
    model,
    format,
    note,
    active,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cameras';
  @override
  VerificationContext validateIntegrity(
    Insertable<Camera> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('manufacturer')) {
      context.handle(
        _manufacturerMeta,
        manufacturer.isAcceptableOrUnknown(
          data['manufacturer']!,
          _manufacturerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manufacturerMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Camera map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Camera(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      manufacturer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manufacturer'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CamerasTable createAlias(String alias) {
    return $CamerasTable(attachedDatabase, alias);
  }
}

class Camera extends DataClass implements Insertable<Camera> {
  final int id;

  /// "Olympus". Dato dell'utente, non testo dell'app.
  final String manufacturer;

  /// "OM-2".
  final String model;

  /// `FilmFormat.key`. Preimposta il formato dei rullini caricati in questa macchina.
  final String format;
  final String? note;

  /// Una macchina venduta sparisce dalla scelta nel form ma resta sui rullini che ha
  /// scattato. Cancellarla invece stacca i rullini (`cameraId` -> NULL).
  final bool active;

  /// Ordine nell'elenco (trascinamento).
  final int sortOrder;
  const Camera({
    required this.id,
    required this.manufacturer,
    required this.model,
    required this.format,
    this.note,
    required this.active,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['manufacturer'] = Variable<String>(manufacturer);
    map['model'] = Variable<String>(model);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['active'] = Variable<bool>(active);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CamerasCompanion toCompanion(bool nullToAbsent) {
    return CamerasCompanion(
      id: Value(id),
      manufacturer: Value(manufacturer),
      model: Value(model),
      format: Value(format),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      active: Value(active),
      sortOrder: Value(sortOrder),
    );
  }

  factory Camera.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Camera(
      id: serializer.fromJson<int>(json['id']),
      manufacturer: serializer.fromJson<String>(json['manufacturer']),
      model: serializer.fromJson<String>(json['model']),
      format: serializer.fromJson<String>(json['format']),
      note: serializer.fromJson<String?>(json['note']),
      active: serializer.fromJson<bool>(json['active']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'manufacturer': serializer.toJson<String>(manufacturer),
      'model': serializer.toJson<String>(model),
      'format': serializer.toJson<String>(format),
      'note': serializer.toJson<String?>(note),
      'active': serializer.toJson<bool>(active),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Camera copyWith({
    int? id,
    String? manufacturer,
    String? model,
    String? format,
    Value<String?> note = const Value.absent(),
    bool? active,
    int? sortOrder,
  }) => Camera(
    id: id ?? this.id,
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    format: format ?? this.format,
    note: note.present ? note.value : this.note,
    active: active ?? this.active,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Camera copyWithCompanion(CamerasCompanion data) {
    return Camera(
      id: data.id.present ? data.id.value : this.id,
      manufacturer: data.manufacturer.present
          ? data.manufacturer.value
          : this.manufacturer,
      model: data.model.present ? data.model.value : this.model,
      format: data.format.present ? data.format.value : this.format,
      note: data.note.present ? data.note.value : this.note,
      active: data.active.present ? data.active.value : this.active,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Camera(')
          ..write('id: $id, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('format: $format, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, manufacturer, model, format, note, active, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Camera &&
          other.id == this.id &&
          other.manufacturer == this.manufacturer &&
          other.model == this.model &&
          other.format == this.format &&
          other.note == this.note &&
          other.active == this.active &&
          other.sortOrder == this.sortOrder);
}

class CamerasCompanion extends UpdateCompanion<Camera> {
  final Value<int> id;
  final Value<String> manufacturer;
  final Value<String> model;
  final Value<String> format;
  final Value<String?> note;
  final Value<bool> active;
  final Value<int> sortOrder;
  const CamerasCompanion({
    this.id = const Value.absent(),
    this.manufacturer = const Value.absent(),
    this.model = const Value.absent(),
    this.format = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CamerasCompanion.insert({
    this.id = const Value.absent(),
    required String manufacturer,
    required String model,
    required String format,
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : manufacturer = Value(manufacturer),
       model = Value(model),
       format = Value(format);
  static Insertable<Camera> custom({
    Expression<int>? id,
    Expression<String>? manufacturer,
    Expression<String>? model,
    Expression<String>? format,
    Expression<String>? note,
    Expression<bool>? active,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (model != null) 'model': model,
      if (format != null) 'format': format,
      if (note != null) 'note': note,
      if (active != null) 'active': active,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CamerasCompanion copyWith({
    Value<int>? id,
    Value<String>? manufacturer,
    Value<String>? model,
    Value<String>? format,
    Value<String?>? note,
    Value<bool>? active,
    Value<int>? sortOrder,
  }) {
    return CamerasCompanion(
      id: id ?? this.id,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      format: format ?? this.format,
      note: note ?? this.note,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (manufacturer.present) {
      map['manufacturer'] = Variable<String>(manufacturer.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CamerasCompanion(')
          ..write('id: $id, ')
          ..write('manufacturer: $manufacturer, ')
          ..write('model: $model, ')
          ..write('format: $format, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $FilmStocksTable extends FilmStocks
    with TableInfo<$FilmStocksTable, FilmStock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmStocksTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isoMeta = const VerificationMeta('iso');
  @override
  late final GeneratedColumn<int> iso = GeneratedColumn<int>(
    'iso',
    aliasedName,
    false,
    check: () => ComparableExpr(iso).isBetweenValues(1, 100000),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processMeta = const VerificationMeta(
    'process',
  );
  @override
  late final GeneratedColumn<String> process = GeneratedColumn<String>(
    'process',
    aliasedName,
    false,
    check: () => process.isIn(filmProcessKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    check: () => format.isIn(filmFormatKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    brand,
    name,
    iso,
    process,
    format,
    isCustom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_stocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmStock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    } else if (isInserting) {
      context.missing(_brandMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('iso')) {
      context.handle(
        _isoMeta,
        iso.isAcceptableOrUnknown(data['iso']!, _isoMeta),
      );
    } else if (isInserting) {
      context.missing(_isoMeta);
    }
    if (data.containsKey('process')) {
      context.handle(
        _processMeta,
        process.isAcceptableOrUnknown(data['process']!, _processMeta),
      );
    } else if (isInserting) {
      context.missing(_processMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {brand, name, format},
  ];
  @override
  FilmStock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmStock(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iso'],
      )!,
      process: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}process'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
    );
  }

  @override
  $FilmStocksTable createAlias(String alias) {
    return $FilmStocksTable(attachedDatabase, alias);
  }
}

class FilmStock extends DataClass implements Insertable<FilmStock> {
  final int id;
  final String brand;
  final String name;

  /// Sensibilita' nominale. Il tetto e' largo (le Delta 3200 si tirano a 25600) ma toglie gli
  /// errori di battitura a sei cifre.
  final int iso;
  final String process;
  final String format;

  /// True per le pellicole aggiunte dall'utente: solo queste si modificano e si cancellano.
  final bool isCustom;
  const FilmStock({
    required this.id,
    required this.brand,
    required this.name,
    required this.iso,
    required this.process,
    required this.format,
    required this.isCustom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['brand'] = Variable<String>(brand);
    map['name'] = Variable<String>(name);
    map['iso'] = Variable<int>(iso);
    map['process'] = Variable<String>(process);
    map['format'] = Variable<String>(format);
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  FilmStocksCompanion toCompanion(bool nullToAbsent) {
    return FilmStocksCompanion(
      id: Value(id),
      brand: Value(brand),
      name: Value(name),
      iso: Value(iso),
      process: Value(process),
      format: Value(format),
      isCustom: Value(isCustom),
    );
  }

  factory FilmStock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmStock(
      id: serializer.fromJson<int>(json['id']),
      brand: serializer.fromJson<String>(json['brand']),
      name: serializer.fromJson<String>(json['name']),
      iso: serializer.fromJson<int>(json['iso']),
      process: serializer.fromJson<String>(json['process']),
      format: serializer.fromJson<String>(json['format']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'brand': serializer.toJson<String>(brand),
      'name': serializer.toJson<String>(name),
      'iso': serializer.toJson<int>(iso),
      'process': serializer.toJson<String>(process),
      'format': serializer.toJson<String>(format),
      'isCustom': serializer.toJson<bool>(isCustom),
    };
  }

  FilmStock copyWith({
    int? id,
    String? brand,
    String? name,
    int? iso,
    String? process,
    String? format,
    bool? isCustom,
  }) => FilmStock(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    name: name ?? this.name,
    iso: iso ?? this.iso,
    process: process ?? this.process,
    format: format ?? this.format,
    isCustom: isCustom ?? this.isCustom,
  );
  FilmStock copyWithCompanion(FilmStocksCompanion data) {
    return FilmStock(
      id: data.id.present ? data.id.value : this.id,
      brand: data.brand.present ? data.brand.value : this.brand,
      name: data.name.present ? data.name.value : this.name,
      iso: data.iso.present ? data.iso.value : this.iso,
      process: data.process.present ? data.process.value : this.process,
      format: data.format.present ? data.format.value : this.format,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmStock(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('iso: $iso, ')
          ..write('process: $process, ')
          ..write('format: $format, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, brand, name, iso, process, format, isCustom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmStock &&
          other.id == this.id &&
          other.brand == this.brand &&
          other.name == this.name &&
          other.iso == this.iso &&
          other.process == this.process &&
          other.format == this.format &&
          other.isCustom == this.isCustom);
}

class FilmStocksCompanion extends UpdateCompanion<FilmStock> {
  final Value<int> id;
  final Value<String> brand;
  final Value<String> name;
  final Value<int> iso;
  final Value<String> process;
  final Value<String> format;
  final Value<bool> isCustom;
  const FilmStocksCompanion({
    this.id = const Value.absent(),
    this.brand = const Value.absent(),
    this.name = const Value.absent(),
    this.iso = const Value.absent(),
    this.process = const Value.absent(),
    this.format = const Value.absent(),
    this.isCustom = const Value.absent(),
  });
  FilmStocksCompanion.insert({
    this.id = const Value.absent(),
    required String brand,
    required String name,
    required int iso,
    required String process,
    required String format,
    this.isCustom = const Value.absent(),
  }) : brand = Value(brand),
       name = Value(name),
       iso = Value(iso),
       process = Value(process),
       format = Value(format);
  static Insertable<FilmStock> custom({
    Expression<int>? id,
    Expression<String>? brand,
    Expression<String>? name,
    Expression<int>? iso,
    Expression<String>? process,
    Expression<String>? format,
    Expression<bool>? isCustom,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (brand != null) 'brand': brand,
      if (name != null) 'name': name,
      if (iso != null) 'iso': iso,
      if (process != null) 'process': process,
      if (format != null) 'format': format,
      if (isCustom != null) 'is_custom': isCustom,
    });
  }

  FilmStocksCompanion copyWith({
    Value<int>? id,
    Value<String>? brand,
    Value<String>? name,
    Value<int>? iso,
    Value<String>? process,
    Value<String>? format,
    Value<bool>? isCustom,
  }) {
    return FilmStocksCompanion(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      name: name ?? this.name,
      iso: iso ?? this.iso,
      process: process ?? this.process,
      format: format ?? this.format,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iso.present) {
      map['iso'] = Variable<int>(iso.value);
    }
    if (process.present) {
      map['process'] = Variable<String>(process.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmStocksCompanion(')
          ..write('id: $id, ')
          ..write('brand: $brand, ')
          ..write('name: $name, ')
          ..write('iso: $iso, ')
          ..write('process: $process, ')
          ..write('format: $format, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }
}

class $RollImagesTable extends RollImages
    with TableInfo<$RollImagesTable, RollImage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RollImagesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filmRollIdMeta = const VerificationMeta(
    'filmRollId',
  );
  @override
  late final GeneratedColumn<int> filmRollId = GeneratedColumn<int>(
    'film_roll_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES film_rolls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbPathMeta = const VerificationMeta(
    'thumbPath',
  );
  @override
  late final GeneratedColumn<String> thumbPath = GeneratedColumn<String>(
    'thumb_path',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    false,
    check: () => ComparableExpr(width).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    false,
    check: () => ComparableExpr(height).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    check: () => ComparableExpr(bytes).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(rollImageKindKeys),
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
    filmRollId,
    path,
    thumbPath,
    width,
    height,
    bytes,
    kind,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'roll_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<RollImage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('film_roll_id')) {
      context.handle(
        _filmRollIdMeta,
        filmRollId.isAcceptableOrUnknown(
          data['film_roll_id']!,
          _filmRollIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filmRollIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('thumb_path')) {
      context.handle(
        _thumbPathMeta,
        thumbPath.isAcceptableOrUnknown(data['thumb_path']!, _thumbPathMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbPathMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
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
  RollImage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RollImage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filmRollId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}film_roll_id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      thumbPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumb_path'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
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
  $RollImagesTable createAlias(String alias) {
    return $RollImagesTable(attachedDatabase, alias);
  }
}

class RollImage extends DataClass implements Insertable<RollImage> {
  final int id;
  final int filmRollId;

  /// Percorsi **relativi** alla cartella documenti (F1.11, `StoredImage.path`): un percorso
  /// assoluto si rompe al primo aggiornamento dell'app su Android.
  final String path;
  final String thumbPath;
  final int width;
  final int height;
  final int bytes;

  /// `RollImageKind.key`.
  final String kind;
  final int sortOrder;
  final int createdAt;
  const RollImage({
    required this.id,
    required this.filmRollId,
    required this.path,
    required this.thumbPath,
    required this.width,
    required this.height,
    required this.bytes,
    required this.kind,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['film_roll_id'] = Variable<int>(filmRollId);
    map['path'] = Variable<String>(path);
    map['thumb_path'] = Variable<String>(thumbPath);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    map['bytes'] = Variable<int>(bytes);
    map['kind'] = Variable<String>(kind);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  RollImagesCompanion toCompanion(bool nullToAbsent) {
    return RollImagesCompanion(
      id: Value(id),
      filmRollId: Value(filmRollId),
      path: Value(path),
      thumbPath: Value(thumbPath),
      width: Value(width),
      height: Value(height),
      bytes: Value(bytes),
      kind: Value(kind),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory RollImage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RollImage(
      id: serializer.fromJson<int>(json['id']),
      filmRollId: serializer.fromJson<int>(json['filmRollId']),
      path: serializer.fromJson<String>(json['path']),
      thumbPath: serializer.fromJson<String>(json['thumbPath']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      bytes: serializer.fromJson<int>(json['bytes']),
      kind: serializer.fromJson<String>(json['kind']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filmRollId': serializer.toJson<int>(filmRollId),
      'path': serializer.toJson<String>(path),
      'thumbPath': serializer.toJson<String>(thumbPath),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'bytes': serializer.toJson<int>(bytes),
      'kind': serializer.toJson<String>(kind),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  RollImage copyWith({
    int? id,
    int? filmRollId,
    String? path,
    String? thumbPath,
    int? width,
    int? height,
    int? bytes,
    String? kind,
    int? sortOrder,
    int? createdAt,
  }) => RollImage(
    id: id ?? this.id,
    filmRollId: filmRollId ?? this.filmRollId,
    path: path ?? this.path,
    thumbPath: thumbPath ?? this.thumbPath,
    width: width ?? this.width,
    height: height ?? this.height,
    bytes: bytes ?? this.bytes,
    kind: kind ?? this.kind,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  RollImage copyWithCompanion(RollImagesCompanion data) {
    return RollImage(
      id: data.id.present ? data.id.value : this.id,
      filmRollId: data.filmRollId.present
          ? data.filmRollId.value
          : this.filmRollId,
      path: data.path.present ? data.path.value : this.path,
      thumbPath: data.thumbPath.present ? data.thumbPath.value : this.thumbPath,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      kind: data.kind.present ? data.kind.value : this.kind,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RollImage(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('path: $path, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('bytes: $bytes, ')
          ..write('kind: $kind, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filmRollId,
    path,
    thumbPath,
    width,
    height,
    bytes,
    kind,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RollImage &&
          other.id == this.id &&
          other.filmRollId == this.filmRollId &&
          other.path == this.path &&
          other.thumbPath == this.thumbPath &&
          other.width == this.width &&
          other.height == this.height &&
          other.bytes == this.bytes &&
          other.kind == this.kind &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class RollImagesCompanion extends UpdateCompanion<RollImage> {
  final Value<int> id;
  final Value<int> filmRollId;
  final Value<String> path;
  final Value<String> thumbPath;
  final Value<int> width;
  final Value<int> height;
  final Value<int> bytes;
  final Value<String> kind;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const RollImagesCompanion({
    this.id = const Value.absent(),
    this.filmRollId = const Value.absent(),
    this.path = const Value.absent(),
    this.thumbPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.bytes = const Value.absent(),
    this.kind = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  RollImagesCompanion.insert({
    this.id = const Value.absent(),
    required int filmRollId,
    required String path,
    required String thumbPath,
    required int width,
    required int height,
    required int bytes,
    required String kind,
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : filmRollId = Value(filmRollId),
       path = Value(path),
       thumbPath = Value(thumbPath),
       width = Value(width),
       height = Value(height),
       bytes = Value(bytes),
       kind = Value(kind),
       createdAt = Value(createdAt);
  static Insertable<RollImage> custom({
    Expression<int>? id,
    Expression<int>? filmRollId,
    Expression<String>? path,
    Expression<String>? thumbPath,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? bytes,
    Expression<String>? kind,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filmRollId != null) 'film_roll_id': filmRollId,
      if (path != null) 'path': path,
      if (thumbPath != null) 'thumb_path': thumbPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (bytes != null) 'bytes': bytes,
      if (kind != null) 'kind': kind,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  RollImagesCompanion copyWith({
    Value<int>? id,
    Value<int>? filmRollId,
    Value<String>? path,
    Value<String>? thumbPath,
    Value<int>? width,
    Value<int>? height,
    Value<int>? bytes,
    Value<String>? kind,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return RollImagesCompanion(
      id: id ?? this.id,
      filmRollId: filmRollId ?? this.filmRollId,
      path: path ?? this.path,
      thumbPath: thumbPath ?? this.thumbPath,
      width: width ?? this.width,
      height: height ?? this.height,
      bytes: bytes ?? this.bytes,
      kind: kind ?? this.kind,
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
    if (filmRollId.present) {
      map['film_roll_id'] = Variable<int>(filmRollId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (thumbPath.present) {
      map['thumb_path'] = Variable<String>(thumbPath.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
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
    return (StringBuffer('RollImagesCompanion(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('path: $path, ')
          ..write('thumbPath: $thumbPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('bytes: $bytes, ')
          ..write('kind: $kind, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FilmRollsTable extends FilmRolls
    with TableInfo<$FilmRollsTable, FilmRoll> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FilmRollsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    check: () => ComparableExpr(sequenceNumber).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _filmStockIdMeta = const VerificationMeta(
    'filmStockId',
  );
  @override
  late final GeneratedColumn<int> filmStockId = GeneratedColumn<int>(
    'film_stock_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES film_stocks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _filmNameMeta = const VerificationMeta(
    'filmName',
  );
  @override
  late final GeneratedColumn<String> filmName = GeneratedColumn<String>(
    'film_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    check: () => format.isIn(filmFormatKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nominalIsoMeta = const VerificationMeta(
    'nominalIso',
  );
  @override
  late final GeneratedColumn<int> nominalIso = GeneratedColumn<int>(
    'nominal_iso',
    aliasedName,
    false,
    check: () => ComparableExpr(nominalIso).isBetweenValues(1, 100000),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exposedIsoMeta = const VerificationMeta(
    'exposedIso',
  );
  @override
  late final GeneratedColumn<int> exposedIso = GeneratedColumn<int>(
    'exposed_iso',
    aliasedName,
    false,
    check: () => ComparableExpr(exposedIso).isBetweenValues(1, 100000),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cameraIdMeta = const VerificationMeta(
    'cameraId',
  );
  @override
  late final GeneratedColumn<int> cameraId = GeneratedColumn<int>(
    'camera_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cameras (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _loadedAtMeta = const VerificationMeta(
    'loadedAt',
  );
  @override
  late final GeneratedColumn<String> loadedAt = GeneratedColumn<String>(
    'loaded_at',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<String> finishedAt = GeneratedColumn<String>(
    'finished_at',
    aliasedName,
    true,
    check: () =>
        finishedAt.isNull() |
        loadedAt.isNull() |
        ComparableExpr(finishedAt).isBiggerOrEqual(loadedAt),
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _framesMeta = const VerificationMeta('frames');
  @override
  late final GeneratedColumn<int> frames = GeneratedColumn<int>(
    'frames',
    aliasedName,
    false,
    check: () => ComparableExpr(frames).isBetweenValues(1, 1000),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 120),
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
    check: () => status.isIn(rollStatusKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costCentsMeta = const VerificationMeta(
    'costCents',
  );
  @override
  late final GeneratedColumn<int> costCents = GeneratedColumn<int>(
    'cost_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(costCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImageIdMeta = const VerificationMeta(
    'coverImageId',
  );
  @override
  late final GeneratedColumn<int> coverImageId = GeneratedColumn<int>(
    'cover_image_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES roll_images (id) ON DELETE SET NULL',
    ),
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
    sequenceNumber,
    filmStockId,
    filmName,
    format,
    nominalIso,
    exposedIso,
    cameraId,
    loadedAt,
    finishedAt,
    frames,
    title,
    note,
    status,
    costCents,
    coverImageId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'film_rolls';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilmRoll> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sequence_number')) {
      context.handle(
        _sequenceNumberMeta,
        sequenceNumber.isAcceptableOrUnknown(
          data['sequence_number']!,
          _sequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceNumberMeta);
    }
    if (data.containsKey('film_stock_id')) {
      context.handle(
        _filmStockIdMeta,
        filmStockId.isAcceptableOrUnknown(
          data['film_stock_id']!,
          _filmStockIdMeta,
        ),
      );
    }
    if (data.containsKey('film_name')) {
      context.handle(
        _filmNameMeta,
        filmName.isAcceptableOrUnknown(data['film_name']!, _filmNameMeta),
      );
    } else if (isInserting) {
      context.missing(_filmNameMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('nominal_iso')) {
      context.handle(
        _nominalIsoMeta,
        nominalIso.isAcceptableOrUnknown(data['nominal_iso']!, _nominalIsoMeta),
      );
    } else if (isInserting) {
      context.missing(_nominalIsoMeta);
    }
    if (data.containsKey('exposed_iso')) {
      context.handle(
        _exposedIsoMeta,
        exposedIso.isAcceptableOrUnknown(data['exposed_iso']!, _exposedIsoMeta),
      );
    } else if (isInserting) {
      context.missing(_exposedIsoMeta);
    }
    if (data.containsKey('camera_id')) {
      context.handle(
        _cameraIdMeta,
        cameraId.isAcceptableOrUnknown(data['camera_id']!, _cameraIdMeta),
      );
    }
    if (data.containsKey('loaded_at')) {
      context.handle(
        _loadedAtMeta,
        loadedAt.isAcceptableOrUnknown(data['loaded_at']!, _loadedAtMeta),
      );
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('frames')) {
      context.handle(
        _framesMeta,
        frames.isAcceptableOrUnknown(data['frames']!, _framesMeta),
      );
    } else if (isInserting) {
      context.missing(_framesMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
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
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('cost_cents')) {
      context.handle(
        _costCentsMeta,
        costCents.isAcceptableOrUnknown(data['cost_cents']!, _costCentsMeta),
      );
    }
    if (data.containsKey('cover_image_id')) {
      context.handle(
        _coverImageIdMeta,
        coverImageId.isAcceptableOrUnknown(
          data['cover_image_id']!,
          _coverImageIdMeta,
        ),
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
  FilmRoll map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilmRoll(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      filmStockId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}film_stock_id'],
      ),
      filmName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}film_name'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      nominalIso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nominal_iso'],
      )!,
      exposedIso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exposed_iso'],
      )!,
      cameraId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}camera_id'],
      ),
      loadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loaded_at'],
      ),
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finished_at'],
      ),
      frames: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frames'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      costCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_cents'],
      ),
      coverImageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_image_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FilmRollsTable createAlias(String alias) {
    return $FilmRollsTable(attachedDatabase, alias);
  }
}

class FilmRoll extends DataClass implements Insertable<FilmRoll> {
  final int id;

  /// Il "#17": `max + 1`, assegnato da `FilmRepository.addRoll`. E' anche l'indirizzo del QR
  /// (`filmtracker://roll/<n>`, F6.12), quindi non si riusa: UNIQUE.
  final int sequenceNumber;
  final int? filmStockId;

  /// ⚑ Denormalizzato ("Kodak Portra 400"): se l'utente cancella una pellicola
  /// personalizzata, i rullini continuano a dire che cosa erano.
  final String filmName;
  final String format;
  final int nominalIso;

  /// Push/pull: se diverso da [nominalIso] la UI lo evidenzia.
  final int exposedIso;
  final int? cameraId;

  /// `YYYY-MM-DD`.
  final String? loadedAt;

  /// `YYYY-MM-DD`. Non prima del caricamento (il confronto fra testi ISO e' cronologico).
  final String? finishedAt;

  /// Fotogrammi nominali: 36, 24, 12, 16...
  final int frames;

  /// "Praga - settembre 2026".
  final String? title;
  final String? note;

  /// `RollStatus.key`.
  final String status;

  /// Costo della pellicola.
  final int? costCents;

  /// La copertina dell'archivio. ⚑ Che sia un'immagine **di questo rullino** lo controlla
  /// `FilmRepository.setCoverImage`: un CHECK non puo' leggere un'altra tabella.
  final int? coverImageId;
  final int createdAt;
  const FilmRoll({
    required this.id,
    required this.sequenceNumber,
    this.filmStockId,
    required this.filmName,
    required this.format,
    required this.nominalIso,
    required this.exposedIso,
    this.cameraId,
    this.loadedAt,
    this.finishedAt,
    required this.frames,
    this.title,
    this.note,
    required this.status,
    this.costCents,
    this.coverImageId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    if (!nullToAbsent || filmStockId != null) {
      map['film_stock_id'] = Variable<int>(filmStockId);
    }
    map['film_name'] = Variable<String>(filmName);
    map['format'] = Variable<String>(format);
    map['nominal_iso'] = Variable<int>(nominalIso);
    map['exposed_iso'] = Variable<int>(exposedIso);
    if (!nullToAbsent || cameraId != null) {
      map['camera_id'] = Variable<int>(cameraId);
    }
    if (!nullToAbsent || loadedAt != null) {
      map['loaded_at'] = Variable<String>(loadedAt);
    }
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<String>(finishedAt);
    }
    map['frames'] = Variable<int>(frames);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || costCents != null) {
      map['cost_cents'] = Variable<int>(costCents);
    }
    if (!nullToAbsent || coverImageId != null) {
      map['cover_image_id'] = Variable<int>(coverImageId);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  FilmRollsCompanion toCompanion(bool nullToAbsent) {
    return FilmRollsCompanion(
      id: Value(id),
      sequenceNumber: Value(sequenceNumber),
      filmStockId: filmStockId == null && nullToAbsent
          ? const Value.absent()
          : Value(filmStockId),
      filmName: Value(filmName),
      format: Value(format),
      nominalIso: Value(nominalIso),
      exposedIso: Value(exposedIso),
      cameraId: cameraId == null && nullToAbsent
          ? const Value.absent()
          : Value(cameraId),
      loadedAt: loadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(loadedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      frames: Value(frames),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      costCents: costCents == null && nullToAbsent
          ? const Value.absent()
          : Value(costCents),
      coverImageId: coverImageId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageId),
      createdAt: Value(createdAt),
    );
  }

  factory FilmRoll.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilmRoll(
      id: serializer.fromJson<int>(json['id']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      filmStockId: serializer.fromJson<int?>(json['filmStockId']),
      filmName: serializer.fromJson<String>(json['filmName']),
      format: serializer.fromJson<String>(json['format']),
      nominalIso: serializer.fromJson<int>(json['nominalIso']),
      exposedIso: serializer.fromJson<int>(json['exposedIso']),
      cameraId: serializer.fromJson<int?>(json['cameraId']),
      loadedAt: serializer.fromJson<String?>(json['loadedAt']),
      finishedAt: serializer.fromJson<String?>(json['finishedAt']),
      frames: serializer.fromJson<int>(json['frames']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      costCents: serializer.fromJson<int?>(json['costCents']),
      coverImageId: serializer.fromJson<int?>(json['coverImageId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'filmStockId': serializer.toJson<int?>(filmStockId),
      'filmName': serializer.toJson<String>(filmName),
      'format': serializer.toJson<String>(format),
      'nominalIso': serializer.toJson<int>(nominalIso),
      'exposedIso': serializer.toJson<int>(exposedIso),
      'cameraId': serializer.toJson<int?>(cameraId),
      'loadedAt': serializer.toJson<String?>(loadedAt),
      'finishedAt': serializer.toJson<String?>(finishedAt),
      'frames': serializer.toJson<int>(frames),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'costCents': serializer.toJson<int?>(costCents),
      'coverImageId': serializer.toJson<int?>(coverImageId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  FilmRoll copyWith({
    int? id,
    int? sequenceNumber,
    Value<int?> filmStockId = const Value.absent(),
    String? filmName,
    String? format,
    int? nominalIso,
    int? exposedIso,
    Value<int?> cameraId = const Value.absent(),
    Value<String?> loadedAt = const Value.absent(),
    Value<String?> finishedAt = const Value.absent(),
    int? frames,
    Value<String?> title = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? status,
    Value<int?> costCents = const Value.absent(),
    Value<int?> coverImageId = const Value.absent(),
    int? createdAt,
  }) => FilmRoll(
    id: id ?? this.id,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    filmStockId: filmStockId.present ? filmStockId.value : this.filmStockId,
    filmName: filmName ?? this.filmName,
    format: format ?? this.format,
    nominalIso: nominalIso ?? this.nominalIso,
    exposedIso: exposedIso ?? this.exposedIso,
    cameraId: cameraId.present ? cameraId.value : this.cameraId,
    loadedAt: loadedAt.present ? loadedAt.value : this.loadedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    frames: frames ?? this.frames,
    title: title.present ? title.value : this.title,
    note: note.present ? note.value : this.note,
    status: status ?? this.status,
    costCents: costCents.present ? costCents.value : this.costCents,
    coverImageId: coverImageId.present ? coverImageId.value : this.coverImageId,
    createdAt: createdAt ?? this.createdAt,
  );
  FilmRoll copyWithCompanion(FilmRollsCompanion data) {
    return FilmRoll(
      id: data.id.present ? data.id.value : this.id,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      filmStockId: data.filmStockId.present
          ? data.filmStockId.value
          : this.filmStockId,
      filmName: data.filmName.present ? data.filmName.value : this.filmName,
      format: data.format.present ? data.format.value : this.format,
      nominalIso: data.nominalIso.present
          ? data.nominalIso.value
          : this.nominalIso,
      exposedIso: data.exposedIso.present
          ? data.exposedIso.value
          : this.exposedIso,
      cameraId: data.cameraId.present ? data.cameraId.value : this.cameraId,
      loadedAt: data.loadedAt.present ? data.loadedAt.value : this.loadedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      frames: data.frames.present ? data.frames.value : this.frames,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      costCents: data.costCents.present ? data.costCents.value : this.costCents,
      coverImageId: data.coverImageId.present
          ? data.coverImageId.value
          : this.coverImageId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilmRoll(')
          ..write('id: $id, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('filmStockId: $filmStockId, ')
          ..write('filmName: $filmName, ')
          ..write('format: $format, ')
          ..write('nominalIso: $nominalIso, ')
          ..write('exposedIso: $exposedIso, ')
          ..write('cameraId: $cameraId, ')
          ..write('loadedAt: $loadedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('frames: $frames, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('costCents: $costCents, ')
          ..write('coverImageId: $coverImageId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sequenceNumber,
    filmStockId,
    filmName,
    format,
    nominalIso,
    exposedIso,
    cameraId,
    loadedAt,
    finishedAt,
    frames,
    title,
    note,
    status,
    costCents,
    coverImageId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilmRoll &&
          other.id == this.id &&
          other.sequenceNumber == this.sequenceNumber &&
          other.filmStockId == this.filmStockId &&
          other.filmName == this.filmName &&
          other.format == this.format &&
          other.nominalIso == this.nominalIso &&
          other.exposedIso == this.exposedIso &&
          other.cameraId == this.cameraId &&
          other.loadedAt == this.loadedAt &&
          other.finishedAt == this.finishedAt &&
          other.frames == this.frames &&
          other.title == this.title &&
          other.note == this.note &&
          other.status == this.status &&
          other.costCents == this.costCents &&
          other.coverImageId == this.coverImageId &&
          other.createdAt == this.createdAt);
}

class FilmRollsCompanion extends UpdateCompanion<FilmRoll> {
  final Value<int> id;
  final Value<int> sequenceNumber;
  final Value<int?> filmStockId;
  final Value<String> filmName;
  final Value<String> format;
  final Value<int> nominalIso;
  final Value<int> exposedIso;
  final Value<int?> cameraId;
  final Value<String?> loadedAt;
  final Value<String?> finishedAt;
  final Value<int> frames;
  final Value<String?> title;
  final Value<String?> note;
  final Value<String> status;
  final Value<int?> costCents;
  final Value<int?> coverImageId;
  final Value<int> createdAt;
  const FilmRollsCompanion({
    this.id = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.filmStockId = const Value.absent(),
    this.filmName = const Value.absent(),
    this.format = const Value.absent(),
    this.nominalIso = const Value.absent(),
    this.exposedIso = const Value.absent(),
    this.cameraId = const Value.absent(),
    this.loadedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.frames = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.costCents = const Value.absent(),
    this.coverImageId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FilmRollsCompanion.insert({
    this.id = const Value.absent(),
    required int sequenceNumber,
    this.filmStockId = const Value.absent(),
    required String filmName,
    required String format,
    required int nominalIso,
    required int exposedIso,
    this.cameraId = const Value.absent(),
    this.loadedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    required int frames,
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    required String status,
    this.costCents = const Value.absent(),
    this.coverImageId = const Value.absent(),
    required int createdAt,
  }) : sequenceNumber = Value(sequenceNumber),
       filmName = Value(filmName),
       format = Value(format),
       nominalIso = Value(nominalIso),
       exposedIso = Value(exposedIso),
       frames = Value(frames),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<FilmRoll> custom({
    Expression<int>? id,
    Expression<int>? sequenceNumber,
    Expression<int>? filmStockId,
    Expression<String>? filmName,
    Expression<String>? format,
    Expression<int>? nominalIso,
    Expression<int>? exposedIso,
    Expression<int>? cameraId,
    Expression<String>? loadedAt,
    Expression<String>? finishedAt,
    Expression<int>? frames,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? status,
    Expression<int>? costCents,
    Expression<int>? coverImageId,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (filmStockId != null) 'film_stock_id': filmStockId,
      if (filmName != null) 'film_name': filmName,
      if (format != null) 'format': format,
      if (nominalIso != null) 'nominal_iso': nominalIso,
      if (exposedIso != null) 'exposed_iso': exposedIso,
      if (cameraId != null) 'camera_id': cameraId,
      if (loadedAt != null) 'loaded_at': loadedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (frames != null) 'frames': frames,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (costCents != null) 'cost_cents': costCents,
      if (coverImageId != null) 'cover_image_id': coverImageId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FilmRollsCompanion copyWith({
    Value<int>? id,
    Value<int>? sequenceNumber,
    Value<int?>? filmStockId,
    Value<String>? filmName,
    Value<String>? format,
    Value<int>? nominalIso,
    Value<int>? exposedIso,
    Value<int?>? cameraId,
    Value<String?>? loadedAt,
    Value<String?>? finishedAt,
    Value<int>? frames,
    Value<String?>? title,
    Value<String?>? note,
    Value<String>? status,
    Value<int?>? costCents,
    Value<int?>? coverImageId,
    Value<int>? createdAt,
  }) {
    return FilmRollsCompanion(
      id: id ?? this.id,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      filmStockId: filmStockId ?? this.filmStockId,
      filmName: filmName ?? this.filmName,
      format: format ?? this.format,
      nominalIso: nominalIso ?? this.nominalIso,
      exposedIso: exposedIso ?? this.exposedIso,
      cameraId: cameraId ?? this.cameraId,
      loadedAt: loadedAt ?? this.loadedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      frames: frames ?? this.frames,
      title: title ?? this.title,
      note: note ?? this.note,
      status: status ?? this.status,
      costCents: costCents ?? this.costCents,
      coverImageId: coverImageId ?? this.coverImageId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (filmStockId.present) {
      map['film_stock_id'] = Variable<int>(filmStockId.value);
    }
    if (filmName.present) {
      map['film_name'] = Variable<String>(filmName.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (nominalIso.present) {
      map['nominal_iso'] = Variable<int>(nominalIso.value);
    }
    if (exposedIso.present) {
      map['exposed_iso'] = Variable<int>(exposedIso.value);
    }
    if (cameraId.present) {
      map['camera_id'] = Variable<int>(cameraId.value);
    }
    if (loadedAt.present) {
      map['loaded_at'] = Variable<String>(loadedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<String>(finishedAt.value);
    }
    if (frames.present) {
      map['frames'] = Variable<int>(frames.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (costCents.present) {
      map['cost_cents'] = Variable<int>(costCents.value);
    }
    if (coverImageId.present) {
      map['cover_image_id'] = Variable<int>(coverImageId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FilmRollsCompanion(')
          ..write('id: $id, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('filmStockId: $filmStockId, ')
          ..write('filmName: $filmName, ')
          ..write('format: $format, ')
          ..write('nominalIso: $nominalIso, ')
          ..write('exposedIso: $exposedIso, ')
          ..write('cameraId: $cameraId, ')
          ..write('loadedAt: $loadedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('frames: $frames, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('costCents: $costCents, ')
          ..write('coverImageId: $coverImageId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DevelopmentsTable extends Developments
    with TableInfo<$DevelopmentsTable, Development> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevelopmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filmRollIdMeta = const VerificationMeta(
    'filmRollId',
  );
  @override
  late final GeneratedColumn<int> filmRollId = GeneratedColumn<int>(
    'film_roll_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES film_rolls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _laboratoryMeta = const VerificationMeta(
    'laboratory',
  );
  @override
  late final GeneratedColumn<String> laboratory = GeneratedColumn<String>(
    'laboratory',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<String> submittedAt = GeneratedColumn<String>(
    'submitted_at',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _returnedAtMeta = const VerificationMeta(
    'returnedAt',
  );
  @override
  late final GeneratedColumn<String> returnedAt = GeneratedColumn<String>(
    'returned_at',
    aliasedName,
    true,
    check: () =>
        returnedAt.isNull() |
        submittedAt.isNull() |
        ComparableExpr(returnedAt).isBiggerOrEqual(submittedAt),
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _developmentCostCentsMeta =
      const VerificationMeta('developmentCostCents');
  @override
  late final GeneratedColumn<int> developmentCostCents = GeneratedColumn<int>(
    'development_cost_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(developmentCostCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scanCostCentsMeta = const VerificationMeta(
    'scanCostCents',
  );
  @override
  late final GeneratedColumn<int> scanCostCents = GeneratedColumn<int>(
    'scan_cost_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(scanCostCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processMeta = const VerificationMeta(
    'process',
  );
  @override
  late final GeneratedColumn<String> process = GeneratedColumn<String>(
    'process',
    aliasedName,
    true,
    check: () => process.isIn(filmProcessKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selfDevelopedMeta = const VerificationMeta(
    'selfDeveloped',
  );
  @override
  late final GeneratedColumn<bool> selfDeveloped = GeneratedColumn<bool>(
    'self_developed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("self_developed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    filmRollId,
    laboratory,
    submittedAt,
    returnedAt,
    developmentCostCents,
    scanCostCents,
    process,
    selfDeveloped,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'developments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Development> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('film_roll_id')) {
      context.handle(
        _filmRollIdMeta,
        filmRollId.isAcceptableOrUnknown(
          data['film_roll_id']!,
          _filmRollIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filmRollIdMeta);
    }
    if (data.containsKey('laboratory')) {
      context.handle(
        _laboratoryMeta,
        laboratory.isAcceptableOrUnknown(data['laboratory']!, _laboratoryMeta),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
      );
    }
    if (data.containsKey('development_cost_cents')) {
      context.handle(
        _developmentCostCentsMeta,
        developmentCostCents.isAcceptableOrUnknown(
          data['development_cost_cents']!,
          _developmentCostCentsMeta,
        ),
      );
    }
    if (data.containsKey('scan_cost_cents')) {
      context.handle(
        _scanCostCentsMeta,
        scanCostCents.isAcceptableOrUnknown(
          data['scan_cost_cents']!,
          _scanCostCentsMeta,
        ),
      );
    }
    if (data.containsKey('process')) {
      context.handle(
        _processMeta,
        process.isAcceptableOrUnknown(data['process']!, _processMeta),
      );
    }
    if (data.containsKey('self_developed')) {
      context.handle(
        _selfDevelopedMeta,
        selfDeveloped.isAcceptableOrUnknown(
          data['self_developed']!,
          _selfDevelopedMeta,
        ),
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
  Development map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Development(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filmRollId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}film_roll_id'],
      )!,
      laboratory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}laboratory'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitted_at'],
      ),
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}returned_at'],
      ),
      developmentCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}development_cost_cents'],
      ),
      scanCostCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scan_cost_cents'],
      ),
      process: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}process'],
      ),
      selfDeveloped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}self_developed'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $DevelopmentsTable createAlias(String alias) {
    return $DevelopmentsTable(attachedDatabase, alias);
  }
}

class Development extends DataClass implements Insertable<Development> {
  final int id;
  final int filmRollId;

  /// ⚑ Nullable, anche se F6.2 lo da' obbligatorio: lo sviluppo in casa non ha un
  /// laboratorio, e chi ha dimenticato il nome deve poter registrare lo stesso le date.
  final String? laboratory;
  final String? submittedAt;
  final String? returnedAt;
  final int? developmentCostCents;
  final int? scanCostCents;

  /// `FilmProcess.key`; null se non indicato.
  final String? process;
  final bool selfDeveloped;
  final String? note;
  const Development({
    required this.id,
    required this.filmRollId,
    this.laboratory,
    this.submittedAt,
    this.returnedAt,
    this.developmentCostCents,
    this.scanCostCents,
    this.process,
    required this.selfDeveloped,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['film_roll_id'] = Variable<int>(filmRollId);
    if (!nullToAbsent || laboratory != null) {
      map['laboratory'] = Variable<String>(laboratory);
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<String>(submittedAt);
    }
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<String>(returnedAt);
    }
    if (!nullToAbsent || developmentCostCents != null) {
      map['development_cost_cents'] = Variable<int>(developmentCostCents);
    }
    if (!nullToAbsent || scanCostCents != null) {
      map['scan_cost_cents'] = Variable<int>(scanCostCents);
    }
    if (!nullToAbsent || process != null) {
      map['process'] = Variable<String>(process);
    }
    map['self_developed'] = Variable<bool>(selfDeveloped);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  DevelopmentsCompanion toCompanion(bool nullToAbsent) {
    return DevelopmentsCompanion(
      id: Value(id),
      filmRollId: Value(filmRollId),
      laboratory: laboratory == null && nullToAbsent
          ? const Value.absent()
          : Value(laboratory),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
      developmentCostCents: developmentCostCents == null && nullToAbsent
          ? const Value.absent()
          : Value(developmentCostCents),
      scanCostCents: scanCostCents == null && nullToAbsent
          ? const Value.absent()
          : Value(scanCostCents),
      process: process == null && nullToAbsent
          ? const Value.absent()
          : Value(process),
      selfDeveloped: Value(selfDeveloped),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Development.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Development(
      id: serializer.fromJson<int>(json['id']),
      filmRollId: serializer.fromJson<int>(json['filmRollId']),
      laboratory: serializer.fromJson<String?>(json['laboratory']),
      submittedAt: serializer.fromJson<String?>(json['submittedAt']),
      returnedAt: serializer.fromJson<String?>(json['returnedAt']),
      developmentCostCents: serializer.fromJson<int?>(
        json['developmentCostCents'],
      ),
      scanCostCents: serializer.fromJson<int?>(json['scanCostCents']),
      process: serializer.fromJson<String?>(json['process']),
      selfDeveloped: serializer.fromJson<bool>(json['selfDeveloped']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filmRollId': serializer.toJson<int>(filmRollId),
      'laboratory': serializer.toJson<String?>(laboratory),
      'submittedAt': serializer.toJson<String?>(submittedAt),
      'returnedAt': serializer.toJson<String?>(returnedAt),
      'developmentCostCents': serializer.toJson<int?>(developmentCostCents),
      'scanCostCents': serializer.toJson<int?>(scanCostCents),
      'process': serializer.toJson<String?>(process),
      'selfDeveloped': serializer.toJson<bool>(selfDeveloped),
      'note': serializer.toJson<String?>(note),
    };
  }

  Development copyWith({
    int? id,
    int? filmRollId,
    Value<String?> laboratory = const Value.absent(),
    Value<String?> submittedAt = const Value.absent(),
    Value<String?> returnedAt = const Value.absent(),
    Value<int?> developmentCostCents = const Value.absent(),
    Value<int?> scanCostCents = const Value.absent(),
    Value<String?> process = const Value.absent(),
    bool? selfDeveloped,
    Value<String?> note = const Value.absent(),
  }) => Development(
    id: id ?? this.id,
    filmRollId: filmRollId ?? this.filmRollId,
    laboratory: laboratory.present ? laboratory.value : this.laboratory,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
    developmentCostCents: developmentCostCents.present
        ? developmentCostCents.value
        : this.developmentCostCents,
    scanCostCents: scanCostCents.present
        ? scanCostCents.value
        : this.scanCostCents,
    process: process.present ? process.value : this.process,
    selfDeveloped: selfDeveloped ?? this.selfDeveloped,
    note: note.present ? note.value : this.note,
  );
  Development copyWithCompanion(DevelopmentsCompanion data) {
    return Development(
      id: data.id.present ? data.id.value : this.id,
      filmRollId: data.filmRollId.present
          ? data.filmRollId.value
          : this.filmRollId,
      laboratory: data.laboratory.present
          ? data.laboratory.value
          : this.laboratory,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
      developmentCostCents: data.developmentCostCents.present
          ? data.developmentCostCents.value
          : this.developmentCostCents,
      scanCostCents: data.scanCostCents.present
          ? data.scanCostCents.value
          : this.scanCostCents,
      process: data.process.present ? data.process.value : this.process,
      selfDeveloped: data.selfDeveloped.present
          ? data.selfDeveloped.value
          : this.selfDeveloped,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Development(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('laboratory: $laboratory, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('developmentCostCents: $developmentCostCents, ')
          ..write('scanCostCents: $scanCostCents, ')
          ..write('process: $process, ')
          ..write('selfDeveloped: $selfDeveloped, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filmRollId,
    laboratory,
    submittedAt,
    returnedAt,
    developmentCostCents,
    scanCostCents,
    process,
    selfDeveloped,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Development &&
          other.id == this.id &&
          other.filmRollId == this.filmRollId &&
          other.laboratory == this.laboratory &&
          other.submittedAt == this.submittedAt &&
          other.returnedAt == this.returnedAt &&
          other.developmentCostCents == this.developmentCostCents &&
          other.scanCostCents == this.scanCostCents &&
          other.process == this.process &&
          other.selfDeveloped == this.selfDeveloped &&
          other.note == this.note);
}

class DevelopmentsCompanion extends UpdateCompanion<Development> {
  final Value<int> id;
  final Value<int> filmRollId;
  final Value<String?> laboratory;
  final Value<String?> submittedAt;
  final Value<String?> returnedAt;
  final Value<int?> developmentCostCents;
  final Value<int?> scanCostCents;
  final Value<String?> process;
  final Value<bool> selfDeveloped;
  final Value<String?> note;
  const DevelopmentsCompanion({
    this.id = const Value.absent(),
    this.filmRollId = const Value.absent(),
    this.laboratory = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.developmentCostCents = const Value.absent(),
    this.scanCostCents = const Value.absent(),
    this.process = const Value.absent(),
    this.selfDeveloped = const Value.absent(),
    this.note = const Value.absent(),
  });
  DevelopmentsCompanion.insert({
    this.id = const Value.absent(),
    required int filmRollId,
    this.laboratory = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.developmentCostCents = const Value.absent(),
    this.scanCostCents = const Value.absent(),
    this.process = const Value.absent(),
    this.selfDeveloped = const Value.absent(),
    this.note = const Value.absent(),
  }) : filmRollId = Value(filmRollId);
  static Insertable<Development> custom({
    Expression<int>? id,
    Expression<int>? filmRollId,
    Expression<String>? laboratory,
    Expression<String>? submittedAt,
    Expression<String>? returnedAt,
    Expression<int>? developmentCostCents,
    Expression<int>? scanCostCents,
    Expression<String>? process,
    Expression<bool>? selfDeveloped,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filmRollId != null) 'film_roll_id': filmRollId,
      if (laboratory != null) 'laboratory': laboratory,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (developmentCostCents != null)
        'development_cost_cents': developmentCostCents,
      if (scanCostCents != null) 'scan_cost_cents': scanCostCents,
      if (process != null) 'process': process,
      if (selfDeveloped != null) 'self_developed': selfDeveloped,
      if (note != null) 'note': note,
    });
  }

  DevelopmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? filmRollId,
    Value<String?>? laboratory,
    Value<String?>? submittedAt,
    Value<String?>? returnedAt,
    Value<int?>? developmentCostCents,
    Value<int?>? scanCostCents,
    Value<String?>? process,
    Value<bool>? selfDeveloped,
    Value<String?>? note,
  }) {
    return DevelopmentsCompanion(
      id: id ?? this.id,
      filmRollId: filmRollId ?? this.filmRollId,
      laboratory: laboratory ?? this.laboratory,
      submittedAt: submittedAt ?? this.submittedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      developmentCostCents: developmentCostCents ?? this.developmentCostCents,
      scanCostCents: scanCostCents ?? this.scanCostCents,
      process: process ?? this.process,
      selfDeveloped: selfDeveloped ?? this.selfDeveloped,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filmRollId.present) {
      map['film_roll_id'] = Variable<int>(filmRollId.value);
    }
    if (laboratory.present) {
      map['laboratory'] = Variable<String>(laboratory.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<String>(submittedAt.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<String>(returnedAt.value);
    }
    if (developmentCostCents.present) {
      map['development_cost_cents'] = Variable<int>(developmentCostCents.value);
    }
    if (scanCostCents.present) {
      map['scan_cost_cents'] = Variable<int>(scanCostCents.value);
    }
    if (process.present) {
      map['process'] = Variable<String>(process.value);
    }
    if (selfDeveloped.present) {
      map['self_developed'] = Variable<bool>(selfDeveloped.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevelopmentsCompanion(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('laboratory: $laboratory, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('developmentCostCents: $developmentCostCents, ')
          ..write('scanCostCents: $scanCostCents, ')
          ..write('process: $process, ')
          ..write('selfDeveloped: $selfDeveloped, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $PrintOrdersTable extends PrintOrders
    with TableInfo<$PrintOrdersTable, PrintOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintOrdersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _filmRollIdMeta = const VerificationMeta(
    'filmRollId',
  );
  @override
  late final GeneratedColumn<int> filmRollId = GeneratedColumn<int>(
    'film_roll_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES film_rolls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _laboratoryMeta = const VerificationMeta(
    'laboratory',
  );
  @override
  late final GeneratedColumn<String> laboratory = GeneratedColumn<String>(
    'laboratory',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 80),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<String> submittedAt = GeneratedColumn<String>(
    'submitted_at',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _returnedAtMeta = const VerificationMeta(
    'returnedAt',
  );
  @override
  late final GeneratedColumn<String> returnedAt = GeneratedColumn<String>(
    'returned_at',
    aliasedName,
    true,
    check: () =>
        returnedAt.isNull() |
        submittedAt.isNull() |
        ComparableExpr(returnedAt).isBiggerOrEqual(submittedAt),
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfPrintsMeta = const VerificationMeta(
    'numberOfPrints',
  );
  @override
  late final GeneratedColumn<int> numberOfPrints = GeneratedColumn<int>(
    'number_of_prints',
    aliasedName,
    true,
    check: () => ComparableExpr(numberOfPrints).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costCentsMeta = const VerificationMeta(
    'costCents',
  );
  @override
  late final GeneratedColumn<int> costCents = GeneratedColumn<int>(
    'cost_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(costCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
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
    filmRollId,
    laboratory,
    submittedAt,
    returnedAt,
    format,
    numberOfPrints,
    costCents,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'print_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrintOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('film_roll_id')) {
      context.handle(
        _filmRollIdMeta,
        filmRollId.isAcceptableOrUnknown(
          data['film_roll_id']!,
          _filmRollIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filmRollIdMeta);
    }
    if (data.containsKey('laboratory')) {
      context.handle(
        _laboratoryMeta,
        laboratory.isAcceptableOrUnknown(data['laboratory']!, _laboratoryMeta),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('number_of_prints')) {
      context.handle(
        _numberOfPrintsMeta,
        numberOfPrints.isAcceptableOrUnknown(
          data['number_of_prints']!,
          _numberOfPrintsMeta,
        ),
      );
    }
    if (data.containsKey('cost_cents')) {
      context.handle(
        _costCentsMeta,
        costCents.isAcceptableOrUnknown(data['cost_cents']!, _costCentsMeta),
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
  PrintOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      filmRollId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}film_roll_id'],
      )!,
      laboratory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}laboratory'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}submitted_at'],
      ),
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}returned_at'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      numberOfPrints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_prints'],
      ),
      costCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_cents'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PrintOrdersTable createAlias(String alias) {
    return $PrintOrdersTable(attachedDatabase, alias);
  }
}

class PrintOrder extends DataClass implements Insertable<PrintOrder> {
  final int id;
  final int filmRollId;

  /// Nullable per la stessa ragione di `Developments.laboratory`.
  final String? laboratory;
  final String? submittedAt;
  final String? returnedAt;

  /// Testo libero: "10x15", "13x18 opaco".
  final String? format;
  final int? numberOfPrints;
  final int? costCents;
  final String? note;
  const PrintOrder({
    required this.id,
    required this.filmRollId,
    this.laboratory,
    this.submittedAt,
    this.returnedAt,
    this.format,
    this.numberOfPrints,
    this.costCents,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['film_roll_id'] = Variable<int>(filmRollId);
    if (!nullToAbsent || laboratory != null) {
      map['laboratory'] = Variable<String>(laboratory);
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<String>(submittedAt);
    }
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<String>(returnedAt);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || numberOfPrints != null) {
      map['number_of_prints'] = Variable<int>(numberOfPrints);
    }
    if (!nullToAbsent || costCents != null) {
      map['cost_cents'] = Variable<int>(costCents);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PrintOrdersCompanion toCompanion(bool nullToAbsent) {
    return PrintOrdersCompanion(
      id: Value(id),
      filmRollId: Value(filmRollId),
      laboratory: laboratory == null && nullToAbsent
          ? const Value.absent()
          : Value(laboratory),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      numberOfPrints: numberOfPrints == null && nullToAbsent
          ? const Value.absent()
          : Value(numberOfPrints),
      costCents: costCents == null && nullToAbsent
          ? const Value.absent()
          : Value(costCents),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PrintOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintOrder(
      id: serializer.fromJson<int>(json['id']),
      filmRollId: serializer.fromJson<int>(json['filmRollId']),
      laboratory: serializer.fromJson<String?>(json['laboratory']),
      submittedAt: serializer.fromJson<String?>(json['submittedAt']),
      returnedAt: serializer.fromJson<String?>(json['returnedAt']),
      format: serializer.fromJson<String?>(json['format']),
      numberOfPrints: serializer.fromJson<int?>(json['numberOfPrints']),
      costCents: serializer.fromJson<int?>(json['costCents']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'filmRollId': serializer.toJson<int>(filmRollId),
      'laboratory': serializer.toJson<String?>(laboratory),
      'submittedAt': serializer.toJson<String?>(submittedAt),
      'returnedAt': serializer.toJson<String?>(returnedAt),
      'format': serializer.toJson<String?>(format),
      'numberOfPrints': serializer.toJson<int?>(numberOfPrints),
      'costCents': serializer.toJson<int?>(costCents),
      'note': serializer.toJson<String?>(note),
    };
  }

  PrintOrder copyWith({
    int? id,
    int? filmRollId,
    Value<String?> laboratory = const Value.absent(),
    Value<String?> submittedAt = const Value.absent(),
    Value<String?> returnedAt = const Value.absent(),
    Value<String?> format = const Value.absent(),
    Value<int?> numberOfPrints = const Value.absent(),
    Value<int?> costCents = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => PrintOrder(
    id: id ?? this.id,
    filmRollId: filmRollId ?? this.filmRollId,
    laboratory: laboratory.present ? laboratory.value : this.laboratory,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
    format: format.present ? format.value : this.format,
    numberOfPrints: numberOfPrints.present
        ? numberOfPrints.value
        : this.numberOfPrints,
    costCents: costCents.present ? costCents.value : this.costCents,
    note: note.present ? note.value : this.note,
  );
  PrintOrder copyWithCompanion(PrintOrdersCompanion data) {
    return PrintOrder(
      id: data.id.present ? data.id.value : this.id,
      filmRollId: data.filmRollId.present
          ? data.filmRollId.value
          : this.filmRollId,
      laboratory: data.laboratory.present
          ? data.laboratory.value
          : this.laboratory,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
      format: data.format.present ? data.format.value : this.format,
      numberOfPrints: data.numberOfPrints.present
          ? data.numberOfPrints.value
          : this.numberOfPrints,
      costCents: data.costCents.present ? data.costCents.value : this.costCents,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintOrder(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('laboratory: $laboratory, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('format: $format, ')
          ..write('numberOfPrints: $numberOfPrints, ')
          ..write('costCents: $costCents, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    filmRollId,
    laboratory,
    submittedAt,
    returnedAt,
    format,
    numberOfPrints,
    costCents,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintOrder &&
          other.id == this.id &&
          other.filmRollId == this.filmRollId &&
          other.laboratory == this.laboratory &&
          other.submittedAt == this.submittedAt &&
          other.returnedAt == this.returnedAt &&
          other.format == this.format &&
          other.numberOfPrints == this.numberOfPrints &&
          other.costCents == this.costCents &&
          other.note == this.note);
}

class PrintOrdersCompanion extends UpdateCompanion<PrintOrder> {
  final Value<int> id;
  final Value<int> filmRollId;
  final Value<String?> laboratory;
  final Value<String?> submittedAt;
  final Value<String?> returnedAt;
  final Value<String?> format;
  final Value<int?> numberOfPrints;
  final Value<int?> costCents;
  final Value<String?> note;
  const PrintOrdersCompanion({
    this.id = const Value.absent(),
    this.filmRollId = const Value.absent(),
    this.laboratory = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.format = const Value.absent(),
    this.numberOfPrints = const Value.absent(),
    this.costCents = const Value.absent(),
    this.note = const Value.absent(),
  });
  PrintOrdersCompanion.insert({
    this.id = const Value.absent(),
    required int filmRollId,
    this.laboratory = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.format = const Value.absent(),
    this.numberOfPrints = const Value.absent(),
    this.costCents = const Value.absent(),
    this.note = const Value.absent(),
  }) : filmRollId = Value(filmRollId);
  static Insertable<PrintOrder> custom({
    Expression<int>? id,
    Expression<int>? filmRollId,
    Expression<String>? laboratory,
    Expression<String>? submittedAt,
    Expression<String>? returnedAt,
    Expression<String>? format,
    Expression<int>? numberOfPrints,
    Expression<int>? costCents,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (filmRollId != null) 'film_roll_id': filmRollId,
      if (laboratory != null) 'laboratory': laboratory,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (format != null) 'format': format,
      if (numberOfPrints != null) 'number_of_prints': numberOfPrints,
      if (costCents != null) 'cost_cents': costCents,
      if (note != null) 'note': note,
    });
  }

  PrintOrdersCompanion copyWith({
    Value<int>? id,
    Value<int>? filmRollId,
    Value<String?>? laboratory,
    Value<String?>? submittedAt,
    Value<String?>? returnedAt,
    Value<String?>? format,
    Value<int?>? numberOfPrints,
    Value<int?>? costCents,
    Value<String?>? note,
  }) {
    return PrintOrdersCompanion(
      id: id ?? this.id,
      filmRollId: filmRollId ?? this.filmRollId,
      laboratory: laboratory ?? this.laboratory,
      submittedAt: submittedAt ?? this.submittedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      format: format ?? this.format,
      numberOfPrints: numberOfPrints ?? this.numberOfPrints,
      costCents: costCents ?? this.costCents,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (filmRollId.present) {
      map['film_roll_id'] = Variable<int>(filmRollId.value);
    }
    if (laboratory.present) {
      map['laboratory'] = Variable<String>(laboratory.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<String>(submittedAt.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<String>(returnedAt.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (numberOfPrints.present) {
      map['number_of_prints'] = Variable<int>(numberOfPrints.value);
    }
    if (costCents.present) {
      map['cost_cents'] = Variable<int>(costCents.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintOrdersCompanion(')
          ..write('id: $id, ')
          ..write('filmRollId: $filmRollId, ')
          ..write('laboratory: $laboratory, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('format: $format, ')
          ..write('numberOfPrints: $numberOfPrints, ')
          ..write('costCents: $costCents, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CamerasTable cameras = $CamerasTable(this);
  late final $FilmStocksTable filmStocks = $FilmStocksTable(this);
  late final $RollImagesTable rollImages = $RollImagesTable(this);
  late final $FilmRollsTable filmRolls = $FilmRollsTable(this);
  late final $DevelopmentsTable developments = $DevelopmentsTable(this);
  late final $PrintOrdersTable printOrders = $PrintOrdersTable(this);
  late final Index idxFilmRollsStatus = Index(
    'idx_film_rolls_status',
    'CREATE INDEX idx_film_rolls_status ON film_rolls (status)',
  );
  late final Index idxFilmRollsCamera = Index(
    'idx_film_rolls_camera',
    'CREATE INDEX idx_film_rolls_camera ON film_rolls (camera_id)',
  );
  late final Index idxFilmRollsStock = Index(
    'idx_film_rolls_stock',
    'CREATE INDEX idx_film_rolls_stock ON film_rolls (film_stock_id)',
  );
  late final Index idxPrintOrdersRoll = Index(
    'idx_print_orders_roll',
    'CREATE INDEX idx_print_orders_roll ON print_orders (film_roll_id)',
  );
  late final Index idxRollImagesRoll = Index(
    'idx_roll_images_roll',
    'CREATE INDEX idx_roll_images_roll ON roll_images (film_roll_id, sort_order)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cameras,
    filmStocks,
    rollImages,
    filmRolls,
    developments,
    printOrders,
    idxFilmRollsStatus,
    idxFilmRollsCamera,
    idxFilmRollsStock,
    idxPrintOrdersRoll,
    idxRollImagesRoll,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'film_rolls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('roll_images', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'film_stocks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('film_rolls', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cameras',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('film_rolls', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'roll_images',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('film_rolls', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'film_rolls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('developments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'film_rolls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('print_orders', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CamerasTableCreateCompanionBuilder = CamerasCompanion Function({
  Value<int> id,
  required String manufacturer,
  required String model,
  required String format,
  Value<String?> note,
  Value<bool> active,
  Value<int> sortOrder,
});
typedef $$CamerasTableUpdateCompanionBuilder = CamerasCompanion Function({
  Value<int> id,
  Value<String> manufacturer,
  Value<String> model,
  Value<String> format,
  Value<String?> note,
  Value<bool> active,
  Value<int> sortOrder,
});

final class $$CamerasTableReferences
    extends BaseReferences<_$AppDatabase, $CamerasTable, Camera> {
  $$CamerasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FilmRollsTable, List<FilmRoll>>
  _filmRollsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.filmRolls,
    aliasName: 'cameras__id__film_rolls__camera_id',
  );

  $$FilmRollsTableProcessedTableManager get filmRollsRefs {
    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.cameraId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_filmRollsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CamerasTableFilterComposer
    extends Composer<_$AppDatabase, $CamerasTable> {
  $$CamerasTableFilterComposer({
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

  ColumnFilters<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

  Expression<bool> filmRollsRefs(
    Expression<bool> Function($$FilmRollsTableFilterComposer f) f,
  ) {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.cameraId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CamerasTableOrderingComposer
    extends Composer<_$AppDatabase, $CamerasTable> {
  $$CamerasTableOrderingComposer({
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

  ColumnOrderings<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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
}

class $$CamerasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CamerasTable> {
  $$CamerasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get manufacturer => $composableBuilder(
    column: $table.manufacturer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> filmRollsRefs<T extends Object>(
    Expression<T> Function($$FilmRollsTableAnnotationComposer a) f,
  ) {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.cameraId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CamerasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CamerasTable,
          Camera,
          $$CamerasTableFilterComposer,
          $$CamerasTableOrderingComposer,
          $$CamerasTableAnnotationComposer,
          $$CamerasTableCreateCompanionBuilder,
          $$CamerasTableUpdateCompanionBuilder,
          (Camera, $$CamerasTableReferences),
          Camera,
          PrefetchHooks Function({bool filmRollsRefs})
        > {
  $$CamerasTableTableManager(_$AppDatabase db, $CamerasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CamerasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CamerasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CamerasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> manufacturer = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CamerasCompanion(
                id: id,
                manufacturer: manufacturer,
                model: model,
                format: format,
                note: note,
                active: active,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String manufacturer,
                required String model,
                required String format,
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CamerasCompanion.insert(
                id: id,
                manufacturer: manufacturer,
                model: model,
                format: format,
                note: note,
                active: active,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CamerasTable, Camera>(table),
                  $$CamerasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (filmRollsRefs) db.filmRolls],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (filmRollsRefs)
                    await $_getPrefetchedData<Camera, $CamerasTable, FilmRoll>(
                      currentTable: table,
                      referencedTable: $$CamerasTableReferences
                          ._filmRollsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CamerasTableReferences(db, table, p0).filmRollsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cameraId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CamerasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CamerasTable,
      Camera,
      $$CamerasTableFilterComposer,
      $$CamerasTableOrderingComposer,
      $$CamerasTableAnnotationComposer,
      $$CamerasTableCreateCompanionBuilder,
      $$CamerasTableUpdateCompanionBuilder,
      (Camera, $$CamerasTableReferences),
      Camera,
      PrefetchHooks Function({bool filmRollsRefs})
    >;
typedef $$FilmStocksTableCreateCompanionBuilder = FilmStocksCompanion Function({
  Value<int> id,
  required String brand,
  required String name,
  required int iso,
  required String process,
  required String format,
  Value<bool> isCustom,
});
typedef $$FilmStocksTableUpdateCompanionBuilder = FilmStocksCompanion Function({
  Value<int> id,
  Value<String> brand,
  Value<String> name,
  Value<int> iso,
  Value<String> process,
  Value<String> format,
  Value<bool> isCustom,
});

final class $$FilmStocksTableReferences
    extends BaseReferences<_$AppDatabase, $FilmStocksTable, FilmStock> {
  $$FilmStocksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FilmRollsTable, List<FilmRoll>>
  _filmRollsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.filmRolls,
    aliasName: 'film_stocks__id__film_rolls__film_stock_id',
  );

  $$FilmRollsTableProcessedTableManager get filmRollsRefs {
    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.filmStockId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_filmRollsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FilmStocksTableFilterComposer
    extends Composer<_$AppDatabase, $FilmStocksTable> {
  $$FilmStocksTableFilterComposer({
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

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iso => $composableBuilder(
    column: $table.iso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> filmRollsRefs(
    Expression<bool> Function($$FilmRollsTableFilterComposer f) f,
  ) {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.filmStockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FilmStocksTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmStocksTable> {
  $$FilmStocksTableOrderingComposer({
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

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iso => $composableBuilder(
    column: $table.iso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FilmStocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmStocksTable> {
  $$FilmStocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get iso =>
      $composableBuilder(column: $table.iso, builder: (column) => column);

  GeneratedColumn<String> get process =>
      $composableBuilder(column: $table.process, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  Expression<T> filmRollsRefs<T extends Object>(
    Expression<T> Function($$FilmRollsTableAnnotationComposer a) f,
  ) {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.filmStockId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FilmStocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmStocksTable,
          FilmStock,
          $$FilmStocksTableFilterComposer,
          $$FilmStocksTableOrderingComposer,
          $$FilmStocksTableAnnotationComposer,
          $$FilmStocksTableCreateCompanionBuilder,
          $$FilmStocksTableUpdateCompanionBuilder,
          (FilmStock, $$FilmStocksTableReferences),
          FilmStock,
          PrefetchHooks Function({bool filmRollsRefs})
        > {
  $$FilmStocksTableTableManager(_$AppDatabase db, $FilmStocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmStocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmStocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmStocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> brand = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> iso = const Value.absent(),
                Value<String> process = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
              }) => FilmStocksCompanion(
                id: id,
                brand: brand,
                name: name,
                iso: iso,
                process: process,
                format: format,
                isCustom: isCustom,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String brand,
                required String name,
                required int iso,
                required String process,
                required String format,
                Value<bool> isCustom = const Value.absent(),
              }) => FilmStocksCompanion.insert(
                id: id,
                brand: brand,
                name: name,
                iso: iso,
                process: process,
                format: format,
                isCustom: isCustom,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FilmStocksTable, FilmStock>(table),
                  $$FilmStocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (filmRollsRefs) db.filmRolls],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (filmRollsRefs)
                    await $_getPrefetchedData<
                      FilmStock,
                      $FilmStocksTable,
                      FilmRoll
                    >(
                      currentTable: table,
                      referencedTable: $$FilmStocksTableReferences
                          ._filmRollsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FilmStocksTableReferences(
                            db,
                            table,
                            p0,
                          ).filmRollsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.filmStockId == item.id,
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

typedef $$FilmStocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmStocksTable,
      FilmStock,
      $$FilmStocksTableFilterComposer,
      $$FilmStocksTableOrderingComposer,
      $$FilmStocksTableAnnotationComposer,
      $$FilmStocksTableCreateCompanionBuilder,
      $$FilmStocksTableUpdateCompanionBuilder,
      (FilmStock, $$FilmStocksTableReferences),
      FilmStock,
      PrefetchHooks Function({bool filmRollsRefs})
    >;
typedef $$RollImagesTableCreateCompanionBuilder = RollImagesCompanion Function({
  Value<int> id,
  required int filmRollId,
  required String path,
  required String thumbPath,
  required int width,
  required int height,
  required int bytes,
  required String kind,
  Value<int> sortOrder,
  required int createdAt,
});
typedef $$RollImagesTableUpdateCompanionBuilder = RollImagesCompanion Function({
  Value<int> id,
  Value<int> filmRollId,
  Value<String> path,
  Value<String> thumbPath,
  Value<int> width,
  Value<int> height,
  Value<int> bytes,
  Value<String> kind,
  Value<int> sortOrder,
  Value<int> createdAt,
});

final class $$RollImagesTableReferences
    extends BaseReferences<_$AppDatabase, $RollImagesTable, RollImage> {
  $$RollImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FilmRollsTable _filmRollIdTable(_$AppDatabase db) =>
      db.filmRolls.createAlias('roll_images__film_roll_id__film_rolls__id');

  $$FilmRollsTableProcessedTableManager get filmRollId {
    final $_column = $_itemColumn<int>('film_roll_id')!;

    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_filmRollIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$FilmRollsTable, List<FilmRoll>>
  _filmRollsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.filmRolls,
    aliasName: 'roll_images__id__film_rolls__cover_image_id',
  );

  $$FilmRollsTableProcessedTableManager get filmRollsRefs {
    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.coverImageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_filmRollsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RollImagesTableFilterComposer
    extends Composer<_$AppDatabase, $RollImagesTable> {
  $$RollImagesTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
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

  $$FilmRollsTableFilterComposer get filmRollId {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> filmRollsRefs(
    Expression<bool> Function($$FilmRollsTableFilterComposer f) f,
  ) {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.coverImageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RollImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $RollImagesTable> {
  $$RollImagesTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbPath => $composableBuilder(
    column: $table.thumbPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
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

  $$FilmRollsTableOrderingComposer get filmRollId {
    final $$FilmRollsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableOrderingComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RollImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RollImagesTable> {
  $$RollImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get thumbPath =>
      $composableBuilder(column: $table.thumbPath, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FilmRollsTableAnnotationComposer get filmRollId {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> filmRollsRefs<T extends Object>(
    Expression<T> Function($$FilmRollsTableAnnotationComposer a) f,
  ) {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.coverImageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RollImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RollImagesTable,
          RollImage,
          $$RollImagesTableFilterComposer,
          $$RollImagesTableOrderingComposer,
          $$RollImagesTableAnnotationComposer,
          $$RollImagesTableCreateCompanionBuilder,
          $$RollImagesTableUpdateCompanionBuilder,
          (RollImage, $$RollImagesTableReferences),
          RollImage,
          PrefetchHooks Function({bool filmRollId, bool filmRollsRefs})
        > {
  $$RollImagesTableTableManager(_$AppDatabase db, $RollImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RollImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RollImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RollImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> filmRollId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> thumbPath = const Value.absent(),
                Value<int> width = const Value.absent(),
                Value<int> height = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => RollImagesCompanion(
                id: id,
                filmRollId: filmRollId,
                path: path,
                thumbPath: thumbPath,
                width: width,
                height: height,
                bytes: bytes,
                kind: kind,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int filmRollId,
                required String path,
                required String thumbPath,
                required int width,
                required int height,
                required int bytes,
                required String kind,
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => RollImagesCompanion.insert(
                id: id,
                filmRollId: filmRollId,
                path: path,
                thumbPath: thumbPath,
                width: width,
                height: height,
                bytes: bytes,
                kind: kind,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RollImagesTable, RollImage>(table),
                  $$RollImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollId = false, filmRollsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (filmRollsRefs) db.filmRolls],
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
                    if (filmRollId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.filmRollId,
                        referencedTable: $$RollImagesTableReferences
                            ._filmRollIdTable(db),
                        referencedColumn: $$RollImagesTableReferences
                            ._filmRollIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (filmRollsRefs)
                    await $_getPrefetchedData<
                      RollImage,
                      $RollImagesTable,
                      FilmRoll
                    >(
                      currentTable: table,
                      referencedTable: $$RollImagesTableReferences
                          ._filmRollsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RollImagesTableReferences(
                            db,
                            table,
                            p0,
                          ).filmRollsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.coverImageId == item.id,
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

typedef $$RollImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RollImagesTable,
      RollImage,
      $$RollImagesTableFilterComposer,
      $$RollImagesTableOrderingComposer,
      $$RollImagesTableAnnotationComposer,
      $$RollImagesTableCreateCompanionBuilder,
      $$RollImagesTableUpdateCompanionBuilder,
      (RollImage, $$RollImagesTableReferences),
      RollImage,
      PrefetchHooks Function({bool filmRollId, bool filmRollsRefs})
    >;
typedef $$FilmRollsTableCreateCompanionBuilder = FilmRollsCompanion Function({
  Value<int> id,
  required int sequenceNumber,
  Value<int?> filmStockId,
  required String filmName,
  required String format,
  required int nominalIso,
  required int exposedIso,
  Value<int?> cameraId,
  Value<String?> loadedAt,
  Value<String?> finishedAt,
  required int frames,
  Value<String?> title,
  Value<String?> note,
  required String status,
  Value<int?> costCents,
  Value<int?> coverImageId,
  required int createdAt,
});
typedef $$FilmRollsTableUpdateCompanionBuilder = FilmRollsCompanion Function({
  Value<int> id,
  Value<int> sequenceNumber,
  Value<int?> filmStockId,
  Value<String> filmName,
  Value<String> format,
  Value<int> nominalIso,
  Value<int> exposedIso,
  Value<int?> cameraId,
  Value<String?> loadedAt,
  Value<String?> finishedAt,
  Value<int> frames,
  Value<String?> title,
  Value<String?> note,
  Value<String> status,
  Value<int?> costCents,
  Value<int?> coverImageId,
  Value<int> createdAt,
});

final class $$FilmRollsTableReferences
    extends BaseReferences<_$AppDatabase, $FilmRollsTable, FilmRoll> {
  $$FilmRollsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FilmStocksTable _filmStockIdTable(_$AppDatabase db) =>
      db.filmStocks.createAlias('film_rolls__film_stock_id__film_stocks__id');

  $$FilmStocksTableProcessedTableManager? get filmStockId {
    final $_column = $_itemColumn<int>('film_stock_id');
    if ($_column == null) return null;
    final manager = $$FilmStocksTableTableManager(
      $_db,
      $_db.filmStocks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_filmStockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CamerasTable _cameraIdTable(_$AppDatabase db) =>
      db.cameras.createAlias('film_rolls__camera_id__cameras__id');

  $$CamerasTableProcessedTableManager? get cameraId {
    final $_column = $_itemColumn<int>('camera_id');
    if ($_column == null) return null;
    final manager = $$CamerasTableTableManager(
      $_db,
      $_db.cameras,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cameraIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RollImagesTable _coverImageIdTable(_$AppDatabase db) =>
      db.rollImages.createAlias('film_rolls__cover_image_id__roll_images__id');

  $$RollImagesTableProcessedTableManager? get coverImageId {
    final $_column = $_itemColumn<int>('cover_image_id');
    if ($_column == null) return null;
    final manager = $$RollImagesTableTableManager(
      $_db,
      $_db.rollImages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coverImageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RollImagesTable, List<RollImage>>
  _rollImagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rollImages,
    aliasName: 'film_rolls__id__roll_images__film_roll_id',
  );

  $$RollImagesTableProcessedTableManager get rollImagesRefs {
    final manager = $$RollImagesTableTableManager(
      $_db,
      $_db.rollImages,
    ).filter((f) => f.filmRollId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rollImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DevelopmentsTable, List<Development>>
  _developmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.developments,
    aliasName: 'film_rolls__id__developments__film_roll_id',
  );

  $$DevelopmentsTableProcessedTableManager get developmentsRefs {
    final manager = $$DevelopmentsTableTableManager(
      $_db,
      $_db.developments,
    ).filter((f) => f.filmRollId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_developmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PrintOrdersTable, List<PrintOrder>>
  _printOrdersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.printOrders,
    aliasName: 'film_rolls__id__print_orders__film_roll_id',
  );

  $$PrintOrdersTableProcessedTableManager get printOrdersRefs {
    final manager = $$PrintOrdersTableTableManager(
      $_db,
      $_db.printOrders,
    ).filter((f) => f.filmRollId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_printOrdersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FilmRollsTableFilterComposer
    extends Composer<_$AppDatabase, $FilmRollsTable> {
  $$FilmRollsTableFilterComposer({
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

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filmName => $composableBuilder(
    column: $table.filmName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nominalIso => $composableBuilder(
    column: $table.nominalIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exposedIso => $composableBuilder(
    column: $table.exposedIso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loadedAt => $composableBuilder(
    column: $table.loadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frames => $composableBuilder(
    column: $table.frames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnFilters<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FilmStocksTableFilterComposer get filmStockId {
    final $$FilmStocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmStockId,
      referencedTable: $db.filmStocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmStocksTableFilterComposer(
            $db: $db,
            $table: $db.filmStocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CamerasTableFilterComposer get cameraId {
    final $$CamerasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cameraId,
      referencedTable: $db.cameras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CamerasTableFilterComposer(
            $db: $db,
            $table: $db.cameras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RollImagesTableFilterComposer get coverImageId {
    final $$RollImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverImageId,
      referencedTable: $db.rollImages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RollImagesTableFilterComposer(
            $db: $db,
            $table: $db.rollImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rollImagesRefs(
    Expression<bool> Function($$RollImagesTableFilterComposer f) f,
  ) {
    final $$RollImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rollImages,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RollImagesTableFilterComposer(
            $db: $db,
            $table: $db.rollImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> developmentsRefs(
    Expression<bool> Function($$DevelopmentsTableFilterComposer f) f,
  ) {
    final $$DevelopmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.developments,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevelopmentsTableFilterComposer(
            $db: $db,
            $table: $db.developments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> printOrdersRefs(
    Expression<bool> Function($$PrintOrdersTableFilterComposer f) f,
  ) {
    final $$PrintOrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.printOrders,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrintOrdersTableFilterComposer(
            $db: $db,
            $table: $db.printOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FilmRollsTableOrderingComposer
    extends Composer<_$AppDatabase, $FilmRollsTable> {
  $$FilmRollsTableOrderingComposer({
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

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filmName => $composableBuilder(
    column: $table.filmName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nominalIso => $composableBuilder(
    column: $table.nominalIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exposedIso => $composableBuilder(
    column: $table.exposedIso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loadedAt => $composableBuilder(
    column: $table.loadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frames => $composableBuilder(
    column: $table.frames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnOrderings<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FilmStocksTableOrderingComposer get filmStockId {
    final $$FilmStocksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmStockId,
      referencedTable: $db.filmStocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmStocksTableOrderingComposer(
            $db: $db,
            $table: $db.filmStocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CamerasTableOrderingComposer get cameraId {
    final $$CamerasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cameraId,
      referencedTable: $db.cameras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CamerasTableOrderingComposer(
            $db: $db,
            $table: $db.cameras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RollImagesTableOrderingComposer get coverImageId {
    final $$RollImagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverImageId,
      referencedTable: $db.rollImages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RollImagesTableOrderingComposer(
            $db: $db,
            $table: $db.rollImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FilmRollsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FilmRollsTable> {
  $$FilmRollsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filmName =>
      $composableBuilder(column: $table.filmName, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get nominalIso => $composableBuilder(
    column: $table.nominalIso,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exposedIso => $composableBuilder(
    column: $table.exposedIso,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loadedAt =>
      $composableBuilder(column: $table.loadedAt, builder: (column) => column);

  GeneratedColumn<String> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get frames =>
      $composableBuilder(column: $table.frames, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get costCents =>
      $composableBuilder(column: $table.costCents, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FilmStocksTableAnnotationComposer get filmStockId {
    final $$FilmStocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmStockId,
      referencedTable: $db.filmStocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmStocksTableAnnotationComposer(
            $db: $db,
            $table: $db.filmStocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CamerasTableAnnotationComposer get cameraId {
    final $$CamerasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cameraId,
      referencedTable: $db.cameras,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CamerasTableAnnotationComposer(
            $db: $db,
            $table: $db.cameras,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RollImagesTableAnnotationComposer get coverImageId {
    final $$RollImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverImageId,
      referencedTable: $db.rollImages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RollImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.rollImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rollImagesRefs<T extends Object>(
    Expression<T> Function($$RollImagesTableAnnotationComposer a) f,
  ) {
    final $$RollImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rollImages,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RollImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.rollImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> developmentsRefs<T extends Object>(
    Expression<T> Function($$DevelopmentsTableAnnotationComposer a) f,
  ) {
    final $$DevelopmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.developments,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DevelopmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.developments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> printOrdersRefs<T extends Object>(
    Expression<T> Function($$PrintOrdersTableAnnotationComposer a) f,
  ) {
    final $$PrintOrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.printOrders,
      getReferencedColumn: (t) => t.filmRollId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrintOrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.printOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FilmRollsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FilmRollsTable,
          FilmRoll,
          $$FilmRollsTableFilterComposer,
          $$FilmRollsTableOrderingComposer,
          $$FilmRollsTableAnnotationComposer,
          $$FilmRollsTableCreateCompanionBuilder,
          $$FilmRollsTableUpdateCompanionBuilder,
          (FilmRoll, $$FilmRollsTableReferences),
          FilmRoll,
          PrefetchHooks Function({
            bool filmStockId,
            bool cameraId,
            bool coverImageId,
            bool rollImagesRefs,
            bool developmentsRefs,
            bool printOrdersRefs,
          })
        > {
  $$FilmRollsTableTableManager(_$AppDatabase db, $FilmRollsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FilmRollsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FilmRollsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FilmRollsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<int?> filmStockId = const Value.absent(),
                Value<String> filmName = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int> nominalIso = const Value.absent(),
                Value<int> exposedIso = const Value.absent(),
                Value<int?> cameraId = const Value.absent(),
                Value<String?> loadedAt = const Value.absent(),
                Value<String?> finishedAt = const Value.absent(),
                Value<int> frames = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> costCents = const Value.absent(),
                Value<int?> coverImageId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => FilmRollsCompanion(
                id: id,
                sequenceNumber: sequenceNumber,
                filmStockId: filmStockId,
                filmName: filmName,
                format: format,
                nominalIso: nominalIso,
                exposedIso: exposedIso,
                cameraId: cameraId,
                loadedAt: loadedAt,
                finishedAt: finishedAt,
                frames: frames,
                title: title,
                note: note,
                status: status,
                costCents: costCents,
                coverImageId: coverImageId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sequenceNumber,
                Value<int?> filmStockId = const Value.absent(),
                required String filmName,
                required String format,
                required int nominalIso,
                required int exposedIso,
                Value<int?> cameraId = const Value.absent(),
                Value<String?> loadedAt = const Value.absent(),
                Value<String?> finishedAt = const Value.absent(),
                required int frames,
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String status,
                Value<int?> costCents = const Value.absent(),
                Value<int?> coverImageId = const Value.absent(),
                required int createdAt,
              }) => FilmRollsCompanion.insert(
                id: id,
                sequenceNumber: sequenceNumber,
                filmStockId: filmStockId,
                filmName: filmName,
                format: format,
                nominalIso: nominalIso,
                exposedIso: exposedIso,
                cameraId: cameraId,
                loadedAt: loadedAt,
                finishedAt: finishedAt,
                frames: frames,
                title: title,
                note: note,
                status: status,
                costCents: costCents,
                coverImageId: coverImageId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FilmRollsTable, FilmRoll>(table),
                  $$FilmRollsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                filmStockId = false,
                cameraId = false,
                coverImageId = false,
                rollImagesRefs = false,
                developmentsRefs = false,
                printOrdersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rollImagesRefs) db.rollImages,
                    if (developmentsRefs) db.developments,
                    if (printOrdersRefs) db.printOrders,
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
                        if (filmStockId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.filmStockId,
                            referencedTable: $$FilmRollsTableReferences
                                ._filmStockIdTable(db),
                            referencedColumn: $$FilmRollsTableReferences
                                ._filmStockIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (cameraId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.cameraId,
                            referencedTable: $$FilmRollsTableReferences
                                ._cameraIdTable(db),
                            referencedColumn: $$FilmRollsTableReferences
                                ._cameraIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (coverImageId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.coverImageId,
                            referencedTable: $$FilmRollsTableReferences
                                ._coverImageIdTable(db),
                            referencedColumn: $$FilmRollsTableReferences
                                ._coverImageIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rollImagesRefs)
                        await $_getPrefetchedData<
                          FilmRoll,
                          $FilmRollsTable,
                          RollImage
                        >(
                          currentTable: table,
                          referencedTable: $$FilmRollsTableReferences
                              ._rollImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FilmRollsTableReferences(
                                db,
                                table,
                                p0,
                              ).rollImagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.filmRollId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (developmentsRefs)
                        await $_getPrefetchedData<
                          FilmRoll,
                          $FilmRollsTable,
                          Development
                        >(
                          currentTable: table,
                          referencedTable: $$FilmRollsTableReferences
                              ._developmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FilmRollsTableReferences(
                                db,
                                table,
                                p0,
                              ).developmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.filmRollId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (printOrdersRefs)
                        await $_getPrefetchedData<
                          FilmRoll,
                          $FilmRollsTable,
                          PrintOrder
                        >(
                          currentTable: table,
                          referencedTable: $$FilmRollsTableReferences
                              ._printOrdersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FilmRollsTableReferences(
                                db,
                                table,
                                p0,
                              ).printOrdersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.filmRollId == item.id,
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

typedef $$FilmRollsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FilmRollsTable,
      FilmRoll,
      $$FilmRollsTableFilterComposer,
      $$FilmRollsTableOrderingComposer,
      $$FilmRollsTableAnnotationComposer,
      $$FilmRollsTableCreateCompanionBuilder,
      $$FilmRollsTableUpdateCompanionBuilder,
      (FilmRoll, $$FilmRollsTableReferences),
      FilmRoll,
      PrefetchHooks Function({
        bool filmStockId,
        bool cameraId,
        bool coverImageId,
        bool rollImagesRefs,
        bool developmentsRefs,
        bool printOrdersRefs,
      })
    >;
typedef $$DevelopmentsTableCreateCompanionBuilder =
    DevelopmentsCompanion Function({
      Value<int> id,
      required int filmRollId,
      Value<String?> laboratory,
      Value<String?> submittedAt,
      Value<String?> returnedAt,
      Value<int?> developmentCostCents,
      Value<int?> scanCostCents,
      Value<String?> process,
      Value<bool> selfDeveloped,
      Value<String?> note,
    });
typedef $$DevelopmentsTableUpdateCompanionBuilder =
    DevelopmentsCompanion Function({
      Value<int> id,
      Value<int> filmRollId,
      Value<String?> laboratory,
      Value<String?> submittedAt,
      Value<String?> returnedAt,
      Value<int?> developmentCostCents,
      Value<int?> scanCostCents,
      Value<String?> process,
      Value<bool> selfDeveloped,
      Value<String?> note,
    });

final class $$DevelopmentsTableReferences
    extends BaseReferences<_$AppDatabase, $DevelopmentsTable, Development> {
  $$DevelopmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FilmRollsTable _filmRollIdTable(_$AppDatabase db) =>
      db.filmRolls.createAlias('developments__film_roll_id__film_rolls__id');

  $$FilmRollsTableProcessedTableManager get filmRollId {
    final $_column = $_itemColumn<int>('film_roll_id')!;

    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_filmRollIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DevelopmentsTableFilterComposer
    extends Composer<_$AppDatabase, $DevelopmentsTable> {
  $$DevelopmentsTableFilterComposer({
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

  ColumnFilters<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get developmentCostCents => $composableBuilder(
    column: $table.developmentCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scanCostCents => $composableBuilder(
    column: $table.scanCostCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get selfDeveloped => $composableBuilder(
    column: $table.selfDeveloped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$FilmRollsTableFilterComposer get filmRollId {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevelopmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DevelopmentsTable> {
  $$DevelopmentsTableOrderingComposer({
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

  ColumnOrderings<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get developmentCostCents => $composableBuilder(
    column: $table.developmentCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scanCostCents => $composableBuilder(
    column: $table.scanCostCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get process => $composableBuilder(
    column: $table.process,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get selfDeveloped => $composableBuilder(
    column: $table.selfDeveloped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$FilmRollsTableOrderingComposer get filmRollId {
    final $$FilmRollsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableOrderingComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevelopmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevelopmentsTable> {
  $$DevelopmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get developmentCostCents => $composableBuilder(
    column: $table.developmentCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scanCostCents => $composableBuilder(
    column: $table.scanCostCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get process =>
      $composableBuilder(column: $table.process, builder: (column) => column);

  GeneratedColumn<bool> get selfDeveloped => $composableBuilder(
    column: $table.selfDeveloped,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$FilmRollsTableAnnotationComposer get filmRollId {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DevelopmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DevelopmentsTable,
          Development,
          $$DevelopmentsTableFilterComposer,
          $$DevelopmentsTableOrderingComposer,
          $$DevelopmentsTableAnnotationComposer,
          $$DevelopmentsTableCreateCompanionBuilder,
          $$DevelopmentsTableUpdateCompanionBuilder,
          (Development, $$DevelopmentsTableReferences),
          Development,
          PrefetchHooks Function({bool filmRollId})
        > {
  $$DevelopmentsTableTableManager(_$AppDatabase db, $DevelopmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevelopmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevelopmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevelopmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> filmRollId = const Value.absent(),
                Value<String?> laboratory = const Value.absent(),
                Value<String?> submittedAt = const Value.absent(),
                Value<String?> returnedAt = const Value.absent(),
                Value<int?> developmentCostCents = const Value.absent(),
                Value<int?> scanCostCents = const Value.absent(),
                Value<String?> process = const Value.absent(),
                Value<bool> selfDeveloped = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => DevelopmentsCompanion(
                id: id,
                filmRollId: filmRollId,
                laboratory: laboratory,
                submittedAt: submittedAt,
                returnedAt: returnedAt,
                developmentCostCents: developmentCostCents,
                scanCostCents: scanCostCents,
                process: process,
                selfDeveloped: selfDeveloped,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int filmRollId,
                Value<String?> laboratory = const Value.absent(),
                Value<String?> submittedAt = const Value.absent(),
                Value<String?> returnedAt = const Value.absent(),
                Value<int?> developmentCostCents = const Value.absent(),
                Value<int?> scanCostCents = const Value.absent(),
                Value<String?> process = const Value.absent(),
                Value<bool> selfDeveloped = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => DevelopmentsCompanion.insert(
                id: id,
                filmRollId: filmRollId,
                laboratory: laboratory,
                submittedAt: submittedAt,
                returnedAt: returnedAt,
                developmentCostCents: developmentCostCents,
                scanCostCents: scanCostCents,
                process: process,
                selfDeveloped: selfDeveloped,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DevelopmentsTable, Development>(table),
                  $$DevelopmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollId = false}) {
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
                    if (filmRollId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.filmRollId,
                        referencedTable: $$DevelopmentsTableReferences
                            ._filmRollIdTable(db),
                        referencedColumn: $$DevelopmentsTableReferences
                            ._filmRollIdTable(db)
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

typedef $$DevelopmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DevelopmentsTable,
      Development,
      $$DevelopmentsTableFilterComposer,
      $$DevelopmentsTableOrderingComposer,
      $$DevelopmentsTableAnnotationComposer,
      $$DevelopmentsTableCreateCompanionBuilder,
      $$DevelopmentsTableUpdateCompanionBuilder,
      (Development, $$DevelopmentsTableReferences),
      Development,
      PrefetchHooks Function({bool filmRollId})
    >;
typedef $$PrintOrdersTableCreateCompanionBuilder =
    PrintOrdersCompanion Function({
      Value<int> id,
      required int filmRollId,
      Value<String?> laboratory,
      Value<String?> submittedAt,
      Value<String?> returnedAt,
      Value<String?> format,
      Value<int?> numberOfPrints,
      Value<int?> costCents,
      Value<String?> note,
    });
typedef $$PrintOrdersTableUpdateCompanionBuilder =
    PrintOrdersCompanion Function({
      Value<int> id,
      Value<int> filmRollId,
      Value<String?> laboratory,
      Value<String?> submittedAt,
      Value<String?> returnedAt,
      Value<String?> format,
      Value<int?> numberOfPrints,
      Value<int?> costCents,
      Value<String?> note,
    });

final class $$PrintOrdersTableReferences
    extends BaseReferences<_$AppDatabase, $PrintOrdersTable, PrintOrder> {
  $$PrintOrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FilmRollsTable _filmRollIdTable(_$AppDatabase db) =>
      db.filmRolls.createAlias('print_orders__film_roll_id__film_rolls__id');

  $$FilmRollsTableProcessedTableManager get filmRollId {
    final $_column = $_itemColumn<int>('film_roll_id')!;

    final manager = $$FilmRollsTableTableManager(
      $_db,
      $_db.filmRolls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_filmRollIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PrintOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $PrintOrdersTable> {
  $$PrintOrdersTableFilterComposer({
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

  ColumnFilters<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get numberOfPrints => $composableBuilder(
    column: $table.numberOfPrints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$FilmRollsTableFilterComposer get filmRollId {
    final $$FilmRollsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableFilterComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrintOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintOrdersTable> {
  $$PrintOrdersTableOrderingComposer({
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

  ColumnOrderings<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get numberOfPrints => $composableBuilder(
    column: $table.numberOfPrints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costCents => $composableBuilder(
    column: $table.costCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$FilmRollsTableOrderingComposer get filmRollId {
    final $$FilmRollsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableOrderingComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrintOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintOrdersTable> {
  $$PrintOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get laboratory => $composableBuilder(
    column: $table.laboratory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get numberOfPrints => $composableBuilder(
    column: $table.numberOfPrints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costCents =>
      $composableBuilder(column: $table.costCents, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$FilmRollsTableAnnotationComposer get filmRollId {
    final $$FilmRollsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.filmRollId,
      referencedTable: $db.filmRolls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FilmRollsTableAnnotationComposer(
            $db: $db,
            $table: $db.filmRolls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrintOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintOrdersTable,
          PrintOrder,
          $$PrintOrdersTableFilterComposer,
          $$PrintOrdersTableOrderingComposer,
          $$PrintOrdersTableAnnotationComposer,
          $$PrintOrdersTableCreateCompanionBuilder,
          $$PrintOrdersTableUpdateCompanionBuilder,
          (PrintOrder, $$PrintOrdersTableReferences),
          PrintOrder,
          PrefetchHooks Function({bool filmRollId})
        > {
  $$PrintOrdersTableTableManager(_$AppDatabase db, $PrintOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> filmRollId = const Value.absent(),
                Value<String?> laboratory = const Value.absent(),
                Value<String?> submittedAt = const Value.absent(),
                Value<String?> returnedAt = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<int?> numberOfPrints = const Value.absent(),
                Value<int?> costCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => PrintOrdersCompanion(
                id: id,
                filmRollId: filmRollId,
                laboratory: laboratory,
                submittedAt: submittedAt,
                returnedAt: returnedAt,
                format: format,
                numberOfPrints: numberOfPrints,
                costCents: costCents,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int filmRollId,
                Value<String?> laboratory = const Value.absent(),
                Value<String?> submittedAt = const Value.absent(),
                Value<String?> returnedAt = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<int?> numberOfPrints = const Value.absent(),
                Value<int?> costCents = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => PrintOrdersCompanion.insert(
                id: id,
                filmRollId: filmRollId,
                laboratory: laboratory,
                submittedAt: submittedAt,
                returnedAt: returnedAt,
                format: format,
                numberOfPrints: numberOfPrints,
                costCents: costCents,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrintOrdersTable, PrintOrder>(table),
                  $$PrintOrdersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({filmRollId = false}) {
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
                    if (filmRollId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.filmRollId,
                        referencedTable: $$PrintOrdersTableReferences
                            ._filmRollIdTable(db),
                        referencedColumn: $$PrintOrdersTableReferences
                            ._filmRollIdTable(db)
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

typedef $$PrintOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintOrdersTable,
      PrintOrder,
      $$PrintOrdersTableFilterComposer,
      $$PrintOrdersTableOrderingComposer,
      $$PrintOrdersTableAnnotationComposer,
      $$PrintOrdersTableCreateCompanionBuilder,
      $$PrintOrdersTableUpdateCompanionBuilder,
      (PrintOrder, $$PrintOrdersTableReferences),
      PrintOrder,
      PrefetchHooks Function({bool filmRollId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CamerasTableTableManager get cameras =>
      $$CamerasTableTableManager(_db, _db.cameras);
  $$FilmStocksTableTableManager get filmStocks =>
      $$FilmStocksTableTableManager(_db, _db.filmStocks);
  $$RollImagesTableTableManager get rollImages =>
      $$RollImagesTableTableManager(_db, _db.rollImages);
  $$FilmRollsTableTableManager get filmRolls =>
      $$FilmRollsTableTableManager(_db, _db.filmRolls);
  $$DevelopmentsTableTableManager get developments =>
      $$DevelopmentsTableTableManager(_db, _db.developments);
  $$PrintOrdersTableTableManager get printOrders =>
      $$PrintOrdersTableTableManager(_db, _db.printOrders);
}
