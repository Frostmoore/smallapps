// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $QrCodesTable extends QrCodes with TableInfo<$QrCodesTable, QrCode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QrCodesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(qrKindKeys),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 4000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldsJsonMeta = const VerificationMeta(
    'fieldsJson',
  );
  @override
  late final GeneratedColumn<String> fieldsJson = GeneratedColumn<String>(
    'fields_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    check: () => source.isIn(QrSource.all),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _styleJsonMeta = const VerificationMeta(
    'styleJson',
  );
  @override
  late final GeneratedColumn<String> styleJson = GeneratedColumn<String>(
    'style_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<int> lastUsedAt = GeneratedColumn<int>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    payload,
    fieldsJson,
    title,
    source,
    styleJson,
    isFavorite,
    createdAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'qr_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<QrCode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('fields_json')) {
      context.handle(
        _fieldsJsonMeta,
        fieldsJson.isAcceptableOrUnknown(data['fields_json']!, _fieldsJsonMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('style_json')) {
      context.handle(
        _styleJsonMeta,
        styleJson.isAcceptableOrUnknown(data['style_json']!, _styleJsonMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QrCode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QrCode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      fieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields_json'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      styleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_json'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $QrCodesTable createAlias(String alias) {
    return $QrCodesTable(attachedDatabase, alias);
  }
}

class QrCode extends DataClass implements Insertable<QrCode> {
  final int id;

  /// `QrKind.name`.
  final String kind;

  /// La stringa **esatta** codificata nel QR (quella di `QrEncoder.encode`, o quella letta).
  /// ⚑ 4000 e non 2953: il limite del QR e' in byte UTF-8, questo in caratteri, ed e' solo un
  /// argine contro un dato assurdo. Il controllo vero e' `QrCapacity` prima di disegnare.
  final String payload;

  /// `QrContent.toFields()` in JSON, per riaprire il modulo; null per testo e link (il
  /// payload basta).
  final String? fieldsJson;

  /// `autoTitle` o il nome dato dall'utente.
  final String title;

  /// Una delle chiavi di [QrSource].
  final String source;

  /// `QrStyle.toJson()` in JSON; null = `QrStyle.plain`.
  final String? styleJson;

  /// Preferito = salvato con nome, escluso dalla potatura della cronologia.
  final bool isFavorite;
  final int createdAt;

  /// Aggiornato a ogni visualizzazione: ordina la cronologia.
  final int lastUsedAt;
  const QrCode({
    required this.id,
    required this.kind,
    required this.payload,
    this.fieldsJson,
    required this.title,
    required this.source,
    this.styleJson,
    required this.isFavorite,
    required this.createdAt,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    if (!nullToAbsent || fieldsJson != null) {
      map['fields_json'] = Variable<String>(fieldsJson);
    }
    map['title'] = Variable<String>(title);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || styleJson != null) {
      map['style_json'] = Variable<String>(styleJson);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<int>(createdAt);
    map['last_used_at'] = Variable<int>(lastUsedAt);
    return map;
  }

  QrCodesCompanion toCompanion(bool nullToAbsent) {
    return QrCodesCompanion(
      id: Value(id),
      kind: Value(kind),
      payload: Value(payload),
      fieldsJson: fieldsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldsJson),
      title: Value(title),
      source: Value(source),
      styleJson: styleJson == null && nullToAbsent
          ? const Value.absent()
          : Value(styleJson),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory QrCode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QrCode(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      fieldsJson: serializer.fromJson<String?>(json['fieldsJson']),
      title: serializer.fromJson<String>(json['title']),
      source: serializer.fromJson<String>(json['source']),
      styleJson: serializer.fromJson<String?>(json['styleJson']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastUsedAt: serializer.fromJson<int>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'fieldsJson': serializer.toJson<String?>(fieldsJson),
      'title': serializer.toJson<String>(title),
      'source': serializer.toJson<String>(source),
      'styleJson': serializer.toJson<String?>(styleJson),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastUsedAt': serializer.toJson<int>(lastUsedAt),
    };
  }

  QrCode copyWith({
    int? id,
    String? kind,
    String? payload,
    Value<String?> fieldsJson = const Value.absent(),
    String? title,
    String? source,
    Value<String?> styleJson = const Value.absent(),
    bool? isFavorite,
    int? createdAt,
    int? lastUsedAt,
  }) => QrCode(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    fieldsJson: fieldsJson.present ? fieldsJson.value : this.fieldsJson,
    title: title ?? this.title,
    source: source ?? this.source,
    styleJson: styleJson.present ? styleJson.value : this.styleJson,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  QrCode copyWithCompanion(QrCodesCompanion data) {
    return QrCode(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      fieldsJson: data.fieldsJson.present
          ? data.fieldsJson.value
          : this.fieldsJson,
      title: data.title.present ? data.title.value : this.title,
      source: data.source.present ? data.source.value : this.source,
      styleJson: data.styleJson.present ? data.styleJson.value : this.styleJson,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QrCode(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('styleJson: $styleJson, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    payload,
    fieldsJson,
    title,
    source,
    styleJson,
    isFavorite,
    createdAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QrCode &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.fieldsJson == this.fieldsJson &&
          other.title == this.title &&
          other.source == this.source &&
          other.styleJson == this.styleJson &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class QrCodesCompanion extends UpdateCompanion<QrCode> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> payload;
  final Value<String?> fieldsJson;
  final Value<String> title;
  final Value<String> source;
  final Value<String?> styleJson;
  final Value<bool> isFavorite;
  final Value<int> createdAt;
  final Value<int> lastUsedAt;
  const QrCodesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.fieldsJson = const Value.absent(),
    this.title = const Value.absent(),
    this.source = const Value.absent(),
    this.styleJson = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  });
  QrCodesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String payload,
    this.fieldsJson = const Value.absent(),
    required String title,
    required String source,
    this.styleJson = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required int createdAt,
    required int lastUsedAt,
  }) : kind = Value(kind),
       payload = Value(payload),
       title = Value(title),
       source = Value(source),
       createdAt = Value(createdAt),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<QrCode> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<String>? fieldsJson,
    Expression<String>? title,
    Expression<String>? source,
    Expression<String>? styleJson,
    Expression<bool>? isFavorite,
    Expression<int>? createdAt,
    Expression<int>? lastUsedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (fieldsJson != null) 'fields_json': fieldsJson,
      if (title != null) 'title': title,
      if (source != null) 'source': source,
      if (styleJson != null) 'style_json': styleJson,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    });
  }

  QrCodesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? payload,
    Value<String?>? fieldsJson,
    Value<String>? title,
    Value<String>? source,
    Value<String?>? styleJson,
    Value<bool>? isFavorite,
    Value<int>? createdAt,
    Value<int>? lastUsedAt,
  }) {
    return QrCodesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      fieldsJson: fieldsJson ?? this.fieldsJson,
      title: title ?? this.title,
      source: source ?? this.source,
      styleJson: styleJson ?? this.styleJson,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (fieldsJson.present) {
      map['fields_json'] = Variable<String>(fieldsJson.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (styleJson.present) {
      map['style_json'] = Variable<String>(styleJson.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(lastUsedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QrCodesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('title: $title, ')
          ..write('source: $source, ')
          ..write('styleJson: $styleJson, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$QrDatabase extends GeneratedDatabase {
  _$QrDatabase(QueryExecutor e) : super(e);
  $QrDatabaseManager get managers => $QrDatabaseManager(this);
  late final $QrCodesTable qrCodes = $QrCodesTable(this);
  late final Index idxQrCodesFavoriteUsed = Index(
    'idx_qr_codes_favorite_used',
    'CREATE INDEX idx_qr_codes_favorite_used ON qr_codes (is_favorite, last_used_at DESC)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    qrCodes,
    idxQrCodesFavoriteUsed,
  ];
}

typedef $$QrCodesTableCreateCompanionBuilder = QrCodesCompanion Function({
  Value<int> id,
  required String kind,
  required String payload,
  Value<String?> fieldsJson,
  required String title,
  required String source,
  Value<String?> styleJson,
  Value<bool> isFavorite,
  required int createdAt,
  required int lastUsedAt,
});
typedef $$QrCodesTableUpdateCompanionBuilder = QrCodesCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> payload,
  Value<String?> fieldsJson,
  Value<String> title,
  Value<String> source,
  Value<String?> styleJson,
  Value<bool> isFavorite,
  Value<int> createdAt,
  Value<int> lastUsedAt,
});

class $$QrCodesTableFilterComposer
    extends Composer<_$QrDatabase, $QrCodesTable> {
  $$QrCodesTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get styleJson => $composableBuilder(
    column: $table.styleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QrCodesTableOrderingComposer
    extends Composer<_$QrDatabase, $QrCodesTable> {
  $$QrCodesTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get styleJson => $composableBuilder(
    column: $table.styleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QrCodesTableAnnotationComposer
    extends Composer<_$QrDatabase, $QrCodesTable> {
  $$QrCodesTableAnnotationComposer({
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

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get styleJson =>
      $composableBuilder(column: $table.styleJson, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$QrCodesTableTableManager
    extends
        RootTableManager<
          _$QrDatabase,
          $QrCodesTable,
          QrCode,
          $$QrCodesTableFilterComposer,
          $$QrCodesTableOrderingComposer,
          $$QrCodesTableAnnotationComposer,
          $$QrCodesTableCreateCompanionBuilder,
          $$QrCodesTableUpdateCompanionBuilder,
          (QrCode, BaseReferences<_$QrDatabase, $QrCodesTable, QrCode>),
          QrCode,
          PrefetchHooks Function()
        > {
  $$QrCodesTableTableManager(_$QrDatabase db, $QrCodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QrCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QrCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QrCodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String?> fieldsJson = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> styleJson = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> lastUsedAt = const Value.absent(),
              }) => QrCodesCompanion(
                id: id,
                kind: kind,
                payload: payload,
                fieldsJson: fieldsJson,
                title: title,
                source: source,
                styleJson: styleJson,
                isFavorite: isFavorite,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String payload,
                Value<String?> fieldsJson = const Value.absent(),
                required String title,
                required String source,
                Value<String?> styleJson = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required int createdAt,
                required int lastUsedAt,
              }) => QrCodesCompanion.insert(
                id: id,
                kind: kind,
                payload: payload,
                fieldsJson: fieldsJson,
                title: title,
                source: source,
                styleJson: styleJson,
                isFavorite: isFavorite,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QrCodesTable, QrCode>(table),
                  BaseReferences<_$QrDatabase, $QrCodesTable, QrCode>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QrCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$QrDatabase,
      $QrCodesTable,
      QrCode,
      $$QrCodesTableFilterComposer,
      $$QrCodesTableOrderingComposer,
      $$QrCodesTableAnnotationComposer,
      $$QrCodesTableCreateCompanionBuilder,
      $$QrCodesTableUpdateCompanionBuilder,
      (QrCode, BaseReferences<_$QrDatabase, $QrCodesTable, QrCode>),
      QrCode,
      PrefetchHooks Function()
    >;

class $QrDatabaseManager {
  final _$QrDatabase _db;
  $QrDatabaseManager(this._db);
  $$QrCodesTableTableManager get qrCodes =>
      $$QrCodesTableTableManager(_db, _db.qrCodes);
}
