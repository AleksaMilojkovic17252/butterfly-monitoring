// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SkeletonPingsTable extends SkeletonPings
    with TableInfo<$SkeletonPingsTable, SkeletonPing> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkeletonPingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<DateTime> observedAt = GeneratedColumn<DateTime>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    observedAt,
    lat,
    lon,
    note,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skeleton_ping';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkeletonPing> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SkeletonPing map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkeletonPing(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}observed_at'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      ),
    );
  }

  @override
  $SkeletonPingsTable createAlias(String alias) {
    return $SkeletonPingsTable(attachedDatabase, alias);
  }
}

class SkeletonPing extends DataClass implements Insertable<SkeletonPing> {
  final String id;
  final DateTime observedAt;
  final double lat;
  final double lon;
  final String note;
  final DateTime? sentAt;
  const SkeletonPing({
    required this.id,
    required this.observedAt,
    required this.lat,
    required this.lon,
    required this.note,
    this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['observed_at'] = Variable<DateTime>(observedAt);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<DateTime>(sentAt);
    }
    return map;
  }

  SkeletonPingsCompanion toCompanion(bool nullToAbsent) {
    return SkeletonPingsCompanion(
      id: Value(id),
      observedAt: Value(observedAt),
      lat: Value(lat),
      lon: Value(lon),
      note: Value(note),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
    );
  }

  factory SkeletonPing.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkeletonPing(
      id: serializer.fromJson<String>(json['id']),
      observedAt: serializer.fromJson<DateTime>(json['observedAt']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      note: serializer.fromJson<String>(json['note']),
      sentAt: serializer.fromJson<DateTime?>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'observedAt': serializer.toJson<DateTime>(observedAt),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'note': serializer.toJson<String>(note),
      'sentAt': serializer.toJson<DateTime?>(sentAt),
    };
  }

  SkeletonPing copyWith({
    String? id,
    DateTime? observedAt,
    double? lat,
    double? lon,
    String? note,
    Value<DateTime?> sentAt = const Value.absent(),
  }) => SkeletonPing(
    id: id ?? this.id,
    observedAt: observedAt ?? this.observedAt,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    note: note ?? this.note,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
  );
  SkeletonPing copyWithCompanion(SkeletonPingsCompanion data) {
    return SkeletonPing(
      id: data.id.present ? data.id.value : this.id,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      note: data.note.present ? data.note.value : this.note,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkeletonPing(')
          ..write('id: $id, ')
          ..write('observedAt: $observedAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('note: $note, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, observedAt, lat, lon, note, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkeletonPing &&
          other.id == this.id &&
          other.observedAt == this.observedAt &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.note == this.note &&
          other.sentAt == this.sentAt);
}

class SkeletonPingsCompanion extends UpdateCompanion<SkeletonPing> {
  final Value<String> id;
  final Value<DateTime> observedAt;
  final Value<double> lat;
  final Value<double> lon;
  final Value<String> note;
  final Value<DateTime?> sentAt;
  final Value<int> rowid;
  const SkeletonPingsCompanion({
    this.id = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.note = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkeletonPingsCompanion.insert({
    required String id,
    required DateTime observedAt,
    required double lat,
    required double lon,
    this.note = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       observedAt = Value(observedAt),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<SkeletonPing> custom({
    Expression<String>? id,
    Expression<DateTime>? observedAt,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? note,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (observedAt != null) 'observed_at': observedAt,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (note != null) 'note': note,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkeletonPingsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? observedAt,
    Value<double>? lat,
    Value<double>? lon,
    Value<String>? note,
    Value<DateTime?>? sentAt,
    Value<int>? rowid,
  }) {
    return SkeletonPingsCompanion(
      id: id ?? this.id,
      observedAt: observedAt ?? this.observedAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      note: note ?? this.note,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<DateTime>(observedAt.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkeletonPingsCompanion(')
          ..write('id: $id, ')
          ..write('observedAt: $observedAt, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('note: $note, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SkeletonPingsTable skeletonPings = $SkeletonPingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [skeletonPings];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SkeletonPingsTableCreateCompanionBuilder =
    SkeletonPingsCompanion Function({
      required String id,
      required DateTime observedAt,
      required double lat,
      required double lon,
      Value<String> note,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });
typedef $$SkeletonPingsTableUpdateCompanionBuilder =
    SkeletonPingsCompanion Function({
      Value<String> id,
      Value<DateTime> observedAt,
      Value<double> lat,
      Value<double> lon,
      Value<String> note,
      Value<DateTime?> sentAt,
      Value<int> rowid,
    });

class $$SkeletonPingsTableFilterComposer
    extends Composer<_$AppDatabase, $SkeletonPingsTable> {
  $$SkeletonPingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SkeletonPingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SkeletonPingsTable> {
  $$SkeletonPingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SkeletonPingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkeletonPingsTable> {
  $$SkeletonPingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$SkeletonPingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkeletonPingsTable,
          SkeletonPing,
          $$SkeletonPingsTableFilterComposer,
          $$SkeletonPingsTableOrderingComposer,
          $$SkeletonPingsTableAnnotationComposer,
          $$SkeletonPingsTableCreateCompanionBuilder,
          $$SkeletonPingsTableUpdateCompanionBuilder,
          (
            SkeletonPing,
            BaseReferences<_$AppDatabase, $SkeletonPingsTable, SkeletonPing>,
          ),
          SkeletonPing,
          PrefetchHooks Function()
        > {
  $$SkeletonPingsTableTableManager(_$AppDatabase db, $SkeletonPingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkeletonPingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkeletonPingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkeletonPingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> observedAt = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkeletonPingsCompanion(
                id: id,
                observedAt: observedAt,
                lat: lat,
                lon: lon,
                note: note,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime observedAt,
                required double lat,
                required double lon,
                Value<String> note = const Value.absent(),
                Value<DateTime?> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkeletonPingsCompanion.insert(
                id: id,
                observedAt: observedAt,
                lat: lat,
                lon: lon,
                note: note,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SkeletonPingsTable, SkeletonPing>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SkeletonPingsTable,
                    SkeletonPing
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SkeletonPingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkeletonPingsTable,
      SkeletonPing,
      $$SkeletonPingsTableFilterComposer,
      $$SkeletonPingsTableOrderingComposer,
      $$SkeletonPingsTableAnnotationComposer,
      $$SkeletonPingsTableCreateCompanionBuilder,
      $$SkeletonPingsTableUpdateCompanionBuilder,
      (
        SkeletonPing,
        BaseReferences<_$AppDatabase, $SkeletonPingsTable, SkeletonPing>,
      ),
      SkeletonPing,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SkeletonPingsTableTableManager get skeletonPings =>
      $$SkeletonPingsTableTableManager(_db, _db.skeletonPings);
}
