// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $MealEntriesTable extends MealEntries
    with TableInfo<$MealEntriesTable, LocalMeal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messIdMeta = const VerificationMeta('messId');
  @override
  late final GeneratedColumn<String> messId = GeneratedColumn<String>(
    'mess_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealTypeIdMeta = const VerificationMeta(
    'mealTypeId',
  );
  @override
  late final GeneratedColumn<String> mealTypeId = GeneratedColumn<String>(
    'meal_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<double> count = GeneratedColumn<double>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guestCountMeta = const VerificationMeta(
    'guestCount',
  );
  @override
  late final GeneratedColumn<int> guestCount = GeneratedColumn<int>(
    'guest_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOffMeta = const VerificationMeta('isOff');
  @override
  late final GeneratedColumn<bool> isOff = GeneratedColumn<bool>(
    'is_off',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_off" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messId,
    memberId,
    mealTypeId,
    date,
    count,
    guestCount,
    isOff,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMeal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mess_id')) {
      context.handle(
        _messIdMeta,
        messId.isAcceptableOrUnknown(data['mess_id']!, _messIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('meal_type_id')) {
      context.handle(
        _mealTypeIdMeta,
        mealTypeId.isAcceptableOrUnknown(
          data['meal_type_id']!,
          _mealTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mealTypeIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('guest_count')) {
      context.handle(
        _guestCountMeta,
        guestCount.isAcceptableOrUnknown(data['guest_count']!, _guestCountMeta),
      );
    } else if (isInserting) {
      context.missing(_guestCountMeta);
    }
    if (data.containsKey('is_off')) {
      context.handle(
        _isOffMeta,
        isOff.isAcceptableOrUnknown(data['is_off']!, _isOffMeta),
      );
    } else if (isInserting) {
      context.missing(_isOffMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId, date, mealTypeId};
  @override
  LocalMeal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMeal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mess_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      mealTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_type_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}count'],
      )!,
      guestCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guest_count'],
      )!,
      isOff: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_off'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MealEntriesTable createAlias(String alias) {
    return $MealEntriesTable(attachedDatabase, alias);
  }
}

class LocalMeal extends DataClass implements Insertable<LocalMeal> {
  final String id;
  final String messId;
  final String memberId;
  final String mealTypeId;

  /// `yyyy-mm-dd`, so ranges compare as text.
  final String date;
  final double count;
  final int guestCount;
  final bool isOff;
  final DateTime updatedAt;
  const LocalMeal({
    required this.id,
    required this.messId,
    required this.memberId,
    required this.mealTypeId,
    required this.date,
    required this.count,
    required this.guestCount,
    required this.isOff,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mess_id'] = Variable<String>(messId);
    map['member_id'] = Variable<String>(memberId);
    map['meal_type_id'] = Variable<String>(mealTypeId);
    map['date'] = Variable<String>(date);
    map['count'] = Variable<double>(count);
    map['guest_count'] = Variable<int>(guestCount);
    map['is_off'] = Variable<bool>(isOff);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MealEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealEntriesCompanion(
      id: Value(id),
      messId: Value(messId),
      memberId: Value(memberId),
      mealTypeId: Value(mealTypeId),
      date: Value(date),
      count: Value(count),
      guestCount: Value(guestCount),
      isOff: Value(isOff),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMeal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMeal(
      id: serializer.fromJson<String>(json['id']),
      messId: serializer.fromJson<String>(json['messId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      mealTypeId: serializer.fromJson<String>(json['mealTypeId']),
      date: serializer.fromJson<String>(json['date']),
      count: serializer.fromJson<double>(json['count']),
      guestCount: serializer.fromJson<int>(json['guestCount']),
      isOff: serializer.fromJson<bool>(json['isOff']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messId': serializer.toJson<String>(messId),
      'memberId': serializer.toJson<String>(memberId),
      'mealTypeId': serializer.toJson<String>(mealTypeId),
      'date': serializer.toJson<String>(date),
      'count': serializer.toJson<double>(count),
      'guestCount': serializer.toJson<int>(guestCount),
      'isOff': serializer.toJson<bool>(isOff),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMeal copyWith({
    String? id,
    String? messId,
    String? memberId,
    String? mealTypeId,
    String? date,
    double? count,
    int? guestCount,
    bool? isOff,
    DateTime? updatedAt,
  }) => LocalMeal(
    id: id ?? this.id,
    messId: messId ?? this.messId,
    memberId: memberId ?? this.memberId,
    mealTypeId: mealTypeId ?? this.mealTypeId,
    date: date ?? this.date,
    count: count ?? this.count,
    guestCount: guestCount ?? this.guestCount,
    isOff: isOff ?? this.isOff,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMeal copyWithCompanion(MealEntriesCompanion data) {
    return LocalMeal(
      id: data.id.present ? data.id.value : this.id,
      messId: data.messId.present ? data.messId.value : this.messId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      mealTypeId: data.mealTypeId.present
          ? data.mealTypeId.value
          : this.mealTypeId,
      date: data.date.present ? data.date.value : this.date,
      count: data.count.present ? data.count.value : this.count,
      guestCount: data.guestCount.present
          ? data.guestCount.value
          : this.guestCount,
      isOff: data.isOff.present ? data.isOff.value : this.isOff,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeal(')
          ..write('id: $id, ')
          ..write('messId: $messId, ')
          ..write('memberId: $memberId, ')
          ..write('mealTypeId: $mealTypeId, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('guestCount: $guestCount, ')
          ..write('isOff: $isOff, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messId,
    memberId,
    mealTypeId,
    date,
    count,
    guestCount,
    isOff,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMeal &&
          other.id == this.id &&
          other.messId == this.messId &&
          other.memberId == this.memberId &&
          other.mealTypeId == this.mealTypeId &&
          other.date == this.date &&
          other.count == this.count &&
          other.guestCount == this.guestCount &&
          other.isOff == this.isOff &&
          other.updatedAt == this.updatedAt);
}

class MealEntriesCompanion extends UpdateCompanion<LocalMeal> {
  final Value<String> id;
  final Value<String> messId;
  final Value<String> memberId;
  final Value<String> mealTypeId;
  final Value<String> date;
  final Value<double> count;
  final Value<int> guestCount;
  final Value<bool> isOff;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MealEntriesCompanion({
    this.id = const Value.absent(),
    this.messId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.mealTypeId = const Value.absent(),
    this.date = const Value.absent(),
    this.count = const Value.absent(),
    this.guestCount = const Value.absent(),
    this.isOff = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealEntriesCompanion.insert({
    required String id,
    required String messId,
    required String memberId,
    required String mealTypeId,
    required String date,
    required double count,
    required int guestCount,
    required bool isOff,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messId = Value(messId),
       memberId = Value(memberId),
       mealTypeId = Value(mealTypeId),
       date = Value(date),
       count = Value(count),
       guestCount = Value(guestCount),
       isOff = Value(isOff),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMeal> custom({
    Expression<String>? id,
    Expression<String>? messId,
    Expression<String>? memberId,
    Expression<String>? mealTypeId,
    Expression<String>? date,
    Expression<double>? count,
    Expression<int>? guestCount,
    Expression<bool>? isOff,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messId != null) 'mess_id': messId,
      if (memberId != null) 'member_id': memberId,
      if (mealTypeId != null) 'meal_type_id': mealTypeId,
      if (date != null) 'date': date,
      if (count != null) 'count': count,
      if (guestCount != null) 'guest_count': guestCount,
      if (isOff != null) 'is_off': isOff,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? messId,
    Value<String>? memberId,
    Value<String>? mealTypeId,
    Value<String>? date,
    Value<double>? count,
    Value<int>? guestCount,
    Value<bool>? isOff,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MealEntriesCompanion(
      id: id ?? this.id,
      messId: messId ?? this.messId,
      memberId: memberId ?? this.memberId,
      mealTypeId: mealTypeId ?? this.mealTypeId,
      date: date ?? this.date,
      count: count ?? this.count,
      guestCount: guestCount ?? this.guestCount,
      isOff: isOff ?? this.isOff,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messId.present) {
      map['mess_id'] = Variable<String>(messId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (mealTypeId.present) {
      map['meal_type_id'] = Variable<String>(mealTypeId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (count.present) {
      map['count'] = Variable<double>(count.value);
    }
    if (guestCount.present) {
      map['guest_count'] = Variable<int>(guestCount.value);
    }
    if (isOff.present) {
      map['is_off'] = Variable<bool>(isOff.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealEntriesCompanion(')
          ..write('id: $id, ')
          ..write('messId: $messId, ')
          ..write('memberId: $memberId, ')
          ..write('mealTypeId: $mealTypeId, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('guestCount: $guestCount, ')
          ..write('isOff: $isOff, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BazarsTable extends Bazars with TableInfo<$BazarsTable, LocalBazar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BazarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messIdMeta = const VerificationMeta('messId');
  @override
  late final GeneratedColumn<String> messId = GeneratedColumn<String>(
    'mess_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _buyerMemberIdMeta = const VerificationMeta(
    'buyerMemberId',
  );
  @override
  late final GeneratedColumn<String> buyerMemberId = GeneratedColumn<String>(
    'buyer_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidByMemberIdMeta = const VerificationMeta(
    'paidByMemberId',
  );
  @override
  late final GeneratedColumn<String> paidByMemberId = GeneratedColumn<String>(
    'paid_by_member_id',
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptPathMeta = const VerificationMeta(
    'receiptPath',
  );
  @override
  late final GeneratedColumn<String> receiptPath = GeneratedColumn<String>(
    'receipt_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messId,
    date,
    amount,
    buyerMemberId,
    paidByMemberId,
    note,
    source,
    receiptPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bazars';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalBazar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mess_id')) {
      context.handle(
        _messIdMeta,
        messId.isAcceptableOrUnknown(data['mess_id']!, _messIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('buyer_member_id')) {
      context.handle(
        _buyerMemberIdMeta,
        buyerMemberId.isAcceptableOrUnknown(
          data['buyer_member_id']!,
          _buyerMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('paid_by_member_id')) {
      context.handle(
        _paidByMemberIdMeta,
        paidByMemberId.isAcceptableOrUnknown(
          data['paid_by_member_id']!,
          _paidByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('receipt_path')) {
      context.handle(
        _receiptPathMeta,
        receiptPath.isAcceptableOrUnknown(
          data['receipt_path']!,
          _receiptPathMeta,
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalBazar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalBazar(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mess_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      buyerMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buyer_member_id'],
      ),
      paidByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_by_member_id'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      receiptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BazarsTable createAlias(String alias) {
    return $BazarsTable(attachedDatabase, alias);
  }
}

class LocalBazar extends DataClass implements Insertable<LocalBazar> {
  final String id;
  final String messId;
  final String date;
  final double amount;
  final String? buyerMemberId;
  final String? paidByMemberId;
  final String? note;
  final String source;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalBazar({
    required this.id,
    required this.messId,
    required this.date,
    required this.amount,
    this.buyerMemberId,
    this.paidByMemberId,
    this.note,
    required this.source,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mess_id'] = Variable<String>(messId);
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || buyerMemberId != null) {
      map['buyer_member_id'] = Variable<String>(buyerMemberId);
    }
    if (!nullToAbsent || paidByMemberId != null) {
      map['paid_by_member_id'] = Variable<String>(paidByMemberId);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || receiptPath != null) {
      map['receipt_path'] = Variable<String>(receiptPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BazarsCompanion toCompanion(bool nullToAbsent) {
    return BazarsCompanion(
      id: Value(id),
      messId: Value(messId),
      date: Value(date),
      amount: Value(amount),
      buyerMemberId: buyerMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(buyerMemberId),
      paidByMemberId: paidByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidByMemberId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      source: Value(source),
      receiptPath: receiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalBazar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalBazar(
      id: serializer.fromJson<String>(json['id']),
      messId: serializer.fromJson<String>(json['messId']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      buyerMemberId: serializer.fromJson<String?>(json['buyerMemberId']),
      paidByMemberId: serializer.fromJson<String?>(json['paidByMemberId']),
      note: serializer.fromJson<String?>(json['note']),
      source: serializer.fromJson<String>(json['source']),
      receiptPath: serializer.fromJson<String?>(json['receiptPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messId': serializer.toJson<String>(messId),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<double>(amount),
      'buyerMemberId': serializer.toJson<String?>(buyerMemberId),
      'paidByMemberId': serializer.toJson<String?>(paidByMemberId),
      'note': serializer.toJson<String?>(note),
      'source': serializer.toJson<String>(source),
      'receiptPath': serializer.toJson<String?>(receiptPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalBazar copyWith({
    String? id,
    String? messId,
    String? date,
    double? amount,
    Value<String?> buyerMemberId = const Value.absent(),
    Value<String?> paidByMemberId = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? source,
    Value<String?> receiptPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalBazar(
    id: id ?? this.id,
    messId: messId ?? this.messId,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    buyerMemberId: buyerMemberId.present
        ? buyerMemberId.value
        : this.buyerMemberId,
    paidByMemberId: paidByMemberId.present
        ? paidByMemberId.value
        : this.paidByMemberId,
    note: note.present ? note.value : this.note,
    source: source ?? this.source,
    receiptPath: receiptPath.present ? receiptPath.value : this.receiptPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalBazar copyWithCompanion(BazarsCompanion data) {
    return LocalBazar(
      id: data.id.present ? data.id.value : this.id,
      messId: data.messId.present ? data.messId.value : this.messId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      buyerMemberId: data.buyerMemberId.present
          ? data.buyerMemberId.value
          : this.buyerMemberId,
      paidByMemberId: data.paidByMemberId.present
          ? data.paidByMemberId.value
          : this.paidByMemberId,
      note: data.note.present ? data.note.value : this.note,
      source: data.source.present ? data.source.value : this.source,
      receiptPath: data.receiptPath.present
          ? data.receiptPath.value
          : this.receiptPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalBazar(')
          ..write('id: $id, ')
          ..write('messId: $messId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('buyerMemberId: $buyerMemberId, ')
          ..write('paidByMemberId: $paidByMemberId, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    messId,
    date,
    amount,
    buyerMemberId,
    paidByMemberId,
    note,
    source,
    receiptPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalBazar &&
          other.id == this.id &&
          other.messId == this.messId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.buyerMemberId == this.buyerMemberId &&
          other.paidByMemberId == this.paidByMemberId &&
          other.note == this.note &&
          other.source == this.source &&
          other.receiptPath == this.receiptPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BazarsCompanion extends UpdateCompanion<LocalBazar> {
  final Value<String> id;
  final Value<String> messId;
  final Value<String> date;
  final Value<double> amount;
  final Value<String?> buyerMemberId;
  final Value<String?> paidByMemberId;
  final Value<String?> note;
  final Value<String> source;
  final Value<String?> receiptPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BazarsCompanion({
    this.id = const Value.absent(),
    this.messId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.buyerMemberId = const Value.absent(),
    this.paidByMemberId = const Value.absent(),
    this.note = const Value.absent(),
    this.source = const Value.absent(),
    this.receiptPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BazarsCompanion.insert({
    required String id,
    required String messId,
    required String date,
    required double amount,
    this.buyerMemberId = const Value.absent(),
    this.paidByMemberId = const Value.absent(),
    this.note = const Value.absent(),
    required String source,
    this.receiptPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messId = Value(messId),
       date = Value(date),
       amount = Value(amount),
       source = Value(source),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalBazar> custom({
    Expression<String>? id,
    Expression<String>? messId,
    Expression<String>? date,
    Expression<double>? amount,
    Expression<String>? buyerMemberId,
    Expression<String>? paidByMemberId,
    Expression<String>? note,
    Expression<String>? source,
    Expression<String>? receiptPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messId != null) 'mess_id': messId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (buyerMemberId != null) 'buyer_member_id': buyerMemberId,
      if (paidByMemberId != null) 'paid_by_member_id': paidByMemberId,
      if (note != null) 'note': note,
      if (source != null) 'source': source,
      if (receiptPath != null) 'receipt_path': receiptPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BazarsCompanion copyWith({
    Value<String>? id,
    Value<String>? messId,
    Value<String>? date,
    Value<double>? amount,
    Value<String?>? buyerMemberId,
    Value<String?>? paidByMemberId,
    Value<String?>? note,
    Value<String>? source,
    Value<String?>? receiptPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BazarsCompanion(
      id: id ?? this.id,
      messId: messId ?? this.messId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      buyerMemberId: buyerMemberId ?? this.buyerMemberId,
      paidByMemberId: paidByMemberId ?? this.paidByMemberId,
      note: note ?? this.note,
      source: source ?? this.source,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messId.present) {
      map['mess_id'] = Variable<String>(messId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (buyerMemberId.present) {
      map['buyer_member_id'] = Variable<String>(buyerMemberId.value);
    }
    if (paidByMemberId.present) {
      map['paid_by_member_id'] = Variable<String>(paidByMemberId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (receiptPath.present) {
      map['receipt_path'] = Variable<String>(receiptPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BazarsCompanion(')
          ..write('id: $id, ')
          ..write('messId: $messId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('buyerMemberId: $buyerMemberId, ')
          ..write('paidByMemberId: $paidByMemberId, ')
          ..write('note: $note, ')
          ..write('source: $source, ')
          ..write('receiptPath: $receiptPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BazarItemsTable extends BazarItems
    with TableInfo<$BazarItemsTable, LocalBazarItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BazarItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bazarIdMeta = const VerificationMeta(
    'bazarId',
  );
  @override
  late final GeneratedColumn<String> bazarId = GeneratedColumn<String>(
    'bazar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bazarId,
    name,
    price,
    qty,
    unit,
    sort,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bazar_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalBazarItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bazar_id')) {
      context.handle(
        _bazarIdMeta,
        bazarId.isAcceptableOrUnknown(data['bazar_id']!, _bazarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bazarIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    } else if (isInserting) {
      context.missing(_sortMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalBazarItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalBazarItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bazarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bazar_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
    );
  }

  @override
  $BazarItemsTable createAlias(String alias) {
    return $BazarItemsTable(attachedDatabase, alias);
  }
}

class LocalBazarItem extends DataClass implements Insertable<LocalBazarItem> {
  final String id;
  final String bazarId;
  final String name;
  final double price;
  final double? qty;
  final String? unit;
  final int sort;
  const LocalBazarItem({
    required this.id,
    required this.bazarId,
    required this.name,
    required this.price,
    this.qty,
    this.unit,
    required this.sort,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bazar_id'] = Variable<String>(bazarId);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || qty != null) {
      map['qty'] = Variable<double>(qty);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['sort'] = Variable<int>(sort);
    return map;
  }

  BazarItemsCompanion toCompanion(bool nullToAbsent) {
    return BazarItemsCompanion(
      id: Value(id),
      bazarId: Value(bazarId),
      name: Value(name),
      price: Value(price),
      qty: qty == null && nullToAbsent ? const Value.absent() : Value(qty),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      sort: Value(sort),
    );
  }

  factory LocalBazarItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalBazarItem(
      id: serializer.fromJson<String>(json['id']),
      bazarId: serializer.fromJson<String>(json['bazarId']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<double>(json['price']),
      qty: serializer.fromJson<double?>(json['qty']),
      unit: serializer.fromJson<String?>(json['unit']),
      sort: serializer.fromJson<int>(json['sort']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bazarId': serializer.toJson<String>(bazarId),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<double>(price),
      'qty': serializer.toJson<double?>(qty),
      'unit': serializer.toJson<String?>(unit),
      'sort': serializer.toJson<int>(sort),
    };
  }

  LocalBazarItem copyWith({
    String? id,
    String? bazarId,
    String? name,
    double? price,
    Value<double?> qty = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? sort,
  }) => LocalBazarItem(
    id: id ?? this.id,
    bazarId: bazarId ?? this.bazarId,
    name: name ?? this.name,
    price: price ?? this.price,
    qty: qty.present ? qty.value : this.qty,
    unit: unit.present ? unit.value : this.unit,
    sort: sort ?? this.sort,
  );
  LocalBazarItem copyWithCompanion(BazarItemsCompanion data) {
    return LocalBazarItem(
      id: data.id.present ? data.id.value : this.id,
      bazarId: data.bazarId.present ? data.bazarId.value : this.bazarId,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      qty: data.qty.present ? data.qty.value : this.qty,
      unit: data.unit.present ? data.unit.value : this.unit,
      sort: data.sort.present ? data.sort.value : this.sort,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalBazarItem(')
          ..write('id: $id, ')
          ..write('bazarId: $bazarId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('sort: $sort')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bazarId, name, price, qty, unit, sort);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalBazarItem &&
          other.id == this.id &&
          other.bazarId == this.bazarId &&
          other.name == this.name &&
          other.price == this.price &&
          other.qty == this.qty &&
          other.unit == this.unit &&
          other.sort == this.sort);
}

class BazarItemsCompanion extends UpdateCompanion<LocalBazarItem> {
  final Value<String> id;
  final Value<String> bazarId;
  final Value<String> name;
  final Value<double> price;
  final Value<double?> qty;
  final Value<String?> unit;
  final Value<int> sort;
  final Value<int> rowid;
  const BazarItemsCompanion({
    this.id = const Value.absent(),
    this.bazarId = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.sort = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BazarItemsCompanion.insert({
    required String id,
    required String bazarId,
    required String name,
    required double price,
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    required int sort,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bazarId = Value(bazarId),
       name = Value(name),
       price = Value(price),
       sort = Value(sort);
  static Insertable<LocalBazarItem> custom({
    Expression<String>? id,
    Expression<String>? bazarId,
    Expression<String>? name,
    Expression<double>? price,
    Expression<double>? qty,
    Expression<String>? unit,
    Expression<int>? sort,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bazarId != null) 'bazar_id': bazarId,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (qty != null) 'qty': qty,
      if (unit != null) 'unit': unit,
      if (sort != null) 'sort': sort,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BazarItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? bazarId,
    Value<String>? name,
    Value<double>? price,
    Value<double?>? qty,
    Value<String?>? unit,
    Value<int>? sort,
    Value<int>? rowid,
  }) {
    return BazarItemsCompanion(
      id: id ?? this.id,
      bazarId: bazarId ?? this.bazarId,
      name: name ?? this.name,
      price: price ?? this.price,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      sort: sort ?? this.sort,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bazarId.present) {
      map['bazar_id'] = Variable<String>(bazarId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BazarItemsCompanion(')
          ..write('id: $id, ')
          ..write('bazarId: $bazarId, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('sort: $sort, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JsonCacheTable extends JsonCache
    with TableInfo<$JsonCacheTable, JsonCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JsonCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'json_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<JsonCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  JsonCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JsonCacheData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $JsonCacheTable createAlias(String alias) {
    return $JsonCacheTable(attachedDatabase, alias);
  }
}

class JsonCacheData extends DataClass implements Insertable<JsonCacheData> {
  final String key;
  final String json;
  const JsonCacheData({required this.key, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['json'] = Variable<String>(json);
    return map;
  }

  JsonCacheCompanion toCompanion(bool nullToAbsent) {
    return JsonCacheCompanion(key: Value(key), json: Value(json));
  }

  factory JsonCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JsonCacheData(
      key: serializer.fromJson<String>(json['key']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'json': serializer.toJson<String>(json),
    };
  }

  JsonCacheData copyWith({String? key, String? json}) =>
      JsonCacheData(key: key ?? this.key, json: json ?? this.json);
  JsonCacheData copyWithCompanion(JsonCacheCompanion data) {
    return JsonCacheData(
      key: data.key.present ? data.key.value : this.key,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JsonCacheData(')
          ..write('key: $key, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JsonCacheData &&
          other.key == this.key &&
          other.json == this.json);
}

class JsonCacheCompanion extends UpdateCompanion<JsonCacheData> {
  final Value<String> key;
  final Value<String> json;
  final Value<int> rowid;
  const JsonCacheCompanion({
    this.key = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JsonCacheCompanion.insert({
    required String key,
    required String json,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       json = Value(json);
  static Insertable<JsonCacheData> custom({
    Expression<String>? key,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JsonCacheCompanion copyWith({
    Value<String>? key,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return JsonCacheCompanion(
      key: key ?? this.key,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JsonCacheCompanion(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowKeyMeta = const VerificationMeta('rowKey');
  @override
  late final GeneratedColumn<String> rowKey = GeneratedColumn<String>(
    'row_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('upsert'),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(opPending),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entity,
    rowKey,
    op,
    payload,
    attempts,
    status,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('row_key')) {
      context.handle(
        _rowKeyMeta,
        rowKey.isAcceptableOrUnknown(data['row_key']!, _rowKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_rowKeyMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
  SyncOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      rowKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_key'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncOp extends DataClass implements Insertable<SyncOp> {
  final String id;
  final String entity;
  final String rowKey;
  final String op;
  final String payload;
  final int attempts;

  /// [opPending], [opSyncing] or [opFailed].
  final String status;

  /// A [FailureKind] name.
  final String? lastError;
  final DateTime createdAt;
  const SyncOp({
    required this.id,
    required this.entity,
    required this.rowKey,
    required this.op,
    required this.payload,
    required this.attempts,
    required this.status,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity'] = Variable<String>(entity);
    map['row_key'] = Variable<String>(rowKey);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entity: Value(entity),
      rowKey: Value(rowKey),
      op: Value(op),
      payload: Value(payload),
      attempts: Value(attempts),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory SyncOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOp(
      id: serializer.fromJson<String>(json['id']),
      entity: serializer.fromJson<String>(json['entity']),
      rowKey: serializer.fromJson<String>(json['rowKey']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entity': serializer.toJson<String>(entity),
      'rowKey': serializer.toJson<String>(rowKey),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncOp copyWith({
    String? id,
    String? entity,
    String? rowKey,
    String? op,
    String? payload,
    int? attempts,
    String? status,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => SyncOp(
    id: id ?? this.id,
    entity: entity ?? this.entity,
    rowKey: rowKey ?? this.rowKey,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncOp copyWithCompanion(SyncQueueCompanion data) {
    return SyncOp(
      id: data.id.present ? data.id.value : this.id,
      entity: data.entity.present ? data.entity.value : this.entity,
      rowKey: data.rowKey.present ? data.rowKey.value : this.rowKey,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOp(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('rowKey: $rowKey, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entity,
    rowKey,
    op,
    payload,
    attempts,
    status,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOp &&
          other.id == this.id &&
          other.entity == this.entity &&
          other.rowKey == this.rowKey &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.attempts == this.attempts &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncOp> {
  final Value<String> id;
  final Value<String> entity;
  final Value<String> rowKey;
  final Value<String> op;
  final Value<String> payload;
  final Value<int> attempts;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entity = const Value.absent(),
    this.rowKey = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entity,
    required String rowKey,
    this.op = const Value.absent(),
    required String payload,
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entity = Value(entity),
       rowKey = Value(rowKey),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncOp> custom({
    Expression<String>? id,
    Expression<String>? entity,
    Expression<String>? rowKey,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? attempts,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entity != null) 'entity': entity,
      if (rowKey != null) 'row_key': rowKey,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entity,
    Value<String>? rowKey,
    Value<String>? op,
    Value<String>? payload,
    Value<int>? attempts,
    Value<String>? status,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      rowKey: rowKey ?? this.rowKey,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (rowKey.present) {
      map['row_key'] = Variable<String>(rowKey.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entity: $entity, ')
          ..write('rowKey: $rowKey, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  late final $MealEntriesTable mealEntries = $MealEntriesTable(this);
  late final $BazarsTable bazars = $BazarsTable(this);
  late final $BazarItemsTable bazarItems = $BazarItemsTable(this);
  late final $JsonCacheTable jsonCache = $JsonCacheTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    mealEntries,
    bazars,
    bazarItems,
    jsonCache,
    syncQueue,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
