// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NegoziTable extends Negozi with TableInfo<$NegoziTable, Negozio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NegoziTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE COLLATE NOCASE CHECK (length(nome) BETWEEN 1 AND 60)',
  );
  static const VerificationMeta _creatoIlMeta = const VerificationMeta(
    'creatoIl',
  );
  @override
  late final GeneratedColumn<int> creatoIl = GeneratedColumn<int>(
    'creato_il',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nome, creatoIl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'negozi';
  @override
  VerificationContext validateIntegrity(
    Insertable<Negozio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('creato_il')) {
      context.handle(
        _creatoIlMeta,
        creatoIl.isAcceptableOrUnknown(data['creato_il']!, _creatoIlMeta),
      );
    } else if (isInserting) {
      context.missing(_creatoIlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Negozio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Negozio(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      creatoIl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creato_il'],
      )!,
    );
  }

  @override
  $NegoziTable createAlias(String alias) {
    return $NegoziTable(attachedDatabase, alias);
  }
}

class Negozio extends DataClass implements Insertable<Negozio> {
  final int id;

  /// ⚑ UNIQUE COLLATE NOCASE: «Esselunga» ed «ESSELUNGA» sono lo stesso negozio (lo scontrino e'
  /// in maiuscolo, l'utente scrive come vuole).
  final String nome;

  /// Epoch ms UTC.
  final int creatoIl;
  const Negozio({required this.id, required this.nome, required this.creatoIl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    map['creato_il'] = Variable<int>(creatoIl);
    return map;
  }

  NegoziCompanion toCompanion(bool nullToAbsent) {
    return NegoziCompanion(
      id: Value(id),
      nome: Value(nome),
      creatoIl: Value(creatoIl),
    );
  }

  factory Negozio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Negozio(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      creatoIl: serializer.fromJson<int>(json['creatoIl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'creatoIl': serializer.toJson<int>(creatoIl),
    };
  }

  Negozio copyWith({int? id, String? nome, int? creatoIl}) => Negozio(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    creatoIl: creatoIl ?? this.creatoIl,
  );
  Negozio copyWithCompanion(NegoziCompanion data) {
    return Negozio(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      creatoIl: data.creatoIl.present ? data.creatoIl.value : this.creatoIl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Negozio(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('creatoIl: $creatoIl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, creatoIl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Negozio &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.creatoIl == this.creatoIl);
}

class NegoziCompanion extends UpdateCompanion<Negozio> {
  final Value<int> id;
  final Value<String> nome;
  final Value<int> creatoIl;
  const NegoziCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.creatoIl = const Value.absent(),
  });
  NegoziCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    required int creatoIl,
  }) : nome = Value(nome),
       creatoIl = Value(creatoIl);
  static Insertable<Negozio> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<int>? creatoIl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (creatoIl != null) 'creato_il': creatoIl,
    });
  }

  NegoziCompanion copyWith({
    Value<int>? id,
    Value<String>? nome,
    Value<int>? creatoIl,
  }) {
    return NegoziCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      creatoIl: creatoIl ?? this.creatoIl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (creatoIl.present) {
      map['creato_il'] = Variable<int>(creatoIl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NegoziCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('creatoIl: $creatoIl')
          ..write(')'))
        .toString();
  }
}

class $SpeseTable extends Spese with TableInfo<$SpeseTable, SpesaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeseTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _statoMeta = const VerificationMeta('stato');
  @override
  late final GeneratedColumn<String> stato = GeneratedColumn<String>(
    'stato',
    aliasedName,
    false,
    check: () => stato.isIn(const ['in_corso', 'chiusa']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _negozioIdMeta = const VerificationMeta(
    'negozioId',
  );
  @override
  late final GeneratedColumn<int> negozioId = GeneratedColumn<int>(
    'negozio_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES negozi (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _iniziataIlMeta = const VerificationMeta(
    'iniziataIl',
  );
  @override
  late final GeneratedColumn<int> iniziataIl = GeneratedColumn<int>(
    'iniziata_il',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chiusaIlMeta = const VerificationMeta(
    'chiusaIl',
  );
  @override
  late final GeneratedColumn<int> chiusaIl = GeneratedColumn<int>(
    'chiusa_il',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dataSpesaMeta = const VerificationMeta(
    'dataSpesa',
  );
  @override
  late final GeneratedColumn<String> dataSpesa = GeneratedColumn<String>(
    'data_spesa',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _budgetCentsMeta = const VerificationMeta(
    'budgetCents',
  );
  @override
  late final GeneratedColumn<int> budgetCents = GeneratedColumn<int>(
    'budget_cents',
    aliasedName,
    true,
    check: () => ComparableExpr(budgetCents).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totaleCentsMeta = const VerificationMeta(
    'totaleCents',
  );
  @override
  late final GeneratedColumn<int> totaleCents = GeneratedColumn<int>(
    'totale_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totaleScontrinoCentsMeta =
      const VerificationMeta('totaleScontrinoCents');
  @override
  late final GeneratedColumn<int> totaleScontrinoCents = GeneratedColumn<int>(
    'totale_scontrino_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fonteMeta = const VerificationMeta('fonte');
  @override
  late final GeneratedColumn<String> fonte = GeneratedColumn<String>(
    'fonte',
    aliasedName,
    false,
    check: () => fonte.isIn(const ['contate', 'scontrino']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('contate'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stato,
    negozioId,
    iniziataIl,
    chiusaIl,
    dataSpesa,
    budgetCents,
    totaleCents,
    totaleScontrinoCents,
    fonte,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spese';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpesaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stato')) {
      context.handle(
        _statoMeta,
        stato.isAcceptableOrUnknown(data['stato']!, _statoMeta),
      );
    } else if (isInserting) {
      context.missing(_statoMeta);
    }
    if (data.containsKey('negozio_id')) {
      context.handle(
        _negozioIdMeta,
        negozioId.isAcceptableOrUnknown(data['negozio_id']!, _negozioIdMeta),
      );
    }
    if (data.containsKey('iniziata_il')) {
      context.handle(
        _iniziataIlMeta,
        iniziataIl.isAcceptableOrUnknown(data['iniziata_il']!, _iniziataIlMeta),
      );
    } else if (isInserting) {
      context.missing(_iniziataIlMeta);
    }
    if (data.containsKey('chiusa_il')) {
      context.handle(
        _chiusaIlMeta,
        chiusaIl.isAcceptableOrUnknown(data['chiusa_il']!, _chiusaIlMeta),
      );
    }
    if (data.containsKey('data_spesa')) {
      context.handle(
        _dataSpesaMeta,
        dataSpesa.isAcceptableOrUnknown(data['data_spesa']!, _dataSpesaMeta),
      );
    }
    if (data.containsKey('budget_cents')) {
      context.handle(
        _budgetCentsMeta,
        budgetCents.isAcceptableOrUnknown(
          data['budget_cents']!,
          _budgetCentsMeta,
        ),
      );
    }
    if (data.containsKey('totale_cents')) {
      context.handle(
        _totaleCentsMeta,
        totaleCents.isAcceptableOrUnknown(
          data['totale_cents']!,
          _totaleCentsMeta,
        ),
      );
    }
    if (data.containsKey('totale_scontrino_cents')) {
      context.handle(
        _totaleScontrinoCentsMeta,
        totaleScontrinoCents.isAcceptableOrUnknown(
          data['totale_scontrino_cents']!,
          _totaleScontrinoCentsMeta,
        ),
      );
    }
    if (data.containsKey('fonte')) {
      context.handle(
        _fonteMeta,
        fonte.isAcceptableOrUnknown(data['fonte']!, _fonteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpesaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpesaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      stato: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stato'],
      )!,
      negozioId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}negozio_id'],
      ),
      iniziataIl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iniziata_il'],
      )!,
      chiusaIl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chiusa_il'],
      ),
      dataSpesa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_spesa'],
      ),
      budgetCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_cents'],
      ),
      totaleCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}totale_cents'],
      )!,
      totaleScontrinoCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}totale_scontrino_cents'],
      ),
      fonte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fonte'],
      )!,
    );
  }

  @override
  $SpeseTable createAlias(String alias) {
    return $SpeseTable(attachedDatabase, alias);
  }
}

class SpesaRow extends DataClass implements Insertable<SpesaRow> {
  final int id;

  /// 'in_corso' | 'chiusa'.
  final String stato;

  /// ON DELETE SET NULL: eliminare un negozio lascia le spese «senza negozio».
  final int? negozioId;

  /// Epoch ms UTC.
  final int iniziataIl;

  /// Epoch ms UTC; presente se e solo se chiusa (CHECK di tabella).
  final int? chiusaIl;

  /// `YYYY-MM-DD` (`CivilDate`, ADR-008): il giorno della spesa, dallo scontrino se letto.
  /// Obbligatoria quando chiusa (CHECK di tabella).
  final String? dataSpesa;
  final int? budgetCents;

  /// ⚑ Scritto alla CHIUSURA (`Spesa.totale`) e mai ricalcolato: un aggiornamento delle regole di
  /// calcolo non deve cambiare lo storico. Per la spesa in corso vale 0: si calcola dalle righe.
  final int totaleCents;

  /// Il TOTALE stampato sullo scontrino, se letto.
  final int? totaleScontrinoCents;

  /// 'contate' | 'scontrino': quale insieme di righe fa fede.
  final String fonte;
  const SpesaRow({
    required this.id,
    required this.stato,
    this.negozioId,
    required this.iniziataIl,
    this.chiusaIl,
    this.dataSpesa,
    this.budgetCents,
    required this.totaleCents,
    this.totaleScontrinoCents,
    required this.fonte,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stato'] = Variable<String>(stato);
    if (!nullToAbsent || negozioId != null) {
      map['negozio_id'] = Variable<int>(negozioId);
    }
    map['iniziata_il'] = Variable<int>(iniziataIl);
    if (!nullToAbsent || chiusaIl != null) {
      map['chiusa_il'] = Variable<int>(chiusaIl);
    }
    if (!nullToAbsent || dataSpesa != null) {
      map['data_spesa'] = Variable<String>(dataSpesa);
    }
    if (!nullToAbsent || budgetCents != null) {
      map['budget_cents'] = Variable<int>(budgetCents);
    }
    map['totale_cents'] = Variable<int>(totaleCents);
    if (!nullToAbsent || totaleScontrinoCents != null) {
      map['totale_scontrino_cents'] = Variable<int>(totaleScontrinoCents);
    }
    map['fonte'] = Variable<String>(fonte);
    return map;
  }

  SpeseCompanion toCompanion(bool nullToAbsent) {
    return SpeseCompanion(
      id: Value(id),
      stato: Value(stato),
      negozioId: negozioId == null && nullToAbsent
          ? const Value.absent()
          : Value(negozioId),
      iniziataIl: Value(iniziataIl),
      chiusaIl: chiusaIl == null && nullToAbsent
          ? const Value.absent()
          : Value(chiusaIl),
      dataSpesa: dataSpesa == null && nullToAbsent
          ? const Value.absent()
          : Value(dataSpesa),
      budgetCents: budgetCents == null && nullToAbsent
          ? const Value.absent()
          : Value(budgetCents),
      totaleCents: Value(totaleCents),
      totaleScontrinoCents: totaleScontrinoCents == null && nullToAbsent
          ? const Value.absent()
          : Value(totaleScontrinoCents),
      fonte: Value(fonte),
    );
  }

  factory SpesaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpesaRow(
      id: serializer.fromJson<int>(json['id']),
      stato: serializer.fromJson<String>(json['stato']),
      negozioId: serializer.fromJson<int?>(json['negozioId']),
      iniziataIl: serializer.fromJson<int>(json['iniziataIl']),
      chiusaIl: serializer.fromJson<int?>(json['chiusaIl']),
      dataSpesa: serializer.fromJson<String?>(json['dataSpesa']),
      budgetCents: serializer.fromJson<int?>(json['budgetCents']),
      totaleCents: serializer.fromJson<int>(json['totaleCents']),
      totaleScontrinoCents: serializer.fromJson<int?>(
        json['totaleScontrinoCents'],
      ),
      fonte: serializer.fromJson<String>(json['fonte']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stato': serializer.toJson<String>(stato),
      'negozioId': serializer.toJson<int?>(negozioId),
      'iniziataIl': serializer.toJson<int>(iniziataIl),
      'chiusaIl': serializer.toJson<int?>(chiusaIl),
      'dataSpesa': serializer.toJson<String?>(dataSpesa),
      'budgetCents': serializer.toJson<int?>(budgetCents),
      'totaleCents': serializer.toJson<int>(totaleCents),
      'totaleScontrinoCents': serializer.toJson<int?>(totaleScontrinoCents),
      'fonte': serializer.toJson<String>(fonte),
    };
  }

  SpesaRow copyWith({
    int? id,
    String? stato,
    Value<int?> negozioId = const Value.absent(),
    int? iniziataIl,
    Value<int?> chiusaIl = const Value.absent(),
    Value<String?> dataSpesa = const Value.absent(),
    Value<int?> budgetCents = const Value.absent(),
    int? totaleCents,
    Value<int?> totaleScontrinoCents = const Value.absent(),
    String? fonte,
  }) => SpesaRow(
    id: id ?? this.id,
    stato: stato ?? this.stato,
    negozioId: negozioId.present ? negozioId.value : this.negozioId,
    iniziataIl: iniziataIl ?? this.iniziataIl,
    chiusaIl: chiusaIl.present ? chiusaIl.value : this.chiusaIl,
    dataSpesa: dataSpesa.present ? dataSpesa.value : this.dataSpesa,
    budgetCents: budgetCents.present ? budgetCents.value : this.budgetCents,
    totaleCents: totaleCents ?? this.totaleCents,
    totaleScontrinoCents: totaleScontrinoCents.present
        ? totaleScontrinoCents.value
        : this.totaleScontrinoCents,
    fonte: fonte ?? this.fonte,
  );
  SpesaRow copyWithCompanion(SpeseCompanion data) {
    return SpesaRow(
      id: data.id.present ? data.id.value : this.id,
      stato: data.stato.present ? data.stato.value : this.stato,
      negozioId: data.negozioId.present ? data.negozioId.value : this.negozioId,
      iniziataIl: data.iniziataIl.present
          ? data.iniziataIl.value
          : this.iniziataIl,
      chiusaIl: data.chiusaIl.present ? data.chiusaIl.value : this.chiusaIl,
      dataSpesa: data.dataSpesa.present ? data.dataSpesa.value : this.dataSpesa,
      budgetCents: data.budgetCents.present
          ? data.budgetCents.value
          : this.budgetCents,
      totaleCents: data.totaleCents.present
          ? data.totaleCents.value
          : this.totaleCents,
      totaleScontrinoCents: data.totaleScontrinoCents.present
          ? data.totaleScontrinoCents.value
          : this.totaleScontrinoCents,
      fonte: data.fonte.present ? data.fonte.value : this.fonte,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpesaRow(')
          ..write('id: $id, ')
          ..write('stato: $stato, ')
          ..write('negozioId: $negozioId, ')
          ..write('iniziataIl: $iniziataIl, ')
          ..write('chiusaIl: $chiusaIl, ')
          ..write('dataSpesa: $dataSpesa, ')
          ..write('budgetCents: $budgetCents, ')
          ..write('totaleCents: $totaleCents, ')
          ..write('totaleScontrinoCents: $totaleScontrinoCents, ')
          ..write('fonte: $fonte')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stato,
    negozioId,
    iniziataIl,
    chiusaIl,
    dataSpesa,
    budgetCents,
    totaleCents,
    totaleScontrinoCents,
    fonte,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpesaRow &&
          other.id == this.id &&
          other.stato == this.stato &&
          other.negozioId == this.negozioId &&
          other.iniziataIl == this.iniziataIl &&
          other.chiusaIl == this.chiusaIl &&
          other.dataSpesa == this.dataSpesa &&
          other.budgetCents == this.budgetCents &&
          other.totaleCents == this.totaleCents &&
          other.totaleScontrinoCents == this.totaleScontrinoCents &&
          other.fonte == this.fonte);
}

class SpeseCompanion extends UpdateCompanion<SpesaRow> {
  final Value<int> id;
  final Value<String> stato;
  final Value<int?> negozioId;
  final Value<int> iniziataIl;
  final Value<int?> chiusaIl;
  final Value<String?> dataSpesa;
  final Value<int?> budgetCents;
  final Value<int> totaleCents;
  final Value<int?> totaleScontrinoCents;
  final Value<String> fonte;
  const SpeseCompanion({
    this.id = const Value.absent(),
    this.stato = const Value.absent(),
    this.negozioId = const Value.absent(),
    this.iniziataIl = const Value.absent(),
    this.chiusaIl = const Value.absent(),
    this.dataSpesa = const Value.absent(),
    this.budgetCents = const Value.absent(),
    this.totaleCents = const Value.absent(),
    this.totaleScontrinoCents = const Value.absent(),
    this.fonte = const Value.absent(),
  });
  SpeseCompanion.insert({
    this.id = const Value.absent(),
    required String stato,
    this.negozioId = const Value.absent(),
    required int iniziataIl,
    this.chiusaIl = const Value.absent(),
    this.dataSpesa = const Value.absent(),
    this.budgetCents = const Value.absent(),
    this.totaleCents = const Value.absent(),
    this.totaleScontrinoCents = const Value.absent(),
    this.fonte = const Value.absent(),
  }) : stato = Value(stato),
       iniziataIl = Value(iniziataIl);
  static Insertable<SpesaRow> custom({
    Expression<int>? id,
    Expression<String>? stato,
    Expression<int>? negozioId,
    Expression<int>? iniziataIl,
    Expression<int>? chiusaIl,
    Expression<String>? dataSpesa,
    Expression<int>? budgetCents,
    Expression<int>? totaleCents,
    Expression<int>? totaleScontrinoCents,
    Expression<String>? fonte,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stato != null) 'stato': stato,
      if (negozioId != null) 'negozio_id': negozioId,
      if (iniziataIl != null) 'iniziata_il': iniziataIl,
      if (chiusaIl != null) 'chiusa_il': chiusaIl,
      if (dataSpesa != null) 'data_spesa': dataSpesa,
      if (budgetCents != null) 'budget_cents': budgetCents,
      if (totaleCents != null) 'totale_cents': totaleCents,
      if (totaleScontrinoCents != null)
        'totale_scontrino_cents': totaleScontrinoCents,
      if (fonte != null) 'fonte': fonte,
    });
  }

  SpeseCompanion copyWith({
    Value<int>? id,
    Value<String>? stato,
    Value<int?>? negozioId,
    Value<int>? iniziataIl,
    Value<int?>? chiusaIl,
    Value<String?>? dataSpesa,
    Value<int?>? budgetCents,
    Value<int>? totaleCents,
    Value<int?>? totaleScontrinoCents,
    Value<String>? fonte,
  }) {
    return SpeseCompanion(
      id: id ?? this.id,
      stato: stato ?? this.stato,
      negozioId: negozioId ?? this.negozioId,
      iniziataIl: iniziataIl ?? this.iniziataIl,
      chiusaIl: chiusaIl ?? this.chiusaIl,
      dataSpesa: dataSpesa ?? this.dataSpesa,
      budgetCents: budgetCents ?? this.budgetCents,
      totaleCents: totaleCents ?? this.totaleCents,
      totaleScontrinoCents: totaleScontrinoCents ?? this.totaleScontrinoCents,
      fonte: fonte ?? this.fonte,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stato.present) {
      map['stato'] = Variable<String>(stato.value);
    }
    if (negozioId.present) {
      map['negozio_id'] = Variable<int>(negozioId.value);
    }
    if (iniziataIl.present) {
      map['iniziata_il'] = Variable<int>(iniziataIl.value);
    }
    if (chiusaIl.present) {
      map['chiusa_il'] = Variable<int>(chiusaIl.value);
    }
    if (dataSpesa.present) {
      map['data_spesa'] = Variable<String>(dataSpesa.value);
    }
    if (budgetCents.present) {
      map['budget_cents'] = Variable<int>(budgetCents.value);
    }
    if (totaleCents.present) {
      map['totale_cents'] = Variable<int>(totaleCents.value);
    }
    if (totaleScontrinoCents.present) {
      map['totale_scontrino_cents'] = Variable<int>(totaleScontrinoCents.value);
    }
    if (fonte.present) {
      map['fonte'] = Variable<String>(fonte.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeseCompanion(')
          ..write('id: $id, ')
          ..write('stato: $stato, ')
          ..write('negozioId: $negozioId, ')
          ..write('iniziataIl: $iniziataIl, ')
          ..write('chiusaIl: $chiusaIl, ')
          ..write('dataSpesa: $dataSpesa, ')
          ..write('budgetCents: $budgetCents, ')
          ..write('totaleCents: $totaleCents, ')
          ..write('totaleScontrinoCents: $totaleScontrinoCents, ')
          ..write('fonte: $fonte')
          ..write(')'))
        .toString();
  }
}

class $RigheTable extends Righe with TableInfo<$RigheTable, RigaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RigheTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _spesaIdMeta = const VerificationMeta(
    'spesaId',
  );
  @override
  late final GeneratedColumn<int> spesaId = GeneratedColumn<int>(
    'spesa_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES spese (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _insiemeMeta = const VerificationMeta(
    'insieme',
  );
  @override
  late final GeneratedColumn<String> insieme = GeneratedColumn<String>(
    'insieme',
    aliasedName,
    false,
    check: () => insieme.isIn(const ['contate', 'scontrino']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posizioneMeta = const VerificationMeta(
    'posizione',
  );
  @override
  late final GeneratedColumn<int> posizione = GeneratedColumn<int>(
    'posizione',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
    'nome',
    aliasedName,
    false,
    check: () => ComparableExpr(nome.length).isSmallerOrEqualValue(80),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pezziMeta = const VerificationMeta('pezzi');
  @override
  late final GeneratedColumn<int> pezzi = GeneratedColumn<int>(
    'pezzi',
    aliasedName,
    true,
    check: () => ComparableExpr(pezzi).isBetweenValues(1, 999),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _millesimiMeta = const VerificationMeta(
    'millesimi',
  );
  @override
  late final GeneratedColumn<int> millesimi = GeneratedColumn<int>(
    'millesimi',
    aliasedName,
    true,
    check: () => ComparableExpr(millesimi).isBetweenValues(1, 99999),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitaMeta = const VerificationMeta('unita');
  @override
  late final GeneratedColumn<String> unita = GeneratedColumn<String>(
    'unita',
    aliasedName,
    true,
    check: () => unita.isIn(const ['kg', 'l']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prezzoUnitarioCentsMeta =
      const VerificationMeta('prezzoUnitarioCents');
  @override
  late final GeneratedColumn<int> prezzoUnitarioCents = GeneratedColumn<int>(
    'prezzo_unitario_cents',
    aliasedName,
    false,
    check: () =>
        BooleanExpressionOperators(prezzoUnitarioCents.equals(0)).not(),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totaleCentsMeta = const VerificationMeta(
    'totaleCents',
  );
  @override
  late final GeneratedColumn<int> totaleCents = GeneratedColumn<int>(
    'totale_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offertaJsonMeta = const VerificationMeta(
    'offertaJson',
  );
  @override
  late final GeneratedColumn<String> offertaJson = GeneratedColumn<String>(
    'offerta_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prezzoRifCentsMeta = const VerificationMeta(
    'prezzoRifCents',
  );
  @override
  late final GeneratedColumn<int> prezzoRifCents = GeneratedColumn<int>(
    'prezzo_rif_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitaRifMeta = const VerificationMeta(
    'unitaRif',
  );
  @override
  late final GeneratedColumn<String> unitaRif = GeneratedColumn<String>(
    'unita_rif',
    aliasedName,
    true,
    check: () => unitaRif.isIn(const ['kg', 'l']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totaleStampatoCentsMeta =
      const VerificationMeta('totaleStampatoCents');
  @override
  late final GeneratedColumn<int> totaleStampatoCents = GeneratedColumn<int>(
    'totale_stampato_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _origineMeta = const VerificationMeta(
    'origine',
  );
  @override
  late final GeneratedColumn<String> origine = GeneratedColumn<String>(
    'origine',
    aliasedName,
    false,
    check: () => origine.isIn(const [
      'tastierino',
      'cartellino',
      'bilancia',
      'scontrino',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stornataMeta = const VerificationMeta(
    'stornata',
  );
  @override
  late final GeneratedColumn<bool> stornata = GeneratedColumn<bool>(
    'stornata',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("stornata" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creataIlMeta = const VerificationMeta(
    'creataIl',
  );
  @override
  late final GeneratedColumn<int> creataIl = GeneratedColumn<int>(
    'creata_il',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    spesaId,
    insieme,
    posizione,
    nome,
    pezzi,
    millesimi,
    unita,
    prezzoUnitarioCents,
    totaleCents,
    offertaJson,
    prezzoRifCents,
    unitaRif,
    totaleStampatoCents,
    origine,
    stornata,
    creataIl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'righe';
  @override
  VerificationContext validateIntegrity(
    Insertable<RigaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('spesa_id')) {
      context.handle(
        _spesaIdMeta,
        spesaId.isAcceptableOrUnknown(data['spesa_id']!, _spesaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spesaIdMeta);
    }
    if (data.containsKey('insieme')) {
      context.handle(
        _insiemeMeta,
        insieme.isAcceptableOrUnknown(data['insieme']!, _insiemeMeta),
      );
    } else if (isInserting) {
      context.missing(_insiemeMeta);
    }
    if (data.containsKey('posizione')) {
      context.handle(
        _posizioneMeta,
        posizione.isAcceptableOrUnknown(data['posizione']!, _posizioneMeta),
      );
    } else if (isInserting) {
      context.missing(_posizioneMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
        _nomeMeta,
        nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta),
      );
    }
    if (data.containsKey('pezzi')) {
      context.handle(
        _pezziMeta,
        pezzi.isAcceptableOrUnknown(data['pezzi']!, _pezziMeta),
      );
    }
    if (data.containsKey('millesimi')) {
      context.handle(
        _millesimiMeta,
        millesimi.isAcceptableOrUnknown(data['millesimi']!, _millesimiMeta),
      );
    }
    if (data.containsKey('unita')) {
      context.handle(
        _unitaMeta,
        unita.isAcceptableOrUnknown(data['unita']!, _unitaMeta),
      );
    }
    if (data.containsKey('prezzo_unitario_cents')) {
      context.handle(
        _prezzoUnitarioCentsMeta,
        prezzoUnitarioCents.isAcceptableOrUnknown(
          data['prezzo_unitario_cents']!,
          _prezzoUnitarioCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prezzoUnitarioCentsMeta);
    }
    if (data.containsKey('totale_cents')) {
      context.handle(
        _totaleCentsMeta,
        totaleCents.isAcceptableOrUnknown(
          data['totale_cents']!,
          _totaleCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totaleCentsMeta);
    }
    if (data.containsKey('offerta_json')) {
      context.handle(
        _offertaJsonMeta,
        offertaJson.isAcceptableOrUnknown(
          data['offerta_json']!,
          _offertaJsonMeta,
        ),
      );
    }
    if (data.containsKey('prezzo_rif_cents')) {
      context.handle(
        _prezzoRifCentsMeta,
        prezzoRifCents.isAcceptableOrUnknown(
          data['prezzo_rif_cents']!,
          _prezzoRifCentsMeta,
        ),
      );
    }
    if (data.containsKey('unita_rif')) {
      context.handle(
        _unitaRifMeta,
        unitaRif.isAcceptableOrUnknown(data['unita_rif']!, _unitaRifMeta),
      );
    }
    if (data.containsKey('totale_stampato_cents')) {
      context.handle(
        _totaleStampatoCentsMeta,
        totaleStampatoCents.isAcceptableOrUnknown(
          data['totale_stampato_cents']!,
          _totaleStampatoCentsMeta,
        ),
      );
    }
    if (data.containsKey('origine')) {
      context.handle(
        _origineMeta,
        origine.isAcceptableOrUnknown(data['origine']!, _origineMeta),
      );
    } else if (isInserting) {
      context.missing(_origineMeta);
    }
    if (data.containsKey('stornata')) {
      context.handle(
        _stornataMeta,
        stornata.isAcceptableOrUnknown(data['stornata']!, _stornataMeta),
      );
    }
    if (data.containsKey('creata_il')) {
      context.handle(
        _creataIlMeta,
        creataIl.isAcceptableOrUnknown(data['creata_il']!, _creataIlMeta),
      );
    } else if (isInserting) {
      context.missing(_creataIlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RigaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RigaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      spesaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spesa_id'],
      )!,
      insieme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}insieme'],
      )!,
      posizione: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}posizione'],
      )!,
      nome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nome'],
      )!,
      pezzi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pezzi'],
      ),
      millesimi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}millesimi'],
      ),
      unita: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unita'],
      ),
      prezzoUnitarioCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prezzo_unitario_cents'],
      )!,
      totaleCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}totale_cents'],
      )!,
      offertaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offerta_json'],
      ),
      prezzoRifCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prezzo_rif_cents'],
      ),
      unitaRif: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unita_rif'],
      ),
      totaleStampatoCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}totale_stampato_cents'],
      ),
      origine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origine'],
      )!,
      stornata: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stornata'],
      )!,
      creataIl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}creata_il'],
      )!,
    );
  }

  @override
  $RigheTable createAlias(String alias) {
    return $RigheTable(attachedDatabase, alias);
  }
}

class RigaRow extends DataClass implements Insertable<RigaRow> {
  final int id;
  final int spesaId;

  /// ⚑ 'contate' | 'scontrino': le righe dello scontrino si AFFIANCANO a quelle contate, non le
  /// sostituiscono (nel dettaglio si vedono entrambe).
  final String insieme;

  /// Ordine di inserimento dentro l'insieme.
  final int posizione;
  final String nome;
  final int? pezzi;

  /// Grammi o millilitri.
  final int? millesimi;
  final String? unita;

  /// Negativo solo per gli sconti; mai zero.
  final int prezzoUnitarioCents;

  /// `RigaSpesa.totale` al momento dell'inserimento (stesso motivo di `spese.totale_cents`).
  final int totaleCents;

  /// `Offerta.toJson()`.
  final String? offertaJson;

  /// €/kg o €/l stampato sul cartellino di un prodotto a pezzi.
  final int? prezzoRifCents;
  final String? unitaRif;

  /// Bilancia (e righe dello scontrino): l'importo stampato, che vince sul calcolo.
  final int? totaleStampatoCents;
  final String origine;

  /// Solo `insieme = 'scontrino'`: un articolo annullato da uno storno.
  final bool stornata;

  /// Epoch ms UTC.
  final int creataIl;
  const RigaRow({
    required this.id,
    required this.spesaId,
    required this.insieme,
    required this.posizione,
    required this.nome,
    this.pezzi,
    this.millesimi,
    this.unita,
    required this.prezzoUnitarioCents,
    required this.totaleCents,
    this.offertaJson,
    this.prezzoRifCents,
    this.unitaRif,
    this.totaleStampatoCents,
    required this.origine,
    required this.stornata,
    required this.creataIl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['spesa_id'] = Variable<int>(spesaId);
    map['insieme'] = Variable<String>(insieme);
    map['posizione'] = Variable<int>(posizione);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || pezzi != null) {
      map['pezzi'] = Variable<int>(pezzi);
    }
    if (!nullToAbsent || millesimi != null) {
      map['millesimi'] = Variable<int>(millesimi);
    }
    if (!nullToAbsent || unita != null) {
      map['unita'] = Variable<String>(unita);
    }
    map['prezzo_unitario_cents'] = Variable<int>(prezzoUnitarioCents);
    map['totale_cents'] = Variable<int>(totaleCents);
    if (!nullToAbsent || offertaJson != null) {
      map['offerta_json'] = Variable<String>(offertaJson);
    }
    if (!nullToAbsent || prezzoRifCents != null) {
      map['prezzo_rif_cents'] = Variable<int>(prezzoRifCents);
    }
    if (!nullToAbsent || unitaRif != null) {
      map['unita_rif'] = Variable<String>(unitaRif);
    }
    if (!nullToAbsent || totaleStampatoCents != null) {
      map['totale_stampato_cents'] = Variable<int>(totaleStampatoCents);
    }
    map['origine'] = Variable<String>(origine);
    map['stornata'] = Variable<bool>(stornata);
    map['creata_il'] = Variable<int>(creataIl);
    return map;
  }

  RigheCompanion toCompanion(bool nullToAbsent) {
    return RigheCompanion(
      id: Value(id),
      spesaId: Value(spesaId),
      insieme: Value(insieme),
      posizione: Value(posizione),
      nome: Value(nome),
      pezzi: pezzi == null && nullToAbsent
          ? const Value.absent()
          : Value(pezzi),
      millesimi: millesimi == null && nullToAbsent
          ? const Value.absent()
          : Value(millesimi),
      unita: unita == null && nullToAbsent
          ? const Value.absent()
          : Value(unita),
      prezzoUnitarioCents: Value(prezzoUnitarioCents),
      totaleCents: Value(totaleCents),
      offertaJson: offertaJson == null && nullToAbsent
          ? const Value.absent()
          : Value(offertaJson),
      prezzoRifCents: prezzoRifCents == null && nullToAbsent
          ? const Value.absent()
          : Value(prezzoRifCents),
      unitaRif: unitaRif == null && nullToAbsent
          ? const Value.absent()
          : Value(unitaRif),
      totaleStampatoCents: totaleStampatoCents == null && nullToAbsent
          ? const Value.absent()
          : Value(totaleStampatoCents),
      origine: Value(origine),
      stornata: Value(stornata),
      creataIl: Value(creataIl),
    );
  }

  factory RigaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RigaRow(
      id: serializer.fromJson<int>(json['id']),
      spesaId: serializer.fromJson<int>(json['spesaId']),
      insieme: serializer.fromJson<String>(json['insieme']),
      posizione: serializer.fromJson<int>(json['posizione']),
      nome: serializer.fromJson<String>(json['nome']),
      pezzi: serializer.fromJson<int?>(json['pezzi']),
      millesimi: serializer.fromJson<int?>(json['millesimi']),
      unita: serializer.fromJson<String?>(json['unita']),
      prezzoUnitarioCents: serializer.fromJson<int>(
        json['prezzoUnitarioCents'],
      ),
      totaleCents: serializer.fromJson<int>(json['totaleCents']),
      offertaJson: serializer.fromJson<String?>(json['offertaJson']),
      prezzoRifCents: serializer.fromJson<int?>(json['prezzoRifCents']),
      unitaRif: serializer.fromJson<String?>(json['unitaRif']),
      totaleStampatoCents: serializer.fromJson<int?>(
        json['totaleStampatoCents'],
      ),
      origine: serializer.fromJson<String>(json['origine']),
      stornata: serializer.fromJson<bool>(json['stornata']),
      creataIl: serializer.fromJson<int>(json['creataIl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'spesaId': serializer.toJson<int>(spesaId),
      'insieme': serializer.toJson<String>(insieme),
      'posizione': serializer.toJson<int>(posizione),
      'nome': serializer.toJson<String>(nome),
      'pezzi': serializer.toJson<int?>(pezzi),
      'millesimi': serializer.toJson<int?>(millesimi),
      'unita': serializer.toJson<String?>(unita),
      'prezzoUnitarioCents': serializer.toJson<int>(prezzoUnitarioCents),
      'totaleCents': serializer.toJson<int>(totaleCents),
      'offertaJson': serializer.toJson<String?>(offertaJson),
      'prezzoRifCents': serializer.toJson<int?>(prezzoRifCents),
      'unitaRif': serializer.toJson<String?>(unitaRif),
      'totaleStampatoCents': serializer.toJson<int?>(totaleStampatoCents),
      'origine': serializer.toJson<String>(origine),
      'stornata': serializer.toJson<bool>(stornata),
      'creataIl': serializer.toJson<int>(creataIl),
    };
  }

  RigaRow copyWith({
    int? id,
    int? spesaId,
    String? insieme,
    int? posizione,
    String? nome,
    Value<int?> pezzi = const Value.absent(),
    Value<int?> millesimi = const Value.absent(),
    Value<String?> unita = const Value.absent(),
    int? prezzoUnitarioCents,
    int? totaleCents,
    Value<String?> offertaJson = const Value.absent(),
    Value<int?> prezzoRifCents = const Value.absent(),
    Value<String?> unitaRif = const Value.absent(),
    Value<int?> totaleStampatoCents = const Value.absent(),
    String? origine,
    bool? stornata,
    int? creataIl,
  }) => RigaRow(
    id: id ?? this.id,
    spesaId: spesaId ?? this.spesaId,
    insieme: insieme ?? this.insieme,
    posizione: posizione ?? this.posizione,
    nome: nome ?? this.nome,
    pezzi: pezzi.present ? pezzi.value : this.pezzi,
    millesimi: millesimi.present ? millesimi.value : this.millesimi,
    unita: unita.present ? unita.value : this.unita,
    prezzoUnitarioCents: prezzoUnitarioCents ?? this.prezzoUnitarioCents,
    totaleCents: totaleCents ?? this.totaleCents,
    offertaJson: offertaJson.present ? offertaJson.value : this.offertaJson,
    prezzoRifCents: prezzoRifCents.present
        ? prezzoRifCents.value
        : this.prezzoRifCents,
    unitaRif: unitaRif.present ? unitaRif.value : this.unitaRif,
    totaleStampatoCents: totaleStampatoCents.present
        ? totaleStampatoCents.value
        : this.totaleStampatoCents,
    origine: origine ?? this.origine,
    stornata: stornata ?? this.stornata,
    creataIl: creataIl ?? this.creataIl,
  );
  RigaRow copyWithCompanion(RigheCompanion data) {
    return RigaRow(
      id: data.id.present ? data.id.value : this.id,
      spesaId: data.spesaId.present ? data.spesaId.value : this.spesaId,
      insieme: data.insieme.present ? data.insieme.value : this.insieme,
      posizione: data.posizione.present ? data.posizione.value : this.posizione,
      nome: data.nome.present ? data.nome.value : this.nome,
      pezzi: data.pezzi.present ? data.pezzi.value : this.pezzi,
      millesimi: data.millesimi.present ? data.millesimi.value : this.millesimi,
      unita: data.unita.present ? data.unita.value : this.unita,
      prezzoUnitarioCents: data.prezzoUnitarioCents.present
          ? data.prezzoUnitarioCents.value
          : this.prezzoUnitarioCents,
      totaleCents: data.totaleCents.present
          ? data.totaleCents.value
          : this.totaleCents,
      offertaJson: data.offertaJson.present
          ? data.offertaJson.value
          : this.offertaJson,
      prezzoRifCents: data.prezzoRifCents.present
          ? data.prezzoRifCents.value
          : this.prezzoRifCents,
      unitaRif: data.unitaRif.present ? data.unitaRif.value : this.unitaRif,
      totaleStampatoCents: data.totaleStampatoCents.present
          ? data.totaleStampatoCents.value
          : this.totaleStampatoCents,
      origine: data.origine.present ? data.origine.value : this.origine,
      stornata: data.stornata.present ? data.stornata.value : this.stornata,
      creataIl: data.creataIl.present ? data.creataIl.value : this.creataIl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RigaRow(')
          ..write('id: $id, ')
          ..write('spesaId: $spesaId, ')
          ..write('insieme: $insieme, ')
          ..write('posizione: $posizione, ')
          ..write('nome: $nome, ')
          ..write('pezzi: $pezzi, ')
          ..write('millesimi: $millesimi, ')
          ..write('unita: $unita, ')
          ..write('prezzoUnitarioCents: $prezzoUnitarioCents, ')
          ..write('totaleCents: $totaleCents, ')
          ..write('offertaJson: $offertaJson, ')
          ..write('prezzoRifCents: $prezzoRifCents, ')
          ..write('unitaRif: $unitaRif, ')
          ..write('totaleStampatoCents: $totaleStampatoCents, ')
          ..write('origine: $origine, ')
          ..write('stornata: $stornata, ')
          ..write('creataIl: $creataIl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    spesaId,
    insieme,
    posizione,
    nome,
    pezzi,
    millesimi,
    unita,
    prezzoUnitarioCents,
    totaleCents,
    offertaJson,
    prezzoRifCents,
    unitaRif,
    totaleStampatoCents,
    origine,
    stornata,
    creataIl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RigaRow &&
          other.id == this.id &&
          other.spesaId == this.spesaId &&
          other.insieme == this.insieme &&
          other.posizione == this.posizione &&
          other.nome == this.nome &&
          other.pezzi == this.pezzi &&
          other.millesimi == this.millesimi &&
          other.unita == this.unita &&
          other.prezzoUnitarioCents == this.prezzoUnitarioCents &&
          other.totaleCents == this.totaleCents &&
          other.offertaJson == this.offertaJson &&
          other.prezzoRifCents == this.prezzoRifCents &&
          other.unitaRif == this.unitaRif &&
          other.totaleStampatoCents == this.totaleStampatoCents &&
          other.origine == this.origine &&
          other.stornata == this.stornata &&
          other.creataIl == this.creataIl);
}

class RigheCompanion extends UpdateCompanion<RigaRow> {
  final Value<int> id;
  final Value<int> spesaId;
  final Value<String> insieme;
  final Value<int> posizione;
  final Value<String> nome;
  final Value<int?> pezzi;
  final Value<int?> millesimi;
  final Value<String?> unita;
  final Value<int> prezzoUnitarioCents;
  final Value<int> totaleCents;
  final Value<String?> offertaJson;
  final Value<int?> prezzoRifCents;
  final Value<String?> unitaRif;
  final Value<int?> totaleStampatoCents;
  final Value<String> origine;
  final Value<bool> stornata;
  final Value<int> creataIl;
  const RigheCompanion({
    this.id = const Value.absent(),
    this.spesaId = const Value.absent(),
    this.insieme = const Value.absent(),
    this.posizione = const Value.absent(),
    this.nome = const Value.absent(),
    this.pezzi = const Value.absent(),
    this.millesimi = const Value.absent(),
    this.unita = const Value.absent(),
    this.prezzoUnitarioCents = const Value.absent(),
    this.totaleCents = const Value.absent(),
    this.offertaJson = const Value.absent(),
    this.prezzoRifCents = const Value.absent(),
    this.unitaRif = const Value.absent(),
    this.totaleStampatoCents = const Value.absent(),
    this.origine = const Value.absent(),
    this.stornata = const Value.absent(),
    this.creataIl = const Value.absent(),
  });
  RigheCompanion.insert({
    this.id = const Value.absent(),
    required int spesaId,
    required String insieme,
    required int posizione,
    this.nome = const Value.absent(),
    this.pezzi = const Value.absent(),
    this.millesimi = const Value.absent(),
    this.unita = const Value.absent(),
    required int prezzoUnitarioCents,
    required int totaleCents,
    this.offertaJson = const Value.absent(),
    this.prezzoRifCents = const Value.absent(),
    this.unitaRif = const Value.absent(),
    this.totaleStampatoCents = const Value.absent(),
    required String origine,
    this.stornata = const Value.absent(),
    required int creataIl,
  }) : spesaId = Value(spesaId),
       insieme = Value(insieme),
       posizione = Value(posizione),
       prezzoUnitarioCents = Value(prezzoUnitarioCents),
       totaleCents = Value(totaleCents),
       origine = Value(origine),
       creataIl = Value(creataIl);
  static Insertable<RigaRow> custom({
    Expression<int>? id,
    Expression<int>? spesaId,
    Expression<String>? insieme,
    Expression<int>? posizione,
    Expression<String>? nome,
    Expression<int>? pezzi,
    Expression<int>? millesimi,
    Expression<String>? unita,
    Expression<int>? prezzoUnitarioCents,
    Expression<int>? totaleCents,
    Expression<String>? offertaJson,
    Expression<int>? prezzoRifCents,
    Expression<String>? unitaRif,
    Expression<int>? totaleStampatoCents,
    Expression<String>? origine,
    Expression<bool>? stornata,
    Expression<int>? creataIl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (spesaId != null) 'spesa_id': spesaId,
      if (insieme != null) 'insieme': insieme,
      if (posizione != null) 'posizione': posizione,
      if (nome != null) 'nome': nome,
      if (pezzi != null) 'pezzi': pezzi,
      if (millesimi != null) 'millesimi': millesimi,
      if (unita != null) 'unita': unita,
      if (prezzoUnitarioCents != null)
        'prezzo_unitario_cents': prezzoUnitarioCents,
      if (totaleCents != null) 'totale_cents': totaleCents,
      if (offertaJson != null) 'offerta_json': offertaJson,
      if (prezzoRifCents != null) 'prezzo_rif_cents': prezzoRifCents,
      if (unitaRif != null) 'unita_rif': unitaRif,
      if (totaleStampatoCents != null)
        'totale_stampato_cents': totaleStampatoCents,
      if (origine != null) 'origine': origine,
      if (stornata != null) 'stornata': stornata,
      if (creataIl != null) 'creata_il': creataIl,
    });
  }

  RigheCompanion copyWith({
    Value<int>? id,
    Value<int>? spesaId,
    Value<String>? insieme,
    Value<int>? posizione,
    Value<String>? nome,
    Value<int?>? pezzi,
    Value<int?>? millesimi,
    Value<String?>? unita,
    Value<int>? prezzoUnitarioCents,
    Value<int>? totaleCents,
    Value<String?>? offertaJson,
    Value<int?>? prezzoRifCents,
    Value<String?>? unitaRif,
    Value<int?>? totaleStampatoCents,
    Value<String>? origine,
    Value<bool>? stornata,
    Value<int>? creataIl,
  }) {
    return RigheCompanion(
      id: id ?? this.id,
      spesaId: spesaId ?? this.spesaId,
      insieme: insieme ?? this.insieme,
      posizione: posizione ?? this.posizione,
      nome: nome ?? this.nome,
      pezzi: pezzi ?? this.pezzi,
      millesimi: millesimi ?? this.millesimi,
      unita: unita ?? this.unita,
      prezzoUnitarioCents: prezzoUnitarioCents ?? this.prezzoUnitarioCents,
      totaleCents: totaleCents ?? this.totaleCents,
      offertaJson: offertaJson ?? this.offertaJson,
      prezzoRifCents: prezzoRifCents ?? this.prezzoRifCents,
      unitaRif: unitaRif ?? this.unitaRif,
      totaleStampatoCents: totaleStampatoCents ?? this.totaleStampatoCents,
      origine: origine ?? this.origine,
      stornata: stornata ?? this.stornata,
      creataIl: creataIl ?? this.creataIl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (spesaId.present) {
      map['spesa_id'] = Variable<int>(spesaId.value);
    }
    if (insieme.present) {
      map['insieme'] = Variable<String>(insieme.value);
    }
    if (posizione.present) {
      map['posizione'] = Variable<int>(posizione.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (pezzi.present) {
      map['pezzi'] = Variable<int>(pezzi.value);
    }
    if (millesimi.present) {
      map['millesimi'] = Variable<int>(millesimi.value);
    }
    if (unita.present) {
      map['unita'] = Variable<String>(unita.value);
    }
    if (prezzoUnitarioCents.present) {
      map['prezzo_unitario_cents'] = Variable<int>(prezzoUnitarioCents.value);
    }
    if (totaleCents.present) {
      map['totale_cents'] = Variable<int>(totaleCents.value);
    }
    if (offertaJson.present) {
      map['offerta_json'] = Variable<String>(offertaJson.value);
    }
    if (prezzoRifCents.present) {
      map['prezzo_rif_cents'] = Variable<int>(prezzoRifCents.value);
    }
    if (unitaRif.present) {
      map['unita_rif'] = Variable<String>(unitaRif.value);
    }
    if (totaleStampatoCents.present) {
      map['totale_stampato_cents'] = Variable<int>(totaleStampatoCents.value);
    }
    if (origine.present) {
      map['origine'] = Variable<String>(origine.value);
    }
    if (stornata.present) {
      map['stornata'] = Variable<bool>(stornata.value);
    }
    if (creataIl.present) {
      map['creata_il'] = Variable<int>(creataIl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RigheCompanion(')
          ..write('id: $id, ')
          ..write('spesaId: $spesaId, ')
          ..write('insieme: $insieme, ')
          ..write('posizione: $posizione, ')
          ..write('nome: $nome, ')
          ..write('pezzi: $pezzi, ')
          ..write('millesimi: $millesimi, ')
          ..write('unita: $unita, ')
          ..write('prezzoUnitarioCents: $prezzoUnitarioCents, ')
          ..write('totaleCents: $totaleCents, ')
          ..write('offertaJson: $offertaJson, ')
          ..write('prezzoRifCents: $prezzoRifCents, ')
          ..write('unitaRif: $unitaRif, ')
          ..write('totaleStampatoCents: $totaleStampatoCents, ')
          ..write('origine: $origine, ')
          ..write('stornata: $stornata, ')
          ..write('creataIl: $creataIl')
          ..write(')'))
        .toString();
  }
}

abstract class _$SpendingDatabase extends GeneratedDatabase {
  _$SpendingDatabase(QueryExecutor e) : super(e);
  $SpendingDatabaseManager get managers => $SpendingDatabaseManager(this);
  late final $NegoziTable negozi = $NegoziTable(this);
  late final $SpeseTable spese = $SpeseTable(this);
  late final $RigheTable righe = $RigheTable(this);
  late final Index speseUnaInCorso = Index(
    'spese_una_in_corso',
    'CREATE UNIQUE INDEX spese_una_in_corso ON spese (stato) WHERE stato = \'in_corso\'',
  );
  late final Index idxSpeseStorico = Index(
    'idx_spese_storico',
    'CREATE INDEX idx_spese_storico ON spese (stato, data_spesa DESC, id DESC)',
  );
  late final Index idxSpeseNegozio = Index(
    'idx_spese_negozio',
    'CREATE INDEX idx_spese_negozio ON spese (negozio_id)',
  );
  late final Index idxRigheSpesa = Index(
    'idx_righe_spesa',
    'CREATE INDEX idx_righe_spesa ON righe (spesa_id, insieme, posizione)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    negozi,
    spese,
    righe,
    speseUnaInCorso,
    idxSpeseStorico,
    idxSpeseNegozio,
    idxRigheSpesa,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'negozi',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('spese', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'spese',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('righe', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$NegoziTableCreateCompanionBuilder = NegoziCompanion Function({
  Value<int> id,
  required String nome,
  required int creatoIl,
});
typedef $$NegoziTableUpdateCompanionBuilder = NegoziCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<int> creatoIl,
});

final class $$NegoziTableReferences
    extends BaseReferences<_$SpendingDatabase, $NegoziTable, Negozio> {
  $$NegoziTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SpeseTable, List<SpesaRow>> _speseRefsTable(
    _$SpendingDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.spese,
    aliasName: 'negozi__id__spese__negozio_id',
  );

  $$SpeseTableProcessedTableManager get speseRefs {
    final manager = $$SpeseTableTableManager(
      $_db,
      $_db.spese,
    ).filter((f) => f.negozioId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_speseRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NegoziTableFilterComposer
    extends Composer<_$SpendingDatabase, $NegoziTable> {
  $$NegoziTableFilterComposer({
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

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creatoIl => $composableBuilder(
    column: $table.creatoIl,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> speseRefs(
    Expression<bool> Function($$SpeseTableFilterComposer f) f,
  ) {
    final $$SpeseTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spese,
      getReferencedColumn: (t) => t.negozioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeseTableFilterComposer(
            $db: $db,
            $table: $db.spese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NegoziTableOrderingComposer
    extends Composer<_$SpendingDatabase, $NegoziTable> {
  $$NegoziTableOrderingComposer({
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

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creatoIl => $composableBuilder(
    column: $table.creatoIl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NegoziTableAnnotationComposer
    extends Composer<_$SpendingDatabase, $NegoziTable> {
  $$NegoziTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get creatoIl =>
      $composableBuilder(column: $table.creatoIl, builder: (column) => column);

  Expression<T> speseRefs<T extends Object>(
    Expression<T> Function($$SpeseTableAnnotationComposer a) f,
  ) {
    final $$SpeseTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.spese,
      getReferencedColumn: (t) => t.negozioId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeseTableAnnotationComposer(
            $db: $db,
            $table: $db.spese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NegoziTableTableManager
    extends
        RootTableManager<
          _$SpendingDatabase,
          $NegoziTable,
          Negozio,
          $$NegoziTableFilterComposer,
          $$NegoziTableOrderingComposer,
          $$NegoziTableAnnotationComposer,
          $$NegoziTableCreateCompanionBuilder,
          $$NegoziTableUpdateCompanionBuilder,
          (Negozio, $$NegoziTableReferences),
          Negozio,
          PrefetchHooks Function({bool speseRefs})
        > {
  $$NegoziTableTableManager(_$SpendingDatabase db, $NegoziTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NegoziTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NegoziTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NegoziTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<int> creatoIl = const Value.absent(),
          }) => NegoziCompanion(id: id, nome: nome, creatoIl: creatoIl),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            required int creatoIl,
          }) => NegoziCompanion.insert(id: id, nome: nome, creatoIl: creatoIl),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NegoziTable, Negozio>(table),
                  $$NegoziTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({speseRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (speseRefs) db.spese],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (speseRefs)
                    await $_getPrefetchedData<Negozio, $NegoziTable, SpesaRow>(
                      currentTable: table,
                      referencedTable: $$NegoziTableReferences._speseRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$NegoziTableReferences(db, table, p0).speseRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.negozioId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NegoziTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendingDatabase,
      $NegoziTable,
      Negozio,
      $$NegoziTableFilterComposer,
      $$NegoziTableOrderingComposer,
      $$NegoziTableAnnotationComposer,
      $$NegoziTableCreateCompanionBuilder,
      $$NegoziTableUpdateCompanionBuilder,
      (Negozio, $$NegoziTableReferences),
      Negozio,
      PrefetchHooks Function({bool speseRefs})
    >;
typedef $$SpeseTableCreateCompanionBuilder = SpeseCompanion Function({
  Value<int> id,
  required String stato,
  Value<int?> negozioId,
  required int iniziataIl,
  Value<int?> chiusaIl,
  Value<String?> dataSpesa,
  Value<int?> budgetCents,
  Value<int> totaleCents,
  Value<int?> totaleScontrinoCents,
  Value<String> fonte,
});
typedef $$SpeseTableUpdateCompanionBuilder = SpeseCompanion Function({
  Value<int> id,
  Value<String> stato,
  Value<int?> negozioId,
  Value<int> iniziataIl,
  Value<int?> chiusaIl,
  Value<String?> dataSpesa,
  Value<int?> budgetCents,
  Value<int> totaleCents,
  Value<int?> totaleScontrinoCents,
  Value<String> fonte,
});

final class $$SpeseTableReferences
    extends BaseReferences<_$SpendingDatabase, $SpeseTable, SpesaRow> {
  $$SpeseTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NegoziTable _negozioIdTable(_$SpendingDatabase db) =>
      db.negozi.createAlias('spese__negozio_id__negozi__id');

  $$NegoziTableProcessedTableManager? get negozioId {
    final $_column = $_itemColumn<int>('negozio_id');
    if ($_column == null) return null;
    final manager = $$NegoziTableTableManager(
      $_db,
      $_db.negozi,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_negozioIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RigheTable, List<RigaRow>> _righeRefsTable(
    _$SpendingDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.righe,
    aliasName: 'spese__id__righe__spesa_id',
  );

  $$RigheTableProcessedTableManager get righeRefs {
    final manager = $$RigheTableTableManager(
      $_db,
      $_db.righe,
    ).filter((f) => f.spesaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_righeRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SpeseTableFilterComposer
    extends Composer<_$SpendingDatabase, $SpeseTable> {
  $$SpeseTableFilterComposer({
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

  ColumnFilters<String> get stato => $composableBuilder(
    column: $table.stato,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iniziataIl => $composableBuilder(
    column: $table.iniziataIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chiusaIl => $composableBuilder(
    column: $table.chiusaIl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataSpesa => $composableBuilder(
    column: $table.dataSpesa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get budgetCents => $composableBuilder(
    column: $table.budgetCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totaleCents => $composableBuilder(
    column: $table.totaleCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totaleScontrinoCents => $composableBuilder(
    column: $table.totaleScontrinoCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fonte => $composableBuilder(
    column: $table.fonte,
    builder: (column) => ColumnFilters(column),
  );

  $$NegoziTableFilterComposer get negozioId {
    final $$NegoziTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.negozioId,
      referencedTable: $db.negozi,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NegoziTableFilterComposer(
            $db: $db,
            $table: $db.negozi,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> righeRefs(
    Expression<bool> Function($$RigheTableFilterComposer f) f,
  ) {
    final $$RigheTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.righe,
      getReferencedColumn: (t) => t.spesaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RigheTableFilterComposer(
            $db: $db,
            $table: $db.righe,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpeseTableOrderingComposer
    extends Composer<_$SpendingDatabase, $SpeseTable> {
  $$SpeseTableOrderingComposer({
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

  ColumnOrderings<String> get stato => $composableBuilder(
    column: $table.stato,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iniziataIl => $composableBuilder(
    column: $table.iniziataIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chiusaIl => $composableBuilder(
    column: $table.chiusaIl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataSpesa => $composableBuilder(
    column: $table.dataSpesa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get budgetCents => $composableBuilder(
    column: $table.budgetCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totaleCents => $composableBuilder(
    column: $table.totaleCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totaleScontrinoCents => $composableBuilder(
    column: $table.totaleScontrinoCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fonte => $composableBuilder(
    column: $table.fonte,
    builder: (column) => ColumnOrderings(column),
  );

  $$NegoziTableOrderingComposer get negozioId {
    final $$NegoziTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.negozioId,
      referencedTable: $db.negozi,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NegoziTableOrderingComposer(
            $db: $db,
            $table: $db.negozi,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpeseTableAnnotationComposer
    extends Composer<_$SpendingDatabase, $SpeseTable> {
  $$SpeseTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stato =>
      $composableBuilder(column: $table.stato, builder: (column) => column);

  GeneratedColumn<int> get iniziataIl => $composableBuilder(
    column: $table.iniziataIl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chiusaIl =>
      $composableBuilder(column: $table.chiusaIl, builder: (column) => column);

  GeneratedColumn<String> get dataSpesa =>
      $composableBuilder(column: $table.dataSpesa, builder: (column) => column);

  GeneratedColumn<int> get budgetCents => $composableBuilder(
    column: $table.budgetCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totaleCents => $composableBuilder(
    column: $table.totaleCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totaleScontrinoCents => $composableBuilder(
    column: $table.totaleScontrinoCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fonte =>
      $composableBuilder(column: $table.fonte, builder: (column) => column);

  $$NegoziTableAnnotationComposer get negozioId {
    final $$NegoziTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.negozioId,
      referencedTable: $db.negozi,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NegoziTableAnnotationComposer(
            $db: $db,
            $table: $db.negozi,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> righeRefs<T extends Object>(
    Expression<T> Function($$RigheTableAnnotationComposer a) f,
  ) {
    final $$RigheTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.righe,
      getReferencedColumn: (t) => t.spesaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RigheTableAnnotationComposer(
            $db: $db,
            $table: $db.righe,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SpeseTableTableManager
    extends
        RootTableManager<
          _$SpendingDatabase,
          $SpeseTable,
          SpesaRow,
          $$SpeseTableFilterComposer,
          $$SpeseTableOrderingComposer,
          $$SpeseTableAnnotationComposer,
          $$SpeseTableCreateCompanionBuilder,
          $$SpeseTableUpdateCompanionBuilder,
          (SpesaRow, $$SpeseTableReferences),
          SpesaRow,
          PrefetchHooks Function({bool negozioId, bool righeRefs})
        > {
  $$SpeseTableTableManager(_$SpendingDatabase db, $SpeseTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeseTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeseTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeseTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> stato = const Value.absent(),
                Value<int?> negozioId = const Value.absent(),
                Value<int> iniziataIl = const Value.absent(),
                Value<int?> chiusaIl = const Value.absent(),
                Value<String?> dataSpesa = const Value.absent(),
                Value<int?> budgetCents = const Value.absent(),
                Value<int> totaleCents = const Value.absent(),
                Value<int?> totaleScontrinoCents = const Value.absent(),
                Value<String> fonte = const Value.absent(),
              }) => SpeseCompanion(
                id: id,
                stato: stato,
                negozioId: negozioId,
                iniziataIl: iniziataIl,
                chiusaIl: chiusaIl,
                dataSpesa: dataSpesa,
                budgetCents: budgetCents,
                totaleCents: totaleCents,
                totaleScontrinoCents: totaleScontrinoCents,
                fonte: fonte,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String stato,
                Value<int?> negozioId = const Value.absent(),
                required int iniziataIl,
                Value<int?> chiusaIl = const Value.absent(),
                Value<String?> dataSpesa = const Value.absent(),
                Value<int?> budgetCents = const Value.absent(),
                Value<int> totaleCents = const Value.absent(),
                Value<int?> totaleScontrinoCents = const Value.absent(),
                Value<String> fonte = const Value.absent(),
              }) => SpeseCompanion.insert(
                id: id,
                stato: stato,
                negozioId: negozioId,
                iniziataIl: iniziataIl,
                chiusaIl: chiusaIl,
                dataSpesa: dataSpesa,
                budgetCents: budgetCents,
                totaleCents: totaleCents,
                totaleScontrinoCents: totaleScontrinoCents,
                fonte: fonte,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpeseTable, SpesaRow>(table),
                  $$SpeseTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({negozioId = false, righeRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (righeRefs) db.righe],
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
                    if (negozioId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.negozioId,
                        referencedTable: $$SpeseTableReferences._negozioIdTable(
                          db,
                        ),
                        referencedColumn: $$SpeseTableReferences
                            ._negozioIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (righeRefs)
                    await $_getPrefetchedData<SpesaRow, $SpeseTable, RigaRow>(
                      currentTable: table,
                      referencedTable: $$SpeseTableReferences._righeRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SpeseTableReferences(db, table, p0).righeRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.spesaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SpeseTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendingDatabase,
      $SpeseTable,
      SpesaRow,
      $$SpeseTableFilterComposer,
      $$SpeseTableOrderingComposer,
      $$SpeseTableAnnotationComposer,
      $$SpeseTableCreateCompanionBuilder,
      $$SpeseTableUpdateCompanionBuilder,
      (SpesaRow, $$SpeseTableReferences),
      SpesaRow,
      PrefetchHooks Function({bool negozioId, bool righeRefs})
    >;
typedef $$RigheTableCreateCompanionBuilder = RigheCompanion Function({
  Value<int> id,
  required int spesaId,
  required String insieme,
  required int posizione,
  Value<String> nome,
  Value<int?> pezzi,
  Value<int?> millesimi,
  Value<String?> unita,
  required int prezzoUnitarioCents,
  required int totaleCents,
  Value<String?> offertaJson,
  Value<int?> prezzoRifCents,
  Value<String?> unitaRif,
  Value<int?> totaleStampatoCents,
  required String origine,
  Value<bool> stornata,
  required int creataIl,
});
typedef $$RigheTableUpdateCompanionBuilder = RigheCompanion Function({
  Value<int> id,
  Value<int> spesaId,
  Value<String> insieme,
  Value<int> posizione,
  Value<String> nome,
  Value<int?> pezzi,
  Value<int?> millesimi,
  Value<String?> unita,
  Value<int> prezzoUnitarioCents,
  Value<int> totaleCents,
  Value<String?> offertaJson,
  Value<int?> prezzoRifCents,
  Value<String?> unitaRif,
  Value<int?> totaleStampatoCents,
  Value<String> origine,
  Value<bool> stornata,
  Value<int> creataIl,
});

final class $$RigheTableReferences
    extends BaseReferences<_$SpendingDatabase, $RigheTable, RigaRow> {
  $$RigheTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SpeseTable _spesaIdTable(_$SpendingDatabase db) =>
      db.spese.createAlias('righe__spesa_id__spese__id');

  $$SpeseTableProcessedTableManager get spesaId {
    final $_column = $_itemColumn<int>('spesa_id')!;

    final manager = $$SpeseTableTableManager(
      $_db,
      $_db.spese,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_spesaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RigheTableFilterComposer
    extends Composer<_$SpendingDatabase, $RigheTable> {
  $$RigheTableFilterComposer({
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

  ColumnFilters<String> get insieme => $composableBuilder(
    column: $table.insieme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get posizione => $composableBuilder(
    column: $table.posizione,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pezzi => $composableBuilder(
    column: $table.pezzi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get millesimi => $composableBuilder(
    column: $table.millesimi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unita => $composableBuilder(
    column: $table.unita,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prezzoUnitarioCents => $composableBuilder(
    column: $table.prezzoUnitarioCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totaleCents => $composableBuilder(
    column: $table.totaleCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offertaJson => $composableBuilder(
    column: $table.offertaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prezzoRifCents => $composableBuilder(
    column: $table.prezzoRifCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitaRif => $composableBuilder(
    column: $table.unitaRif,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totaleStampatoCents => $composableBuilder(
    column: $table.totaleStampatoCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origine => $composableBuilder(
    column: $table.origine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get stornata => $composableBuilder(
    column: $table.stornata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creataIl => $composableBuilder(
    column: $table.creataIl,
    builder: (column) => ColumnFilters(column),
  );

  $$SpeseTableFilterComposer get spesaId {
    final $$SpeseTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spesaId,
      referencedTable: $db.spese,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeseTableFilterComposer(
            $db: $db,
            $table: $db.spese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RigheTableOrderingComposer
    extends Composer<_$SpendingDatabase, $RigheTable> {
  $$RigheTableOrderingComposer({
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

  ColumnOrderings<String> get insieme => $composableBuilder(
    column: $table.insieme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get posizione => $composableBuilder(
    column: $table.posizione,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nome => $composableBuilder(
    column: $table.nome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pezzi => $composableBuilder(
    column: $table.pezzi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get millesimi => $composableBuilder(
    column: $table.millesimi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unita => $composableBuilder(
    column: $table.unita,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prezzoUnitarioCents => $composableBuilder(
    column: $table.prezzoUnitarioCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totaleCents => $composableBuilder(
    column: $table.totaleCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offertaJson => $composableBuilder(
    column: $table.offertaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prezzoRifCents => $composableBuilder(
    column: $table.prezzoRifCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitaRif => $composableBuilder(
    column: $table.unitaRif,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totaleStampatoCents => $composableBuilder(
    column: $table.totaleStampatoCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origine => $composableBuilder(
    column: $table.origine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stornata => $composableBuilder(
    column: $table.stornata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creataIl => $composableBuilder(
    column: $table.creataIl,
    builder: (column) => ColumnOrderings(column),
  );

  $$SpeseTableOrderingComposer get spesaId {
    final $$SpeseTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spesaId,
      referencedTable: $db.spese,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeseTableOrderingComposer(
            $db: $db,
            $table: $db.spese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RigheTableAnnotationComposer
    extends Composer<_$SpendingDatabase, $RigheTable> {
  $$RigheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get insieme =>
      $composableBuilder(column: $table.insieme, builder: (column) => column);

  GeneratedColumn<int> get posizione =>
      $composableBuilder(column: $table.posizione, builder: (column) => column);

  GeneratedColumn<String> get nome =>
      $composableBuilder(column: $table.nome, builder: (column) => column);

  GeneratedColumn<int> get pezzi =>
      $composableBuilder(column: $table.pezzi, builder: (column) => column);

  GeneratedColumn<int> get millesimi =>
      $composableBuilder(column: $table.millesimi, builder: (column) => column);

  GeneratedColumn<String> get unita =>
      $composableBuilder(column: $table.unita, builder: (column) => column);

  GeneratedColumn<int> get prezzoUnitarioCents => $composableBuilder(
    column: $table.prezzoUnitarioCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totaleCents => $composableBuilder(
    column: $table.totaleCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get offertaJson => $composableBuilder(
    column: $table.offertaJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prezzoRifCents => $composableBuilder(
    column: $table.prezzoRifCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitaRif =>
      $composableBuilder(column: $table.unitaRif, builder: (column) => column);

  GeneratedColumn<int> get totaleStampatoCents => $composableBuilder(
    column: $table.totaleStampatoCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origine =>
      $composableBuilder(column: $table.origine, builder: (column) => column);

  GeneratedColumn<bool> get stornata =>
      $composableBuilder(column: $table.stornata, builder: (column) => column);

  GeneratedColumn<int> get creataIl =>
      $composableBuilder(column: $table.creataIl, builder: (column) => column);

  $$SpeseTableAnnotationComposer get spesaId {
    final $$SpeseTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.spesaId,
      referencedTable: $db.spese,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpeseTableAnnotationComposer(
            $db: $db,
            $table: $db.spese,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RigheTableTableManager
    extends
        RootTableManager<
          _$SpendingDatabase,
          $RigheTable,
          RigaRow,
          $$RigheTableFilterComposer,
          $$RigheTableOrderingComposer,
          $$RigheTableAnnotationComposer,
          $$RigheTableCreateCompanionBuilder,
          $$RigheTableUpdateCompanionBuilder,
          (RigaRow, $$RigheTableReferences),
          RigaRow,
          PrefetchHooks Function({bool spesaId})
        > {
  $$RigheTableTableManager(_$SpendingDatabase db, $RigheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RigheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RigheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RigheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> spesaId = const Value.absent(),
                Value<String> insieme = const Value.absent(),
                Value<int> posizione = const Value.absent(),
                Value<String> nome = const Value.absent(),
                Value<int?> pezzi = const Value.absent(),
                Value<int?> millesimi = const Value.absent(),
                Value<String?> unita = const Value.absent(),
                Value<int> prezzoUnitarioCents = const Value.absent(),
                Value<int> totaleCents = const Value.absent(),
                Value<String?> offertaJson = const Value.absent(),
                Value<int?> prezzoRifCents = const Value.absent(),
                Value<String?> unitaRif = const Value.absent(),
                Value<int?> totaleStampatoCents = const Value.absent(),
                Value<String> origine = const Value.absent(),
                Value<bool> stornata = const Value.absent(),
                Value<int> creataIl = const Value.absent(),
              }) => RigheCompanion(
                id: id,
                spesaId: spesaId,
                insieme: insieme,
                posizione: posizione,
                nome: nome,
                pezzi: pezzi,
                millesimi: millesimi,
                unita: unita,
                prezzoUnitarioCents: prezzoUnitarioCents,
                totaleCents: totaleCents,
                offertaJson: offertaJson,
                prezzoRifCents: prezzoRifCents,
                unitaRif: unitaRif,
                totaleStampatoCents: totaleStampatoCents,
                origine: origine,
                stornata: stornata,
                creataIl: creataIl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int spesaId,
                required String insieme,
                required int posizione,
                Value<String> nome = const Value.absent(),
                Value<int?> pezzi = const Value.absent(),
                Value<int?> millesimi = const Value.absent(),
                Value<String?> unita = const Value.absent(),
                required int prezzoUnitarioCents,
                required int totaleCents,
                Value<String?> offertaJson = const Value.absent(),
                Value<int?> prezzoRifCents = const Value.absent(),
                Value<String?> unitaRif = const Value.absent(),
                Value<int?> totaleStampatoCents = const Value.absent(),
                required String origine,
                Value<bool> stornata = const Value.absent(),
                required int creataIl,
              }) => RigheCompanion.insert(
                id: id,
                spesaId: spesaId,
                insieme: insieme,
                posizione: posizione,
                nome: nome,
                pezzi: pezzi,
                millesimi: millesimi,
                unita: unita,
                prezzoUnitarioCents: prezzoUnitarioCents,
                totaleCents: totaleCents,
                offertaJson: offertaJson,
                prezzoRifCents: prezzoRifCents,
                unitaRif: unitaRif,
                totaleStampatoCents: totaleStampatoCents,
                origine: origine,
                stornata: stornata,
                creataIl: creataIl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RigheTable, RigaRow>(table),
                  $$RigheTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({spesaId = false}) {
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
                    if (spesaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.spesaId,
                        referencedTable: $$RigheTableReferences._spesaIdTable(
                          db,
                        ),
                        referencedColumn: $$RigheTableReferences
                            ._spesaIdTable(db)
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

typedef $$RigheTableProcessedTableManager =
    ProcessedTableManager<
      _$SpendingDatabase,
      $RigheTable,
      RigaRow,
      $$RigheTableFilterComposer,
      $$RigheTableOrderingComposer,
      $$RigheTableAnnotationComposer,
      $$RigheTableCreateCompanionBuilder,
      $$RigheTableUpdateCompanionBuilder,
      (RigaRow, $$RigheTableReferences),
      RigaRow,
      PrefetchHooks Function({bool spesaId})
    >;

class $SpendingDatabaseManager {
  final _$SpendingDatabase _db;
  $SpendingDatabaseManager(this._db);
  $$NegoziTableTableManager get negozi =>
      $$NegoziTableTableManager(_db, _db.negozi);
  $$SpeseTableTableManager get spese =>
      $$SpeseTableTableManager(_db, _db.spese);
  $$RigheTableTableManager get righe =>
      $$RigheTableTableManager(_db, _db.righe);
}
