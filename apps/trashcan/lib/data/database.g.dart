// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CollectionCalendarsTable extends CollectionCalendars
    with TableInfo<$CollectionCalendarsTable, CollectionCalendar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionCalendarsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _notificationTimeMeta = const VerificationMeta(
    'notificationTime',
  );
  @override
  late final GeneratedColumn<String> notificationTime = GeneratedColumn<String>(
    'notification_time',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 5,
      maxTextLength: 5,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('20:00'),
  );
  static const VerificationMeta _secondNotificationTimeMeta =
      const VerificationMeta('secondNotificationTime');
  @override
  late final GeneratedColumn<String> secondNotificationTime =
      GeneratedColumn<String>(
        'second_notification_time',
        aliasedName,
        true,
        additionalChecks: GeneratedColumn.checkTextLength(
          minTextLength: 5,
          maxTextLength: 5,
        ),
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
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
    notificationTime,
    secondNotificationTime,
    enabled,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_calendars';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionCalendar> instance, {
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
    if (data.containsKey('notification_time')) {
      context.handle(
        _notificationTimeMeta,
        notificationTime.isAcceptableOrUnknown(
          data['notification_time']!,
          _notificationTimeMeta,
        ),
      );
    }
    if (data.containsKey('second_notification_time')) {
      context.handle(
        _secondNotificationTimeMeta,
        secondNotificationTime.isAcceptableOrUnknown(
          data['second_notification_time']!,
          _secondNotificationTimeMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
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
  CollectionCalendar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionCalendar(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notificationTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notification_time'],
      )!,
      secondNotificationTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}second_notification_time'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
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
  $CollectionCalendarsTable createAlias(String alias) {
    return $CollectionCalendarsTable(attachedDatabase, alias);
  }
}

class CollectionCalendar extends DataClass
    implements Insertable<CollectionCalendar> {
  final int id;
  final String name;

  /// Orario del promemoria, come `HH:mm`.
  ///
  /// ⚑ Testo e non due interi: è un dato che si legge e si scrive sempre insieme, non si
  /// interroga mai per ora separata dai minuti, e in forma testuale è ispezionabile a
  /// occhio in un dump del database.
  final String notificationTime;

  /// Secondo promemoria, funzione Pro. `null` = non impostato.
  final String? secondNotificationTime;
  final bool enabled;
  final int sortOrder;

  /// Istante di creazione, millisecondi UTC (ADR-008: questo è un istante vero).
  final int createdAt;
  const CollectionCalendar({
    required this.id,
    required this.name,
    required this.notificationTime,
    this.secondNotificationTime,
    required this.enabled,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['notification_time'] = Variable<String>(notificationTime);
    if (!nullToAbsent || secondNotificationTime != null) {
      map['second_notification_time'] = Variable<String>(
        secondNotificationTime,
      );
    }
    map['enabled'] = Variable<bool>(enabled);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CollectionCalendarsCompanion toCompanion(bool nullToAbsent) {
    return CollectionCalendarsCompanion(
      id: Value(id),
      name: Value(name),
      notificationTime: Value(notificationTime),
      secondNotificationTime: secondNotificationTime == null && nullToAbsent
          ? const Value.absent()
          : Value(secondNotificationTime),
      enabled: Value(enabled),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory CollectionCalendar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionCalendar(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notificationTime: serializer.fromJson<String>(json['notificationTime']),
      secondNotificationTime: serializer.fromJson<String?>(
        json['secondNotificationTime'],
      ),
      enabled: serializer.fromJson<bool>(json['enabled']),
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
      'notificationTime': serializer.toJson<String>(notificationTime),
      'secondNotificationTime': serializer.toJson<String?>(
        secondNotificationTime,
      ),
      'enabled': serializer.toJson<bool>(enabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CollectionCalendar copyWith({
    int? id,
    String? name,
    String? notificationTime,
    Value<String?> secondNotificationTime = const Value.absent(),
    bool? enabled,
    int? sortOrder,
    int? createdAt,
  }) => CollectionCalendar(
    id: id ?? this.id,
    name: name ?? this.name,
    notificationTime: notificationTime ?? this.notificationTime,
    secondNotificationTime: secondNotificationTime.present
        ? secondNotificationTime.value
        : this.secondNotificationTime,
    enabled: enabled ?? this.enabled,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  CollectionCalendar copyWithCompanion(CollectionCalendarsCompanion data) {
    return CollectionCalendar(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notificationTime: data.notificationTime.present
          ? data.notificationTime.value
          : this.notificationTime,
      secondNotificationTime: data.secondNotificationTime.present
          ? data.secondNotificationTime.value
          : this.secondNotificationTime,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionCalendar(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notificationTime: $notificationTime, ')
          ..write('secondNotificationTime: $secondNotificationTime, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    notificationTime,
    secondNotificationTime,
    enabled,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionCalendar &&
          other.id == this.id &&
          other.name == this.name &&
          other.notificationTime == this.notificationTime &&
          other.secondNotificationTime == this.secondNotificationTime &&
          other.enabled == this.enabled &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class CollectionCalendarsCompanion extends UpdateCompanion<CollectionCalendar> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> notificationTime;
  final Value<String?> secondNotificationTime;
  final Value<bool> enabled;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  const CollectionCalendarsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notificationTime = const Value.absent(),
    this.secondNotificationTime = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CollectionCalendarsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.notificationTime = const Value.absent(),
    this.secondNotificationTime = const Value.absent(),
    this.enabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CollectionCalendar> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? notificationTime,
    Expression<String>? secondNotificationTime,
    Expression<bool>? enabled,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notificationTime != null) 'notification_time': notificationTime,
      if (secondNotificationTime != null)
        'second_notification_time': secondNotificationTime,
      if (enabled != null) 'enabled': enabled,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CollectionCalendarsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? notificationTime,
    Value<String?>? secondNotificationTime,
    Value<bool>? enabled,
    Value<int>? sortOrder,
    Value<int>? createdAt,
  }) {
    return CollectionCalendarsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notificationTime: notificationTime ?? this.notificationTime,
      secondNotificationTime:
          secondNotificationTime ?? this.secondNotificationTime,
      enabled: enabled ?? this.enabled,
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
    if (notificationTime.present) {
      map['notification_time'] = Variable<String>(notificationTime.value);
    }
    if (secondNotificationTime.present) {
      map['second_notification_time'] = Variable<String>(
        secondNotificationTime.value,
      );
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
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
    return (StringBuffer('CollectionCalendarsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notificationTime: $notificationTime, ')
          ..write('secondNotificationTime: $secondNotificationTime, ')
          ..write('enabled: $enabled, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WasteTypesTable extends WasteTypes
    with TableInfo<$WasteTypesTable, WasteType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WasteTypesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _calendarIdMeta = const VerificationMeta(
    'calendarId',
  );
  @override
  late final GeneratedColumn<int> calendarId = GeneratedColumn<int>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES collection_calendars (id) ON DELETE CASCADE',
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
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
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
    calendarId,
    name,
    iconKey,
    colorValue,
    notificationsEnabled,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'waste_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<WasteType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('calendar_id')) {
      context.handle(
        _calendarIdMeta,
        calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
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
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
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
  WasteType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WasteType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      calendarId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calendar_id'],
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
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WasteTypesTable createAlias(String alias) {
    return $WasteTypesTable(attachedDatabase, alias);
  }
}

class WasteType extends DataClass implements Insertable<WasteType> {
  final int id;
  final int calendarId;
  final String name;

  /// Chiave in `WasteIcons.byKey`, **mai** un `IconData.codePoint`.
  ///
  /// ☠ Salvare il codepoint rompe il tree shaking delle icone e in release produce
  /// quadrati vuoti. Vedi `lib/app/waste_presets.dart`.
  final String iconKey;

  /// Colore ARGB come intero.
  final int colorValue;
  final bool notificationsEnabled;
  final int sortOrder;
  const WasteType({
    required this.id,
    required this.calendarId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.notificationsEnabled,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['calendar_id'] = Variable<int>(calendarId);
    map['name'] = Variable<String>(name);
    map['icon_key'] = Variable<String>(iconKey);
    map['color_value'] = Variable<int>(colorValue);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WasteTypesCompanion toCompanion(bool nullToAbsent) {
    return WasteTypesCompanion(
      id: Value(id),
      calendarId: Value(calendarId),
      name: Value(name),
      iconKey: Value(iconKey),
      colorValue: Value(colorValue),
      notificationsEnabled: Value(notificationsEnabled),
      sortOrder: Value(sortOrder),
    );
  }

  factory WasteType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WasteType(
      id: serializer.fromJson<int>(json['id']),
      calendarId: serializer.fromJson<int>(json['calendarId']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'calendarId': serializer.toJson<int>(calendarId),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorValue': serializer.toJson<int>(colorValue),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WasteType copyWith({
    int? id,
    int? calendarId,
    String? name,
    String? iconKey,
    int? colorValue,
    bool? notificationsEnabled,
    int? sortOrder,
  }) => WasteType(
    id: id ?? this.id,
    calendarId: calendarId ?? this.calendarId,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    colorValue: colorValue ?? this.colorValue,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WasteType copyWithCompanion(WasteTypesCompanion data) {
    return WasteType(
      id: data.id.present ? data.id.value : this.id,
      calendarId: data.calendarId.present
          ? data.calendarId.value
          : this.calendarId,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WasteType(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    calendarId,
    name,
    iconKey,
    colorValue,
    notificationsEnabled,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WasteType &&
          other.id == this.id &&
          other.calendarId == this.calendarId &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.colorValue == this.colorValue &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.sortOrder == this.sortOrder);
}

class WasteTypesCompanion extends UpdateCompanion<WasteType> {
  final Value<int> id;
  final Value<int> calendarId;
  final Value<String> name;
  final Value<String> iconKey;
  final Value<int> colorValue;
  final Value<bool> notificationsEnabled;
  final Value<int> sortOrder;
  const WasteTypesCompanion({
    this.id = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  WasteTypesCompanion.insert({
    this.id = const Value.absent(),
    required int calendarId,
    required String name,
    required String iconKey,
    required int colorValue,
    this.notificationsEnabled = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : calendarId = Value(calendarId),
       name = Value(name),
       iconKey = Value(iconKey),
       colorValue = Value(colorValue);
  static Insertable<WasteType> custom({
    Expression<int>? id,
    Expression<int>? calendarId,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? colorValue,
    Expression<bool>? notificationsEnabled,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (calendarId != null) 'calendar_id': calendarId,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorValue != null) 'color_value': colorValue,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  WasteTypesCompanion copyWith({
    Value<int>? id,
    Value<int>? calendarId,
    Value<String>? name,
    Value<String>? iconKey,
    Value<int>? colorValue,
    Value<bool>? notificationsEnabled,
    Value<int>? sortOrder,
  }) {
    return WasteTypesCompanion(
      id: id ?? this.id,
      calendarId: calendarId ?? this.calendarId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<int>(calendarId.value);
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
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WasteTypesCompanion(')
          ..write('id: $id, ')
          ..write('calendarId: $calendarId, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorValue: $colorValue, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $RecurrenceRulesTable extends RecurrenceRules
    with TableInfo<$RecurrenceRulesTable, RecurrenceRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrenceRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wasteTypeIdMeta = const VerificationMeta(
    'wasteTypeId',
  );
  @override
  late final GeneratedColumn<int> wasteTypeId = GeneratedColumn<int>(
    'waste_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES waste_types (id) ON DELETE CASCADE',
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
      maxTextLength: 24,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysMaskMeta = const VerificationMeta(
    'weekdaysMask',
  );
  @override
  late final GeneratedColumn<int> weekdaysMask = GeneratedColumn<int>(
    'weekdays_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _intervalWeeksMeta = const VerificationMeta(
    'intervalWeeks',
  );
  @override
  late final GeneratedColumn<int> intervalWeeks = GeneratedColumn<int>(
    'interval_weeks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorDateMeta = const VerificationMeta(
    'anchorDate',
  );
  @override
  late final GeneratedColumn<String> anchorDate = GeneratedColumn<String>(
    'anchor_date',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nthOfMonthMeta = const VerificationMeta(
    'nthOfMonth',
  );
  @override
  late final GeneratedColumn<int> nthOfMonth = GeneratedColumn<int>(
    'nth_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _manualDatesCsvMeta = const VerificationMeta(
    'manualDatesCsv',
  );
  @override
  late final GeneratedColumn<String> manualDatesCsv = GeneratedColumn<String>(
    'manual_dates_csv',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wasteTypeId,
    kind,
    weekdaysMask,
    intervalWeeks,
    anchorDate,
    dayOfMonth,
    nthOfMonth,
    weekday,
    manualDatesCsv,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrence_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurrenceRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('waste_type_id')) {
      context.handle(
        _wasteTypeIdMeta,
        wasteTypeId.isAcceptableOrUnknown(
          data['waste_type_id']!,
          _wasteTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wasteTypeIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('weekdays_mask')) {
      context.handle(
        _weekdaysMaskMeta,
        weekdaysMask.isAcceptableOrUnknown(
          data['weekdays_mask']!,
          _weekdaysMaskMeta,
        ),
      );
    }
    if (data.containsKey('interval_weeks')) {
      context.handle(
        _intervalWeeksMeta,
        intervalWeeks.isAcceptableOrUnknown(
          data['interval_weeks']!,
          _intervalWeeksMeta,
        ),
      );
    }
    if (data.containsKey('anchor_date')) {
      context.handle(
        _anchorDateMeta,
        anchorDate.isAcceptableOrUnknown(data['anchor_date']!, _anchorDateMeta),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('nth_of_month')) {
      context.handle(
        _nthOfMonthMeta,
        nthOfMonth.isAcceptableOrUnknown(
          data['nth_of_month']!,
          _nthOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('manual_dates_csv')) {
      context.handle(
        _manualDatesCsvMeta,
        manualDatesCsv.isAcceptableOrUnknown(
          data['manual_dates_csv']!,
          _manualDatesCsvMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wasteTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}waste_type_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      weekdaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekdays_mask'],
      )!,
      intervalWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_weeks'],
      ),
      anchorDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_date'],
      ),
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      ),
      nthOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}nth_of_month'],
      ),
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      ),
      manualDatesCsv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manual_dates_csv'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
    );
  }

  @override
  $RecurrenceRulesTable createAlias(String alias) {
    return $RecurrenceRulesTable(attachedDatabase, alias);
  }
}

class RecurrenceRule extends DataClass implements Insertable<RecurrenceRule> {
  final int id;
  final int wasteTypeId;

  /// `weekly` | `everyNWeeks` | `monthlyDay` | `monthlyNthWeekday` | `manual`
  final String kind;

  /// Bitmask dei giorni: bit 0 = lunedì, bit 6 = domenica. Vedi `WeekdayMask`.
  final int weekdaysMask;

  /// Per `everyNWeeks`: ogni quante settimane. Sempre >= 2.
  final int? intervalWeeks;

  /// Per `everyNWeeks`: la data che fissa la fase del ciclo, `YYYY-MM-DD`.
  final String? anchorDate;

  /// Per `monthlyDay`: 1..31, con clamp a fine mese.
  final int? dayOfMonth;

  /// Per `monthlyNthWeekday`: 1..5 oppure -1 per "l'ultimo".
  final int? nthOfMonth;

  /// Per `monthlyNthWeekday`: 1..7.
  final int? weekday;

  /// Per `manual`: date `YYYY-MM-DD` separate da virgola.
  final String? manualDatesCsv;
  final String startDate;
  final String? endDate;
  const RecurrenceRule({
    required this.id,
    required this.wasteTypeId,
    required this.kind,
    required this.weekdaysMask,
    this.intervalWeeks,
    this.anchorDate,
    this.dayOfMonth,
    this.nthOfMonth,
    this.weekday,
    this.manualDatesCsv,
    required this.startDate,
    this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['waste_type_id'] = Variable<int>(wasteTypeId);
    map['kind'] = Variable<String>(kind);
    map['weekdays_mask'] = Variable<int>(weekdaysMask);
    if (!nullToAbsent || intervalWeeks != null) {
      map['interval_weeks'] = Variable<int>(intervalWeeks);
    }
    if (!nullToAbsent || anchorDate != null) {
      map['anchor_date'] = Variable<String>(anchorDate);
    }
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    if (!nullToAbsent || nthOfMonth != null) {
      map['nth_of_month'] = Variable<int>(nthOfMonth);
    }
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    if (!nullToAbsent || manualDatesCsv != null) {
      map['manual_dates_csv'] = Variable<String>(manualDatesCsv);
    }
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    return map;
  }

  RecurrenceRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurrenceRulesCompanion(
      id: Value(id),
      wasteTypeId: Value(wasteTypeId),
      kind: Value(kind),
      weekdaysMask: Value(weekdaysMask),
      intervalWeeks: intervalWeeks == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalWeeks),
      anchorDate: anchorDate == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorDate),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      nthOfMonth: nthOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(nthOfMonth),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      manualDatesCsv: manualDatesCsv == null && nullToAbsent
          ? const Value.absent()
          : Value(manualDatesCsv),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
    );
  }

  factory RecurrenceRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceRule(
      id: serializer.fromJson<int>(json['id']),
      wasteTypeId: serializer.fromJson<int>(json['wasteTypeId']),
      kind: serializer.fromJson<String>(json['kind']),
      weekdaysMask: serializer.fromJson<int>(json['weekdaysMask']),
      intervalWeeks: serializer.fromJson<int?>(json['intervalWeeks']),
      anchorDate: serializer.fromJson<String?>(json['anchorDate']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      nthOfMonth: serializer.fromJson<int?>(json['nthOfMonth']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      manualDatesCsv: serializer.fromJson<String?>(json['manualDatesCsv']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wasteTypeId': serializer.toJson<int>(wasteTypeId),
      'kind': serializer.toJson<String>(kind),
      'weekdaysMask': serializer.toJson<int>(weekdaysMask),
      'intervalWeeks': serializer.toJson<int?>(intervalWeeks),
      'anchorDate': serializer.toJson<String?>(anchorDate),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'nthOfMonth': serializer.toJson<int?>(nthOfMonth),
      'weekday': serializer.toJson<int?>(weekday),
      'manualDatesCsv': serializer.toJson<String?>(manualDatesCsv),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
    };
  }

  RecurrenceRule copyWith({
    int? id,
    int? wasteTypeId,
    String? kind,
    int? weekdaysMask,
    Value<int?> intervalWeeks = const Value.absent(),
    Value<String?> anchorDate = const Value.absent(),
    Value<int?> dayOfMonth = const Value.absent(),
    Value<int?> nthOfMonth = const Value.absent(),
    Value<int?> weekday = const Value.absent(),
    Value<String?> manualDatesCsv = const Value.absent(),
    String? startDate,
    Value<String?> endDate = const Value.absent(),
  }) => RecurrenceRule(
    id: id ?? this.id,
    wasteTypeId: wasteTypeId ?? this.wasteTypeId,
    kind: kind ?? this.kind,
    weekdaysMask: weekdaysMask ?? this.weekdaysMask,
    intervalWeeks: intervalWeeks.present
        ? intervalWeeks.value
        : this.intervalWeeks,
    anchorDate: anchorDate.present ? anchorDate.value : this.anchorDate,
    dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
    nthOfMonth: nthOfMonth.present ? nthOfMonth.value : this.nthOfMonth,
    weekday: weekday.present ? weekday.value : this.weekday,
    manualDatesCsv: manualDatesCsv.present
        ? manualDatesCsv.value
        : this.manualDatesCsv,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
  );
  RecurrenceRule copyWithCompanion(RecurrenceRulesCompanion data) {
    return RecurrenceRule(
      id: data.id.present ? data.id.value : this.id,
      wasteTypeId: data.wasteTypeId.present
          ? data.wasteTypeId.value
          : this.wasteTypeId,
      kind: data.kind.present ? data.kind.value : this.kind,
      weekdaysMask: data.weekdaysMask.present
          ? data.weekdaysMask.value
          : this.weekdaysMask,
      intervalWeeks: data.intervalWeeks.present
          ? data.intervalWeeks.value
          : this.intervalWeeks,
      anchorDate: data.anchorDate.present
          ? data.anchorDate.value
          : this.anchorDate,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      nthOfMonth: data.nthOfMonth.present
          ? data.nthOfMonth.value
          : this.nthOfMonth,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      manualDatesCsv: data.manualDatesCsv.present
          ? data.manualDatesCsv.value
          : this.manualDatesCsv,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceRule(')
          ..write('id: $id, ')
          ..write('wasteTypeId: $wasteTypeId, ')
          ..write('kind: $kind, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('intervalWeeks: $intervalWeeks, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('nthOfMonth: $nthOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('manualDatesCsv: $manualDatesCsv, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wasteTypeId,
    kind,
    weekdaysMask,
    intervalWeeks,
    anchorDate,
    dayOfMonth,
    nthOfMonth,
    weekday,
    manualDatesCsv,
    startDate,
    endDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceRule &&
          other.id == this.id &&
          other.wasteTypeId == this.wasteTypeId &&
          other.kind == this.kind &&
          other.weekdaysMask == this.weekdaysMask &&
          other.intervalWeeks == this.intervalWeeks &&
          other.anchorDate == this.anchorDate &&
          other.dayOfMonth == this.dayOfMonth &&
          other.nthOfMonth == this.nthOfMonth &&
          other.weekday == this.weekday &&
          other.manualDatesCsv == this.manualDatesCsv &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class RecurrenceRulesCompanion extends UpdateCompanion<RecurrenceRule> {
  final Value<int> id;
  final Value<int> wasteTypeId;
  final Value<String> kind;
  final Value<int> weekdaysMask;
  final Value<int?> intervalWeeks;
  final Value<String?> anchorDate;
  final Value<int?> dayOfMonth;
  final Value<int?> nthOfMonth;
  final Value<int?> weekday;
  final Value<String?> manualDatesCsv;
  final Value<String> startDate;
  final Value<String?> endDate;
  const RecurrenceRulesCompanion({
    this.id = const Value.absent(),
    this.wasteTypeId = const Value.absent(),
    this.kind = const Value.absent(),
    this.weekdaysMask = const Value.absent(),
    this.intervalWeeks = const Value.absent(),
    this.anchorDate = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.nthOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    this.manualDatesCsv = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
  });
  RecurrenceRulesCompanion.insert({
    this.id = const Value.absent(),
    required int wasteTypeId,
    required String kind,
    this.weekdaysMask = const Value.absent(),
    this.intervalWeeks = const Value.absent(),
    this.anchorDate = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.nthOfMonth = const Value.absent(),
    this.weekday = const Value.absent(),
    this.manualDatesCsv = const Value.absent(),
    required String startDate,
    this.endDate = const Value.absent(),
  }) : wasteTypeId = Value(wasteTypeId),
       kind = Value(kind),
       startDate = Value(startDate);
  static Insertable<RecurrenceRule> custom({
    Expression<int>? id,
    Expression<int>? wasteTypeId,
    Expression<String>? kind,
    Expression<int>? weekdaysMask,
    Expression<int>? intervalWeeks,
    Expression<String>? anchorDate,
    Expression<int>? dayOfMonth,
    Expression<int>? nthOfMonth,
    Expression<int>? weekday,
    Expression<String>? manualDatesCsv,
    Expression<String>? startDate,
    Expression<String>? endDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wasteTypeId != null) 'waste_type_id': wasteTypeId,
      if (kind != null) 'kind': kind,
      if (weekdaysMask != null) 'weekdays_mask': weekdaysMask,
      if (intervalWeeks != null) 'interval_weeks': intervalWeeks,
      if (anchorDate != null) 'anchor_date': anchorDate,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (nthOfMonth != null) 'nth_of_month': nthOfMonth,
      if (weekday != null) 'weekday': weekday,
      if (manualDatesCsv != null) 'manual_dates_csv': manualDatesCsv,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    });
  }

  RecurrenceRulesCompanion copyWith({
    Value<int>? id,
    Value<int>? wasteTypeId,
    Value<String>? kind,
    Value<int>? weekdaysMask,
    Value<int?>? intervalWeeks,
    Value<String?>? anchorDate,
    Value<int?>? dayOfMonth,
    Value<int?>? nthOfMonth,
    Value<int?>? weekday,
    Value<String?>? manualDatesCsv,
    Value<String>? startDate,
    Value<String?>? endDate,
  }) {
    return RecurrenceRulesCompanion(
      id: id ?? this.id,
      wasteTypeId: wasteTypeId ?? this.wasteTypeId,
      kind: kind ?? this.kind,
      weekdaysMask: weekdaysMask ?? this.weekdaysMask,
      intervalWeeks: intervalWeeks ?? this.intervalWeeks,
      anchorDate: anchorDate ?? this.anchorDate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nthOfMonth: nthOfMonth ?? this.nthOfMonth,
      weekday: weekday ?? this.weekday,
      manualDatesCsv: manualDatesCsv ?? this.manualDatesCsv,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wasteTypeId.present) {
      map['waste_type_id'] = Variable<int>(wasteTypeId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (weekdaysMask.present) {
      map['weekdays_mask'] = Variable<int>(weekdaysMask.value);
    }
    if (intervalWeeks.present) {
      map['interval_weeks'] = Variable<int>(intervalWeeks.value);
    }
    if (anchorDate.present) {
      map['anchor_date'] = Variable<String>(anchorDate.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (nthOfMonth.present) {
      map['nth_of_month'] = Variable<int>(nthOfMonth.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (manualDatesCsv.present) {
      map['manual_dates_csv'] = Variable<String>(manualDatesCsv.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceRulesCompanion(')
          ..write('id: $id, ')
          ..write('wasteTypeId: $wasteTypeId, ')
          ..write('kind: $kind, ')
          ..write('weekdaysMask: $weekdaysMask, ')
          ..write('intervalWeeks: $intervalWeeks, ')
          ..write('anchorDate: $anchorDate, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('nthOfMonth: $nthOfMonth, ')
          ..write('weekday: $weekday, ')
          ..write('manualDatesCsv: $manualDatesCsv, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }
}

class $CollectionExceptionsTable extends CollectionExceptions
    with TableInfo<$CollectionExceptionsTable, ExceptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionExceptionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wasteTypeIdMeta = const VerificationMeta(
    'wasteTypeId',
  );
  @override
  late final GeneratedColumn<int> wasteTypeId = GeneratedColumn<int>(
    'waste_type_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES waste_types (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalDateMeta = const VerificationMeta(
    'originalDate',
  );
  @override
  late final GeneratedColumn<String> originalDate = GeneratedColumn<String>(
    'original_date',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replacementDateMeta = const VerificationMeta(
    'replacementDate',
  );
  @override
  late final GeneratedColumn<String> replacementDate = GeneratedColumn<String>(
    'replacement_date',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
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
    wasteTypeId,
    originalDate,
    replacementDate,
    skipped,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExceptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('waste_type_id')) {
      context.handle(
        _wasteTypeIdMeta,
        wasteTypeId.isAcceptableOrUnknown(
          data['waste_type_id']!,
          _wasteTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wasteTypeIdMeta);
    }
    if (data.containsKey('original_date')) {
      context.handle(
        _originalDateMeta,
        originalDate.isAcceptableOrUnknown(
          data['original_date']!,
          _originalDateMeta,
        ),
      );
    }
    if (data.containsKey('replacement_date')) {
      context.handle(
        _replacementDateMeta,
        replacementDate.isAcceptableOrUnknown(
          data['replacement_date']!,
          _replacementDateMeta,
        ),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  ExceptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExceptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wasteTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}waste_type_id'],
      )!,
      originalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_date'],
      ),
      replacementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replacement_date'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CollectionExceptionsTable createAlias(String alias) {
    return $CollectionExceptionsTable(attachedDatabase, alias);
  }
}

class ExceptionRow extends DataClass implements Insertable<ExceptionRow> {
  final int id;
  final int wasteTypeId;
  final String? originalDate;
  final String? replacementDate;
  final bool skipped;
  final String? note;
  final int createdAt;
  const ExceptionRow({
    required this.id,
    required this.wasteTypeId,
    this.originalDate,
    this.replacementDate,
    required this.skipped,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['waste_type_id'] = Variable<int>(wasteTypeId);
    if (!nullToAbsent || originalDate != null) {
      map['original_date'] = Variable<String>(originalDate);
    }
    if (!nullToAbsent || replacementDate != null) {
      map['replacement_date'] = Variable<String>(replacementDate);
    }
    map['skipped'] = Variable<bool>(skipped);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CollectionExceptionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionExceptionsCompanion(
      id: Value(id),
      wasteTypeId: Value(wasteTypeId),
      originalDate: originalDate == null && nullToAbsent
          ? const Value.absent()
          : Value(originalDate),
      replacementDate: replacementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementDate),
      skipped: Value(skipped),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory ExceptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExceptionRow(
      id: serializer.fromJson<int>(json['id']),
      wasteTypeId: serializer.fromJson<int>(json['wasteTypeId']),
      originalDate: serializer.fromJson<String?>(json['originalDate']),
      replacementDate: serializer.fromJson<String?>(json['replacementDate']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wasteTypeId': serializer.toJson<int>(wasteTypeId),
      'originalDate': serializer.toJson<String?>(originalDate),
      'replacementDate': serializer.toJson<String?>(replacementDate),
      'skipped': serializer.toJson<bool>(skipped),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ExceptionRow copyWith({
    int? id,
    int? wasteTypeId,
    Value<String?> originalDate = const Value.absent(),
    Value<String?> replacementDate = const Value.absent(),
    bool? skipped,
    Value<String?> note = const Value.absent(),
    int? createdAt,
  }) => ExceptionRow(
    id: id ?? this.id,
    wasteTypeId: wasteTypeId ?? this.wasteTypeId,
    originalDate: originalDate.present ? originalDate.value : this.originalDate,
    replacementDate: replacementDate.present
        ? replacementDate.value
        : this.replacementDate,
    skipped: skipped ?? this.skipped,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  ExceptionRow copyWithCompanion(CollectionExceptionsCompanion data) {
    return ExceptionRow(
      id: data.id.present ? data.id.value : this.id,
      wasteTypeId: data.wasteTypeId.present
          ? data.wasteTypeId.value
          : this.wasteTypeId,
      originalDate: data.originalDate.present
          ? data.originalDate.value
          : this.originalDate,
      replacementDate: data.replacementDate.present
          ? data.replacementDate.value
          : this.replacementDate,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExceptionRow(')
          ..write('id: $id, ')
          ..write('wasteTypeId: $wasteTypeId, ')
          ..write('originalDate: $originalDate, ')
          ..write('replacementDate: $replacementDate, ')
          ..write('skipped: $skipped, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wasteTypeId,
    originalDate,
    replacementDate,
    skipped,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExceptionRow &&
          other.id == this.id &&
          other.wasteTypeId == this.wasteTypeId &&
          other.originalDate == this.originalDate &&
          other.replacementDate == this.replacementDate &&
          other.skipped == this.skipped &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class CollectionExceptionsCompanion extends UpdateCompanion<ExceptionRow> {
  final Value<int> id;
  final Value<int> wasteTypeId;
  final Value<String?> originalDate;
  final Value<String?> replacementDate;
  final Value<bool> skipped;
  final Value<String?> note;
  final Value<int> createdAt;
  const CollectionExceptionsCompanion({
    this.id = const Value.absent(),
    this.wasteTypeId = const Value.absent(),
    this.originalDate = const Value.absent(),
    this.replacementDate = const Value.absent(),
    this.skipped = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CollectionExceptionsCompanion.insert({
    this.id = const Value.absent(),
    required int wasteTypeId,
    this.originalDate = const Value.absent(),
    this.replacementDate = const Value.absent(),
    this.skipped = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
  }) : wasteTypeId = Value(wasteTypeId),
       createdAt = Value(createdAt);
  static Insertable<ExceptionRow> custom({
    Expression<int>? id,
    Expression<int>? wasteTypeId,
    Expression<String>? originalDate,
    Expression<String>? replacementDate,
    Expression<bool>? skipped,
    Expression<String>? note,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wasteTypeId != null) 'waste_type_id': wasteTypeId,
      if (originalDate != null) 'original_date': originalDate,
      if (replacementDate != null) 'replacement_date': replacementDate,
      if (skipped != null) 'skipped': skipped,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CollectionExceptionsCompanion copyWith({
    Value<int>? id,
    Value<int>? wasteTypeId,
    Value<String?>? originalDate,
    Value<String?>? replacementDate,
    Value<bool>? skipped,
    Value<String?>? note,
    Value<int>? createdAt,
  }) {
    return CollectionExceptionsCompanion(
      id: id ?? this.id,
      wasteTypeId: wasteTypeId ?? this.wasteTypeId,
      originalDate: originalDate ?? this.originalDate,
      replacementDate: replacementDate ?? this.replacementDate,
      skipped: skipped ?? this.skipped,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wasteTypeId.present) {
      map['waste_type_id'] = Variable<int>(wasteTypeId.value);
    }
    if (originalDate.present) {
      map['original_date'] = Variable<String>(originalDate.value);
    }
    if (replacementDate.present) {
      map['replacement_date'] = Variable<String>(replacementDate.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionExceptionsCompanion(')
          ..write('id: $id, ')
          ..write('wasteTypeId: $wasteTypeId, ')
          ..write('originalDate: $originalDate, ')
          ..write('replacementDate: $replacementDate, ')
          ..write('skipped: $skipped, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CollectionCalendarsTable collectionCalendars =
      $CollectionCalendarsTable(this);
  late final $WasteTypesTable wasteTypes = $WasteTypesTable(this);
  late final $RecurrenceRulesTable recurrenceRules = $RecurrenceRulesTable(
    this,
  );
  late final $CollectionExceptionsTable collectionExceptions =
      $CollectionExceptionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    collectionCalendars,
    wasteTypes,
    recurrenceRules,
    collectionExceptions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'collection_calendars',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('waste_types', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'waste_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recurrence_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'waste_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('collection_exceptions', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CollectionCalendarsTableCreateCompanionBuilder =
    CollectionCalendarsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> notificationTime,
      Value<String?> secondNotificationTime,
      Value<bool> enabled,
      Value<int> sortOrder,
      required int createdAt,
    });
typedef $$CollectionCalendarsTableUpdateCompanionBuilder =
    CollectionCalendarsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> notificationTime,
      Value<String?> secondNotificationTime,
      Value<bool> enabled,
      Value<int> sortOrder,
      Value<int> createdAt,
    });

final class $$CollectionCalendarsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectionCalendarsTable,
          CollectionCalendar
        > {
  $$CollectionCalendarsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$WasteTypesTable, List<WasteType>>
  _wasteTypesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wasteTypes,
    aliasName: 'collection_calendars__id__waste_types__calendar_id',
  );

  $$WasteTypesTableProcessedTableManager get wasteTypesRefs {
    final manager = $$WasteTypesTableTableManager(
      $_db,
      $_db.wasteTypes,
    ).filter((f) => f.calendarId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wasteTypesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CollectionCalendarsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionCalendarsTable> {
  $$CollectionCalendarsTableFilterComposer({
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

  ColumnFilters<String> get notificationTime => $composableBuilder(
    column: $table.notificationTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondNotificationTime => $composableBuilder(
    column: $table.secondNotificationTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
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

  Expression<bool> wasteTypesRefs(
    Expression<bool> Function($$WasteTypesTableFilterComposer f) f,
  ) {
    final $$WasteTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableFilterComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionCalendarsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionCalendarsTable> {
  $$CollectionCalendarsTableOrderingComposer({
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

  ColumnOrderings<String> get notificationTime => $composableBuilder(
    column: $table.notificationTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondNotificationTime => $composableBuilder(
    column: $table.secondNotificationTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
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

class $$CollectionCalendarsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionCalendarsTable> {
  $$CollectionCalendarsTableAnnotationComposer({
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

  GeneratedColumn<String> get notificationTime => $composableBuilder(
    column: $table.notificationTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondNotificationTime => $composableBuilder(
    column: $table.secondNotificationTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> wasteTypesRefs<T extends Object>(
    Expression<T> Function($$WasteTypesTableAnnotationComposer a) f,
  ) {
    final $$WasteTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.calendarId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CollectionCalendarsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionCalendarsTable,
          CollectionCalendar,
          $$CollectionCalendarsTableFilterComposer,
          $$CollectionCalendarsTableOrderingComposer,
          $$CollectionCalendarsTableAnnotationComposer,
          $$CollectionCalendarsTableCreateCompanionBuilder,
          $$CollectionCalendarsTableUpdateCompanionBuilder,
          (CollectionCalendar, $$CollectionCalendarsTableReferences),
          CollectionCalendar,
          PrefetchHooks Function({bool wasteTypesRefs})
        > {
  $$CollectionCalendarsTableTableManager(
    _$AppDatabase db,
    $CollectionCalendarsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionCalendarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionCalendarsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectionCalendarsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> notificationTime = const Value.absent(),
                Value<String?> secondNotificationTime = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CollectionCalendarsCompanion(
                id: id,
                name: name,
                notificationTime: notificationTime,
                secondNotificationTime: secondNotificationTime,
                enabled: enabled,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> notificationTime = const Value.absent(),
                Value<String?> secondNotificationTime = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
              }) => CollectionCalendarsCompanion.insert(
                id: id,
                name: name,
                notificationTime: notificationTime,
                secondNotificationTime: secondNotificationTime,
                enabled: enabled,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionCalendarsTable, CollectionCalendar>(
                    table,
                  ),
                  $$CollectionCalendarsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wasteTypesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (wasteTypesRefs) db.wasteTypes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wasteTypesRefs)
                    await $_getPrefetchedData<
                      CollectionCalendar,
                      $CollectionCalendarsTable,
                      WasteType
                    >(
                      currentTable: table,
                      referencedTable: $$CollectionCalendarsTableReferences
                          ._wasteTypesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CollectionCalendarsTableReferences(
                            db,
                            table,
                            p0,
                          ).wasteTypesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.calendarId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CollectionCalendarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionCalendarsTable,
      CollectionCalendar,
      $$CollectionCalendarsTableFilterComposer,
      $$CollectionCalendarsTableOrderingComposer,
      $$CollectionCalendarsTableAnnotationComposer,
      $$CollectionCalendarsTableCreateCompanionBuilder,
      $$CollectionCalendarsTableUpdateCompanionBuilder,
      (CollectionCalendar, $$CollectionCalendarsTableReferences),
      CollectionCalendar,
      PrefetchHooks Function({bool wasteTypesRefs})
    >;
typedef $$WasteTypesTableCreateCompanionBuilder = WasteTypesCompanion Function({
  Value<int> id,
  required int calendarId,
  required String name,
  required String iconKey,
  required int colorValue,
  Value<bool> notificationsEnabled,
  Value<int> sortOrder,
});
typedef $$WasteTypesTableUpdateCompanionBuilder = WasteTypesCompanion Function({
  Value<int> id,
  Value<int> calendarId,
  Value<String> name,
  Value<String> iconKey,
  Value<int> colorValue,
  Value<bool> notificationsEnabled,
  Value<int> sortOrder,
});

final class $$WasteTypesTableReferences
    extends BaseReferences<_$AppDatabase, $WasteTypesTable, WasteType> {
  $$WasteTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CollectionCalendarsTable _calendarIdTable(_$AppDatabase db) => db
      .collectionCalendars
      .createAlias('waste_types__calendar_id__collection_calendars__id');

  $$CollectionCalendarsTableProcessedTableManager get calendarId {
    final $_column = $_itemColumn<int>('calendar_id')!;

    final manager = $$CollectionCalendarsTableTableManager(
      $_db,
      $_db.collectionCalendars,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_calendarIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RecurrenceRulesTable, List<RecurrenceRule>>
  _recurrenceRulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recurrenceRules,
    aliasName: 'waste_types__id__recurrence_rules__waste_type_id',
  );

  $$RecurrenceRulesTableProcessedTableManager get recurrenceRulesRefs {
    final manager = $$RecurrenceRulesTableTableManager(
      $_db,
      $_db.recurrenceRules,
    ).filter((f) => f.wasteTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recurrenceRulesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CollectionExceptionsTable, List<ExceptionRow>>
  _collectionExceptionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.collectionExceptions,
        aliasName: 'waste_types__id__collection_exceptions__waste_type_id',
      );

  $$CollectionExceptionsTableProcessedTableManager
  get collectionExceptionsRefs {
    final manager = $$CollectionExceptionsTableTableManager(
      $_db,
      $_db.collectionExceptions,
    ).filter((f) => f.wasteTypeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _collectionExceptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WasteTypesTableFilterComposer
    extends Composer<_$AppDatabase, $WasteTypesTable> {
  $$WasteTypesTableFilterComposer({
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

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$CollectionCalendarsTableFilterComposer get calendarId {
    final $$CollectionCalendarsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.calendarId,
      referencedTable: $db.collectionCalendars,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionCalendarsTableFilterComposer(
            $db: $db,
            $table: $db.collectionCalendars,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> recurrenceRulesRefs(
    Expression<bool> Function($$RecurrenceRulesTableFilterComposer f) f,
  ) {
    final $$RecurrenceRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurrenceRules,
      getReferencedColumn: (t) => t.wasteTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurrenceRulesTableFilterComposer(
            $db: $db,
            $table: $db.recurrenceRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> collectionExceptionsRefs(
    Expression<bool> Function($$CollectionExceptionsTableFilterComposer f) f,
  ) {
    final $$CollectionExceptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.collectionExceptions,
      getReferencedColumn: (t) => t.wasteTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CollectionExceptionsTableFilterComposer(
            $db: $db,
            $table: $db.collectionExceptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WasteTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $WasteTypesTable> {
  $$WasteTypesTableOrderingComposer({
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

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$CollectionCalendarsTableOrderingComposer get calendarId {
    final $$CollectionCalendarsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.calendarId,
          referencedTable: $db.collectionCalendars,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectionCalendarsTableOrderingComposer(
                $db: $db,
                $table: $db.collectionCalendars,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$WasteTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WasteTypesTable> {
  $$WasteTypesTableAnnotationComposer({
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

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$CollectionCalendarsTableAnnotationComposer get calendarId {
    final $$CollectionCalendarsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.calendarId,
          referencedTable: $db.collectionCalendars,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectionCalendarsTableAnnotationComposer(
                $db: $db,
                $table: $db.collectionCalendars,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> recurrenceRulesRefs<T extends Object>(
    Expression<T> Function($$RecurrenceRulesTableAnnotationComposer a) f,
  ) {
    final $$RecurrenceRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recurrenceRules,
      getReferencedColumn: (t) => t.wasteTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurrenceRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.recurrenceRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> collectionExceptionsRefs<T extends Object>(
    Expression<T> Function($$CollectionExceptionsTableAnnotationComposer a) f,
  ) {
    final $$CollectionExceptionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.collectionExceptions,
          getReferencedColumn: (t) => t.wasteTypeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CollectionExceptionsTableAnnotationComposer(
                $db: $db,
                $table: $db.collectionExceptions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WasteTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WasteTypesTable,
          WasteType,
          $$WasteTypesTableFilterComposer,
          $$WasteTypesTableOrderingComposer,
          $$WasteTypesTableAnnotationComposer,
          $$WasteTypesTableCreateCompanionBuilder,
          $$WasteTypesTableUpdateCompanionBuilder,
          (WasteType, $$WasteTypesTableReferences),
          WasteType,
          PrefetchHooks Function({
            bool calendarId,
            bool recurrenceRulesRefs,
            bool collectionExceptionsRefs,
          })
        > {
  $$WasteTypesTableTableManager(_$AppDatabase db, $WasteTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WasteTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WasteTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WasteTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> calendarId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => WasteTypesCompanion(
                id: id,
                calendarId: calendarId,
                name: name,
                iconKey: iconKey,
                colorValue: colorValue,
                notificationsEnabled: notificationsEnabled,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int calendarId,
                required String name,
                required String iconKey,
                required int colorValue,
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => WasteTypesCompanion.insert(
                id: id,
                calendarId: calendarId,
                name: name,
                iconKey: iconKey,
                colorValue: colorValue,
                notificationsEnabled: notificationsEnabled,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WasteTypesTable, WasteType>(table),
                  $$WasteTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                calendarId = false,
                recurrenceRulesRefs = false,
                collectionExceptionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (recurrenceRulesRefs) db.recurrenceRules,
                    if (collectionExceptionsRefs) db.collectionExceptions,
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
                        if (calendarId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.calendarId,
                            referencedTable: $$WasteTypesTableReferences
                                ._calendarIdTable(db),
                            referencedColumn: $$WasteTypesTableReferences
                                ._calendarIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (recurrenceRulesRefs)
                        await $_getPrefetchedData<
                          WasteType,
                          $WasteTypesTable,
                          RecurrenceRule
                        >(
                          currentTable: table,
                          referencedTable: $$WasteTypesTableReferences
                              ._recurrenceRulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WasteTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).recurrenceRulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wasteTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (collectionExceptionsRefs)
                        await $_getPrefetchedData<
                          WasteType,
                          $WasteTypesTable,
                          ExceptionRow
                        >(
                          currentTable: table,
                          referencedTable: $$WasteTypesTableReferences
                              ._collectionExceptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WasteTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).collectionExceptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.wasteTypeId == item.id,
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

typedef $$WasteTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WasteTypesTable,
      WasteType,
      $$WasteTypesTableFilterComposer,
      $$WasteTypesTableOrderingComposer,
      $$WasteTypesTableAnnotationComposer,
      $$WasteTypesTableCreateCompanionBuilder,
      $$WasteTypesTableUpdateCompanionBuilder,
      (WasteType, $$WasteTypesTableReferences),
      WasteType,
      PrefetchHooks Function({
        bool calendarId,
        bool recurrenceRulesRefs,
        bool collectionExceptionsRefs,
      })
    >;
typedef $$RecurrenceRulesTableCreateCompanionBuilder =
    RecurrenceRulesCompanion Function({
      Value<int> id,
      required int wasteTypeId,
      required String kind,
      Value<int> weekdaysMask,
      Value<int?> intervalWeeks,
      Value<String?> anchorDate,
      Value<int?> dayOfMonth,
      Value<int?> nthOfMonth,
      Value<int?> weekday,
      Value<String?> manualDatesCsv,
      required String startDate,
      Value<String?> endDate,
    });
typedef $$RecurrenceRulesTableUpdateCompanionBuilder =
    RecurrenceRulesCompanion Function({
      Value<int> id,
      Value<int> wasteTypeId,
      Value<String> kind,
      Value<int> weekdaysMask,
      Value<int?> intervalWeeks,
      Value<String?> anchorDate,
      Value<int?> dayOfMonth,
      Value<int?> nthOfMonth,
      Value<int?> weekday,
      Value<String?> manualDatesCsv,
      Value<String> startDate,
      Value<String?> endDate,
    });

final class $$RecurrenceRulesTableReferences
    extends
        BaseReferences<_$AppDatabase, $RecurrenceRulesTable, RecurrenceRule> {
  $$RecurrenceRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WasteTypesTable _wasteTypeIdTable(_$AppDatabase db) => db.wasteTypes
      .createAlias('recurrence_rules__waste_type_id__waste_types__id');

  $$WasteTypesTableProcessedTableManager get wasteTypeId {
    final $_column = $_itemColumn<int>('waste_type_id')!;

    final manager = $$WasteTypesTableTableManager(
      $_db,
      $_db.wasteTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wasteTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecurrenceRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrenceRulesTable> {
  $$RecurrenceRulesTableFilterComposer({
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

  ColumnFilters<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalWeeks => $composableBuilder(
    column: $table.intervalWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nthOfMonth => $composableBuilder(
    column: $table.nthOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manualDatesCsv => $composableBuilder(
    column: $table.manualDatesCsv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  $$WasteTypesTableFilterComposer get wasteTypeId {
    final $$WasteTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wasteTypeId,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableFilterComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurrenceRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrenceRulesTable> {
  $$RecurrenceRulesTableOrderingComposer({
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

  ColumnOrderings<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalWeeks => $composableBuilder(
    column: $table.intervalWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nthOfMonth => $composableBuilder(
    column: $table.nthOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manualDatesCsv => $composableBuilder(
    column: $table.manualDatesCsv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$WasteTypesTableOrderingComposer get wasteTypeId {
    final $$WasteTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wasteTypeId,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableOrderingComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurrenceRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrenceRulesTable> {
  $$RecurrenceRulesTableAnnotationComposer({
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

  GeneratedColumn<int> get weekdaysMask => $composableBuilder(
    column: $table.weekdaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalWeeks => $composableBuilder(
    column: $table.intervalWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchorDate => $composableBuilder(
    column: $table.anchorDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nthOfMonth => $composableBuilder(
    column: $table.nthOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get manualDatesCsv => $composableBuilder(
    column: $table.manualDatesCsv,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  $$WasteTypesTableAnnotationComposer get wasteTypeId {
    final $$WasteTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wasteTypeId,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecurrenceRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurrenceRulesTable,
          RecurrenceRule,
          $$RecurrenceRulesTableFilterComposer,
          $$RecurrenceRulesTableOrderingComposer,
          $$RecurrenceRulesTableAnnotationComposer,
          $$RecurrenceRulesTableCreateCompanionBuilder,
          $$RecurrenceRulesTableUpdateCompanionBuilder,
          (RecurrenceRule, $$RecurrenceRulesTableReferences),
          RecurrenceRule,
          PrefetchHooks Function({bool wasteTypeId})
        > {
  $$RecurrenceRulesTableTableManager(
    _$AppDatabase db,
    $RecurrenceRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrenceRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrenceRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrenceRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wasteTypeId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> weekdaysMask = const Value.absent(),
                Value<int?> intervalWeeks = const Value.absent(),
                Value<String?> anchorDate = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<int?> nthOfMonth = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<String?> manualDatesCsv = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
              }) => RecurrenceRulesCompanion(
                id: id,
                wasteTypeId: wasteTypeId,
                kind: kind,
                weekdaysMask: weekdaysMask,
                intervalWeeks: intervalWeeks,
                anchorDate: anchorDate,
                dayOfMonth: dayOfMonth,
                nthOfMonth: nthOfMonth,
                weekday: weekday,
                manualDatesCsv: manualDatesCsv,
                startDate: startDate,
                endDate: endDate,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wasteTypeId,
                required String kind,
                Value<int> weekdaysMask = const Value.absent(),
                Value<int?> intervalWeeks = const Value.absent(),
                Value<String?> anchorDate = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<int?> nthOfMonth = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<String?> manualDatesCsv = const Value.absent(),
                required String startDate,
                Value<String?> endDate = const Value.absent(),
              }) => RecurrenceRulesCompanion.insert(
                id: id,
                wasteTypeId: wasteTypeId,
                kind: kind,
                weekdaysMask: weekdaysMask,
                intervalWeeks: intervalWeeks,
                anchorDate: anchorDate,
                dayOfMonth: dayOfMonth,
                nthOfMonth: nthOfMonth,
                weekday: weekday,
                manualDatesCsv: manualDatesCsv,
                startDate: startDate,
                endDate: endDate,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurrenceRulesTable, RecurrenceRule>(table),
                  $$RecurrenceRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wasteTypeId = false}) {
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
                    if (wasteTypeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wasteTypeId,
                        referencedTable: $$RecurrenceRulesTableReferences
                            ._wasteTypeIdTable(db),
                        referencedColumn: $$RecurrenceRulesTableReferences
                            ._wasteTypeIdTable(db)
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

typedef $$RecurrenceRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurrenceRulesTable,
      RecurrenceRule,
      $$RecurrenceRulesTableFilterComposer,
      $$RecurrenceRulesTableOrderingComposer,
      $$RecurrenceRulesTableAnnotationComposer,
      $$RecurrenceRulesTableCreateCompanionBuilder,
      $$RecurrenceRulesTableUpdateCompanionBuilder,
      (RecurrenceRule, $$RecurrenceRulesTableReferences),
      RecurrenceRule,
      PrefetchHooks Function({bool wasteTypeId})
    >;
typedef $$CollectionExceptionsTableCreateCompanionBuilder =
    CollectionExceptionsCompanion Function({
      Value<int> id,
      required int wasteTypeId,
      Value<String?> originalDate,
      Value<String?> replacementDate,
      Value<bool> skipped,
      Value<String?> note,
      required int createdAt,
    });
typedef $$CollectionExceptionsTableUpdateCompanionBuilder =
    CollectionExceptionsCompanion Function({
      Value<int> id,
      Value<int> wasteTypeId,
      Value<String?> originalDate,
      Value<String?> replacementDate,
      Value<bool> skipped,
      Value<String?> note,
      Value<int> createdAt,
    });

final class $$CollectionExceptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CollectionExceptionsTable,
          ExceptionRow
        > {
  $$CollectionExceptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WasteTypesTable _wasteTypeIdTable(_$AppDatabase db) => db.wasteTypes
      .createAlias('collection_exceptions__waste_type_id__waste_types__id');

  $$WasteTypesTableProcessedTableManager get wasteTypeId {
    final $_column = $_itemColumn<int>('waste_type_id')!;

    final manager = $$WasteTypesTableTableManager(
      $_db,
      $_db.wasteTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wasteTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CollectionExceptionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionExceptionsTable> {
  $$CollectionExceptionsTableFilterComposer({
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

  ColumnFilters<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacementDate => $composableBuilder(
    column: $table.replacementDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WasteTypesTableFilterComposer get wasteTypeId {
    final $$WasteTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wasteTypeId,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableFilterComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionExceptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionExceptionsTable> {
  $$CollectionExceptionsTableOrderingComposer({
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

  ColumnOrderings<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacementDate => $composableBuilder(
    column: $table.replacementDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WasteTypesTableOrderingComposer get wasteTypeId {
    final $$WasteTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wasteTypeId,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableOrderingComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionExceptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionExceptionsTable> {
  $$CollectionExceptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalDate => $composableBuilder(
    column: $table.originalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replacementDate => $composableBuilder(
    column: $table.replacementDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$WasteTypesTableAnnotationComposer get wasteTypeId {
    final $$WasteTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wasteTypeId,
      referencedTable: $db.wasteTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WasteTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.wasteTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CollectionExceptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionExceptionsTable,
          ExceptionRow,
          $$CollectionExceptionsTableFilterComposer,
          $$CollectionExceptionsTableOrderingComposer,
          $$CollectionExceptionsTableAnnotationComposer,
          $$CollectionExceptionsTableCreateCompanionBuilder,
          $$CollectionExceptionsTableUpdateCompanionBuilder,
          (ExceptionRow, $$CollectionExceptionsTableReferences),
          ExceptionRow,
          PrefetchHooks Function({bool wasteTypeId})
        > {
  $$CollectionExceptionsTableTableManager(
    _$AppDatabase db,
    $CollectionExceptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionExceptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionExceptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectionExceptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wasteTypeId = const Value.absent(),
                Value<String?> originalDate = const Value.absent(),
                Value<String?> replacementDate = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => CollectionExceptionsCompanion(
                id: id,
                wasteTypeId: wasteTypeId,
                originalDate: originalDate,
                replacementDate: replacementDate,
                skipped: skipped,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wasteTypeId,
                Value<String?> originalDate = const Value.absent(),
                Value<String?> replacementDate = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdAt,
              }) => CollectionExceptionsCompanion.insert(
                id: id,
                wasteTypeId: wasteTypeId,
                originalDate: originalDate,
                replacementDate: replacementDate,
                skipped: skipped,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionExceptionsTable, ExceptionRow>(table),
                  $$CollectionExceptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wasteTypeId = false}) {
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
                    if (wasteTypeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wasteTypeId,
                        referencedTable: $$CollectionExceptionsTableReferences
                            ._wasteTypeIdTable(db),
                        referencedColumn: $$CollectionExceptionsTableReferences
                            ._wasteTypeIdTable(db)
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

typedef $$CollectionExceptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionExceptionsTable,
      ExceptionRow,
      $$CollectionExceptionsTableFilterComposer,
      $$CollectionExceptionsTableOrderingComposer,
      $$CollectionExceptionsTableAnnotationComposer,
      $$CollectionExceptionsTableCreateCompanionBuilder,
      $$CollectionExceptionsTableUpdateCompanionBuilder,
      (ExceptionRow, $$CollectionExceptionsTableReferences),
      ExceptionRow,
      PrefetchHooks Function({bool wasteTypeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CollectionCalendarsTableTableManager get collectionCalendars =>
      $$CollectionCalendarsTableTableManager(_db, _db.collectionCalendars);
  $$WasteTypesTableTableManager get wasteTypes =>
      $$WasteTypesTableTableManager(_db, _db.wasteTypes);
  $$RecurrenceRulesTableTableManager get recurrenceRules =>
      $$RecurrenceRulesTableTableManager(_db, _db.recurrenceRules);
  $$CollectionExceptionsTableTableManager get collectionExceptions =>
      $$CollectionExceptionsTableTableManager(_db, _db.collectionExceptions);
}
