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

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultCrsMeta = const VerificationMeta(
    'defaultCrs',
  );
  @override
  late final GeneratedColumn<int> defaultCrs = GeneratedColumn<int>(
    'default_crs',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4326),
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
  static const VerificationMeta _taxonListVersionIdMeta =
      const VerificationMeta('taxonListVersionId');
  @override
  late final GeneratedColumn<String> taxonListVersionId =
      GeneratedColumn<String>(
        'taxon_list_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    startDate,
    endDate,
    defaultCrs,
    active,
    taxonListVersionId,
    area,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
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
    if (data.containsKey('default_crs')) {
      context.handle(
        _defaultCrsMeta,
        defaultCrs.isAcceptableOrUnknown(data['default_crs']!, _defaultCrsMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('taxon_list_version_id')) {
      context.handle(
        _taxonListVersionIdMeta,
        taxonListVersionId.isAcceptableOrUnknown(
          data['taxon_list_version_id']!,
          _taxonListVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      defaultCrs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_crs'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      taxonListVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_list_version_id'],
      ),
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final int defaultCrs;
  final bool active;
  final String? taxonListVersionId;

  /// Study area as a GeoJSON MultiPolygon, or null.
  final String? area;
  final int? serverVersion;
  final DateTime? deletedAt;
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.defaultCrs,
    required this.active,
    this.taxonListVersionId,
    this.area,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['default_crs'] = Variable<int>(defaultCrs);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || taxonListVersionId != null) {
      map['taxon_list_version_id'] = Variable<String>(taxonListVersionId);
    }
    if (!nullToAbsent || area != null) {
      map['area'] = Variable<String>(area);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      defaultCrs: Value(defaultCrs),
      active: Value(active),
      taxonListVersionId: taxonListVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(taxonListVersionId),
      area: area == null && nullToAbsent ? const Value.absent() : Value(area),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      defaultCrs: serializer.fromJson<int>(json['defaultCrs']),
      active: serializer.fromJson<bool>(json['active']),
      taxonListVersionId: serializer.fromJson<String?>(
        json['taxonListVersionId'],
      ),
      area: serializer.fromJson<String?>(json['area']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'defaultCrs': serializer.toJson<int>(defaultCrs),
      'active': serializer.toJson<bool>(active),
      'taxonListVersionId': serializer.toJson<String?>(taxonListVersionId),
      'area': serializer.toJson<String?>(area),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    int? defaultCrs,
    bool? active,
    Value<String?> taxonListVersionId = const Value.absent(),
    Value<String?> area = const Value.absent(),
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    defaultCrs: defaultCrs ?? this.defaultCrs,
    active: active ?? this.active,
    taxonListVersionId: taxonListVersionId.present
        ? taxonListVersionId.value
        : this.taxonListVersionId,
    area: area.present ? area.value : this.area,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      defaultCrs: data.defaultCrs.present
          ? data.defaultCrs.value
          : this.defaultCrs,
      active: data.active.present ? data.active.value : this.active,
      taxonListVersionId: data.taxonListVersionId.present
          ? data.taxonListVersionId.value
          : this.taxonListVersionId,
      area: data.area.present ? data.area.value : this.area,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('defaultCrs: $defaultCrs, ')
          ..write('active: $active, ')
          ..write('taxonListVersionId: $taxonListVersionId, ')
          ..write('area: $area, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    startDate,
    endDate,
    defaultCrs,
    active,
    taxonListVersionId,
    area,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.defaultCrs == this.defaultCrs &&
          other.active == this.active &&
          other.taxonListVersionId == this.taxonListVersionId &&
          other.area == this.area &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<int> defaultCrs;
  final Value<bool> active;
  final Value<String?> taxonListVersionId;
  final Value<String?> area;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.defaultCrs = const Value.absent(),
    this.active = const Value.absent(),
    this.taxonListVersionId = const Value.absent(),
    this.area = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.defaultCrs = const Value.absent(),
    this.active = const Value.absent(),
    this.taxonListVersionId = const Value.absent(),
    this.area = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? defaultCrs,
    Expression<bool>? active,
    Expression<String>? taxonListVersionId,
    Expression<String>? area,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (defaultCrs != null) 'default_crs': defaultCrs,
      if (active != null) 'active': active,
      if (taxonListVersionId != null)
        'taxon_list_version_id': taxonListVersionId,
      if (area != null) 'area': area,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<int>? defaultCrs,
    Value<bool>? active,
    Value<String?>? taxonListVersionId,
    Value<String?>? area,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      defaultCrs: defaultCrs ?? this.defaultCrs,
      active: active ?? this.active,
      taxonListVersionId: taxonListVersionId ?? this.taxonListVersionId,
      area: area ?? this.area,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (defaultCrs.present) {
      map['default_crs'] = Variable<int>(defaultCrs.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (taxonListVersionId.present) {
      map['taxon_list_version_id'] = Variable<String>(taxonListVersionId.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('defaultCrs: $defaultCrs, ')
          ..write('active: $active, ')
          ..write('taxonListVersionId: $taxonListVersionId, ')
          ..write('area: $area, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
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
  @override
  late final GeneratedColumnWithTypeConverter<QueueStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<QueueStatus>($SyncQueueTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    mutationId,
    projectId,
    entityType,
    entityId,
    operation,
    baseVersion,
    payload,
    createdAt,
    retryCount,
    nextAttemptAt,
    lastError,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  SyncQueueItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueItem(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      status: $SyncQueueTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<QueueStatus, String, String> $converterstatus =
      const EnumNameConverter<QueueStatus>(QueueStatus.values);
}

class SyncQueueItem extends DataClass implements Insertable<SyncQueueItem> {
  final int seq;

  /// UUID v4; lets the server recognise a resend.
  final String mutationId;
  final String projectId;

  /// Server entity type, which is also the local table name.
  final String entityType;
  final String entityId;

  /// `create`, `update`, `delete` or `create_batch`.
  final String operation;
  final int? baseVersion;

  /// JSON, with the server's field names.
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final QueueStatus status;
  const SyncQueueItem({
    required this.seq,
    required this.mutationId,
    required this.projectId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.baseVersion,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.nextAttemptAt,
    this.lastError,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['mutation_id'] = Variable<String>(mutationId);
    map['project_id'] = Variable<String>(projectId);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    {
      map['status'] = Variable<String>(
        $SyncQueueTable.$converterstatus.toSql(status),
      );
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      seq: Value(seq),
      mutationId: Value(mutationId),
      projectId: Value(projectId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      status: Value(status),
    );
  }

  factory SyncQueueItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueItem(
      seq: serializer.fromJson<int>(json['seq']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      status: $SyncQueueTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'mutationId': serializer.toJson<String>(mutationId),
      'projectId': serializer.toJson<String>(projectId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'status': serializer.toJson<String>(
        $SyncQueueTable.$converterstatus.toJson(status),
      ),
    };
  }

  SyncQueueItem copyWith({
    int? seq,
    String? mutationId,
    String? projectId,
    String? entityType,
    String? entityId,
    String? operation,
    Value<int?> baseVersion = const Value.absent(),
    String? payload,
    DateTime? createdAt,
    int? retryCount,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    QueueStatus? status,
  }) => SyncQueueItem(
    seq: seq ?? this.seq,
    mutationId: mutationId ?? this.mutationId,
    projectId: projectId ?? this.projectId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    status: status ?? this.status,
  );
  SyncQueueItem copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueItem(
      seq: data.seq.present ? data.seq.value : this.seq,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueItem(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('projectId: $projectId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    mutationId,
    projectId,
    entityType,
    entityId,
    operation,
    baseVersion,
    payload,
    createdAt,
    retryCount,
    nextAttemptAt,
    lastError,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueItem &&
          other.seq == this.seq &&
          other.mutationId == this.mutationId &&
          other.projectId == this.projectId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.baseVersion == this.baseVersion &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.status == this.status);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueItem> {
  final Value<int> seq;
  final Value<String> mutationId;
  final Value<String> projectId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<int?> baseVersion;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<QueueStatus> status;
  const SyncQueueCompanion({
    this.seq = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.seq = const Value.absent(),
    required String mutationId,
    required String projectId,
    required String entityType,
    required String entityId,
    required String operation,
    this.baseVersion = const Value.absent(),
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required QueueStatus status,
  }) : mutationId = Value(mutationId),
       projectId = Value(projectId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payload = Value(payload),
       createdAt = Value(createdAt),
       status = Value(status);
  static Insertable<SyncQueueItem> custom({
    Expression<int>? seq,
    Expression<String>? mutationId,
    Expression<String>? projectId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<int>? baseVersion,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (mutationId != null) 'mutation_id': mutationId,
      if (projectId != null) 'project_id': projectId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (baseVersion != null) 'base_version': baseVersion,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (status != null) 'status': status,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? seq,
    Value<String>? mutationId,
    Value<String>? projectId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<int?>? baseVersion,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<QueueStatus>? status,
  }) {
    return SyncQueueCompanion(
      seq: seq ?? this.seq,
      mutationId: mutationId ?? this.mutationId,
      projectId: projectId ?? this.projectId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      baseVersion: baseVersion ?? this.baseVersion,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SyncQueueTable.$converterstatus.toSql(status.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('seq: $seq, ')
          ..write('mutationId: $mutationId, ')
          ..write('projectId: $projectId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncStateEntriesTable extends SyncStateEntries
    with TableInfo<$SyncStateEntriesTable, SyncStateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateEntry> instance, {
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
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateEntriesTable createAlias(String alias) {
    return $SyncStateEntriesTable(attachedDatabase, alias);
  }
}

class SyncStateEntry extends DataClass implements Insertable<SyncStateEntry> {
  final String key;
  final String value;
  const SyncStateEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncStateEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateEntry copyWith({String? key, String? value}) =>
      SyncStateEntry(key: key ?? this.key, value: value ?? this.value);
  SyncStateEntry copyWithCompanion(SyncStateEntriesCompanion data) {
    return SyncStateEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateEntriesCompanion extends UpdateCompanion<SyncStateEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitatTypesTable extends HabitatTypes
    with TableInfo<$HabitatTypesTable, HabitatType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitatTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameSrMeta = const VerificationMeta('nameSr');
  @override
  late final GeneratedColumn<String> nameSr = GeneratedColumn<String>(
    'name_sr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _eunisCodeMeta = const VerificationMeta(
    'eunisCode',
  );
  @override
  late final GeneratedColumn<String> eunisCode = GeneratedColumn<String>(
    'eunis_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    nameEn,
    nameSr,
    description,
    sortOrder,
    active,
    eunisCode,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habitat_type';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitatType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_sr')) {
      context.handle(
        _nameSrMeta,
        nameSr.isAcceptableOrUnknown(data['name_sr']!, _nameSrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameSrMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('eunis_code')) {
      context.handle(
        _eunisCodeMeta,
        eunisCode.isAcceptableOrUnknown(data['eunis_code']!, _eunisCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_eunisCodeMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitatType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitatType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameSr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_sr'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      eunisCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}eunis_code'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $HabitatTypesTable createAlias(String alias) {
    return $HabitatTypesTable(attachedDatabase, alias);
  }
}

class HabitatType extends DataClass implements Insertable<HabitatType> {
  final String id;
  final String code;
  final String nameEn;
  final String nameSr;
  final String description;
  final int sortOrder;
  final bool active;
  final String eunisCode;
  final int? serverVersion;
  final DateTime? deletedAt;
  const HabitatType({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameSr,
    required this.description,
    required this.sortOrder,
    required this.active,
    required this.eunisCode,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name_en'] = Variable<String>(nameEn);
    map['name_sr'] = Variable<String>(nameSr);
    map['description'] = Variable<String>(description);
    map['sort_order'] = Variable<int>(sortOrder);
    map['active'] = Variable<bool>(active);
    map['eunis_code'] = Variable<String>(eunisCode);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  HabitatTypesCompanion toCompanion(bool nullToAbsent) {
    return HabitatTypesCompanion(
      id: Value(id),
      code: Value(code),
      nameEn: Value(nameEn),
      nameSr: Value(nameSr),
      description: Value(description),
      sortOrder: Value(sortOrder),
      active: Value(active),
      eunisCode: Value(eunisCode),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory HabitatType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitatType(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameSr: serializer.fromJson<String>(json['nameSr']),
      description: serializer.fromJson<String>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      active: serializer.fromJson<bool>(json['active']),
      eunisCode: serializer.fromJson<String>(json['eunisCode']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameSr': serializer.toJson<String>(nameSr),
      'description': serializer.toJson<String>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'active': serializer.toJson<bool>(active),
      'eunisCode': serializer.toJson<String>(eunisCode),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  HabitatType copyWith({
    String? id,
    String? code,
    String? nameEn,
    String? nameSr,
    String? description,
    int? sortOrder,
    bool? active,
    String? eunisCode,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => HabitatType(
    id: id ?? this.id,
    code: code ?? this.code,
    nameEn: nameEn ?? this.nameEn,
    nameSr: nameSr ?? this.nameSr,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    active: active ?? this.active,
    eunisCode: eunisCode ?? this.eunisCode,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  HabitatType copyWithCompanion(HabitatTypesCompanion data) {
    return HabitatType(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameSr: data.nameSr.present ? data.nameSr.value : this.nameSr,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      active: data.active.present ? data.active.value : this.active,
      eunisCode: data.eunisCode.present ? data.eunisCode.value : this.eunisCode,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitatType(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSr: $nameSr, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('eunisCode: $eunisCode, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    nameEn,
    nameSr,
    description,
    sortOrder,
    active,
    eunisCode,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitatType &&
          other.id == this.id &&
          other.code == this.code &&
          other.nameEn == this.nameEn &&
          other.nameSr == this.nameSr &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder &&
          other.active == this.active &&
          other.eunisCode == this.eunisCode &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class HabitatTypesCompanion extends UpdateCompanion<HabitatType> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> nameEn;
  final Value<String> nameSr;
  final Value<String> description;
  final Value<int> sortOrder;
  final Value<bool> active;
  final Value<String> eunisCode;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const HabitatTypesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameSr = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
    this.eunisCode = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitatTypesCompanion.insert({
    required String id,
    required String code,
    required String nameEn,
    required String nameSr,
    required String description,
    required int sortOrder,
    required bool active,
    required String eunisCode,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       nameEn = Value(nameEn),
       nameSr = Value(nameSr),
       description = Value(description),
       sortOrder = Value(sortOrder),
       active = Value(active),
       eunisCode = Value(eunisCode);
  static Insertable<HabitatType> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? nameEn,
    Expression<String>? nameSr,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<bool>? active,
    Expression<String>? eunisCode,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (nameEn != null) 'name_en': nameEn,
      if (nameSr != null) 'name_sr': nameSr,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (active != null) 'active': active,
      if (eunisCode != null) 'eunis_code': eunisCode,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitatTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? nameEn,
    Value<String>? nameSr,
    Value<String>? description,
    Value<int>? sortOrder,
    Value<bool>? active,
    Value<String>? eunisCode,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return HabitatTypesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      nameEn: nameEn ?? this.nameEn,
      nameSr: nameSr ?? this.nameSr,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      eunisCode: eunisCode ?? this.eunisCode,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameSr.present) {
      map['name_sr'] = Variable<String>(nameSr.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (eunisCode.present) {
      map['eunis_code'] = Variable<String>(eunisCode.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitatTypesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSr: $nameSr, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('eunisCode: $eunisCode, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ManagementTypesTable extends ManagementTypes
    with TableInfo<$ManagementTypesTable, ManagementType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManagementTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameSrMeta = const VerificationMeta('nameSr');
  @override
  late final GeneratedColumn<String> nameSr = GeneratedColumn<String>(
    'name_sr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    nameEn,
    nameSr,
    description,
    sortOrder,
    active,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'management_type';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManagementType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('name_sr')) {
      context.handle(
        _nameSrMeta,
        nameSr.isAcceptableOrUnknown(data['name_sr']!, _nameSrMeta),
      );
    } else if (isInserting) {
      context.missing(_nameSrMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManagementType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManagementType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      nameSr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_sr'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ManagementTypesTable createAlias(String alias) {
    return $ManagementTypesTable(attachedDatabase, alias);
  }
}

class ManagementType extends DataClass implements Insertable<ManagementType> {
  final String id;
  final String code;
  final String nameEn;
  final String nameSr;
  final String description;
  final int sortOrder;
  final bool active;
  final int? serverVersion;
  final DateTime? deletedAt;
  const ManagementType({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameSr,
    required this.description,
    required this.sortOrder,
    required this.active,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name_en'] = Variable<String>(nameEn);
    map['name_sr'] = Variable<String>(nameSr);
    map['description'] = Variable<String>(description);
    map['sort_order'] = Variable<int>(sortOrder);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ManagementTypesCompanion toCompanion(bool nullToAbsent) {
    return ManagementTypesCompanion(
      id: Value(id),
      code: Value(code),
      nameEn: Value(nameEn),
      nameSr: Value(nameSr),
      description: Value(description),
      sortOrder: Value(sortOrder),
      active: Value(active),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ManagementType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManagementType(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      nameSr: serializer.fromJson<String>(json['nameSr']),
      description: serializer.fromJson<String>(json['description']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      active: serializer.fromJson<bool>(json['active']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'nameEn': serializer.toJson<String>(nameEn),
      'nameSr': serializer.toJson<String>(nameSr),
      'description': serializer.toJson<String>(description),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'active': serializer.toJson<bool>(active),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ManagementType copyWith({
    String? id,
    String? code,
    String? nameEn,
    String? nameSr,
    String? description,
    int? sortOrder,
    bool? active,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ManagementType(
    id: id ?? this.id,
    code: code ?? this.code,
    nameEn: nameEn ?? this.nameEn,
    nameSr: nameSr ?? this.nameSr,
    description: description ?? this.description,
    sortOrder: sortOrder ?? this.sortOrder,
    active: active ?? this.active,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ManagementType copyWithCompanion(ManagementTypesCompanion data) {
    return ManagementType(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      nameSr: data.nameSr.present ? data.nameSr.value : this.nameSr,
      description: data.description.present
          ? data.description.value
          : this.description,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      active: data.active.present ? data.active.value : this.active,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManagementType(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSr: $nameSr, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    nameEn,
    nameSr,
    description,
    sortOrder,
    active,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManagementType &&
          other.id == this.id &&
          other.code == this.code &&
          other.nameEn == this.nameEn &&
          other.nameSr == this.nameSr &&
          other.description == this.description &&
          other.sortOrder == this.sortOrder &&
          other.active == this.active &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class ManagementTypesCompanion extends UpdateCompanion<ManagementType> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> nameEn;
  final Value<String> nameSr;
  final Value<String> description;
  final Value<int> sortOrder;
  final Value<bool> active;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ManagementTypesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.nameSr = const Value.absent(),
    this.description = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.active = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManagementTypesCompanion.insert({
    required String id,
    required String code,
    required String nameEn,
    required String nameSr,
    required String description,
    required int sortOrder,
    required bool active,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       nameEn = Value(nameEn),
       nameSr = Value(nameSr),
       description = Value(description),
       sortOrder = Value(sortOrder),
       active = Value(active);
  static Insertable<ManagementType> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? nameEn,
    Expression<String>? nameSr,
    Expression<String>? description,
    Expression<int>? sortOrder,
    Expression<bool>? active,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (nameEn != null) 'name_en': nameEn,
      if (nameSr != null) 'name_sr': nameSr,
      if (description != null) 'description': description,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (active != null) 'active': active,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManagementTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? nameEn,
    Value<String>? nameSr,
    Value<String>? description,
    Value<int>? sortOrder,
    Value<bool>? active,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ManagementTypesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      nameEn: nameEn ?? this.nameEn,
      nameSr: nameSr ?? this.nameSr,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (nameSr.present) {
      map['name_sr'] = Variable<String>(nameSr.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManagementTypesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('nameEn: $nameEn, ')
          ..write('nameSr: $nameSr, ')
          ..write('description: $description, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('active: $active, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlantTaxaTable extends PlantTaxa
    with TableInfo<$PlantTaxaTable, PlantTaxon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlantTaxaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scientificNameMeta = const VerificationMeta(
    'scientificName',
  );
  @override
  late final GeneratedColumn<String> scientificName = GeneratedColumn<String>(
    'scientific_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyMeta = const VerificationMeta('family');
  @override
  late final GeneratedColumn<String> family = GeneratedColumn<String>(
    'family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vernacularNameMeta = const VerificationMeta(
    'vernacularName',
  );
  @override
  late final GeneratedColumn<String> vernacularName = GeneratedColumn<String>(
    'vernacular_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vernacularNameEnMeta = const VerificationMeta(
    'vernacularNameEn',
  );
  @override
  late final GeneratedColumn<String> vernacularNameEn = GeneratedColumn<String>(
    'vernacular_name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxonSourceMeta = const VerificationMeta(
    'taxonSource',
  );
  @override
  late final GeneratedColumn<String> taxonSource = GeneratedColumn<String>(
    'taxon_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxonSourceIdMeta = const VerificationMeta(
    'taxonSourceId',
  );
  @override
  late final GeneratedColumn<String> taxonSourceId = GeneratedColumn<String>(
    'taxon_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scientificName,
    family,
    vernacularName,
    vernacularNameEn,
    taxonSource,
    taxonSourceId,
    active,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plant_taxon';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlantTaxon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scientific_name')) {
      context.handle(
        _scientificNameMeta,
        scientificName.isAcceptableOrUnknown(
          data['scientific_name']!,
          _scientificNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scientificNameMeta);
    }
    if (data.containsKey('family')) {
      context.handle(
        _familyMeta,
        family.isAcceptableOrUnknown(data['family']!, _familyMeta),
      );
    } else if (isInserting) {
      context.missing(_familyMeta);
    }
    if (data.containsKey('vernacular_name')) {
      context.handle(
        _vernacularNameMeta,
        vernacularName.isAcceptableOrUnknown(
          data['vernacular_name']!,
          _vernacularNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vernacularNameMeta);
    }
    if (data.containsKey('vernacular_name_en')) {
      context.handle(
        _vernacularNameEnMeta,
        vernacularNameEn.isAcceptableOrUnknown(
          data['vernacular_name_en']!,
          _vernacularNameEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vernacularNameEnMeta);
    }
    if (data.containsKey('taxon_source')) {
      context.handle(
        _taxonSourceMeta,
        taxonSource.isAcceptableOrUnknown(
          data['taxon_source']!,
          _taxonSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxonSourceMeta);
    }
    if (data.containsKey('taxon_source_id')) {
      context.handle(
        _taxonSourceIdMeta,
        taxonSourceId.isAcceptableOrUnknown(
          data['taxon_source_id']!,
          _taxonSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxonSourceIdMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlantTaxon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlantTaxon(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scientificName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scientific_name'],
      )!,
      family: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family'],
      )!,
      vernacularName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vernacular_name'],
      )!,
      vernacularNameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vernacular_name_en'],
      )!,
      taxonSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_source'],
      )!,
      taxonSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_source_id'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PlantTaxaTable createAlias(String alias) {
    return $PlantTaxaTable(attachedDatabase, alias);
  }
}

class PlantTaxon extends DataClass implements Insertable<PlantTaxon> {
  final String id;
  final String scientificName;
  final String family;
  final String vernacularName;
  final String vernacularNameEn;
  final String taxonSource;
  final String taxonSourceId;
  final bool active;
  final int? serverVersion;
  final DateTime? deletedAt;
  const PlantTaxon({
    required this.id,
    required this.scientificName,
    required this.family,
    required this.vernacularName,
    required this.vernacularNameEn,
    required this.taxonSource,
    required this.taxonSourceId,
    required this.active,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scientific_name'] = Variable<String>(scientificName);
    map['family'] = Variable<String>(family);
    map['vernacular_name'] = Variable<String>(vernacularName);
    map['vernacular_name_en'] = Variable<String>(vernacularNameEn);
    map['taxon_source'] = Variable<String>(taxonSource);
    map['taxon_source_id'] = Variable<String>(taxonSourceId);
    map['active'] = Variable<bool>(active);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  PlantTaxaCompanion toCompanion(bool nullToAbsent) {
    return PlantTaxaCompanion(
      id: Value(id),
      scientificName: Value(scientificName),
      family: Value(family),
      vernacularName: Value(vernacularName),
      vernacularNameEn: Value(vernacularNameEn),
      taxonSource: Value(taxonSource),
      taxonSourceId: Value(taxonSourceId),
      active: Value(active),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PlantTaxon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlantTaxon(
      id: serializer.fromJson<String>(json['id']),
      scientificName: serializer.fromJson<String>(json['scientificName']),
      family: serializer.fromJson<String>(json['family']),
      vernacularName: serializer.fromJson<String>(json['vernacularName']),
      vernacularNameEn: serializer.fromJson<String>(json['vernacularNameEn']),
      taxonSource: serializer.fromJson<String>(json['taxonSource']),
      taxonSourceId: serializer.fromJson<String>(json['taxonSourceId']),
      active: serializer.fromJson<bool>(json['active']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scientificName': serializer.toJson<String>(scientificName),
      'family': serializer.toJson<String>(family),
      'vernacularName': serializer.toJson<String>(vernacularName),
      'vernacularNameEn': serializer.toJson<String>(vernacularNameEn),
      'taxonSource': serializer.toJson<String>(taxonSource),
      'taxonSourceId': serializer.toJson<String>(taxonSourceId),
      'active': serializer.toJson<bool>(active),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  PlantTaxon copyWith({
    String? id,
    String? scientificName,
    String? family,
    String? vernacularName,
    String? vernacularNameEn,
    String? taxonSource,
    String? taxonSourceId,
    bool? active,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => PlantTaxon(
    id: id ?? this.id,
    scientificName: scientificName ?? this.scientificName,
    family: family ?? this.family,
    vernacularName: vernacularName ?? this.vernacularName,
    vernacularNameEn: vernacularNameEn ?? this.vernacularNameEn,
    taxonSource: taxonSource ?? this.taxonSource,
    taxonSourceId: taxonSourceId ?? this.taxonSourceId,
    active: active ?? this.active,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PlantTaxon copyWithCompanion(PlantTaxaCompanion data) {
    return PlantTaxon(
      id: data.id.present ? data.id.value : this.id,
      scientificName: data.scientificName.present
          ? data.scientificName.value
          : this.scientificName,
      family: data.family.present ? data.family.value : this.family,
      vernacularName: data.vernacularName.present
          ? data.vernacularName.value
          : this.vernacularName,
      vernacularNameEn: data.vernacularNameEn.present
          ? data.vernacularNameEn.value
          : this.vernacularNameEn,
      taxonSource: data.taxonSource.present
          ? data.taxonSource.value
          : this.taxonSource,
      taxonSourceId: data.taxonSourceId.present
          ? data.taxonSourceId.value
          : this.taxonSourceId,
      active: data.active.present ? data.active.value : this.active,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlantTaxon(')
          ..write('id: $id, ')
          ..write('scientificName: $scientificName, ')
          ..write('family: $family, ')
          ..write('vernacularName: $vernacularName, ')
          ..write('vernacularNameEn: $vernacularNameEn, ')
          ..write('taxonSource: $taxonSource, ')
          ..write('taxonSourceId: $taxonSourceId, ')
          ..write('active: $active, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scientificName,
    family,
    vernacularName,
    vernacularNameEn,
    taxonSource,
    taxonSourceId,
    active,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlantTaxon &&
          other.id == this.id &&
          other.scientificName == this.scientificName &&
          other.family == this.family &&
          other.vernacularName == this.vernacularName &&
          other.vernacularNameEn == this.vernacularNameEn &&
          other.taxonSource == this.taxonSource &&
          other.taxonSourceId == this.taxonSourceId &&
          other.active == this.active &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class PlantTaxaCompanion extends UpdateCompanion<PlantTaxon> {
  final Value<String> id;
  final Value<String> scientificName;
  final Value<String> family;
  final Value<String> vernacularName;
  final Value<String> vernacularNameEn;
  final Value<String> taxonSource;
  final Value<String> taxonSourceId;
  final Value<bool> active;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const PlantTaxaCompanion({
    this.id = const Value.absent(),
    this.scientificName = const Value.absent(),
    this.family = const Value.absent(),
    this.vernacularName = const Value.absent(),
    this.vernacularNameEn = const Value.absent(),
    this.taxonSource = const Value.absent(),
    this.taxonSourceId = const Value.absent(),
    this.active = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlantTaxaCompanion.insert({
    required String id,
    required String scientificName,
    required String family,
    required String vernacularName,
    required String vernacularNameEn,
    required String taxonSource,
    required String taxonSourceId,
    required bool active,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scientificName = Value(scientificName),
       family = Value(family),
       vernacularName = Value(vernacularName),
       vernacularNameEn = Value(vernacularNameEn),
       taxonSource = Value(taxonSource),
       taxonSourceId = Value(taxonSourceId),
       active = Value(active);
  static Insertable<PlantTaxon> custom({
    Expression<String>? id,
    Expression<String>? scientificName,
    Expression<String>? family,
    Expression<String>? vernacularName,
    Expression<String>? vernacularNameEn,
    Expression<String>? taxonSource,
    Expression<String>? taxonSourceId,
    Expression<bool>? active,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scientificName != null) 'scientific_name': scientificName,
      if (family != null) 'family': family,
      if (vernacularName != null) 'vernacular_name': vernacularName,
      if (vernacularNameEn != null) 'vernacular_name_en': vernacularNameEn,
      if (taxonSource != null) 'taxon_source': taxonSource,
      if (taxonSourceId != null) 'taxon_source_id': taxonSourceId,
      if (active != null) 'active': active,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlantTaxaCompanion copyWith({
    Value<String>? id,
    Value<String>? scientificName,
    Value<String>? family,
    Value<String>? vernacularName,
    Value<String>? vernacularNameEn,
    Value<String>? taxonSource,
    Value<String>? taxonSourceId,
    Value<bool>? active,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PlantTaxaCompanion(
      id: id ?? this.id,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      vernacularName: vernacularName ?? this.vernacularName,
      vernacularNameEn: vernacularNameEn ?? this.vernacularNameEn,
      taxonSource: taxonSource ?? this.taxonSource,
      taxonSourceId: taxonSourceId ?? this.taxonSourceId,
      active: active ?? this.active,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scientificName.present) {
      map['scientific_name'] = Variable<String>(scientificName.value);
    }
    if (family.present) {
      map['family'] = Variable<String>(family.value);
    }
    if (vernacularName.present) {
      map['vernacular_name'] = Variable<String>(vernacularName.value);
    }
    if (vernacularNameEn.present) {
      map['vernacular_name_en'] = Variable<String>(vernacularNameEn.value);
    }
    if (taxonSource.present) {
      map['taxon_source'] = Variable<String>(taxonSource.value);
    }
    if (taxonSourceId.present) {
      map['taxon_source_id'] = Variable<String>(taxonSourceId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlantTaxaCompanion(')
          ..write('id: $id, ')
          ..write('scientificName: $scientificName, ')
          ..write('family: $family, ')
          ..write('vernacularName: $vernacularName, ')
          ..write('vernacularNameEn: $vernacularNameEn, ')
          ..write('taxonSource: $taxonSource, ')
          ..write('taxonSourceId: $taxonSourceId, ')
          ..write('active: $active, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectProtocolsTable extends ProjectProtocols
    with TableInfo<$ProjectProtocolsTable, ProjectProtocol> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectProtocolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES project (id)',
    ),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<String> protocolVersion = GeneratedColumn<String>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surveyMethodMeta = const VerificationMeta(
    'surveyMethod',
  );
  @override
  late final GeneratedColumn<String> surveyMethod = GeneratedColumn<String>(
    'survey_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonStartMeta = const VerificationMeta(
    'seasonStart',
  );
  @override
  late final GeneratedColumn<DateTime> seasonStart = GeneratedColumn<DateTime>(
    'season_start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonEndMeta = const VerificationMeta(
    'seasonEnd',
  );
  @override
  late final GeneratedColumn<DateTime> seasonEnd = GeneratedColumn<DateTime>(
    'season_end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayStartTimeMeta = const VerificationMeta(
    'dayStartTime',
  );
  @override
  late final GeneratedColumn<String> dayStartTime = GeneratedColumn<String>(
    'day_start_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayEndTimeMeta = const VerificationMeta(
    'dayEndTime',
  );
  @override
  late final GeneratedColumn<String> dayEndTime = GeneratedColumn<String>(
    'day_end_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minTemperatureCMeta = const VerificationMeta(
    'minTemperatureC',
  );
  @override
  late final GeneratedColumn<double> minTemperatureC = GeneratedColumn<double>(
    'min_temperature_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sunnyTemperatureCMeta = const VerificationMeta(
    'sunnyTemperatureC',
  );
  @override
  late final GeneratedColumn<double> sunnyTemperatureC =
      GeneratedColumn<double>(
        'sunny_temperature_c',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _maxCloudCoverPctIfCoolMeta =
      const VerificationMeta('maxCloudCoverPctIfCool');
  @override
  late final GeneratedColumn<int> maxCloudCoverPctIfCool = GeneratedColumn<int>(
    'max_cloud_cover_pct_if_cool',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxWindBeaufortMeta = const VerificationMeta(
    'maxWindBeaufort',
  );
  @override
  late final GeneratedColumn<int> maxWindBeaufort = GeneratedColumn<int>(
    'max_wind_beaufort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowPrecipitationMeta =
      const VerificationMeta('allowPrecipitation');
  @override
  late final GeneratedColumn<bool> allowPrecipitation = GeneratedColumn<bool>(
    'allow_precipitation',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_precipitation" IN (0, 1))',
    ),
  );
  static const VerificationMeta _targetVisitsPerSeasonMeta =
      const VerificationMeta('targetVisitsPerSeason');
  @override
  late final GeneratedColumn<int> targetVisitsPerSeason = GeneratedColumn<int>(
    'target_visits_per_season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxDistanceFromTransectMMeta =
      const VerificationMeta('maxDistanceFromTransectM');
  @override
  late final GeneratedColumn<double> maxDistanceFromTransectM =
      GeneratedColumn<double>(
        'max_distance_from_transect_m',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _observationTimeToleranceMinMeta =
      const VerificationMeta('observationTimeToleranceMin');
  @override
  late final GeneratedColumn<int> observationTimeToleranceMin =
      GeneratedColumn<int>(
        'observation_time_tolerance_min',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gpsIntervalSMeta = const VerificationMeta(
    'gpsIntervalS',
  );
  @override
  late final GeneratedColumn<int> gpsIntervalS = GeneratedColumn<int>(
    'gps_interval_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gpsIntervalBatterySaverSMeta =
      const VerificationMeta('gpsIntervalBatterySaverS');
  @override
  late final GeneratedColumn<int> gpsIntervalBatterySaverS =
      GeneratedColumn<int>(
        'gps_interval_battery_saver_s',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gpsAccuracyWarningMMeta =
      const VerificationMeta('gpsAccuracyWarningM');
  @override
  late final GeneratedColumn<double> gpsAccuracyWarningM =
      GeneratedColumn<double>(
        'gps_accuracy_warning_m',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _gpsGapSMeta = const VerificationMeta(
    'gpsGapS',
  );
  @override
  late final GeneratedColumn<int> gpsGapS = GeneratedColumn<int>(
    'gps_gap_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _highCountThresholdMeta =
      const VerificationMeta('highCountThreshold');
  @override
  late final GeneratedColumn<int> highCountThreshold = GeneratedColumn<int>(
    'high_count_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minCoveragePctMeta = const VerificationMeta(
    'minCoveragePct',
  );
  @override
  late final GeneratedColumn<int> minCoveragePct = GeneratedColumn<int>(
    'min_coverage_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    projectId,
    id,
    protocolVersion,
    surveyMethod,
    seasonStart,
    seasonEnd,
    dayStartTime,
    dayEndTime,
    minTemperatureC,
    sunnyTemperatureC,
    maxCloudCoverPctIfCool,
    maxWindBeaufort,
    allowPrecipitation,
    targetVisitsPerSeason,
    maxDistanceFromTransectM,
    observationTimeToleranceMin,
    gpsIntervalS,
    gpsIntervalBatterySaverS,
    gpsAccuracyWarningM,
    gpsGapS,
    highCountThreshold,
    minCoveragePct,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_protocol';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectProtocol> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionMeta);
    }
    if (data.containsKey('survey_method')) {
      context.handle(
        _surveyMethodMeta,
        surveyMethod.isAcceptableOrUnknown(
          data['survey_method']!,
          _surveyMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surveyMethodMeta);
    }
    if (data.containsKey('season_start')) {
      context.handle(
        _seasonStartMeta,
        seasonStart.isAcceptableOrUnknown(
          data['season_start']!,
          _seasonStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonStartMeta);
    }
    if (data.containsKey('season_end')) {
      context.handle(
        _seasonEndMeta,
        seasonEnd.isAcceptableOrUnknown(data['season_end']!, _seasonEndMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonEndMeta);
    }
    if (data.containsKey('day_start_time')) {
      context.handle(
        _dayStartTimeMeta,
        dayStartTime.isAcceptableOrUnknown(
          data['day_start_time']!,
          _dayStartTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayStartTimeMeta);
    }
    if (data.containsKey('day_end_time')) {
      context.handle(
        _dayEndTimeMeta,
        dayEndTime.isAcceptableOrUnknown(
          data['day_end_time']!,
          _dayEndTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayEndTimeMeta);
    }
    if (data.containsKey('min_temperature_c')) {
      context.handle(
        _minTemperatureCMeta,
        minTemperatureC.isAcceptableOrUnknown(
          data['min_temperature_c']!,
          _minTemperatureCMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minTemperatureCMeta);
    }
    if (data.containsKey('sunny_temperature_c')) {
      context.handle(
        _sunnyTemperatureCMeta,
        sunnyTemperatureC.isAcceptableOrUnknown(
          data['sunny_temperature_c']!,
          _sunnyTemperatureCMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sunnyTemperatureCMeta);
    }
    if (data.containsKey('max_cloud_cover_pct_if_cool')) {
      context.handle(
        _maxCloudCoverPctIfCoolMeta,
        maxCloudCoverPctIfCool.isAcceptableOrUnknown(
          data['max_cloud_cover_pct_if_cool']!,
          _maxCloudCoverPctIfCoolMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxCloudCoverPctIfCoolMeta);
    }
    if (data.containsKey('max_wind_beaufort')) {
      context.handle(
        _maxWindBeaufortMeta,
        maxWindBeaufort.isAcceptableOrUnknown(
          data['max_wind_beaufort']!,
          _maxWindBeaufortMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxWindBeaufortMeta);
    }
    if (data.containsKey('allow_precipitation')) {
      context.handle(
        _allowPrecipitationMeta,
        allowPrecipitation.isAcceptableOrUnknown(
          data['allow_precipitation']!,
          _allowPrecipitationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowPrecipitationMeta);
    }
    if (data.containsKey('target_visits_per_season')) {
      context.handle(
        _targetVisitsPerSeasonMeta,
        targetVisitsPerSeason.isAcceptableOrUnknown(
          data['target_visits_per_season']!,
          _targetVisitsPerSeasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetVisitsPerSeasonMeta);
    }
    if (data.containsKey('max_distance_from_transect_m')) {
      context.handle(
        _maxDistanceFromTransectMMeta,
        maxDistanceFromTransectM.isAcceptableOrUnknown(
          data['max_distance_from_transect_m']!,
          _maxDistanceFromTransectMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxDistanceFromTransectMMeta);
    }
    if (data.containsKey('observation_time_tolerance_min')) {
      context.handle(
        _observationTimeToleranceMinMeta,
        observationTimeToleranceMin.isAcceptableOrUnknown(
          data['observation_time_tolerance_min']!,
          _observationTimeToleranceMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observationTimeToleranceMinMeta);
    }
    if (data.containsKey('gps_interval_s')) {
      context.handle(
        _gpsIntervalSMeta,
        gpsIntervalS.isAcceptableOrUnknown(
          data['gps_interval_s']!,
          _gpsIntervalSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gpsIntervalSMeta);
    }
    if (data.containsKey('gps_interval_battery_saver_s')) {
      context.handle(
        _gpsIntervalBatterySaverSMeta,
        gpsIntervalBatterySaverS.isAcceptableOrUnknown(
          data['gps_interval_battery_saver_s']!,
          _gpsIntervalBatterySaverSMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gpsIntervalBatterySaverSMeta);
    }
    if (data.containsKey('gps_accuracy_warning_m')) {
      context.handle(
        _gpsAccuracyWarningMMeta,
        gpsAccuracyWarningM.isAcceptableOrUnknown(
          data['gps_accuracy_warning_m']!,
          _gpsAccuracyWarningMMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_gpsAccuracyWarningMMeta);
    }
    if (data.containsKey('gps_gap_s')) {
      context.handle(
        _gpsGapSMeta,
        gpsGapS.isAcceptableOrUnknown(data['gps_gap_s']!, _gpsGapSMeta),
      );
    } else if (isInserting) {
      context.missing(_gpsGapSMeta);
    }
    if (data.containsKey('high_count_threshold')) {
      context.handle(
        _highCountThresholdMeta,
        highCountThreshold.isAcceptableOrUnknown(
          data['high_count_threshold']!,
          _highCountThresholdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_highCountThresholdMeta);
    }
    if (data.containsKey('min_coverage_pct')) {
      context.handle(
        _minCoveragePctMeta,
        minCoveragePct.isAcceptableOrUnknown(
          data['min_coverage_pct']!,
          _minCoveragePctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minCoveragePctMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectProtocol map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectProtocol(
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_version'],
      )!,
      surveyMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}survey_method'],
      )!,
      seasonStart: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}season_start'],
      )!,
      seasonEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}season_end'],
      )!,
      dayStartTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_start_time'],
      )!,
      dayEndTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_end_time'],
      )!,
      minTemperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_temperature_c'],
      )!,
      sunnyTemperatureC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sunny_temperature_c'],
      )!,
      maxCloudCoverPctIfCool: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_cloud_cover_pct_if_cool'],
      )!,
      maxWindBeaufort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_wind_beaufort'],
      )!,
      allowPrecipitation: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_precipitation'],
      )!,
      targetVisitsPerSeason: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_visits_per_season'],
      )!,
      maxDistanceFromTransectM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_distance_from_transect_m'],
      )!,
      observationTimeToleranceMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observation_time_tolerance_min'],
      )!,
      gpsIntervalS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gps_interval_s'],
      )!,
      gpsIntervalBatterySaverS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gps_interval_battery_saver_s'],
      )!,
      gpsAccuracyWarningM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gps_accuracy_warning_m'],
      )!,
      gpsGapS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gps_gap_s'],
      )!,
      highCountThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}high_count_threshold'],
      )!,
      minCoveragePct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_coverage_pct'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProjectProtocolsTable createAlias(String alias) {
    return $ProjectProtocolsTable(attachedDatabase, alias);
  }
}

class ProjectProtocol extends DataClass implements Insertable<ProjectProtocol> {
  final String projectId;
  final String id;
  final String protocolVersion;
  final String surveyMethod;
  final DateTime seasonStart;
  final DateTime seasonEnd;
  final String dayStartTime;
  final String dayEndTime;
  final double minTemperatureC;
  final double sunnyTemperatureC;
  final int maxCloudCoverPctIfCool;
  final int maxWindBeaufort;
  final bool allowPrecipitation;
  final int targetVisitsPerSeason;
  final double maxDistanceFromTransectM;
  final int observationTimeToleranceMin;
  final int gpsIntervalS;
  final int gpsIntervalBatterySaverS;
  final double gpsAccuracyWarningM;
  final int gpsGapS;
  final int highCountThreshold;
  final int minCoveragePct;
  final int? serverVersion;
  final DateTime? deletedAt;
  const ProjectProtocol({
    required this.projectId,
    required this.id,
    required this.protocolVersion,
    required this.surveyMethod,
    required this.seasonStart,
    required this.seasonEnd,
    required this.dayStartTime,
    required this.dayEndTime,
    required this.minTemperatureC,
    required this.sunnyTemperatureC,
    required this.maxCloudCoverPctIfCool,
    required this.maxWindBeaufort,
    required this.allowPrecipitation,
    required this.targetVisitsPerSeason,
    required this.maxDistanceFromTransectM,
    required this.observationTimeToleranceMin,
    required this.gpsIntervalS,
    required this.gpsIntervalBatterySaverS,
    required this.gpsAccuracyWarningM,
    required this.gpsGapS,
    required this.highCountThreshold,
    required this.minCoveragePct,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['project_id'] = Variable<String>(projectId);
    map['id'] = Variable<String>(id);
    map['protocol_version'] = Variable<String>(protocolVersion);
    map['survey_method'] = Variable<String>(surveyMethod);
    map['season_start'] = Variable<DateTime>(seasonStart);
    map['season_end'] = Variable<DateTime>(seasonEnd);
    map['day_start_time'] = Variable<String>(dayStartTime);
    map['day_end_time'] = Variable<String>(dayEndTime);
    map['min_temperature_c'] = Variable<double>(minTemperatureC);
    map['sunny_temperature_c'] = Variable<double>(sunnyTemperatureC);
    map['max_cloud_cover_pct_if_cool'] = Variable<int>(maxCloudCoverPctIfCool);
    map['max_wind_beaufort'] = Variable<int>(maxWindBeaufort);
    map['allow_precipitation'] = Variable<bool>(allowPrecipitation);
    map['target_visits_per_season'] = Variable<int>(targetVisitsPerSeason);
    map['max_distance_from_transect_m'] = Variable<double>(
      maxDistanceFromTransectM,
    );
    map['observation_time_tolerance_min'] = Variable<int>(
      observationTimeToleranceMin,
    );
    map['gps_interval_s'] = Variable<int>(gpsIntervalS);
    map['gps_interval_battery_saver_s'] = Variable<int>(
      gpsIntervalBatterySaverS,
    );
    map['gps_accuracy_warning_m'] = Variable<double>(gpsAccuracyWarningM);
    map['gps_gap_s'] = Variable<int>(gpsGapS);
    map['high_count_threshold'] = Variable<int>(highCountThreshold);
    map['min_coverage_pct'] = Variable<int>(minCoveragePct);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProjectProtocolsCompanion toCompanion(bool nullToAbsent) {
    return ProjectProtocolsCompanion(
      projectId: Value(projectId),
      id: Value(id),
      protocolVersion: Value(protocolVersion),
      surveyMethod: Value(surveyMethod),
      seasonStart: Value(seasonStart),
      seasonEnd: Value(seasonEnd),
      dayStartTime: Value(dayStartTime),
      dayEndTime: Value(dayEndTime),
      minTemperatureC: Value(minTemperatureC),
      sunnyTemperatureC: Value(sunnyTemperatureC),
      maxCloudCoverPctIfCool: Value(maxCloudCoverPctIfCool),
      maxWindBeaufort: Value(maxWindBeaufort),
      allowPrecipitation: Value(allowPrecipitation),
      targetVisitsPerSeason: Value(targetVisitsPerSeason),
      maxDistanceFromTransectM: Value(maxDistanceFromTransectM),
      observationTimeToleranceMin: Value(observationTimeToleranceMin),
      gpsIntervalS: Value(gpsIntervalS),
      gpsIntervalBatterySaverS: Value(gpsIntervalBatterySaverS),
      gpsAccuracyWarningM: Value(gpsAccuracyWarningM),
      gpsGapS: Value(gpsGapS),
      highCountThreshold: Value(highCountThreshold),
      minCoveragePct: Value(minCoveragePct),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProjectProtocol.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectProtocol(
      projectId: serializer.fromJson<String>(json['projectId']),
      id: serializer.fromJson<String>(json['id']),
      protocolVersion: serializer.fromJson<String>(json['protocolVersion']),
      surveyMethod: serializer.fromJson<String>(json['surveyMethod']),
      seasonStart: serializer.fromJson<DateTime>(json['seasonStart']),
      seasonEnd: serializer.fromJson<DateTime>(json['seasonEnd']),
      dayStartTime: serializer.fromJson<String>(json['dayStartTime']),
      dayEndTime: serializer.fromJson<String>(json['dayEndTime']),
      minTemperatureC: serializer.fromJson<double>(json['minTemperatureC']),
      sunnyTemperatureC: serializer.fromJson<double>(json['sunnyTemperatureC']),
      maxCloudCoverPctIfCool: serializer.fromJson<int>(
        json['maxCloudCoverPctIfCool'],
      ),
      maxWindBeaufort: serializer.fromJson<int>(json['maxWindBeaufort']),
      allowPrecipitation: serializer.fromJson<bool>(json['allowPrecipitation']),
      targetVisitsPerSeason: serializer.fromJson<int>(
        json['targetVisitsPerSeason'],
      ),
      maxDistanceFromTransectM: serializer.fromJson<double>(
        json['maxDistanceFromTransectM'],
      ),
      observationTimeToleranceMin: serializer.fromJson<int>(
        json['observationTimeToleranceMin'],
      ),
      gpsIntervalS: serializer.fromJson<int>(json['gpsIntervalS']),
      gpsIntervalBatterySaverS: serializer.fromJson<int>(
        json['gpsIntervalBatterySaverS'],
      ),
      gpsAccuracyWarningM: serializer.fromJson<double>(
        json['gpsAccuracyWarningM'],
      ),
      gpsGapS: serializer.fromJson<int>(json['gpsGapS']),
      highCountThreshold: serializer.fromJson<int>(json['highCountThreshold']),
      minCoveragePct: serializer.fromJson<int>(json['minCoveragePct']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'projectId': serializer.toJson<String>(projectId),
      'id': serializer.toJson<String>(id),
      'protocolVersion': serializer.toJson<String>(protocolVersion),
      'surveyMethod': serializer.toJson<String>(surveyMethod),
      'seasonStart': serializer.toJson<DateTime>(seasonStart),
      'seasonEnd': serializer.toJson<DateTime>(seasonEnd),
      'dayStartTime': serializer.toJson<String>(dayStartTime),
      'dayEndTime': serializer.toJson<String>(dayEndTime),
      'minTemperatureC': serializer.toJson<double>(minTemperatureC),
      'sunnyTemperatureC': serializer.toJson<double>(sunnyTemperatureC),
      'maxCloudCoverPctIfCool': serializer.toJson<int>(maxCloudCoverPctIfCool),
      'maxWindBeaufort': serializer.toJson<int>(maxWindBeaufort),
      'allowPrecipitation': serializer.toJson<bool>(allowPrecipitation),
      'targetVisitsPerSeason': serializer.toJson<int>(targetVisitsPerSeason),
      'maxDistanceFromTransectM': serializer.toJson<double>(
        maxDistanceFromTransectM,
      ),
      'observationTimeToleranceMin': serializer.toJson<int>(
        observationTimeToleranceMin,
      ),
      'gpsIntervalS': serializer.toJson<int>(gpsIntervalS),
      'gpsIntervalBatterySaverS': serializer.toJson<int>(
        gpsIntervalBatterySaverS,
      ),
      'gpsAccuracyWarningM': serializer.toJson<double>(gpsAccuracyWarningM),
      'gpsGapS': serializer.toJson<int>(gpsGapS),
      'highCountThreshold': serializer.toJson<int>(highCountThreshold),
      'minCoveragePct': serializer.toJson<int>(minCoveragePct),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ProjectProtocol copyWith({
    String? projectId,
    String? id,
    String? protocolVersion,
    String? surveyMethod,
    DateTime? seasonStart,
    DateTime? seasonEnd,
    String? dayStartTime,
    String? dayEndTime,
    double? minTemperatureC,
    double? sunnyTemperatureC,
    int? maxCloudCoverPctIfCool,
    int? maxWindBeaufort,
    bool? allowPrecipitation,
    int? targetVisitsPerSeason,
    double? maxDistanceFromTransectM,
    int? observationTimeToleranceMin,
    int? gpsIntervalS,
    int? gpsIntervalBatterySaverS,
    double? gpsAccuracyWarningM,
    int? gpsGapS,
    int? highCountThreshold,
    int? minCoveragePct,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ProjectProtocol(
    projectId: projectId ?? this.projectId,
    id: id ?? this.id,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    surveyMethod: surveyMethod ?? this.surveyMethod,
    seasonStart: seasonStart ?? this.seasonStart,
    seasonEnd: seasonEnd ?? this.seasonEnd,
    dayStartTime: dayStartTime ?? this.dayStartTime,
    dayEndTime: dayEndTime ?? this.dayEndTime,
    minTemperatureC: minTemperatureC ?? this.minTemperatureC,
    sunnyTemperatureC: sunnyTemperatureC ?? this.sunnyTemperatureC,
    maxCloudCoverPctIfCool:
        maxCloudCoverPctIfCool ?? this.maxCloudCoverPctIfCool,
    maxWindBeaufort: maxWindBeaufort ?? this.maxWindBeaufort,
    allowPrecipitation: allowPrecipitation ?? this.allowPrecipitation,
    targetVisitsPerSeason: targetVisitsPerSeason ?? this.targetVisitsPerSeason,
    maxDistanceFromTransectM:
        maxDistanceFromTransectM ?? this.maxDistanceFromTransectM,
    observationTimeToleranceMin:
        observationTimeToleranceMin ?? this.observationTimeToleranceMin,
    gpsIntervalS: gpsIntervalS ?? this.gpsIntervalS,
    gpsIntervalBatterySaverS:
        gpsIntervalBatterySaverS ?? this.gpsIntervalBatterySaverS,
    gpsAccuracyWarningM: gpsAccuracyWarningM ?? this.gpsAccuracyWarningM,
    gpsGapS: gpsGapS ?? this.gpsGapS,
    highCountThreshold: highCountThreshold ?? this.highCountThreshold,
    minCoveragePct: minCoveragePct ?? this.minCoveragePct,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProjectProtocol copyWithCompanion(ProjectProtocolsCompanion data) {
    return ProjectProtocol(
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      id: data.id.present ? data.id.value : this.id,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      surveyMethod: data.surveyMethod.present
          ? data.surveyMethod.value
          : this.surveyMethod,
      seasonStart: data.seasonStart.present
          ? data.seasonStart.value
          : this.seasonStart,
      seasonEnd: data.seasonEnd.present ? data.seasonEnd.value : this.seasonEnd,
      dayStartTime: data.dayStartTime.present
          ? data.dayStartTime.value
          : this.dayStartTime,
      dayEndTime: data.dayEndTime.present
          ? data.dayEndTime.value
          : this.dayEndTime,
      minTemperatureC: data.minTemperatureC.present
          ? data.minTemperatureC.value
          : this.minTemperatureC,
      sunnyTemperatureC: data.sunnyTemperatureC.present
          ? data.sunnyTemperatureC.value
          : this.sunnyTemperatureC,
      maxCloudCoverPctIfCool: data.maxCloudCoverPctIfCool.present
          ? data.maxCloudCoverPctIfCool.value
          : this.maxCloudCoverPctIfCool,
      maxWindBeaufort: data.maxWindBeaufort.present
          ? data.maxWindBeaufort.value
          : this.maxWindBeaufort,
      allowPrecipitation: data.allowPrecipitation.present
          ? data.allowPrecipitation.value
          : this.allowPrecipitation,
      targetVisitsPerSeason: data.targetVisitsPerSeason.present
          ? data.targetVisitsPerSeason.value
          : this.targetVisitsPerSeason,
      maxDistanceFromTransectM: data.maxDistanceFromTransectM.present
          ? data.maxDistanceFromTransectM.value
          : this.maxDistanceFromTransectM,
      observationTimeToleranceMin: data.observationTimeToleranceMin.present
          ? data.observationTimeToleranceMin.value
          : this.observationTimeToleranceMin,
      gpsIntervalS: data.gpsIntervalS.present
          ? data.gpsIntervalS.value
          : this.gpsIntervalS,
      gpsIntervalBatterySaverS: data.gpsIntervalBatterySaverS.present
          ? data.gpsIntervalBatterySaverS.value
          : this.gpsIntervalBatterySaverS,
      gpsAccuracyWarningM: data.gpsAccuracyWarningM.present
          ? data.gpsAccuracyWarningM.value
          : this.gpsAccuracyWarningM,
      gpsGapS: data.gpsGapS.present ? data.gpsGapS.value : this.gpsGapS,
      highCountThreshold: data.highCountThreshold.present
          ? data.highCountThreshold.value
          : this.highCountThreshold,
      minCoveragePct: data.minCoveragePct.present
          ? data.minCoveragePct.value
          : this.minCoveragePct,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectProtocol(')
          ..write('projectId: $projectId, ')
          ..write('id: $id, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('surveyMethod: $surveyMethod, ')
          ..write('seasonStart: $seasonStart, ')
          ..write('seasonEnd: $seasonEnd, ')
          ..write('dayStartTime: $dayStartTime, ')
          ..write('dayEndTime: $dayEndTime, ')
          ..write('minTemperatureC: $minTemperatureC, ')
          ..write('sunnyTemperatureC: $sunnyTemperatureC, ')
          ..write('maxCloudCoverPctIfCool: $maxCloudCoverPctIfCool, ')
          ..write('maxWindBeaufort: $maxWindBeaufort, ')
          ..write('allowPrecipitation: $allowPrecipitation, ')
          ..write('targetVisitsPerSeason: $targetVisitsPerSeason, ')
          ..write('maxDistanceFromTransectM: $maxDistanceFromTransectM, ')
          ..write('observationTimeToleranceMin: $observationTimeToleranceMin, ')
          ..write('gpsIntervalS: $gpsIntervalS, ')
          ..write('gpsIntervalBatterySaverS: $gpsIntervalBatterySaverS, ')
          ..write('gpsAccuracyWarningM: $gpsAccuracyWarningM, ')
          ..write('gpsGapS: $gpsGapS, ')
          ..write('highCountThreshold: $highCountThreshold, ')
          ..write('minCoveragePct: $minCoveragePct, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    projectId,
    id,
    protocolVersion,
    surveyMethod,
    seasonStart,
    seasonEnd,
    dayStartTime,
    dayEndTime,
    minTemperatureC,
    sunnyTemperatureC,
    maxCloudCoverPctIfCool,
    maxWindBeaufort,
    allowPrecipitation,
    targetVisitsPerSeason,
    maxDistanceFromTransectM,
    observationTimeToleranceMin,
    gpsIntervalS,
    gpsIntervalBatterySaverS,
    gpsAccuracyWarningM,
    gpsGapS,
    highCountThreshold,
    minCoveragePct,
    serverVersion,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectProtocol &&
          other.projectId == this.projectId &&
          other.id == this.id &&
          other.protocolVersion == this.protocolVersion &&
          other.surveyMethod == this.surveyMethod &&
          other.seasonStart == this.seasonStart &&
          other.seasonEnd == this.seasonEnd &&
          other.dayStartTime == this.dayStartTime &&
          other.dayEndTime == this.dayEndTime &&
          other.minTemperatureC == this.minTemperatureC &&
          other.sunnyTemperatureC == this.sunnyTemperatureC &&
          other.maxCloudCoverPctIfCool == this.maxCloudCoverPctIfCool &&
          other.maxWindBeaufort == this.maxWindBeaufort &&
          other.allowPrecipitation == this.allowPrecipitation &&
          other.targetVisitsPerSeason == this.targetVisitsPerSeason &&
          other.maxDistanceFromTransectM == this.maxDistanceFromTransectM &&
          other.observationTimeToleranceMin ==
              this.observationTimeToleranceMin &&
          other.gpsIntervalS == this.gpsIntervalS &&
          other.gpsIntervalBatterySaverS == this.gpsIntervalBatterySaverS &&
          other.gpsAccuracyWarningM == this.gpsAccuracyWarningM &&
          other.gpsGapS == this.gpsGapS &&
          other.highCountThreshold == this.highCountThreshold &&
          other.minCoveragePct == this.minCoveragePct &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class ProjectProtocolsCompanion extends UpdateCompanion<ProjectProtocol> {
  final Value<String> projectId;
  final Value<String> id;
  final Value<String> protocolVersion;
  final Value<String> surveyMethod;
  final Value<DateTime> seasonStart;
  final Value<DateTime> seasonEnd;
  final Value<String> dayStartTime;
  final Value<String> dayEndTime;
  final Value<double> minTemperatureC;
  final Value<double> sunnyTemperatureC;
  final Value<int> maxCloudCoverPctIfCool;
  final Value<int> maxWindBeaufort;
  final Value<bool> allowPrecipitation;
  final Value<int> targetVisitsPerSeason;
  final Value<double> maxDistanceFromTransectM;
  final Value<int> observationTimeToleranceMin;
  final Value<int> gpsIntervalS;
  final Value<int> gpsIntervalBatterySaverS;
  final Value<double> gpsAccuracyWarningM;
  final Value<int> gpsGapS;
  final Value<int> highCountThreshold;
  final Value<int> minCoveragePct;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProjectProtocolsCompanion({
    this.projectId = const Value.absent(),
    this.id = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.surveyMethod = const Value.absent(),
    this.seasonStart = const Value.absent(),
    this.seasonEnd = const Value.absent(),
    this.dayStartTime = const Value.absent(),
    this.dayEndTime = const Value.absent(),
    this.minTemperatureC = const Value.absent(),
    this.sunnyTemperatureC = const Value.absent(),
    this.maxCloudCoverPctIfCool = const Value.absent(),
    this.maxWindBeaufort = const Value.absent(),
    this.allowPrecipitation = const Value.absent(),
    this.targetVisitsPerSeason = const Value.absent(),
    this.maxDistanceFromTransectM = const Value.absent(),
    this.observationTimeToleranceMin = const Value.absent(),
    this.gpsIntervalS = const Value.absent(),
    this.gpsIntervalBatterySaverS = const Value.absent(),
    this.gpsAccuracyWarningM = const Value.absent(),
    this.gpsGapS = const Value.absent(),
    this.highCountThreshold = const Value.absent(),
    this.minCoveragePct = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectProtocolsCompanion.insert({
    required String projectId,
    required String id,
    required String protocolVersion,
    required String surveyMethod,
    required DateTime seasonStart,
    required DateTime seasonEnd,
    required String dayStartTime,
    required String dayEndTime,
    required double minTemperatureC,
    required double sunnyTemperatureC,
    required int maxCloudCoverPctIfCool,
    required int maxWindBeaufort,
    required bool allowPrecipitation,
    required int targetVisitsPerSeason,
    required double maxDistanceFromTransectM,
    required int observationTimeToleranceMin,
    required int gpsIntervalS,
    required int gpsIntervalBatterySaverS,
    required double gpsAccuracyWarningM,
    required int gpsGapS,
    required int highCountThreshold,
    required int minCoveragePct,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : projectId = Value(projectId),
       id = Value(id),
       protocolVersion = Value(protocolVersion),
       surveyMethod = Value(surveyMethod),
       seasonStart = Value(seasonStart),
       seasonEnd = Value(seasonEnd),
       dayStartTime = Value(dayStartTime),
       dayEndTime = Value(dayEndTime),
       minTemperatureC = Value(minTemperatureC),
       sunnyTemperatureC = Value(sunnyTemperatureC),
       maxCloudCoverPctIfCool = Value(maxCloudCoverPctIfCool),
       maxWindBeaufort = Value(maxWindBeaufort),
       allowPrecipitation = Value(allowPrecipitation),
       targetVisitsPerSeason = Value(targetVisitsPerSeason),
       maxDistanceFromTransectM = Value(maxDistanceFromTransectM),
       observationTimeToleranceMin = Value(observationTimeToleranceMin),
       gpsIntervalS = Value(gpsIntervalS),
       gpsIntervalBatterySaverS = Value(gpsIntervalBatterySaverS),
       gpsAccuracyWarningM = Value(gpsAccuracyWarningM),
       gpsGapS = Value(gpsGapS),
       highCountThreshold = Value(highCountThreshold),
       minCoveragePct = Value(minCoveragePct);
  static Insertable<ProjectProtocol> custom({
    Expression<String>? projectId,
    Expression<String>? id,
    Expression<String>? protocolVersion,
    Expression<String>? surveyMethod,
    Expression<DateTime>? seasonStart,
    Expression<DateTime>? seasonEnd,
    Expression<String>? dayStartTime,
    Expression<String>? dayEndTime,
    Expression<double>? minTemperatureC,
    Expression<double>? sunnyTemperatureC,
    Expression<int>? maxCloudCoverPctIfCool,
    Expression<int>? maxWindBeaufort,
    Expression<bool>? allowPrecipitation,
    Expression<int>? targetVisitsPerSeason,
    Expression<double>? maxDistanceFromTransectM,
    Expression<int>? observationTimeToleranceMin,
    Expression<int>? gpsIntervalS,
    Expression<int>? gpsIntervalBatterySaverS,
    Expression<double>? gpsAccuracyWarningM,
    Expression<int>? gpsGapS,
    Expression<int>? highCountThreshold,
    Expression<int>? minCoveragePct,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (projectId != null) 'project_id': projectId,
      if (id != null) 'id': id,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (surveyMethod != null) 'survey_method': surveyMethod,
      if (seasonStart != null) 'season_start': seasonStart,
      if (seasonEnd != null) 'season_end': seasonEnd,
      if (dayStartTime != null) 'day_start_time': dayStartTime,
      if (dayEndTime != null) 'day_end_time': dayEndTime,
      if (minTemperatureC != null) 'min_temperature_c': minTemperatureC,
      if (sunnyTemperatureC != null) 'sunny_temperature_c': sunnyTemperatureC,
      if (maxCloudCoverPctIfCool != null)
        'max_cloud_cover_pct_if_cool': maxCloudCoverPctIfCool,
      if (maxWindBeaufort != null) 'max_wind_beaufort': maxWindBeaufort,
      if (allowPrecipitation != null) 'allow_precipitation': allowPrecipitation,
      if (targetVisitsPerSeason != null)
        'target_visits_per_season': targetVisitsPerSeason,
      if (maxDistanceFromTransectM != null)
        'max_distance_from_transect_m': maxDistanceFromTransectM,
      if (observationTimeToleranceMin != null)
        'observation_time_tolerance_min': observationTimeToleranceMin,
      if (gpsIntervalS != null) 'gps_interval_s': gpsIntervalS,
      if (gpsIntervalBatterySaverS != null)
        'gps_interval_battery_saver_s': gpsIntervalBatterySaverS,
      if (gpsAccuracyWarningM != null)
        'gps_accuracy_warning_m': gpsAccuracyWarningM,
      if (gpsGapS != null) 'gps_gap_s': gpsGapS,
      if (highCountThreshold != null)
        'high_count_threshold': highCountThreshold,
      if (minCoveragePct != null) 'min_coverage_pct': minCoveragePct,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectProtocolsCompanion copyWith({
    Value<String>? projectId,
    Value<String>? id,
    Value<String>? protocolVersion,
    Value<String>? surveyMethod,
    Value<DateTime>? seasonStart,
    Value<DateTime>? seasonEnd,
    Value<String>? dayStartTime,
    Value<String>? dayEndTime,
    Value<double>? minTemperatureC,
    Value<double>? sunnyTemperatureC,
    Value<int>? maxCloudCoverPctIfCool,
    Value<int>? maxWindBeaufort,
    Value<bool>? allowPrecipitation,
    Value<int>? targetVisitsPerSeason,
    Value<double>? maxDistanceFromTransectM,
    Value<int>? observationTimeToleranceMin,
    Value<int>? gpsIntervalS,
    Value<int>? gpsIntervalBatterySaverS,
    Value<double>? gpsAccuracyWarningM,
    Value<int>? gpsGapS,
    Value<int>? highCountThreshold,
    Value<int>? minCoveragePct,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProjectProtocolsCompanion(
      projectId: projectId ?? this.projectId,
      id: id ?? this.id,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      surveyMethod: surveyMethod ?? this.surveyMethod,
      seasonStart: seasonStart ?? this.seasonStart,
      seasonEnd: seasonEnd ?? this.seasonEnd,
      dayStartTime: dayStartTime ?? this.dayStartTime,
      dayEndTime: dayEndTime ?? this.dayEndTime,
      minTemperatureC: minTemperatureC ?? this.minTemperatureC,
      sunnyTemperatureC: sunnyTemperatureC ?? this.sunnyTemperatureC,
      maxCloudCoverPctIfCool:
          maxCloudCoverPctIfCool ?? this.maxCloudCoverPctIfCool,
      maxWindBeaufort: maxWindBeaufort ?? this.maxWindBeaufort,
      allowPrecipitation: allowPrecipitation ?? this.allowPrecipitation,
      targetVisitsPerSeason:
          targetVisitsPerSeason ?? this.targetVisitsPerSeason,
      maxDistanceFromTransectM:
          maxDistanceFromTransectM ?? this.maxDistanceFromTransectM,
      observationTimeToleranceMin:
          observationTimeToleranceMin ?? this.observationTimeToleranceMin,
      gpsIntervalS: gpsIntervalS ?? this.gpsIntervalS,
      gpsIntervalBatterySaverS:
          gpsIntervalBatterySaverS ?? this.gpsIntervalBatterySaverS,
      gpsAccuracyWarningM: gpsAccuracyWarningM ?? this.gpsAccuracyWarningM,
      gpsGapS: gpsGapS ?? this.gpsGapS,
      highCountThreshold: highCountThreshold ?? this.highCountThreshold,
      minCoveragePct: minCoveragePct ?? this.minCoveragePct,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<String>(protocolVersion.value);
    }
    if (surveyMethod.present) {
      map['survey_method'] = Variable<String>(surveyMethod.value);
    }
    if (seasonStart.present) {
      map['season_start'] = Variable<DateTime>(seasonStart.value);
    }
    if (seasonEnd.present) {
      map['season_end'] = Variable<DateTime>(seasonEnd.value);
    }
    if (dayStartTime.present) {
      map['day_start_time'] = Variable<String>(dayStartTime.value);
    }
    if (dayEndTime.present) {
      map['day_end_time'] = Variable<String>(dayEndTime.value);
    }
    if (minTemperatureC.present) {
      map['min_temperature_c'] = Variable<double>(minTemperatureC.value);
    }
    if (sunnyTemperatureC.present) {
      map['sunny_temperature_c'] = Variable<double>(sunnyTemperatureC.value);
    }
    if (maxCloudCoverPctIfCool.present) {
      map['max_cloud_cover_pct_if_cool'] = Variable<int>(
        maxCloudCoverPctIfCool.value,
      );
    }
    if (maxWindBeaufort.present) {
      map['max_wind_beaufort'] = Variable<int>(maxWindBeaufort.value);
    }
    if (allowPrecipitation.present) {
      map['allow_precipitation'] = Variable<bool>(allowPrecipitation.value);
    }
    if (targetVisitsPerSeason.present) {
      map['target_visits_per_season'] = Variable<int>(
        targetVisitsPerSeason.value,
      );
    }
    if (maxDistanceFromTransectM.present) {
      map['max_distance_from_transect_m'] = Variable<double>(
        maxDistanceFromTransectM.value,
      );
    }
    if (observationTimeToleranceMin.present) {
      map['observation_time_tolerance_min'] = Variable<int>(
        observationTimeToleranceMin.value,
      );
    }
    if (gpsIntervalS.present) {
      map['gps_interval_s'] = Variable<int>(gpsIntervalS.value);
    }
    if (gpsIntervalBatterySaverS.present) {
      map['gps_interval_battery_saver_s'] = Variable<int>(
        gpsIntervalBatterySaverS.value,
      );
    }
    if (gpsAccuracyWarningM.present) {
      map['gps_accuracy_warning_m'] = Variable<double>(
        gpsAccuracyWarningM.value,
      );
    }
    if (gpsGapS.present) {
      map['gps_gap_s'] = Variable<int>(gpsGapS.value);
    }
    if (highCountThreshold.present) {
      map['high_count_threshold'] = Variable<int>(highCountThreshold.value);
    }
    if (minCoveragePct.present) {
      map['min_coverage_pct'] = Variable<int>(minCoveragePct.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectProtocolsCompanion(')
          ..write('projectId: $projectId, ')
          ..write('id: $id, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('surveyMethod: $surveyMethod, ')
          ..write('seasonStart: $seasonStart, ')
          ..write('seasonEnd: $seasonEnd, ')
          ..write('dayStartTime: $dayStartTime, ')
          ..write('dayEndTime: $dayEndTime, ')
          ..write('minTemperatureC: $minTemperatureC, ')
          ..write('sunnyTemperatureC: $sunnyTemperatureC, ')
          ..write('maxCloudCoverPctIfCool: $maxCloudCoverPctIfCool, ')
          ..write('maxWindBeaufort: $maxWindBeaufort, ')
          ..write('allowPrecipitation: $allowPrecipitation, ')
          ..write('targetVisitsPerSeason: $targetVisitsPerSeason, ')
          ..write('maxDistanceFromTransectM: $maxDistanceFromTransectM, ')
          ..write('observationTimeToleranceMin: $observationTimeToleranceMin, ')
          ..write('gpsIntervalS: $gpsIntervalS, ')
          ..write('gpsIntervalBatterySaverS: $gpsIntervalBatterySaverS, ')
          ..write('gpsAccuracyWarningM: $gpsAccuracyWarningM, ')
          ..write('gpsGapS: $gpsGapS, ')
          ..write('highCountThreshold: $highCountThreshold, ')
          ..write('minCoveragePct: $minCoveragePct, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConflictsTable extends SyncConflicts
    with TableInfo<$SyncConflictsTable, SyncConflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conflictingFieldsMeta = const VerificationMeta(
    'conflictingFields',
  );
  @override
  late final GeneratedColumn<String> conflictingFields =
      GeneratedColumn<String>(
        'conflicting_fields',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolutionNoteMeta = const VerificationMeta(
    'resolutionNote',
  );
  @override
  late final GeneratedColumn<String> resolutionNote = GeneratedColumn<String>(
    'resolution_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncStatus.pending.name),
      ).withConverter<SyncStatus>($SyncConflictsTable.$convertersyncStatus);
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    conflictingFields,
    createdAt,
    resolvedAt,
    resolutionNote,
    status,
    projectId,
    syncStatus,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_conflict';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncConflict> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('conflicting_fields')) {
      context.handle(
        _conflictingFieldsMeta,
        conflictingFields.isAcceptableOrUnknown(
          data['conflicting_fields']!,
          _conflictingFieldsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conflictingFieldsMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('resolution_note')) {
      context.handle(
        _resolutionNoteMeta,
        resolutionNote.isAcceptableOrUnknown(
          data['resolution_note']!,
          _resolutionNoteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolutionNoteMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConflict(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      conflictingFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflicting_fields'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      resolutionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution_note'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      syncStatus: $SyncConflictsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SyncConflictsTable createAlias(String alias) {
    return $SyncConflictsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class SyncConflict extends DataClass implements Insertable<SyncConflict> {
  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final String conflictingFields;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String resolutionNote;
  final String status;
  final String? projectId;
  final SyncStatus syncStatus;
  final int? serverVersion;
  final DateTime? deletedAt;
  const SyncConflict({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.conflictingFields,
    required this.createdAt,
    this.resolvedAt,
    required this.resolutionNote,
    required this.status,
    this.projectId,
    required this.syncStatus,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['conflicting_fields'] = Variable<String>(conflictingFields);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    map['resolution_note'] = Variable<String>(resolutionNote);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    {
      map['sync_status'] = Variable<String>(
        $SyncConflictsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  SyncConflictsCompanion toCompanion(bool nullToAbsent) {
    return SyncConflictsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      conflictingFields: Value(conflictingFields),
      createdAt: Value(createdAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      resolutionNote: Value(resolutionNote),
      status: Value(status),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      syncStatus: Value(syncStatus),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SyncConflict.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConflict(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      conflictingFields: serializer.fromJson<String>(json['conflictingFields']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      resolutionNote: serializer.fromJson<String>(json['resolutionNote']),
      status: serializer.fromJson<String>(json['status']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      syncStatus: $SyncConflictsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'conflictingFields': serializer.toJson<String>(conflictingFields),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'resolutionNote': serializer.toJson<String>(resolutionNote),
      'status': serializer.toJson<String>(status),
      'projectId': serializer.toJson<String?>(projectId),
      'syncStatus': serializer.toJson<String>(
        $SyncConflictsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  SyncConflict copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? operation,
    String? conflictingFields,
    DateTime? createdAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
    String? resolutionNote,
    String? status,
    Value<String?> projectId = const Value.absent(),
    SyncStatus? syncStatus,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => SyncConflict(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    conflictingFields: conflictingFields ?? this.conflictingFields,
    createdAt: createdAt ?? this.createdAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    resolutionNote: resolutionNote ?? this.resolutionNote,
    status: status ?? this.status,
    projectId: projectId.present ? projectId.value : this.projectId,
    syncStatus: syncStatus ?? this.syncStatus,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SyncConflict copyWithCompanion(SyncConflictsCompanion data) {
    return SyncConflict(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      conflictingFields: data.conflictingFields.present
          ? data.conflictingFields.value
          : this.conflictingFields,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      resolutionNote: data.resolutionNote.present
          ? data.resolutionNote.value
          : this.resolutionNote,
      status: data.status.present ? data.status.value : this.status,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflict(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('conflictingFields: $conflictingFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolutionNote: $resolutionNote, ')
          ..write('status: $status, ')
          ..write('projectId: $projectId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    conflictingFields,
    createdAt,
    resolvedAt,
    resolutionNote,
    status,
    projectId,
    syncStatus,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConflict &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.conflictingFields == this.conflictingFields &&
          other.createdAt == this.createdAt &&
          other.resolvedAt == this.resolvedAt &&
          other.resolutionNote == this.resolutionNote &&
          other.status == this.status &&
          other.projectId == this.projectId &&
          other.syncStatus == this.syncStatus &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class SyncConflictsCompanion extends UpdateCompanion<SyncConflict> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> conflictingFields;
  final Value<DateTime> createdAt;
  final Value<DateTime?> resolvedAt;
  final Value<String> resolutionNote;
  final Value<String> status;
  final Value<String?> projectId;
  final Value<SyncStatus> syncStatus;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const SyncConflictsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.conflictingFields = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.resolutionNote = const Value.absent(),
    this.status = const Value.absent(),
    this.projectId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncConflictsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    required String conflictingFields,
    required DateTime createdAt,
    this.resolvedAt = const Value.absent(),
    required String resolutionNote,
    required String status,
    this.projectId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       conflictingFields = Value(conflictingFields),
       createdAt = Value(createdAt),
       resolutionNote = Value(resolutionNote),
       status = Value(status);
  static Insertable<SyncConflict> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? conflictingFields,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? resolvedAt,
    Expression<String>? resolutionNote,
    Expression<String>? status,
    Expression<String>? projectId,
    Expression<String>? syncStatus,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (conflictingFields != null) 'conflicting_fields': conflictingFields,
      if (createdAt != null) 'created_at': createdAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (resolutionNote != null) 'resolution_note': resolutionNote,
      if (status != null) 'status': status,
      if (projectId != null) 'project_id': projectId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? conflictingFields,
    Value<DateTime>? createdAt,
    Value<DateTime?>? resolvedAt,
    Value<String>? resolutionNote,
    Value<String>? status,
    Value<String?>? projectId,
    Value<SyncStatus>? syncStatus,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return SyncConflictsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      conflictingFields: conflictingFields ?? this.conflictingFields,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (conflictingFields.present) {
      map['conflicting_fields'] = Variable<String>(conflictingFields.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (resolutionNote.present) {
      map['resolution_note'] = Variable<String>(resolutionNote.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $SyncConflictsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConflictsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('conflictingFields: $conflictingFields, ')
          ..write('createdAt: $createdAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('resolutionNote: $resolutionNote, ')
          ..write('status: $status, ')
          ..write('projectId: $projectId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransectsTable extends Transects
    with TableInfo<$TransectsTable, Transect> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES project (id)',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLengthMMeta = const VerificationMeta(
    'targetLengthM',
  );
  @override
  late final GeneratedColumn<double> targetLengthM = GeneratedColumn<double>(
    'target_length_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _habitatSummaryMeta = const VerificationMeta(
    'habitatSummary',
  );
  @override
  late final GeneratedColumn<String> habitatSummary = GeneratedColumn<String>(
    'habitat_summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _geometryMeta = const VerificationMeta(
    'geometry',
  );
  @override
  late final GeneratedColumn<String> geometry = GeneratedColumn<String>(
    'geometry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lengthMMeta = const VerificationMeta(
    'lengthM',
  );
  @override
  late final GeneratedColumn<double> lengthM = GeneratedColumn<double>(
    'length_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    code,
    name,
    description,
    targetLengthM,
    habitatSummary,
    active,
    geometry,
    lengthM,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transect';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transect> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('target_length_m')) {
      context.handle(
        _targetLengthMMeta,
        targetLengthM.isAcceptableOrUnknown(
          data['target_length_m']!,
          _targetLengthMMeta,
        ),
      );
    }
    if (data.containsKey('habitat_summary')) {
      context.handle(
        _habitatSummaryMeta,
        habitatSummary.isAcceptableOrUnknown(
          data['habitat_summary']!,
          _habitatSummaryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_habitatSummaryMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('geometry')) {
      context.handle(
        _geometryMeta,
        geometry.isAcceptableOrUnknown(data['geometry']!, _geometryMeta),
      );
    } else if (isInserting) {
      context.missing(_geometryMeta);
    }
    if (data.containsKey('length_m')) {
      context.handle(
        _lengthMMeta,
        lengthM.isAcceptableOrUnknown(data['length_m']!, _lengthMMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthMMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transect map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transect(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      targetLengthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_length_m'],
      ),
      habitatSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habitat_summary'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      geometry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geometry'],
      )!,
      lengthM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}length_m'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransectsTable createAlias(String alias) {
    return $TransectsTable(attachedDatabase, alias);
  }
}

class Transect extends DataClass implements Insertable<Transect> {
  final String id;
  final String projectId;
  final String code;
  final String name;
  final String description;
  final double? targetLengthM;
  final String habitatSummary;
  final bool active;
  final String geometry;
  final double lengthM;
  final int? serverVersion;
  final DateTime? deletedAt;
  const Transect({
    required this.id,
    required this.projectId,
    required this.code,
    required this.name,
    required this.description,
    this.targetLengthM,
    required this.habitatSummary,
    required this.active,
    required this.geometry,
    required this.lengthM,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || targetLengthM != null) {
      map['target_length_m'] = Variable<double>(targetLengthM);
    }
    map['habitat_summary'] = Variable<String>(habitatSummary);
    map['active'] = Variable<bool>(active);
    map['geometry'] = Variable<String>(geometry);
    map['length_m'] = Variable<double>(lengthM);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransectsCompanion toCompanion(bool nullToAbsent) {
    return TransectsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      code: Value(code),
      name: Value(name),
      description: Value(description),
      targetLengthM: targetLengthM == null && nullToAbsent
          ? const Value.absent()
          : Value(targetLengthM),
      habitatSummary: Value(habitatSummary),
      active: Value(active),
      geometry: Value(geometry),
      lengthM: Value(lengthM),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Transect.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transect(
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      targetLengthM: serializer.fromJson<double?>(json['targetLengthM']),
      habitatSummary: serializer.fromJson<String>(json['habitatSummary']),
      active: serializer.fromJson<bool>(json['active']),
      geometry: serializer.fromJson<String>(json['geometry']),
      lengthM: serializer.fromJson<double>(json['lengthM']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'targetLengthM': serializer.toJson<double?>(targetLengthM),
      'habitatSummary': serializer.toJson<String>(habitatSummary),
      'active': serializer.toJson<bool>(active),
      'geometry': serializer.toJson<String>(geometry),
      'lengthM': serializer.toJson<double>(lengthM),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Transect copyWith({
    String? id,
    String? projectId,
    String? code,
    String? name,
    String? description,
    Value<double?> targetLengthM = const Value.absent(),
    String? habitatSummary,
    bool? active,
    String? geometry,
    double? lengthM,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Transect(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    code: code ?? this.code,
    name: name ?? this.name,
    description: description ?? this.description,
    targetLengthM: targetLengthM.present
        ? targetLengthM.value
        : this.targetLengthM,
    habitatSummary: habitatSummary ?? this.habitatSummary,
    active: active ?? this.active,
    geometry: geometry ?? this.geometry,
    lengthM: lengthM ?? this.lengthM,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Transect copyWithCompanion(TransectsCompanion data) {
    return Transect(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      targetLengthM: data.targetLengthM.present
          ? data.targetLengthM.value
          : this.targetLengthM,
      habitatSummary: data.habitatSummary.present
          ? data.habitatSummary.value
          : this.habitatSummary,
      active: data.active.present ? data.active.value : this.active,
      geometry: data.geometry.present ? data.geometry.value : this.geometry,
      lengthM: data.lengthM.present ? data.lengthM.value : this.lengthM,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transect(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('targetLengthM: $targetLengthM, ')
          ..write('habitatSummary: $habitatSummary, ')
          ..write('active: $active, ')
          ..write('geometry: $geometry, ')
          ..write('lengthM: $lengthM, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    code,
    name,
    description,
    targetLengthM,
    habitatSummary,
    active,
    geometry,
    lengthM,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transect &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.code == this.code &&
          other.name == this.name &&
          other.description == this.description &&
          other.targetLengthM == this.targetLengthM &&
          other.habitatSummary == this.habitatSummary &&
          other.active == this.active &&
          other.geometry == this.geometry &&
          other.lengthM == this.lengthM &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class TransectsCompanion extends UpdateCompanion<Transect> {
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> code;
  final Value<String> name;
  final Value<String> description;
  final Value<double?> targetLengthM;
  final Value<String> habitatSummary;
  final Value<bool> active;
  final Value<String> geometry;
  final Value<double> lengthM;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransectsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.targetLengthM = const Value.absent(),
    this.habitatSummary = const Value.absent(),
    this.active = const Value.absent(),
    this.geometry = const Value.absent(),
    this.lengthM = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransectsCompanion.insert({
    required String id,
    required String projectId,
    required String code,
    required String name,
    required String description,
    this.targetLengthM = const Value.absent(),
    required String habitatSummary,
    required bool active,
    required String geometry,
    required double lengthM,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       code = Value(code),
       name = Value(name),
       description = Value(description),
       habitatSummary = Value(habitatSummary),
       active = Value(active),
       geometry = Value(geometry),
       lengthM = Value(lengthM);
  static Insertable<Transect> custom({
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? targetLengthM,
    Expression<String>? habitatSummary,
    Expression<bool>? active,
    Expression<String>? geometry,
    Expression<double>? lengthM,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (targetLengthM != null) 'target_length_m': targetLengthM,
      if (habitatSummary != null) 'habitat_summary': habitatSummary,
      if (active != null) 'active': active,
      if (geometry != null) 'geometry': geometry,
      if (lengthM != null) 'length_m': lengthM,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransectsCompanion copyWith({
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? code,
    Value<String>? name,
    Value<String>? description,
    Value<double?>? targetLengthM,
    Value<String>? habitatSummary,
    Value<bool>? active,
    Value<String>? geometry,
    Value<double>? lengthM,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransectsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      targetLengthM: targetLengthM ?? this.targetLengthM,
      habitatSummary: habitatSummary ?? this.habitatSummary,
      active: active ?? this.active,
      geometry: geometry ?? this.geometry,
      lengthM: lengthM ?? this.lengthM,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (targetLengthM.present) {
      map['target_length_m'] = Variable<double>(targetLengthM.value);
    }
    if (habitatSummary.present) {
      map['habitat_summary'] = Variable<String>(habitatSummary.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (geometry.present) {
      map['geometry'] = Variable<String>(geometry.value);
    }
    if (lengthM.present) {
      map['length_m'] = Variable<double>(lengthM.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransectsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('targetLengthM: $targetLengthM, ')
          ..write('habitatSummary: $habitatSummary, ')
          ..write('active: $active, ')
          ..write('geometry: $geometry, ')
          ..write('lengthM: $lengthM, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyVisitsTable extends SurveyVisits
    with TableInfo<$SurveyVisitsTable, SurveyVisit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyVisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncStatus, String> syncStatus =
      GeneratedColumn<String>(
        'sync_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncStatus.pending.name),
      ).withConverter<SyncStatus>($SurveyVisitsTable.$convertersyncStatus);
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES project (id)',
    ),
  );
  static const VerificationMeta _transectIdMeta = const VerificationMeta(
    'transectId',
  );
  @override
  late final GeneratedColumn<String> transectId = GeneratedColumn<String>(
    'transect_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transect (id)',
    ),
  );
  static const VerificationMeta _observerIdMeta = const VerificationMeta(
    'observerId',
  );
  @override
  late final GeneratedColumn<String> observerId = GeneratedColumn<String>(
    'observer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  @override
  late final GeneratedColumn<String> protocolVersion = GeneratedColumn<String>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surveyMethodMeta = const VerificationMeta(
    'surveyMethod',
  );
  @override
  late final GeneratedColumn<String> surveyMethod = GeneratedColumn<String>(
    'survey_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pollard_walk'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedSecondsMeta = const VerificationMeta(
    'pausedSeconds',
  );
  @override
  late final GeneratedColumn<int> pausedSeconds = GeneratedColumn<int>(
    'paused_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceWalkedMMeta = const VerificationMeta(
    'distanceWalkedM',
  );
  @override
  late final GeneratedColumn<double> distanceWalkedM = GeneratedColumn<double>(
    'distance_walked_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observerCountMeta = const VerificationMeta(
    'observerCount',
  );
  @override
  late final GeneratedColumn<int> observerCount = GeneratedColumn<int>(
    'observer_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _observerNamesMeta = const VerificationMeta(
    'observerNames',
  );
  @override
  late final GeneratedColumn<String> observerNames = GeneratedColumn<String>(
    'observer_names',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _temperatureStartCMeta = const VerificationMeta(
    'temperatureStartC',
  );
  @override
  late final GeneratedColumn<double> temperatureStartC =
      GeneratedColumn<double>(
        'temperature_start_c',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _temperatureEndCMeta = const VerificationMeta(
    'temperatureEndC',
  );
  @override
  late final GeneratedColumn<double> temperatureEndC = GeneratedColumn<double>(
    'temperature_end_c',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windBeaufortStartMeta = const VerificationMeta(
    'windBeaufortStart',
  );
  @override
  late final GeneratedColumn<int> windBeaufortStart = GeneratedColumn<int>(
    'wind_beaufort_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windBeaufortEndMeta = const VerificationMeta(
    'windBeaufortEnd',
  );
  @override
  late final GeneratedColumn<int> windBeaufortEnd = GeneratedColumn<int>(
    'wind_beaufort_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudCoverStartPctMeta =
      const VerificationMeta('cloudCoverStartPct');
  @override
  late final GeneratedColumn<int> cloudCoverStartPct = GeneratedColumn<int>(
    'cloud_cover_start_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudCoverEndPctMeta = const VerificationMeta(
    'cloudCoverEndPct',
  );
  @override
  late final GeneratedColumn<int> cloudCoverEndPct = GeneratedColumn<int>(
    'cloud_cover_end_pct',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precipitationMeta = const VerificationMeta(
    'precipitation',
  );
  @override
  late final GeneratedColumn<String> precipitation = GeneratedColumn<String>(
    'precipitation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _weatherSuitableMeta = const VerificationMeta(
    'weatherSuitable',
  );
  @override
  late final GeneratedColumn<bool> weatherSuitable = GeneratedColumn<bool>(
    'weather_suitable',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("weather_suitable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _weatherMissingReasonMeta =
      const VerificationMeta('weatherMissingReason');
  @override
  late final GeneratedColumn<String> weatherMissingReason =
      GeneratedColumn<String>(
        'weather_missing_reason',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _zeroObservationConfirmedMeta =
      const VerificationMeta('zeroObservationConfirmed');
  @override
  late final GeneratedColumn<bool> zeroObservationConfirmed =
      GeneratedColumn<bool>(
        'zero_observation_confirmed',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("zero_observation_confirmed" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _batterySaverUsedMeta = const VerificationMeta(
    'batterySaverUsed',
  );
  @override
  late final GeneratedColumn<bool> batterySaverUsed = GeneratedColumn<bool>(
    'battery_saver_used',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("battery_saver_used" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdOfflineMeta = const VerificationMeta(
    'createdOffline',
  );
  @override
  late final GeneratedColumn<bool> createdOffline = GeneratedColumn<bool>(
    'created_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("created_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    serverVersion,
    syncStatus,
    deletedAt,
    id,
    projectId,
    transectId,
    observerId,
    protocolVersion,
    surveyMethod,
    startedAt,
    endedAt,
    durationSeconds,
    pausedSeconds,
    distanceWalkedM,
    observerCount,
    observerNames,
    temperatureStartC,
    temperatureEndC,
    windBeaufortStart,
    windBeaufortEnd,
    cloudCoverStartPct,
    cloudCoverEndPct,
    precipitation,
    weatherSuitable,
    weatherMissingReason,
    zeroObservationConfirmed,
    notes,
    status,
    cancelReason,
    batterySaverUsed,
    deviceId,
    createdOffline,
    createdAt,
    pausedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_visit';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurveyVisit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('transect_id')) {
      context.handle(
        _transectIdMeta,
        transectId.isAcceptableOrUnknown(data['transect_id']!, _transectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transectIdMeta);
    }
    if (data.containsKey('observer_id')) {
      context.handle(
        _observerIdMeta,
        observerId.isAcceptableOrUnknown(data['observer_id']!, _observerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_observerIdMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionMeta);
    }
    if (data.containsKey('survey_method')) {
      context.handle(
        _surveyMethodMeta,
        surveyMethod.isAcceptableOrUnknown(
          data['survey_method']!,
          _surveyMethodMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('paused_seconds')) {
      context.handle(
        _pausedSecondsMeta,
        pausedSeconds.isAcceptableOrUnknown(
          data['paused_seconds']!,
          _pausedSecondsMeta,
        ),
      );
    }
    if (data.containsKey('distance_walked_m')) {
      context.handle(
        _distanceWalkedMMeta,
        distanceWalkedM.isAcceptableOrUnknown(
          data['distance_walked_m']!,
          _distanceWalkedMMeta,
        ),
      );
    }
    if (data.containsKey('observer_count')) {
      context.handle(
        _observerCountMeta,
        observerCount.isAcceptableOrUnknown(
          data['observer_count']!,
          _observerCountMeta,
        ),
      );
    }
    if (data.containsKey('observer_names')) {
      context.handle(
        _observerNamesMeta,
        observerNames.isAcceptableOrUnknown(
          data['observer_names']!,
          _observerNamesMeta,
        ),
      );
    }
    if (data.containsKey('temperature_start_c')) {
      context.handle(
        _temperatureStartCMeta,
        temperatureStartC.isAcceptableOrUnknown(
          data['temperature_start_c']!,
          _temperatureStartCMeta,
        ),
      );
    }
    if (data.containsKey('temperature_end_c')) {
      context.handle(
        _temperatureEndCMeta,
        temperatureEndC.isAcceptableOrUnknown(
          data['temperature_end_c']!,
          _temperatureEndCMeta,
        ),
      );
    }
    if (data.containsKey('wind_beaufort_start')) {
      context.handle(
        _windBeaufortStartMeta,
        windBeaufortStart.isAcceptableOrUnknown(
          data['wind_beaufort_start']!,
          _windBeaufortStartMeta,
        ),
      );
    }
    if (data.containsKey('wind_beaufort_end')) {
      context.handle(
        _windBeaufortEndMeta,
        windBeaufortEnd.isAcceptableOrUnknown(
          data['wind_beaufort_end']!,
          _windBeaufortEndMeta,
        ),
      );
    }
    if (data.containsKey('cloud_cover_start_pct')) {
      context.handle(
        _cloudCoverStartPctMeta,
        cloudCoverStartPct.isAcceptableOrUnknown(
          data['cloud_cover_start_pct']!,
          _cloudCoverStartPctMeta,
        ),
      );
    }
    if (data.containsKey('cloud_cover_end_pct')) {
      context.handle(
        _cloudCoverEndPctMeta,
        cloudCoverEndPct.isAcceptableOrUnknown(
          data['cloud_cover_end_pct']!,
          _cloudCoverEndPctMeta,
        ),
      );
    }
    if (data.containsKey('precipitation')) {
      context.handle(
        _precipitationMeta,
        precipitation.isAcceptableOrUnknown(
          data['precipitation']!,
          _precipitationMeta,
        ),
      );
    }
    if (data.containsKey('weather_suitable')) {
      context.handle(
        _weatherSuitableMeta,
        weatherSuitable.isAcceptableOrUnknown(
          data['weather_suitable']!,
          _weatherSuitableMeta,
        ),
      );
    }
    if (data.containsKey('weather_missing_reason')) {
      context.handle(
        _weatherMissingReasonMeta,
        weatherMissingReason.isAcceptableOrUnknown(
          data['weather_missing_reason']!,
          _weatherMissingReasonMeta,
        ),
      );
    }
    if (data.containsKey('zero_observation_confirmed')) {
      context.handle(
        _zeroObservationConfirmedMeta,
        zeroObservationConfirmed.isAcceptableOrUnknown(
          data['zero_observation_confirmed']!,
          _zeroObservationConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('battery_saver_used')) {
      context.handle(
        _batterySaverUsedMeta,
        batterySaverUsed.isAcceptableOrUnknown(
          data['battery_saver_used']!,
          _batterySaverUsedMeta,
        ),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('created_offline')) {
      context.handle(
        _createdOfflineMeta,
        createdOffline.isAcceptableOrUnknown(
          data['created_offline']!,
          _createdOfflineMeta,
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
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyVisit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyVisit(
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      syncStatus: $SurveyVisitsTable.$convertersyncStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_status'],
        )!,
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      transectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transect_id'],
      )!,
      observerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observer_id'],
      )!,
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_version'],
      )!,
      surveyMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}survey_method'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      pausedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_seconds'],
      )!,
      distanceWalkedM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_walked_m'],
      ),
      observerCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observer_count'],
      )!,
      observerNames: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observer_names'],
      )!,
      temperatureStartC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_start_c'],
      ),
      temperatureEndC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_end_c'],
      ),
      windBeaufortStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wind_beaufort_start'],
      ),
      windBeaufortEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wind_beaufort_end'],
      ),
      cloudCoverStartPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_cover_start_pct'],
      ),
      cloudCoverEndPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cloud_cover_end_pct'],
      ),
      precipitation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}precipitation'],
      )!,
      weatherSuitable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}weather_suitable'],
      ),
      weatherMissingReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weather_missing_reason'],
      )!,
      zeroObservationConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}zero_observation_confirmed'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      )!,
      batterySaverUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}battery_saver_used'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      createdOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}created_offline'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paused_at'],
      ),
    );
  }

  @override
  $SurveyVisitsTable createAlias(String alias) {
    return $SurveyVisitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncStatus, String, String> $convertersyncStatus =
      const EnumNameConverter<SyncStatus>(SyncStatus.values);
}

class SurveyVisit extends DataClass implements Insertable<SurveyVisit> {
  /// Version the server last gave this row; null until pushed.
  final int? serverVersion;
  final SyncStatus syncStatus;

  /// Set by a soft delete.
  final DateTime? deletedAt;
  final String id;
  final String projectId;
  final String transectId;
  final String observerId;
  final String protocolVersion;
  final String surveyMethod;
  final DateTime? startedAt;
  final DateTime? endedAt;

  /// Walking time without pauses.
  final int? durationSeconds;
  final int pausedSeconds;

  /// Computed by the server from the track (T036); the phone never sends it.
  final double? distanceWalkedM;
  final int observerCount;
  final String observerNames;
  final double? temperatureStartC;
  final double? temperatureEndC;
  final int? windBeaufortStart;
  final int? windBeaufortEnd;
  final int? cloudCoverStartPct;
  final int? cloudCoverEndPct;
  final String precipitation;
  final bool? weatherSuitable;
  final String weatherMissingReason;
  final bool zeroObservationConfirmed;
  final String notes;
  final String status;

  /// Set exactly when `status` is `cancelled`, empty otherwise.
  final String cancelReason;
  final bool batterySaverUsed;
  final String deviceId;
  final bool createdOffline;
  final DateTime createdAt;

  /// Local only: when the current pause began, null while walking.
  final DateTime? pausedAt;
  const SurveyVisit({
    this.serverVersion,
    required this.syncStatus,
    this.deletedAt,
    required this.id,
    required this.projectId,
    required this.transectId,
    required this.observerId,
    required this.protocolVersion,
    required this.surveyMethod,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.pausedSeconds,
    this.distanceWalkedM,
    required this.observerCount,
    required this.observerNames,
    this.temperatureStartC,
    this.temperatureEndC,
    this.windBeaufortStart,
    this.windBeaufortEnd,
    this.cloudCoverStartPct,
    this.cloudCoverEndPct,
    required this.precipitation,
    this.weatherSuitable,
    required this.weatherMissingReason,
    required this.zeroObservationConfirmed,
    required this.notes,
    required this.status,
    required this.cancelReason,
    required this.batterySaverUsed,
    required this.deviceId,
    required this.createdOffline,
    required this.createdAt,
    this.pausedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    {
      map['sync_status'] = Variable<String>(
        $SurveyVisitsTable.$convertersyncStatus.toSql(syncStatus),
      );
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['transect_id'] = Variable<String>(transectId);
    map['observer_id'] = Variable<String>(observerId);
    map['protocol_version'] = Variable<String>(protocolVersion);
    map['survey_method'] = Variable<String>(surveyMethod);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['paused_seconds'] = Variable<int>(pausedSeconds);
    if (!nullToAbsent || distanceWalkedM != null) {
      map['distance_walked_m'] = Variable<double>(distanceWalkedM);
    }
    map['observer_count'] = Variable<int>(observerCount);
    map['observer_names'] = Variable<String>(observerNames);
    if (!nullToAbsent || temperatureStartC != null) {
      map['temperature_start_c'] = Variable<double>(temperatureStartC);
    }
    if (!nullToAbsent || temperatureEndC != null) {
      map['temperature_end_c'] = Variable<double>(temperatureEndC);
    }
    if (!nullToAbsent || windBeaufortStart != null) {
      map['wind_beaufort_start'] = Variable<int>(windBeaufortStart);
    }
    if (!nullToAbsent || windBeaufortEnd != null) {
      map['wind_beaufort_end'] = Variable<int>(windBeaufortEnd);
    }
    if (!nullToAbsent || cloudCoverStartPct != null) {
      map['cloud_cover_start_pct'] = Variable<int>(cloudCoverStartPct);
    }
    if (!nullToAbsent || cloudCoverEndPct != null) {
      map['cloud_cover_end_pct'] = Variable<int>(cloudCoverEndPct);
    }
    map['precipitation'] = Variable<String>(precipitation);
    if (!nullToAbsent || weatherSuitable != null) {
      map['weather_suitable'] = Variable<bool>(weatherSuitable);
    }
    map['weather_missing_reason'] = Variable<String>(weatherMissingReason);
    map['zero_observation_confirmed'] = Variable<bool>(
      zeroObservationConfirmed,
    );
    map['notes'] = Variable<String>(notes);
    map['status'] = Variable<String>(status);
    map['cancel_reason'] = Variable<String>(cancelReason);
    map['battery_saver_used'] = Variable<bool>(batterySaverUsed);
    map['device_id'] = Variable<String>(deviceId);
    map['created_offline'] = Variable<bool>(createdOffline);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    return map;
  }

  SurveyVisitsCompanion toCompanion(bool nullToAbsent) {
    return SurveyVisitsCompanion(
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      syncStatus: Value(syncStatus),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      id: Value(id),
      projectId: Value(projectId),
      transectId: Value(transectId),
      observerId: Value(observerId),
      protocolVersion: Value(protocolVersion),
      surveyMethod: Value(surveyMethod),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      pausedSeconds: Value(pausedSeconds),
      distanceWalkedM: distanceWalkedM == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceWalkedM),
      observerCount: Value(observerCount),
      observerNames: Value(observerNames),
      temperatureStartC: temperatureStartC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureStartC),
      temperatureEndC: temperatureEndC == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureEndC),
      windBeaufortStart: windBeaufortStart == null && nullToAbsent
          ? const Value.absent()
          : Value(windBeaufortStart),
      windBeaufortEnd: windBeaufortEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(windBeaufortEnd),
      cloudCoverStartPct: cloudCoverStartPct == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudCoverStartPct),
      cloudCoverEndPct: cloudCoverEndPct == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudCoverEndPct),
      precipitation: Value(precipitation),
      weatherSuitable: weatherSuitable == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherSuitable),
      weatherMissingReason: Value(weatherMissingReason),
      zeroObservationConfirmed: Value(zeroObservationConfirmed),
      notes: Value(notes),
      status: Value(status),
      cancelReason: Value(cancelReason),
      batterySaverUsed: Value(batterySaverUsed),
      deviceId: Value(deviceId),
      createdOffline: Value(createdOffline),
      createdAt: Value(createdAt),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
    );
  }

  factory SurveyVisit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyVisit(
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      syncStatus: $SurveyVisitsTable.$convertersyncStatus.fromJson(
        serializer.fromJson<String>(json['syncStatus']),
      ),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      transectId: serializer.fromJson<String>(json['transectId']),
      observerId: serializer.fromJson<String>(json['observerId']),
      protocolVersion: serializer.fromJson<String>(json['protocolVersion']),
      surveyMethod: serializer.fromJson<String>(json['surveyMethod']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      pausedSeconds: serializer.fromJson<int>(json['pausedSeconds']),
      distanceWalkedM: serializer.fromJson<double?>(json['distanceWalkedM']),
      observerCount: serializer.fromJson<int>(json['observerCount']),
      observerNames: serializer.fromJson<String>(json['observerNames']),
      temperatureStartC: serializer.fromJson<double?>(
        json['temperatureStartC'],
      ),
      temperatureEndC: serializer.fromJson<double?>(json['temperatureEndC']),
      windBeaufortStart: serializer.fromJson<int?>(json['windBeaufortStart']),
      windBeaufortEnd: serializer.fromJson<int?>(json['windBeaufortEnd']),
      cloudCoverStartPct: serializer.fromJson<int?>(json['cloudCoverStartPct']),
      cloudCoverEndPct: serializer.fromJson<int?>(json['cloudCoverEndPct']),
      precipitation: serializer.fromJson<String>(json['precipitation']),
      weatherSuitable: serializer.fromJson<bool?>(json['weatherSuitable']),
      weatherMissingReason: serializer.fromJson<String>(
        json['weatherMissingReason'],
      ),
      zeroObservationConfirmed: serializer.fromJson<bool>(
        json['zeroObservationConfirmed'],
      ),
      notes: serializer.fromJson<String>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      cancelReason: serializer.fromJson<String>(json['cancelReason']),
      batterySaverUsed: serializer.fromJson<bool>(json['batterySaverUsed']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdOffline: serializer.fromJson<bool>(json['createdOffline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'syncStatus': serializer.toJson<String>(
        $SurveyVisitsTable.$convertersyncStatus.toJson(syncStatus),
      ),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'transectId': serializer.toJson<String>(transectId),
      'observerId': serializer.toJson<String>(observerId),
      'protocolVersion': serializer.toJson<String>(protocolVersion),
      'surveyMethod': serializer.toJson<String>(surveyMethod),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'pausedSeconds': serializer.toJson<int>(pausedSeconds),
      'distanceWalkedM': serializer.toJson<double?>(distanceWalkedM),
      'observerCount': serializer.toJson<int>(observerCount),
      'observerNames': serializer.toJson<String>(observerNames),
      'temperatureStartC': serializer.toJson<double?>(temperatureStartC),
      'temperatureEndC': serializer.toJson<double?>(temperatureEndC),
      'windBeaufortStart': serializer.toJson<int?>(windBeaufortStart),
      'windBeaufortEnd': serializer.toJson<int?>(windBeaufortEnd),
      'cloudCoverStartPct': serializer.toJson<int?>(cloudCoverStartPct),
      'cloudCoverEndPct': serializer.toJson<int?>(cloudCoverEndPct),
      'precipitation': serializer.toJson<String>(precipitation),
      'weatherSuitable': serializer.toJson<bool?>(weatherSuitable),
      'weatherMissingReason': serializer.toJson<String>(weatherMissingReason),
      'zeroObservationConfirmed': serializer.toJson<bool>(
        zeroObservationConfirmed,
      ),
      'notes': serializer.toJson<String>(notes),
      'status': serializer.toJson<String>(status),
      'cancelReason': serializer.toJson<String>(cancelReason),
      'batterySaverUsed': serializer.toJson<bool>(batterySaverUsed),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdOffline': serializer.toJson<bool>(createdOffline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
    };
  }

  SurveyVisit copyWith({
    Value<int?> serverVersion = const Value.absent(),
    SyncStatus? syncStatus,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? id,
    String? projectId,
    String? transectId,
    String? observerId,
    String? protocolVersion,
    String? surveyMethod,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    int? pausedSeconds,
    Value<double?> distanceWalkedM = const Value.absent(),
    int? observerCount,
    String? observerNames,
    Value<double?> temperatureStartC = const Value.absent(),
    Value<double?> temperatureEndC = const Value.absent(),
    Value<int?> windBeaufortStart = const Value.absent(),
    Value<int?> windBeaufortEnd = const Value.absent(),
    Value<int?> cloudCoverStartPct = const Value.absent(),
    Value<int?> cloudCoverEndPct = const Value.absent(),
    String? precipitation,
    Value<bool?> weatherSuitable = const Value.absent(),
    String? weatherMissingReason,
    bool? zeroObservationConfirmed,
    String? notes,
    String? status,
    String? cancelReason,
    bool? batterySaverUsed,
    String? deviceId,
    bool? createdOffline,
    DateTime? createdAt,
    Value<DateTime?> pausedAt = const Value.absent(),
  }) => SurveyVisit(
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    syncStatus: syncStatus ?? this.syncStatus,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    transectId: transectId ?? this.transectId,
    observerId: observerId ?? this.observerId,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    surveyMethod: surveyMethod ?? this.surveyMethod,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    pausedSeconds: pausedSeconds ?? this.pausedSeconds,
    distanceWalkedM: distanceWalkedM.present
        ? distanceWalkedM.value
        : this.distanceWalkedM,
    observerCount: observerCount ?? this.observerCount,
    observerNames: observerNames ?? this.observerNames,
    temperatureStartC: temperatureStartC.present
        ? temperatureStartC.value
        : this.temperatureStartC,
    temperatureEndC: temperatureEndC.present
        ? temperatureEndC.value
        : this.temperatureEndC,
    windBeaufortStart: windBeaufortStart.present
        ? windBeaufortStart.value
        : this.windBeaufortStart,
    windBeaufortEnd: windBeaufortEnd.present
        ? windBeaufortEnd.value
        : this.windBeaufortEnd,
    cloudCoverStartPct: cloudCoverStartPct.present
        ? cloudCoverStartPct.value
        : this.cloudCoverStartPct,
    cloudCoverEndPct: cloudCoverEndPct.present
        ? cloudCoverEndPct.value
        : this.cloudCoverEndPct,
    precipitation: precipitation ?? this.precipitation,
    weatherSuitable: weatherSuitable.present
        ? weatherSuitable.value
        : this.weatherSuitable,
    weatherMissingReason: weatherMissingReason ?? this.weatherMissingReason,
    zeroObservationConfirmed:
        zeroObservationConfirmed ?? this.zeroObservationConfirmed,
    notes: notes ?? this.notes,
    status: status ?? this.status,
    cancelReason: cancelReason ?? this.cancelReason,
    batterySaverUsed: batterySaverUsed ?? this.batterySaverUsed,
    deviceId: deviceId ?? this.deviceId,
    createdOffline: createdOffline ?? this.createdOffline,
    createdAt: createdAt ?? this.createdAt,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
  );
  SurveyVisit copyWithCompanion(SurveyVisitsCompanion data) {
    return SurveyVisit(
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      transectId: data.transectId.present
          ? data.transectId.value
          : this.transectId,
      observerId: data.observerId.present
          ? data.observerId.value
          : this.observerId,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      surveyMethod: data.surveyMethod.present
          ? data.surveyMethod.value
          : this.surveyMethod,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      pausedSeconds: data.pausedSeconds.present
          ? data.pausedSeconds.value
          : this.pausedSeconds,
      distanceWalkedM: data.distanceWalkedM.present
          ? data.distanceWalkedM.value
          : this.distanceWalkedM,
      observerCount: data.observerCount.present
          ? data.observerCount.value
          : this.observerCount,
      observerNames: data.observerNames.present
          ? data.observerNames.value
          : this.observerNames,
      temperatureStartC: data.temperatureStartC.present
          ? data.temperatureStartC.value
          : this.temperatureStartC,
      temperatureEndC: data.temperatureEndC.present
          ? data.temperatureEndC.value
          : this.temperatureEndC,
      windBeaufortStart: data.windBeaufortStart.present
          ? data.windBeaufortStart.value
          : this.windBeaufortStart,
      windBeaufortEnd: data.windBeaufortEnd.present
          ? data.windBeaufortEnd.value
          : this.windBeaufortEnd,
      cloudCoverStartPct: data.cloudCoverStartPct.present
          ? data.cloudCoverStartPct.value
          : this.cloudCoverStartPct,
      cloudCoverEndPct: data.cloudCoverEndPct.present
          ? data.cloudCoverEndPct.value
          : this.cloudCoverEndPct,
      precipitation: data.precipitation.present
          ? data.precipitation.value
          : this.precipitation,
      weatherSuitable: data.weatherSuitable.present
          ? data.weatherSuitable.value
          : this.weatherSuitable,
      weatherMissingReason: data.weatherMissingReason.present
          ? data.weatherMissingReason.value
          : this.weatherMissingReason,
      zeroObservationConfirmed: data.zeroObservationConfirmed.present
          ? data.zeroObservationConfirmed.value
          : this.zeroObservationConfirmed,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      batterySaverUsed: data.batterySaverUsed.present
          ? data.batterySaverUsed.value
          : this.batterySaverUsed,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdOffline: data.createdOffline.present
          ? data.createdOffline.value
          : this.createdOffline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyVisit(')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('transectId: $transectId, ')
          ..write('observerId: $observerId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('surveyMethod: $surveyMethod, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('distanceWalkedM: $distanceWalkedM, ')
          ..write('observerCount: $observerCount, ')
          ..write('observerNames: $observerNames, ')
          ..write('temperatureStartC: $temperatureStartC, ')
          ..write('temperatureEndC: $temperatureEndC, ')
          ..write('windBeaufortStart: $windBeaufortStart, ')
          ..write('windBeaufortEnd: $windBeaufortEnd, ')
          ..write('cloudCoverStartPct: $cloudCoverStartPct, ')
          ..write('cloudCoverEndPct: $cloudCoverEndPct, ')
          ..write('precipitation: $precipitation, ')
          ..write('weatherSuitable: $weatherSuitable, ')
          ..write('weatherMissingReason: $weatherMissingReason, ')
          ..write('zeroObservationConfirmed: $zeroObservationConfirmed, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('batterySaverUsed: $batterySaverUsed, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdOffline: $createdOffline, ')
          ..write('createdAt: $createdAt, ')
          ..write('pausedAt: $pausedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    serverVersion,
    syncStatus,
    deletedAt,
    id,
    projectId,
    transectId,
    observerId,
    protocolVersion,
    surveyMethod,
    startedAt,
    endedAt,
    durationSeconds,
    pausedSeconds,
    distanceWalkedM,
    observerCount,
    observerNames,
    temperatureStartC,
    temperatureEndC,
    windBeaufortStart,
    windBeaufortEnd,
    cloudCoverStartPct,
    cloudCoverEndPct,
    precipitation,
    weatherSuitable,
    weatherMissingReason,
    zeroObservationConfirmed,
    notes,
    status,
    cancelReason,
    batterySaverUsed,
    deviceId,
    createdOffline,
    createdAt,
    pausedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyVisit &&
          other.serverVersion == this.serverVersion &&
          other.syncStatus == this.syncStatus &&
          other.deletedAt == this.deletedAt &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.transectId == this.transectId &&
          other.observerId == this.observerId &&
          other.protocolVersion == this.protocolVersion &&
          other.surveyMethod == this.surveyMethod &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.pausedSeconds == this.pausedSeconds &&
          other.distanceWalkedM == this.distanceWalkedM &&
          other.observerCount == this.observerCount &&
          other.observerNames == this.observerNames &&
          other.temperatureStartC == this.temperatureStartC &&
          other.temperatureEndC == this.temperatureEndC &&
          other.windBeaufortStart == this.windBeaufortStart &&
          other.windBeaufortEnd == this.windBeaufortEnd &&
          other.cloudCoverStartPct == this.cloudCoverStartPct &&
          other.cloudCoverEndPct == this.cloudCoverEndPct &&
          other.precipitation == this.precipitation &&
          other.weatherSuitable == this.weatherSuitable &&
          other.weatherMissingReason == this.weatherMissingReason &&
          other.zeroObservationConfirmed == this.zeroObservationConfirmed &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.cancelReason == this.cancelReason &&
          other.batterySaverUsed == this.batterySaverUsed &&
          other.deviceId == this.deviceId &&
          other.createdOffline == this.createdOffline &&
          other.createdAt == this.createdAt &&
          other.pausedAt == this.pausedAt);
}

class SurveyVisitsCompanion extends UpdateCompanion<SurveyVisit> {
  final Value<int?> serverVersion;
  final Value<SyncStatus> syncStatus;
  final Value<DateTime?> deletedAt;
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> transectId;
  final Value<String> observerId;
  final Value<String> protocolVersion;
  final Value<String> surveyMethod;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int?> durationSeconds;
  final Value<int> pausedSeconds;
  final Value<double?> distanceWalkedM;
  final Value<int> observerCount;
  final Value<String> observerNames;
  final Value<double?> temperatureStartC;
  final Value<double?> temperatureEndC;
  final Value<int?> windBeaufortStart;
  final Value<int?> windBeaufortEnd;
  final Value<int?> cloudCoverStartPct;
  final Value<int?> cloudCoverEndPct;
  final Value<String> precipitation;
  final Value<bool?> weatherSuitable;
  final Value<String> weatherMissingReason;
  final Value<bool> zeroObservationConfirmed;
  final Value<String> notes;
  final Value<String> status;
  final Value<String> cancelReason;
  final Value<bool> batterySaverUsed;
  final Value<String> deviceId;
  final Value<bool> createdOffline;
  final Value<DateTime> createdAt;
  final Value<DateTime?> pausedAt;
  final Value<int> rowid;
  const SurveyVisitsCompanion({
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.transectId = const Value.absent(),
    this.observerId = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.surveyMethod = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.distanceWalkedM = const Value.absent(),
    this.observerCount = const Value.absent(),
    this.observerNames = const Value.absent(),
    this.temperatureStartC = const Value.absent(),
    this.temperatureEndC = const Value.absent(),
    this.windBeaufortStart = const Value.absent(),
    this.windBeaufortEnd = const Value.absent(),
    this.cloudCoverStartPct = const Value.absent(),
    this.cloudCoverEndPct = const Value.absent(),
    this.precipitation = const Value.absent(),
    this.weatherSuitable = const Value.absent(),
    this.weatherMissingReason = const Value.absent(),
    this.zeroObservationConfirmed = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.batterySaverUsed = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdOffline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyVisitsCompanion.insert({
    this.serverVersion = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String id,
    required String projectId,
    required String transectId,
    required String observerId,
    required String protocolVersion,
    this.surveyMethod = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.pausedSeconds = const Value.absent(),
    this.distanceWalkedM = const Value.absent(),
    this.observerCount = const Value.absent(),
    this.observerNames = const Value.absent(),
    this.temperatureStartC = const Value.absent(),
    this.temperatureEndC = const Value.absent(),
    this.windBeaufortStart = const Value.absent(),
    this.windBeaufortEnd = const Value.absent(),
    this.cloudCoverStartPct = const Value.absent(),
    this.cloudCoverEndPct = const Value.absent(),
    this.precipitation = const Value.absent(),
    this.weatherSuitable = const Value.absent(),
    this.weatherMissingReason = const Value.absent(),
    this.zeroObservationConfirmed = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.batterySaverUsed = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdOffline = const Value.absent(),
    required DateTime createdAt,
    this.pausedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       transectId = Value(transectId),
       observerId = Value(observerId),
       protocolVersion = Value(protocolVersion),
       createdAt = Value(createdAt);
  static Insertable<SurveyVisit> custom({
    Expression<int>? serverVersion,
    Expression<String>? syncStatus,
    Expression<DateTime>? deletedAt,
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? transectId,
    Expression<String>? observerId,
    Expression<String>? protocolVersion,
    Expression<String>? surveyMethod,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationSeconds,
    Expression<int>? pausedSeconds,
    Expression<double>? distanceWalkedM,
    Expression<int>? observerCount,
    Expression<String>? observerNames,
    Expression<double>? temperatureStartC,
    Expression<double>? temperatureEndC,
    Expression<int>? windBeaufortStart,
    Expression<int>? windBeaufortEnd,
    Expression<int>? cloudCoverStartPct,
    Expression<int>? cloudCoverEndPct,
    Expression<String>? precipitation,
    Expression<bool>? weatherSuitable,
    Expression<String>? weatherMissingReason,
    Expression<bool>? zeroObservationConfirmed,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? cancelReason,
    Expression<bool>? batterySaverUsed,
    Expression<String>? deviceId,
    Expression<bool>? createdOffline,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? pausedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (serverVersion != null) 'server_version': serverVersion,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (transectId != null) 'transect_id': transectId,
      if (observerId != null) 'observer_id': observerId,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (surveyMethod != null) 'survey_method': surveyMethod,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (pausedSeconds != null) 'paused_seconds': pausedSeconds,
      if (distanceWalkedM != null) 'distance_walked_m': distanceWalkedM,
      if (observerCount != null) 'observer_count': observerCount,
      if (observerNames != null) 'observer_names': observerNames,
      if (temperatureStartC != null) 'temperature_start_c': temperatureStartC,
      if (temperatureEndC != null) 'temperature_end_c': temperatureEndC,
      if (windBeaufortStart != null) 'wind_beaufort_start': windBeaufortStart,
      if (windBeaufortEnd != null) 'wind_beaufort_end': windBeaufortEnd,
      if (cloudCoverStartPct != null)
        'cloud_cover_start_pct': cloudCoverStartPct,
      if (cloudCoverEndPct != null) 'cloud_cover_end_pct': cloudCoverEndPct,
      if (precipitation != null) 'precipitation': precipitation,
      if (weatherSuitable != null) 'weather_suitable': weatherSuitable,
      if (weatherMissingReason != null)
        'weather_missing_reason': weatherMissingReason,
      if (zeroObservationConfirmed != null)
        'zero_observation_confirmed': zeroObservationConfirmed,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (batterySaverUsed != null) 'battery_saver_used': batterySaverUsed,
      if (deviceId != null) 'device_id': deviceId,
      if (createdOffline != null) 'created_offline': createdOffline,
      if (createdAt != null) 'created_at': createdAt,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyVisitsCompanion copyWith({
    Value<int?>? serverVersion,
    Value<SyncStatus>? syncStatus,
    Value<DateTime?>? deletedAt,
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? transectId,
    Value<String>? observerId,
    Value<String>? protocolVersion,
    Value<String>? surveyMethod,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int?>? durationSeconds,
    Value<int>? pausedSeconds,
    Value<double?>? distanceWalkedM,
    Value<int>? observerCount,
    Value<String>? observerNames,
    Value<double?>? temperatureStartC,
    Value<double?>? temperatureEndC,
    Value<int?>? windBeaufortStart,
    Value<int?>? windBeaufortEnd,
    Value<int?>? cloudCoverStartPct,
    Value<int?>? cloudCoverEndPct,
    Value<String>? precipitation,
    Value<bool?>? weatherSuitable,
    Value<String>? weatherMissingReason,
    Value<bool>? zeroObservationConfirmed,
    Value<String>? notes,
    Value<String>? status,
    Value<String>? cancelReason,
    Value<bool>? batterySaverUsed,
    Value<String>? deviceId,
    Value<bool>? createdOffline,
    Value<DateTime>? createdAt,
    Value<DateTime?>? pausedAt,
    Value<int>? rowid,
  }) {
    return SurveyVisitsCompanion(
      serverVersion: serverVersion ?? this.serverVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      transectId: transectId ?? this.transectId,
      observerId: observerId ?? this.observerId,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      surveyMethod: surveyMethod ?? this.surveyMethod,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
      distanceWalkedM: distanceWalkedM ?? this.distanceWalkedM,
      observerCount: observerCount ?? this.observerCount,
      observerNames: observerNames ?? this.observerNames,
      temperatureStartC: temperatureStartC ?? this.temperatureStartC,
      temperatureEndC: temperatureEndC ?? this.temperatureEndC,
      windBeaufortStart: windBeaufortStart ?? this.windBeaufortStart,
      windBeaufortEnd: windBeaufortEnd ?? this.windBeaufortEnd,
      cloudCoverStartPct: cloudCoverStartPct ?? this.cloudCoverStartPct,
      cloudCoverEndPct: cloudCoverEndPct ?? this.cloudCoverEndPct,
      precipitation: precipitation ?? this.precipitation,
      weatherSuitable: weatherSuitable ?? this.weatherSuitable,
      weatherMissingReason: weatherMissingReason ?? this.weatherMissingReason,
      zeroObservationConfirmed:
          zeroObservationConfirmed ?? this.zeroObservationConfirmed,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      batterySaverUsed: batterySaverUsed ?? this.batterySaverUsed,
      deviceId: deviceId ?? this.deviceId,
      createdOffline: createdOffline ?? this.createdOffline,
      createdAt: createdAt ?? this.createdAt,
      pausedAt: pausedAt ?? this.pausedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(
        $SurveyVisitsTable.$convertersyncStatus.toSql(syncStatus.value),
      );
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (transectId.present) {
      map['transect_id'] = Variable<String>(transectId.value);
    }
    if (observerId.present) {
      map['observer_id'] = Variable<String>(observerId.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<String>(protocolVersion.value);
    }
    if (surveyMethod.present) {
      map['survey_method'] = Variable<String>(surveyMethod.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (pausedSeconds.present) {
      map['paused_seconds'] = Variable<int>(pausedSeconds.value);
    }
    if (distanceWalkedM.present) {
      map['distance_walked_m'] = Variable<double>(distanceWalkedM.value);
    }
    if (observerCount.present) {
      map['observer_count'] = Variable<int>(observerCount.value);
    }
    if (observerNames.present) {
      map['observer_names'] = Variable<String>(observerNames.value);
    }
    if (temperatureStartC.present) {
      map['temperature_start_c'] = Variable<double>(temperatureStartC.value);
    }
    if (temperatureEndC.present) {
      map['temperature_end_c'] = Variable<double>(temperatureEndC.value);
    }
    if (windBeaufortStart.present) {
      map['wind_beaufort_start'] = Variable<int>(windBeaufortStart.value);
    }
    if (windBeaufortEnd.present) {
      map['wind_beaufort_end'] = Variable<int>(windBeaufortEnd.value);
    }
    if (cloudCoverStartPct.present) {
      map['cloud_cover_start_pct'] = Variable<int>(cloudCoverStartPct.value);
    }
    if (cloudCoverEndPct.present) {
      map['cloud_cover_end_pct'] = Variable<int>(cloudCoverEndPct.value);
    }
    if (precipitation.present) {
      map['precipitation'] = Variable<String>(precipitation.value);
    }
    if (weatherSuitable.present) {
      map['weather_suitable'] = Variable<bool>(weatherSuitable.value);
    }
    if (weatherMissingReason.present) {
      map['weather_missing_reason'] = Variable<String>(
        weatherMissingReason.value,
      );
    }
    if (zeroObservationConfirmed.present) {
      map['zero_observation_confirmed'] = Variable<bool>(
        zeroObservationConfirmed.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (batterySaverUsed.present) {
      map['battery_saver_used'] = Variable<bool>(batterySaverUsed.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdOffline.present) {
      map['created_offline'] = Variable<bool>(createdOffline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyVisitsCompanion(')
          ..write('serverVersion: $serverVersion, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('transectId: $transectId, ')
          ..write('observerId: $observerId, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('surveyMethod: $surveyMethod, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('pausedSeconds: $pausedSeconds, ')
          ..write('distanceWalkedM: $distanceWalkedM, ')
          ..write('observerCount: $observerCount, ')
          ..write('observerNames: $observerNames, ')
          ..write('temperatureStartC: $temperatureStartC, ')
          ..write('temperatureEndC: $temperatureEndC, ')
          ..write('windBeaufortStart: $windBeaufortStart, ')
          ..write('windBeaufortEnd: $windBeaufortEnd, ')
          ..write('cloudCoverStartPct: $cloudCoverStartPct, ')
          ..write('cloudCoverEndPct: $cloudCoverEndPct, ')
          ..write('precipitation: $precipitation, ')
          ..write('weatherSuitable: $weatherSuitable, ')
          ..write('weatherMissingReason: $weatherMissingReason, ')
          ..write('zeroObservationConfirmed: $zeroObservationConfirmed, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('batterySaverUsed: $batterySaverUsed, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdOffline: $createdOffline, ')
          ..write('createdAt: $createdAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaxaTable extends Taxa with TableInfo<$TaxaTable, Taxon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaxaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rankMeta = const VerificationMeta('rank');
  @override
  late final GeneratedColumn<String> rank = GeneratedColumn<String>(
    'rank',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genusMeta = const VerificationMeta('genus');
  @override
  late final GeneratedColumn<String> genus = GeneratedColumn<String>(
    'genus',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familyMeta = const VerificationMeta('family');
  @override
  late final GeneratedColumn<String> family = GeneratedColumn<String>(
    'family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vernacularNameSrMeta = const VerificationMeta(
    'vernacularNameSr',
  );
  @override
  late final GeneratedColumn<String> vernacularNameSr = GeneratedColumn<String>(
    'vernacular_name_sr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vernacularNameEnMeta = const VerificationMeta(
    'vernacularNameEn',
  );
  @override
  late final GeneratedColumn<String> vernacularNameEn = GeneratedColumn<String>(
    'vernacular_name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxonSourceMeta = const VerificationMeta(
    'taxonSource',
  );
  @override
  late final GeneratedColumn<String> taxonSource = GeneratedColumn<String>(
    'taxon_source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxonSourceIdMeta = const VerificationMeta(
    'taxonSourceId',
  );
  @override
  late final GeneratedColumn<String> taxonSourceId = GeneratedColumn<String>(
    'taxon_source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _photoRequiredMeta = const VerificationMeta(
    'photoRequired',
  );
  @override
  late final GeneratedColumn<bool> photoRequired = GeneratedColumn<bool>(
    'photo_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("photo_required" IN (0, 1))',
    ),
  );
  static const VerificationMeta _identificationNotesMeta =
      const VerificationMeta('identificationNotes');
  @override
  late final GeneratedColumn<String> identificationNotes =
      GeneratedColumn<String>(
        'identification_notes',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _acceptedNameIdMeta = const VerificationMeta(
    'acceptedNameId',
  );
  @override
  late final GeneratedColumn<String> acceptedNameId = GeneratedColumn<String>(
    'accepted_name_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _introducedInIdMeta = const VerificationMeta(
    'introducedInId',
  );
  @override
  late final GeneratedColumn<String> introducedInId = GeneratedColumn<String>(
    'introduced_in_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retiredInIdMeta = const VerificationMeta(
    'retiredInId',
  );
  @override
  late final GeneratedColumn<String> retiredInId = GeneratedColumn<String>(
    'retired_in_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scientificNameMeta = const VerificationMeta(
    'scientificName',
  );
  @override
  late final GeneratedColumn<String> scientificName = GeneratedColumn<String>(
    'scientific_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    author,
    rank,
    genus,
    family,
    vernacularNameSr,
    vernacularNameEn,
    taxonSource,
    taxonSourceId,
    active,
    photoRequired,
    identificationNotes,
    acceptedNameId,
    introducedInId,
    retiredInId,
    scientificName,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'taxon';
  @override
  VerificationContext validateIntegrity(
    Insertable<Taxon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('rank')) {
      context.handle(
        _rankMeta,
        rank.isAcceptableOrUnknown(data['rank']!, _rankMeta),
      );
    } else if (isInserting) {
      context.missing(_rankMeta);
    }
    if (data.containsKey('genus')) {
      context.handle(
        _genusMeta,
        genus.isAcceptableOrUnknown(data['genus']!, _genusMeta),
      );
    } else if (isInserting) {
      context.missing(_genusMeta);
    }
    if (data.containsKey('family')) {
      context.handle(
        _familyMeta,
        family.isAcceptableOrUnknown(data['family']!, _familyMeta),
      );
    } else if (isInserting) {
      context.missing(_familyMeta);
    }
    if (data.containsKey('vernacular_name_sr')) {
      context.handle(
        _vernacularNameSrMeta,
        vernacularNameSr.isAcceptableOrUnknown(
          data['vernacular_name_sr']!,
          _vernacularNameSrMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vernacularNameSrMeta);
    }
    if (data.containsKey('vernacular_name_en')) {
      context.handle(
        _vernacularNameEnMeta,
        vernacularNameEn.isAcceptableOrUnknown(
          data['vernacular_name_en']!,
          _vernacularNameEnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vernacularNameEnMeta);
    }
    if (data.containsKey('taxon_source')) {
      context.handle(
        _taxonSourceMeta,
        taxonSource.isAcceptableOrUnknown(
          data['taxon_source']!,
          _taxonSourceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxonSourceMeta);
    }
    if (data.containsKey('taxon_source_id')) {
      context.handle(
        _taxonSourceIdMeta,
        taxonSourceId.isAcceptableOrUnknown(
          data['taxon_source_id']!,
          _taxonSourceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taxonSourceIdMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('photo_required')) {
      context.handle(
        _photoRequiredMeta,
        photoRequired.isAcceptableOrUnknown(
          data['photo_required']!,
          _photoRequiredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_photoRequiredMeta);
    }
    if (data.containsKey('identification_notes')) {
      context.handle(
        _identificationNotesMeta,
        identificationNotes.isAcceptableOrUnknown(
          data['identification_notes']!,
          _identificationNotesMeta,
        ),
      );
    }
    if (data.containsKey('accepted_name_id')) {
      context.handle(
        _acceptedNameIdMeta,
        acceptedNameId.isAcceptableOrUnknown(
          data['accepted_name_id']!,
          _acceptedNameIdMeta,
        ),
      );
    }
    if (data.containsKey('introduced_in_id')) {
      context.handle(
        _introducedInIdMeta,
        introducedInId.isAcceptableOrUnknown(
          data['introduced_in_id']!,
          _introducedInIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_introducedInIdMeta);
    }
    if (data.containsKey('retired_in_id')) {
      context.handle(
        _retiredInIdMeta,
        retiredInId.isAcceptableOrUnknown(
          data['retired_in_id']!,
          _retiredInIdMeta,
        ),
      );
    }
    if (data.containsKey('scientific_name')) {
      context.handle(
        _scientificNameMeta,
        scientificName.isAcceptableOrUnknown(
          data['scientific_name']!,
          _scientificNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scientificNameMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Taxon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Taxon(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      rank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rank'],
      )!,
      genus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genus'],
      )!,
      family: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family'],
      )!,
      vernacularNameSr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vernacular_name_sr'],
      )!,
      vernacularNameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vernacular_name_en'],
      )!,
      taxonSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_source'],
      )!,
      taxonSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}taxon_source_id'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      photoRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}photo_required'],
      )!,
      identificationNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identification_notes'],
      ),
      acceptedNameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accepted_name_id'],
      ),
      introducedInId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}introduced_in_id'],
      )!,
      retiredInId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}retired_in_id'],
      ),
      scientificName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scientific_name'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TaxaTable createAlias(String alias) {
    return $TaxaTable(attachedDatabase, alias);
  }
}

class Taxon extends DataClass implements Insertable<Taxon> {
  final String id;
  final String author;
  final String rank;
  final String genus;
  final String family;
  final String vernacularNameSr;
  final String vernacularNameEn;
  final String taxonSource;
  final String taxonSourceId;
  final bool active;
  final bool photoRequired;
  final String? identificationNotes;
  final String? acceptedNameId;
  final String introducedInId;
  final String? retiredInId;
  final String scientificName;
  final int? serverVersion;
  final DateTime? deletedAt;
  const Taxon({
    required this.id,
    required this.author,
    required this.rank,
    required this.genus,
    required this.family,
    required this.vernacularNameSr,
    required this.vernacularNameEn,
    required this.taxonSource,
    required this.taxonSourceId,
    required this.active,
    required this.photoRequired,
    this.identificationNotes,
    this.acceptedNameId,
    required this.introducedInId,
    this.retiredInId,
    required this.scientificName,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['author'] = Variable<String>(author);
    map['rank'] = Variable<String>(rank);
    map['genus'] = Variable<String>(genus);
    map['family'] = Variable<String>(family);
    map['vernacular_name_sr'] = Variable<String>(vernacularNameSr);
    map['vernacular_name_en'] = Variable<String>(vernacularNameEn);
    map['taxon_source'] = Variable<String>(taxonSource);
    map['taxon_source_id'] = Variable<String>(taxonSourceId);
    map['active'] = Variable<bool>(active);
    map['photo_required'] = Variable<bool>(photoRequired);
    if (!nullToAbsent || identificationNotes != null) {
      map['identification_notes'] = Variable<String>(identificationNotes);
    }
    if (!nullToAbsent || acceptedNameId != null) {
      map['accepted_name_id'] = Variable<String>(acceptedNameId);
    }
    map['introduced_in_id'] = Variable<String>(introducedInId);
    if (!nullToAbsent || retiredInId != null) {
      map['retired_in_id'] = Variable<String>(retiredInId);
    }
    map['scientific_name'] = Variable<String>(scientificName);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TaxaCompanion toCompanion(bool nullToAbsent) {
    return TaxaCompanion(
      id: Value(id),
      author: Value(author),
      rank: Value(rank),
      genus: Value(genus),
      family: Value(family),
      vernacularNameSr: Value(vernacularNameSr),
      vernacularNameEn: Value(vernacularNameEn),
      taxonSource: Value(taxonSource),
      taxonSourceId: Value(taxonSourceId),
      active: Value(active),
      photoRequired: Value(photoRequired),
      identificationNotes: identificationNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(identificationNotes),
      acceptedNameId: acceptedNameId == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptedNameId),
      introducedInId: Value(introducedInId),
      retiredInId: retiredInId == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredInId),
      scientificName: Value(scientificName),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Taxon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Taxon(
      id: serializer.fromJson<String>(json['id']),
      author: serializer.fromJson<String>(json['author']),
      rank: serializer.fromJson<String>(json['rank']),
      genus: serializer.fromJson<String>(json['genus']),
      family: serializer.fromJson<String>(json['family']),
      vernacularNameSr: serializer.fromJson<String>(json['vernacularNameSr']),
      vernacularNameEn: serializer.fromJson<String>(json['vernacularNameEn']),
      taxonSource: serializer.fromJson<String>(json['taxonSource']),
      taxonSourceId: serializer.fromJson<String>(json['taxonSourceId']),
      active: serializer.fromJson<bool>(json['active']),
      photoRequired: serializer.fromJson<bool>(json['photoRequired']),
      identificationNotes: serializer.fromJson<String?>(
        json['identificationNotes'],
      ),
      acceptedNameId: serializer.fromJson<String?>(json['acceptedNameId']),
      introducedInId: serializer.fromJson<String>(json['introducedInId']),
      retiredInId: serializer.fromJson<String?>(json['retiredInId']),
      scientificName: serializer.fromJson<String>(json['scientificName']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'author': serializer.toJson<String>(author),
      'rank': serializer.toJson<String>(rank),
      'genus': serializer.toJson<String>(genus),
      'family': serializer.toJson<String>(family),
      'vernacularNameSr': serializer.toJson<String>(vernacularNameSr),
      'vernacularNameEn': serializer.toJson<String>(vernacularNameEn),
      'taxonSource': serializer.toJson<String>(taxonSource),
      'taxonSourceId': serializer.toJson<String>(taxonSourceId),
      'active': serializer.toJson<bool>(active),
      'photoRequired': serializer.toJson<bool>(photoRequired),
      'identificationNotes': serializer.toJson<String?>(identificationNotes),
      'acceptedNameId': serializer.toJson<String?>(acceptedNameId),
      'introducedInId': serializer.toJson<String>(introducedInId),
      'retiredInId': serializer.toJson<String?>(retiredInId),
      'scientificName': serializer.toJson<String>(scientificName),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Taxon copyWith({
    String? id,
    String? author,
    String? rank,
    String? genus,
    String? family,
    String? vernacularNameSr,
    String? vernacularNameEn,
    String? taxonSource,
    String? taxonSourceId,
    bool? active,
    bool? photoRequired,
    Value<String?> identificationNotes = const Value.absent(),
    Value<String?> acceptedNameId = const Value.absent(),
    String? introducedInId,
    Value<String?> retiredInId = const Value.absent(),
    String? scientificName,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Taxon(
    id: id ?? this.id,
    author: author ?? this.author,
    rank: rank ?? this.rank,
    genus: genus ?? this.genus,
    family: family ?? this.family,
    vernacularNameSr: vernacularNameSr ?? this.vernacularNameSr,
    vernacularNameEn: vernacularNameEn ?? this.vernacularNameEn,
    taxonSource: taxonSource ?? this.taxonSource,
    taxonSourceId: taxonSourceId ?? this.taxonSourceId,
    active: active ?? this.active,
    photoRequired: photoRequired ?? this.photoRequired,
    identificationNotes: identificationNotes.present
        ? identificationNotes.value
        : this.identificationNotes,
    acceptedNameId: acceptedNameId.present
        ? acceptedNameId.value
        : this.acceptedNameId,
    introducedInId: introducedInId ?? this.introducedInId,
    retiredInId: retiredInId.present ? retiredInId.value : this.retiredInId,
    scientificName: scientificName ?? this.scientificName,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Taxon copyWithCompanion(TaxaCompanion data) {
    return Taxon(
      id: data.id.present ? data.id.value : this.id,
      author: data.author.present ? data.author.value : this.author,
      rank: data.rank.present ? data.rank.value : this.rank,
      genus: data.genus.present ? data.genus.value : this.genus,
      family: data.family.present ? data.family.value : this.family,
      vernacularNameSr: data.vernacularNameSr.present
          ? data.vernacularNameSr.value
          : this.vernacularNameSr,
      vernacularNameEn: data.vernacularNameEn.present
          ? data.vernacularNameEn.value
          : this.vernacularNameEn,
      taxonSource: data.taxonSource.present
          ? data.taxonSource.value
          : this.taxonSource,
      taxonSourceId: data.taxonSourceId.present
          ? data.taxonSourceId.value
          : this.taxonSourceId,
      active: data.active.present ? data.active.value : this.active,
      photoRequired: data.photoRequired.present
          ? data.photoRequired.value
          : this.photoRequired,
      identificationNotes: data.identificationNotes.present
          ? data.identificationNotes.value
          : this.identificationNotes,
      acceptedNameId: data.acceptedNameId.present
          ? data.acceptedNameId.value
          : this.acceptedNameId,
      introducedInId: data.introducedInId.present
          ? data.introducedInId.value
          : this.introducedInId,
      retiredInId: data.retiredInId.present
          ? data.retiredInId.value
          : this.retiredInId,
      scientificName: data.scientificName.present
          ? data.scientificName.value
          : this.scientificName,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Taxon(')
          ..write('id: $id, ')
          ..write('author: $author, ')
          ..write('rank: $rank, ')
          ..write('genus: $genus, ')
          ..write('family: $family, ')
          ..write('vernacularNameSr: $vernacularNameSr, ')
          ..write('vernacularNameEn: $vernacularNameEn, ')
          ..write('taxonSource: $taxonSource, ')
          ..write('taxonSourceId: $taxonSourceId, ')
          ..write('active: $active, ')
          ..write('photoRequired: $photoRequired, ')
          ..write('identificationNotes: $identificationNotes, ')
          ..write('acceptedNameId: $acceptedNameId, ')
          ..write('introducedInId: $introducedInId, ')
          ..write('retiredInId: $retiredInId, ')
          ..write('scientificName: $scientificName, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    author,
    rank,
    genus,
    family,
    vernacularNameSr,
    vernacularNameEn,
    taxonSource,
    taxonSourceId,
    active,
    photoRequired,
    identificationNotes,
    acceptedNameId,
    introducedInId,
    retiredInId,
    scientificName,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Taxon &&
          other.id == this.id &&
          other.author == this.author &&
          other.rank == this.rank &&
          other.genus == this.genus &&
          other.family == this.family &&
          other.vernacularNameSr == this.vernacularNameSr &&
          other.vernacularNameEn == this.vernacularNameEn &&
          other.taxonSource == this.taxonSource &&
          other.taxonSourceId == this.taxonSourceId &&
          other.active == this.active &&
          other.photoRequired == this.photoRequired &&
          other.identificationNotes == this.identificationNotes &&
          other.acceptedNameId == this.acceptedNameId &&
          other.introducedInId == this.introducedInId &&
          other.retiredInId == this.retiredInId &&
          other.scientificName == this.scientificName &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class TaxaCompanion extends UpdateCompanion<Taxon> {
  final Value<String> id;
  final Value<String> author;
  final Value<String> rank;
  final Value<String> genus;
  final Value<String> family;
  final Value<String> vernacularNameSr;
  final Value<String> vernacularNameEn;
  final Value<String> taxonSource;
  final Value<String> taxonSourceId;
  final Value<bool> active;
  final Value<bool> photoRequired;
  final Value<String?> identificationNotes;
  final Value<String?> acceptedNameId;
  final Value<String> introducedInId;
  final Value<String?> retiredInId;
  final Value<String> scientificName;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TaxaCompanion({
    this.id = const Value.absent(),
    this.author = const Value.absent(),
    this.rank = const Value.absent(),
    this.genus = const Value.absent(),
    this.family = const Value.absent(),
    this.vernacularNameSr = const Value.absent(),
    this.vernacularNameEn = const Value.absent(),
    this.taxonSource = const Value.absent(),
    this.taxonSourceId = const Value.absent(),
    this.active = const Value.absent(),
    this.photoRequired = const Value.absent(),
    this.identificationNotes = const Value.absent(),
    this.acceptedNameId = const Value.absent(),
    this.introducedInId = const Value.absent(),
    this.retiredInId = const Value.absent(),
    this.scientificName = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaxaCompanion.insert({
    required String id,
    required String author,
    required String rank,
    required String genus,
    required String family,
    required String vernacularNameSr,
    required String vernacularNameEn,
    required String taxonSource,
    required String taxonSourceId,
    required bool active,
    required bool photoRequired,
    this.identificationNotes = const Value.absent(),
    this.acceptedNameId = const Value.absent(),
    required String introducedInId,
    this.retiredInId = const Value.absent(),
    required String scientificName,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       author = Value(author),
       rank = Value(rank),
       genus = Value(genus),
       family = Value(family),
       vernacularNameSr = Value(vernacularNameSr),
       vernacularNameEn = Value(vernacularNameEn),
       taxonSource = Value(taxonSource),
       taxonSourceId = Value(taxonSourceId),
       active = Value(active),
       photoRequired = Value(photoRequired),
       introducedInId = Value(introducedInId),
       scientificName = Value(scientificName);
  static Insertable<Taxon> custom({
    Expression<String>? id,
    Expression<String>? author,
    Expression<String>? rank,
    Expression<String>? genus,
    Expression<String>? family,
    Expression<String>? vernacularNameSr,
    Expression<String>? vernacularNameEn,
    Expression<String>? taxonSource,
    Expression<String>? taxonSourceId,
    Expression<bool>? active,
    Expression<bool>? photoRequired,
    Expression<String>? identificationNotes,
    Expression<String>? acceptedNameId,
    Expression<String>? introducedInId,
    Expression<String>? retiredInId,
    Expression<String>? scientificName,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (author != null) 'author': author,
      if (rank != null) 'rank': rank,
      if (genus != null) 'genus': genus,
      if (family != null) 'family': family,
      if (vernacularNameSr != null) 'vernacular_name_sr': vernacularNameSr,
      if (vernacularNameEn != null) 'vernacular_name_en': vernacularNameEn,
      if (taxonSource != null) 'taxon_source': taxonSource,
      if (taxonSourceId != null) 'taxon_source_id': taxonSourceId,
      if (active != null) 'active': active,
      if (photoRequired != null) 'photo_required': photoRequired,
      if (identificationNotes != null)
        'identification_notes': identificationNotes,
      if (acceptedNameId != null) 'accepted_name_id': acceptedNameId,
      if (introducedInId != null) 'introduced_in_id': introducedInId,
      if (retiredInId != null) 'retired_in_id': retiredInId,
      if (scientificName != null) 'scientific_name': scientificName,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaxaCompanion copyWith({
    Value<String>? id,
    Value<String>? author,
    Value<String>? rank,
    Value<String>? genus,
    Value<String>? family,
    Value<String>? vernacularNameSr,
    Value<String>? vernacularNameEn,
    Value<String>? taxonSource,
    Value<String>? taxonSourceId,
    Value<bool>? active,
    Value<bool>? photoRequired,
    Value<String?>? identificationNotes,
    Value<String?>? acceptedNameId,
    Value<String>? introducedInId,
    Value<String?>? retiredInId,
    Value<String>? scientificName,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaxaCompanion(
      id: id ?? this.id,
      author: author ?? this.author,
      rank: rank ?? this.rank,
      genus: genus ?? this.genus,
      family: family ?? this.family,
      vernacularNameSr: vernacularNameSr ?? this.vernacularNameSr,
      vernacularNameEn: vernacularNameEn ?? this.vernacularNameEn,
      taxonSource: taxonSource ?? this.taxonSource,
      taxonSourceId: taxonSourceId ?? this.taxonSourceId,
      active: active ?? this.active,
      photoRequired: photoRequired ?? this.photoRequired,
      identificationNotes: identificationNotes ?? this.identificationNotes,
      acceptedNameId: acceptedNameId ?? this.acceptedNameId,
      introducedInId: introducedInId ?? this.introducedInId,
      retiredInId: retiredInId ?? this.retiredInId,
      scientificName: scientificName ?? this.scientificName,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (rank.present) {
      map['rank'] = Variable<String>(rank.value);
    }
    if (genus.present) {
      map['genus'] = Variable<String>(genus.value);
    }
    if (family.present) {
      map['family'] = Variable<String>(family.value);
    }
    if (vernacularNameSr.present) {
      map['vernacular_name_sr'] = Variable<String>(vernacularNameSr.value);
    }
    if (vernacularNameEn.present) {
      map['vernacular_name_en'] = Variable<String>(vernacularNameEn.value);
    }
    if (taxonSource.present) {
      map['taxon_source'] = Variable<String>(taxonSource.value);
    }
    if (taxonSourceId.present) {
      map['taxon_source_id'] = Variable<String>(taxonSourceId.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (photoRequired.present) {
      map['photo_required'] = Variable<bool>(photoRequired.value);
    }
    if (identificationNotes.present) {
      map['identification_notes'] = Variable<String>(identificationNotes.value);
    }
    if (acceptedNameId.present) {
      map['accepted_name_id'] = Variable<String>(acceptedNameId.value);
    }
    if (introducedInId.present) {
      map['introduced_in_id'] = Variable<String>(introducedInId.value);
    }
    if (retiredInId.present) {
      map['retired_in_id'] = Variable<String>(retiredInId.value);
    }
    if (scientificName.present) {
      map['scientific_name'] = Variable<String>(scientificName.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaxaCompanion(')
          ..write('id: $id, ')
          ..write('author: $author, ')
          ..write('rank: $rank, ')
          ..write('genus: $genus, ')
          ..write('family: $family, ')
          ..write('vernacularNameSr: $vernacularNameSr, ')
          ..write('vernacularNameEn: $vernacularNameEn, ')
          ..write('taxonSource: $taxonSource, ')
          ..write('taxonSourceId: $taxonSourceId, ')
          ..write('active: $active, ')
          ..write('photoRequired: $photoRequired, ')
          ..write('identificationNotes: $identificationNotes, ')
          ..write('acceptedNameId: $acceptedNameId, ')
          ..write('introducedInId: $introducedInId, ')
          ..write('retiredInId: $retiredInId, ')
          ..write('scientificName: $scientificName, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaxonListVersionsTable extends TaxonListVersions
    with TableInfo<$TaxonListVersionsTable, TaxonListVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaxonListVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionLabelMeta = const VerificationMeta(
    'versionLabel',
  );
  @override
  late final GeneratedColumn<String> versionLabel = GeneratedColumn<String>(
    'version_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCurrentMeta = const VerificationMeta(
    'isCurrent',
  );
  @override
  late final GeneratedColumn<bool> isCurrent = GeneratedColumn<bool>(
    'is_current',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_current" IN (0, 1))',
    ),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    versionLabel,
    source,
    publishedAt,
    isCurrent,
    notes,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'taxon_list_version';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaxonListVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version_label')) {
      context.handle(
        _versionLabelMeta,
        versionLabel.isAcceptableOrUnknown(
          data['version_label']!,
          _versionLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionLabelMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('is_current')) {
      context.handle(
        _isCurrentMeta,
        isCurrent.isAcceptableOrUnknown(data['is_current']!, _isCurrentMeta),
      );
    } else if (isInserting) {
      context.missing(_isCurrentMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaxonListVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaxonListVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      versionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_label'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      )!,
      isCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_current'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TaxonListVersionsTable createAlias(String alias) {
    return $TaxonListVersionsTable(attachedDatabase, alias);
  }
}

class TaxonListVersion extends DataClass
    implements Insertable<TaxonListVersion> {
  final String id;
  final String versionLabel;
  final String source;
  final DateTime publishedAt;
  final bool isCurrent;
  final String notes;
  final int? serverVersion;
  final DateTime? deletedAt;
  const TaxonListVersion({
    required this.id,
    required this.versionLabel,
    required this.source,
    required this.publishedAt,
    required this.isCurrent,
    required this.notes,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version_label'] = Variable<String>(versionLabel);
    map['source'] = Variable<String>(source);
    map['published_at'] = Variable<DateTime>(publishedAt);
    map['is_current'] = Variable<bool>(isCurrent);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TaxonListVersionsCompanion toCompanion(bool nullToAbsent) {
    return TaxonListVersionsCompanion(
      id: Value(id),
      versionLabel: Value(versionLabel),
      source: Value(source),
      publishedAt: Value(publishedAt),
      isCurrent: Value(isCurrent),
      notes: Value(notes),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TaxonListVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaxonListVersion(
      id: serializer.fromJson<String>(json['id']),
      versionLabel: serializer.fromJson<String>(json['versionLabel']),
      source: serializer.fromJson<String>(json['source']),
      publishedAt: serializer.fromJson<DateTime>(json['publishedAt']),
      isCurrent: serializer.fromJson<bool>(json['isCurrent']),
      notes: serializer.fromJson<String>(json['notes']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'versionLabel': serializer.toJson<String>(versionLabel),
      'source': serializer.toJson<String>(source),
      'publishedAt': serializer.toJson<DateTime>(publishedAt),
      'isCurrent': serializer.toJson<bool>(isCurrent),
      'notes': serializer.toJson<String>(notes),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TaxonListVersion copyWith({
    String? id,
    String? versionLabel,
    String? source,
    DateTime? publishedAt,
    bool? isCurrent,
    String? notes,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TaxonListVersion(
    id: id ?? this.id,
    versionLabel: versionLabel ?? this.versionLabel,
    source: source ?? this.source,
    publishedAt: publishedAt ?? this.publishedAt,
    isCurrent: isCurrent ?? this.isCurrent,
    notes: notes ?? this.notes,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TaxonListVersion copyWithCompanion(TaxonListVersionsCompanion data) {
    return TaxonListVersion(
      id: data.id.present ? data.id.value : this.id,
      versionLabel: data.versionLabel.present
          ? data.versionLabel.value
          : this.versionLabel,
      source: data.source.present ? data.source.value : this.source,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      isCurrent: data.isCurrent.present ? data.isCurrent.value : this.isCurrent,
      notes: data.notes.present ? data.notes.value : this.notes,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaxonListVersion(')
          ..write('id: $id, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('source: $source, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('notes: $notes, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    versionLabel,
    source,
    publishedAt,
    isCurrent,
    notes,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaxonListVersion &&
          other.id == this.id &&
          other.versionLabel == this.versionLabel &&
          other.source == this.source &&
          other.publishedAt == this.publishedAt &&
          other.isCurrent == this.isCurrent &&
          other.notes == this.notes &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class TaxonListVersionsCompanion extends UpdateCompanion<TaxonListVersion> {
  final Value<String> id;
  final Value<String> versionLabel;
  final Value<String> source;
  final Value<DateTime> publishedAt;
  final Value<bool> isCurrent;
  final Value<String> notes;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TaxonListVersionsCompanion({
    this.id = const Value.absent(),
    this.versionLabel = const Value.absent(),
    this.source = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.isCurrent = const Value.absent(),
    this.notes = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaxonListVersionsCompanion.insert({
    required String id,
    required String versionLabel,
    required String source,
    required DateTime publishedAt,
    required bool isCurrent,
    required String notes,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       versionLabel = Value(versionLabel),
       source = Value(source),
       publishedAt = Value(publishedAt),
       isCurrent = Value(isCurrent),
       notes = Value(notes);
  static Insertable<TaxonListVersion> custom({
    Expression<String>? id,
    Expression<String>? versionLabel,
    Expression<String>? source,
    Expression<DateTime>? publishedAt,
    Expression<bool>? isCurrent,
    Expression<String>? notes,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (versionLabel != null) 'version_label': versionLabel,
      if (source != null) 'source': source,
      if (publishedAt != null) 'published_at': publishedAt,
      if (isCurrent != null) 'is_current': isCurrent,
      if (notes != null) 'notes': notes,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaxonListVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? versionLabel,
    Value<String>? source,
    Value<DateTime>? publishedAt,
    Value<bool>? isCurrent,
    Value<String>? notes,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TaxonListVersionsCompanion(
      id: id ?? this.id,
      versionLabel: versionLabel ?? this.versionLabel,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      isCurrent: isCurrent ?? this.isCurrent,
      notes: notes ?? this.notes,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (versionLabel.present) {
      map['version_label'] = Variable<String>(versionLabel.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (isCurrent.present) {
      map['is_current'] = Variable<bool>(isCurrent.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaxonListVersionsCompanion(')
          ..write('id: $id, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('source: $source, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('isCurrent: $isCurrent, ')
          ..write('notes: $notes, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransectSectionsTable extends TransectSections
    with TableInfo<$TransectSectionsTable, TransectSection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransectSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transectIdMeta = const VerificationMeta(
    'transectId',
  );
  @override
  late final GeneratedColumn<String> transectId = GeneratedColumn<String>(
    'transect_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES transect (id)',
    ),
  );
  static const VerificationMeta _sectionCodeMeta = const VerificationMeta(
    'sectionCode',
  );
  @override
  late final GeneratedColumn<String> sectionCode = GeneratedColumn<String>(
    'section_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceNumberMeta = const VerificationMeta(
    'sequenceNumber',
  );
  @override
  late final GeneratedColumn<int> sequenceNumber = GeneratedColumn<int>(
    'sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitatTypeIdMeta = const VerificationMeta(
    'habitatTypeId',
  );
  @override
  late final GeneratedColumn<String> habitatTypeId = GeneratedColumn<String>(
    'habitat_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managementTypeIdMeta = const VerificationMeta(
    'managementTypeId',
  );
  @override
  late final GeneratedColumn<String> managementTypeId = GeneratedColumn<String>(
    'management_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geometryMeta = const VerificationMeta(
    'geometry',
  );
  @override
  late final GeneratedColumn<String> geometry = GeneratedColumn<String>(
    'geometry',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transectId,
    sectionCode,
    sequenceNumber,
    notes,
    habitatTypeId,
    managementTypeId,
    geometry,
    serverVersion,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transect_section';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransectSection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transect_id')) {
      context.handle(
        _transectIdMeta,
        transectId.isAcceptableOrUnknown(data['transect_id']!, _transectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_transectIdMeta);
    }
    if (data.containsKey('section_code')) {
      context.handle(
        _sectionCodeMeta,
        sectionCode.isAcceptableOrUnknown(
          data['section_code']!,
          _sectionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionCodeMeta);
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
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('habitat_type_id')) {
      context.handle(
        _habitatTypeIdMeta,
        habitatTypeId.isAcceptableOrUnknown(
          data['habitat_type_id']!,
          _habitatTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('management_type_id')) {
      context.handle(
        _managementTypeIdMeta,
        managementTypeId.isAcceptableOrUnknown(
          data['management_type_id']!,
          _managementTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('geometry')) {
      context.handle(
        _geometryMeta,
        geometry.isAcceptableOrUnknown(data['geometry']!, _geometryMeta),
      );
    } else if (isInserting) {
      context.missing(_geometryMeta);
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransectSection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransectSection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transect_id'],
      )!,
      sectionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section_code'],
      )!,
      sequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_number'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      habitatTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habitat_type_id'],
      ),
      managementTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}management_type_id'],
      ),
      geometry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geometry'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TransectSectionsTable createAlias(String alias) {
    return $TransectSectionsTable(attachedDatabase, alias);
  }
}

class TransectSection extends DataClass implements Insertable<TransectSection> {
  final String id;
  final String transectId;
  final String sectionCode;
  final int sequenceNumber;
  final String notes;
  final String? habitatTypeId;
  final String? managementTypeId;
  final String geometry;
  final int? serverVersion;
  final DateTime? deletedAt;
  const TransectSection({
    required this.id,
    required this.transectId,
    required this.sectionCode,
    required this.sequenceNumber,
    required this.notes,
    this.habitatTypeId,
    this.managementTypeId,
    required this.geometry,
    this.serverVersion,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transect_id'] = Variable<String>(transectId);
    map['section_code'] = Variable<String>(sectionCode);
    map['sequence_number'] = Variable<int>(sequenceNumber);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || habitatTypeId != null) {
      map['habitat_type_id'] = Variable<String>(habitatTypeId);
    }
    if (!nullToAbsent || managementTypeId != null) {
      map['management_type_id'] = Variable<String>(managementTypeId);
    }
    map['geometry'] = Variable<String>(geometry);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TransectSectionsCompanion toCompanion(bool nullToAbsent) {
    return TransectSectionsCompanion(
      id: Value(id),
      transectId: Value(transectId),
      sectionCode: Value(sectionCode),
      sequenceNumber: Value(sequenceNumber),
      notes: Value(notes),
      habitatTypeId: habitatTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(habitatTypeId),
      managementTypeId: managementTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(managementTypeId),
      geometry: Value(geometry),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory TransectSection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransectSection(
      id: serializer.fromJson<String>(json['id']),
      transectId: serializer.fromJson<String>(json['transectId']),
      sectionCode: serializer.fromJson<String>(json['sectionCode']),
      sequenceNumber: serializer.fromJson<int>(json['sequenceNumber']),
      notes: serializer.fromJson<String>(json['notes']),
      habitatTypeId: serializer.fromJson<String?>(json['habitatTypeId']),
      managementTypeId: serializer.fromJson<String?>(json['managementTypeId']),
      geometry: serializer.fromJson<String>(json['geometry']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transectId': serializer.toJson<String>(transectId),
      'sectionCode': serializer.toJson<String>(sectionCode),
      'sequenceNumber': serializer.toJson<int>(sequenceNumber),
      'notes': serializer.toJson<String>(notes),
      'habitatTypeId': serializer.toJson<String?>(habitatTypeId),
      'managementTypeId': serializer.toJson<String?>(managementTypeId),
      'geometry': serializer.toJson<String>(geometry),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  TransectSection copyWith({
    String? id,
    String? transectId,
    String? sectionCode,
    int? sequenceNumber,
    String? notes,
    Value<String?> habitatTypeId = const Value.absent(),
    Value<String?> managementTypeId = const Value.absent(),
    String? geometry,
    Value<int?> serverVersion = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => TransectSection(
    id: id ?? this.id,
    transectId: transectId ?? this.transectId,
    sectionCode: sectionCode ?? this.sectionCode,
    sequenceNumber: sequenceNumber ?? this.sequenceNumber,
    notes: notes ?? this.notes,
    habitatTypeId: habitatTypeId.present
        ? habitatTypeId.value
        : this.habitatTypeId,
    managementTypeId: managementTypeId.present
        ? managementTypeId.value
        : this.managementTypeId,
    geometry: geometry ?? this.geometry,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  TransectSection copyWithCompanion(TransectSectionsCompanion data) {
    return TransectSection(
      id: data.id.present ? data.id.value : this.id,
      transectId: data.transectId.present
          ? data.transectId.value
          : this.transectId,
      sectionCode: data.sectionCode.present
          ? data.sectionCode.value
          : this.sectionCode,
      sequenceNumber: data.sequenceNumber.present
          ? data.sequenceNumber.value
          : this.sequenceNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      habitatTypeId: data.habitatTypeId.present
          ? data.habitatTypeId.value
          : this.habitatTypeId,
      managementTypeId: data.managementTypeId.present
          ? data.managementTypeId.value
          : this.managementTypeId,
      geometry: data.geometry.present ? data.geometry.value : this.geometry,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransectSection(')
          ..write('id: $id, ')
          ..write('transectId: $transectId, ')
          ..write('sectionCode: $sectionCode, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('notes: $notes, ')
          ..write('habitatTypeId: $habitatTypeId, ')
          ..write('managementTypeId: $managementTypeId, ')
          ..write('geometry: $geometry, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transectId,
    sectionCode,
    sequenceNumber,
    notes,
    habitatTypeId,
    managementTypeId,
    geometry,
    serverVersion,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransectSection &&
          other.id == this.id &&
          other.transectId == this.transectId &&
          other.sectionCode == this.sectionCode &&
          other.sequenceNumber == this.sequenceNumber &&
          other.notes == this.notes &&
          other.habitatTypeId == this.habitatTypeId &&
          other.managementTypeId == this.managementTypeId &&
          other.geometry == this.geometry &&
          other.serverVersion == this.serverVersion &&
          other.deletedAt == this.deletedAt);
}

class TransectSectionsCompanion extends UpdateCompanion<TransectSection> {
  final Value<String> id;
  final Value<String> transectId;
  final Value<String> sectionCode;
  final Value<int> sequenceNumber;
  final Value<String> notes;
  final Value<String?> habitatTypeId;
  final Value<String?> managementTypeId;
  final Value<String> geometry;
  final Value<int?> serverVersion;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TransectSectionsCompanion({
    this.id = const Value.absent(),
    this.transectId = const Value.absent(),
    this.sectionCode = const Value.absent(),
    this.sequenceNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.habitatTypeId = const Value.absent(),
    this.managementTypeId = const Value.absent(),
    this.geometry = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransectSectionsCompanion.insert({
    required String id,
    required String transectId,
    required String sectionCode,
    required int sequenceNumber,
    required String notes,
    this.habitatTypeId = const Value.absent(),
    this.managementTypeId = const Value.absent(),
    required String geometry,
    this.serverVersion = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transectId = Value(transectId),
       sectionCode = Value(sectionCode),
       sequenceNumber = Value(sequenceNumber),
       notes = Value(notes),
       geometry = Value(geometry);
  static Insertable<TransectSection> custom({
    Expression<String>? id,
    Expression<String>? transectId,
    Expression<String>? sectionCode,
    Expression<int>? sequenceNumber,
    Expression<String>? notes,
    Expression<String>? habitatTypeId,
    Expression<String>? managementTypeId,
    Expression<String>? geometry,
    Expression<int>? serverVersion,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transectId != null) 'transect_id': transectId,
      if (sectionCode != null) 'section_code': sectionCode,
      if (sequenceNumber != null) 'sequence_number': sequenceNumber,
      if (notes != null) 'notes': notes,
      if (habitatTypeId != null) 'habitat_type_id': habitatTypeId,
      if (managementTypeId != null) 'management_type_id': managementTypeId,
      if (geometry != null) 'geometry': geometry,
      if (serverVersion != null) 'server_version': serverVersion,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransectSectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? transectId,
    Value<String>? sectionCode,
    Value<int>? sequenceNumber,
    Value<String>? notes,
    Value<String?>? habitatTypeId,
    Value<String?>? managementTypeId,
    Value<String>? geometry,
    Value<int?>? serverVersion,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TransectSectionsCompanion(
      id: id ?? this.id,
      transectId: transectId ?? this.transectId,
      sectionCode: sectionCode ?? this.sectionCode,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      notes: notes ?? this.notes,
      habitatTypeId: habitatTypeId ?? this.habitatTypeId,
      managementTypeId: managementTypeId ?? this.managementTypeId,
      geometry: geometry ?? this.geometry,
      serverVersion: serverVersion ?? this.serverVersion,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transectId.present) {
      map['transect_id'] = Variable<String>(transectId.value);
    }
    if (sectionCode.present) {
      map['section_code'] = Variable<String>(sectionCode.value);
    }
    if (sequenceNumber.present) {
      map['sequence_number'] = Variable<int>(sequenceNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (habitatTypeId.present) {
      map['habitat_type_id'] = Variable<String>(habitatTypeId.value);
    }
    if (managementTypeId.present) {
      map['management_type_id'] = Variable<String>(managementTypeId.value);
    }
    if (geometry.present) {
      map['geometry'] = Variable<String>(geometry.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransectSectionsCompanion(')
          ..write('id: $id, ')
          ..write('transectId: $transectId, ')
          ..write('sectionCode: $sectionCode, ')
          ..write('sequenceNumber: $sequenceNumber, ')
          ..write('notes: $notes, ')
          ..write('habitatTypeId: $habitatTypeId, ')
          ..write('managementTypeId: $managementTypeId, ')
          ..write('geometry: $geometry, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SkeletonPingsTable skeletonPings = $SkeletonPingsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncStateEntriesTable syncStateEntries = $SyncStateEntriesTable(
    this,
  );
  late final $HabitatTypesTable habitatTypes = $HabitatTypesTable(this);
  late final $ManagementTypesTable managementTypes = $ManagementTypesTable(
    this,
  );
  late final $PlantTaxaTable plantTaxa = $PlantTaxaTable(this);
  late final $ProjectProtocolsTable projectProtocols = $ProjectProtocolsTable(
    this,
  );
  late final $SyncConflictsTable syncConflicts = $SyncConflictsTable(this);
  late final $TransectsTable transects = $TransectsTable(this);
  late final $SurveyVisitsTable surveyVisits = $SurveyVisitsTable(this);
  late final $TaxaTable taxa = $TaxaTable(this);
  late final $TaxonListVersionsTable taxonListVersions =
      $TaxonListVersionsTable(this);
  late final $TransectSectionsTable transectSections = $TransectSectionsTable(
    this,
  );
  late final Index syncQueueEntity = Index(
    'sync_queue_entity',
    'CREATE INDEX sync_queue_entity ON sync_queue (entity_type, entity_id, seq)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    skeletonPings,
    projects,
    syncQueue,
    syncStateEntries,
    habitatTypes,
    managementTypes,
    plantTaxa,
    projectProtocols,
    syncConflicts,
    transects,
    surveyVisits,
    taxa,
    taxonListVersions,
    transectSections,
    syncQueueEntity,
  ];
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
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String name,
  Value<String> description,
  required DateTime startDate,
  Value<DateTime?> endDate,
  Value<int> defaultCrs,
  Value<bool> active,
  Value<String?> taxonListVersionId,
  Value<String?> area,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> description,
  Value<DateTime> startDate,
  Value<DateTime?> endDate,
  Value<int> defaultCrs,
  Value<bool> active,
  Value<String?> taxonListVersionId,
  Value<String?> area,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProjectProtocolsTable, List<ProjectProtocol>>
  _projectProtocolsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.projectProtocols,
    aliasName: 'project__id__project_protocol__project_id',
  );

  $$ProjectProtocolsTableProcessedTableManager get projectProtocolsRefs {
    final manager = $$ProjectProtocolsTableTableManager(
      $_db,
      $_db.projectProtocols,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _projectProtocolsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransectsTable, List<Transect>>
  _transectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transects,
    aliasName: 'project__id__transect__project_id',
  );

  $$TransectsTableProcessedTableManager get transectsRefs {
    final manager = $$TransectsTableTableManager(
      $_db,
      $_db.transects,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SurveyVisitsTable, List<SurveyVisit>>
  _surveyVisitsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.surveyVisits,
    aliasName: 'project__id__survey_visit__project_id',
  );

  $$SurveyVisitsTableProcessedTableManager get surveyVisitsRefs {
    final manager = $$SurveyVisitsTableTableManager(
      $_db,
      $_db.surveyVisits,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_surveyVisitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultCrs => $composableBuilder(
    column: $table.defaultCrs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonListVersionId => $composableBuilder(
    column: $table.taxonListVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> projectProtocolsRefs(
    Expression<bool> Function($$ProjectProtocolsTableFilterComposer f) f,
  ) {
    final $$ProjectProtocolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectProtocols,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectProtocolsTableFilterComposer(
            $db: $db,
            $table: $db.projectProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transectsRefs(
    Expression<bool> Function($$TransectsTableFilterComposer f) f,
  ) {
    final $$TransectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableFilterComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> surveyVisitsRefs(
    Expression<bool> Function($$SurveyVisitsTableFilterComposer f) f,
  ) {
    final $$SurveyVisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surveyVisits,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveyVisitsTableFilterComposer(
            $db: $db,
            $table: $db.surveyVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultCrs => $composableBuilder(
    column: $table.defaultCrs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonListVersionId => $composableBuilder(
    column: $table.taxonListVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get defaultCrs => $composableBuilder(
    column: $table.defaultCrs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get taxonListVersionId => $composableBuilder(
    column: $table.taxonListVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> projectProtocolsRefs<T extends Object>(
    Expression<T> Function($$ProjectProtocolsTableAnnotationComposer a) f,
  ) {
    final $$ProjectProtocolsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projectProtocols,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectProtocolsTableAnnotationComposer(
            $db: $db,
            $table: $db.projectProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transectsRefs<T extends Object>(
    Expression<T> Function($$TransectsTableAnnotationComposer a) f,
  ) {
    final $$TransectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableAnnotationComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> surveyVisitsRefs<T extends Object>(
    Expression<T> Function($$SurveyVisitsTableAnnotationComposer a) f,
  ) {
    final $$SurveyVisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surveyVisits,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveyVisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.surveyVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({
            bool projectProtocolsRefs,
            bool transectsRefs,
            bool surveyVisitsRefs,
          })
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> defaultCrs = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String?> taxonListVersionId = const Value.absent(),
                Value<String?> area = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                defaultCrs: defaultCrs,
                active: active,
                taxonListVersionId: taxonListVersionId,
                area: area,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> description = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> defaultCrs = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String?> taxonListVersionId = const Value.absent(),
                Value<String?> area = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                startDate: startDate,
                endDate: endDate,
                defaultCrs: defaultCrs,
                active: active,
                taxonListVersionId: taxonListVersionId,
                area: area,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                projectProtocolsRefs = false,
                transectsRefs = false,
                surveyVisitsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (projectProtocolsRefs) db.projectProtocols,
                    if (transectsRefs) db.transects,
                    if (surveyVisitsRefs) db.surveyVisits,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (projectProtocolsRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          ProjectProtocol
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._projectProtocolsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).projectProtocolsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transectsRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          Transect
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._transectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).transectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (surveyVisitsRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          SurveyVisit
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._surveyVisitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).surveyVisitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
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

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({
        bool projectProtocolsRefs,
        bool transectsRefs,
        bool surveyVisitsRefs,
      })
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> seq,
  required String mutationId,
  required String projectId,
  required String entityType,
  required String entityId,
  required String operation,
  Value<int?> baseVersion,
  required String payload,
  required DateTime createdAt,
  Value<int> retryCount,
  Value<DateTime?> nextAttemptAt,
  Value<String?> lastError,
  required QueueStatus status,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> seq,
  Value<String> mutationId,
  Value<String> projectId,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<int?> baseVersion,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<DateTime?> nextAttemptAt,
  Value<String?> lastError,
  Value<QueueStatus> status,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<QueueStatus, QueueStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QueueStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueItem,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueItem,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueItem>,
          ),
          SyncQueueItem,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<QueueStatus> status = const Value.absent(),
              }) => SyncQueueCompanion(
                seq: seq,
                mutationId: mutationId,
                projectId: projectId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                baseVersion: baseVersion,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String mutationId,
                required String projectId,
                required String entityType,
                required String entityId,
                required String operation,
                Value<int?> baseVersion = const Value.absent(),
                required String payload,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required QueueStatus status,
              }) => SyncQueueCompanion.insert(
                seq: seq,
                mutationId: mutationId,
                projectId: projectId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                baseVersion: baseVersion,
                payload: payload,
                createdAt: createdAt,
                retryCount: retryCount,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueItem>(table),
                  BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueItem>(
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

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueItem,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueItem,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueItem>,
      ),
      SyncQueueItem,
      PrefetchHooks Function()
    >;
typedef $$SyncStateEntriesTableCreateCompanionBuilder =
    SyncStateEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStateEntriesTableUpdateCompanionBuilder =
    SyncStateEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStateEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateEntriesTable> {
  $$SyncStateEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateEntriesTable> {
  $$SyncStateEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateEntriesTable> {
  $$SyncStateEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateEntriesTable,
          SyncStateEntry,
          $$SyncStateEntriesTableFilterComposer,
          $$SyncStateEntriesTableOrderingComposer,
          $$SyncStateEntriesTableAnnotationComposer,
          $$SyncStateEntriesTableCreateCompanionBuilder,
          $$SyncStateEntriesTableUpdateCompanionBuilder,
          (
            SyncStateEntry,
            BaseReferences<
              _$AppDatabase,
              $SyncStateEntriesTable,
              SyncStateEntry
            >,
          ),
          SyncStateEntry,
          PrefetchHooks Function()
        > {
  $$SyncStateEntriesTableTableManager(
    _$AppDatabase db,
    $SyncStateEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateEntriesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateEntriesTable, SyncStateEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncStateEntriesTable,
                    SyncStateEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateEntriesTable,
      SyncStateEntry,
      $$SyncStateEntriesTableFilterComposer,
      $$SyncStateEntriesTableOrderingComposer,
      $$SyncStateEntriesTableAnnotationComposer,
      $$SyncStateEntriesTableCreateCompanionBuilder,
      $$SyncStateEntriesTableUpdateCompanionBuilder,
      (
        SyncStateEntry,
        BaseReferences<_$AppDatabase, $SyncStateEntriesTable, SyncStateEntry>,
      ),
      SyncStateEntry,
      PrefetchHooks Function()
    >;
typedef $$HabitatTypesTableCreateCompanionBuilder =
    HabitatTypesCompanion Function({
      required String id,
      required String code,
      required String nameEn,
      required String nameSr,
      required String description,
      required int sortOrder,
      required bool active,
      required String eunisCode,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$HabitatTypesTableUpdateCompanionBuilder =
    HabitatTypesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> nameEn,
      Value<String> nameSr,
      Value<String> description,
      Value<int> sortOrder,
      Value<bool> active,
      Value<String> eunisCode,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$HabitatTypesTableFilterComposer
    extends Composer<_$AppDatabase, $HabitatTypesTable> {
  $$HabitatTypesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSr => $composableBuilder(
    column: $table.nameSr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eunisCode => $composableBuilder(
    column: $table.eunisCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitatTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitatTypesTable> {
  $$HabitatTypesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSr => $composableBuilder(
    column: $table.nameSr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eunisCode => $composableBuilder(
    column: $table.eunisCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitatTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitatTypesTable> {
  $$HabitatTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameSr =>
      $composableBuilder(column: $table.nameSr, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get eunisCode =>
      $composableBuilder(column: $table.eunisCode, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$HabitatTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitatTypesTable,
          HabitatType,
          $$HabitatTypesTableFilterComposer,
          $$HabitatTypesTableOrderingComposer,
          $$HabitatTypesTableAnnotationComposer,
          $$HabitatTypesTableCreateCompanionBuilder,
          $$HabitatTypesTableUpdateCompanionBuilder,
          (
            HabitatType,
            BaseReferences<_$AppDatabase, $HabitatTypesTable, HabitatType>,
          ),
          HabitatType,
          PrefetchHooks Function()
        > {
  $$HabitatTypesTableTableManager(_$AppDatabase db, $HabitatTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitatTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitatTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitatTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameSr = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> eunisCode = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitatTypesCompanion(
                id: id,
                code: code,
                nameEn: nameEn,
                nameSr: nameSr,
                description: description,
                sortOrder: sortOrder,
                active: active,
                eunisCode: eunisCode,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String nameEn,
                required String nameSr,
                required String description,
                required int sortOrder,
                required bool active,
                required String eunisCode,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitatTypesCompanion.insert(
                id: id,
                code: code,
                nameEn: nameEn,
                nameSr: nameSr,
                description: description,
                sortOrder: sortOrder,
                active: active,
                eunisCode: eunisCode,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitatTypesTable, HabitatType>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HabitatTypesTable,
                    HabitatType
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitatTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitatTypesTable,
      HabitatType,
      $$HabitatTypesTableFilterComposer,
      $$HabitatTypesTableOrderingComposer,
      $$HabitatTypesTableAnnotationComposer,
      $$HabitatTypesTableCreateCompanionBuilder,
      $$HabitatTypesTableUpdateCompanionBuilder,
      (
        HabitatType,
        BaseReferences<_$AppDatabase, $HabitatTypesTable, HabitatType>,
      ),
      HabitatType,
      PrefetchHooks Function()
    >;
typedef $$ManagementTypesTableCreateCompanionBuilder =
    ManagementTypesCompanion Function({
      required String id,
      required String code,
      required String nameEn,
      required String nameSr,
      required String description,
      required int sortOrder,
      required bool active,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ManagementTypesTableUpdateCompanionBuilder =
    ManagementTypesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> nameEn,
      Value<String> nameSr,
      Value<String> description,
      Value<int> sortOrder,
      Value<bool> active,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$ManagementTypesTableFilterComposer
    extends Composer<_$AppDatabase, $ManagementTypesTable> {
  $$ManagementTypesTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameSr => $composableBuilder(
    column: $table.nameSr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManagementTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $ManagementTypesTable> {
  $$ManagementTypesTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameSr => $composableBuilder(
    column: $table.nameSr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManagementTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManagementTypesTable> {
  $$ManagementTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get nameSr =>
      $composableBuilder(column: $table.nameSr, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ManagementTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ManagementTypesTable,
          ManagementType,
          $$ManagementTypesTableFilterComposer,
          $$ManagementTypesTableOrderingComposer,
          $$ManagementTypesTableAnnotationComposer,
          $$ManagementTypesTableCreateCompanionBuilder,
          $$ManagementTypesTableUpdateCompanionBuilder,
          (
            ManagementType,
            BaseReferences<
              _$AppDatabase,
              $ManagementTypesTable,
              ManagementType
            >,
          ),
          ManagementType,
          PrefetchHooks Function()
        > {
  $$ManagementTypesTableTableManager(
    _$AppDatabase db,
    $ManagementTypesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManagementTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManagementTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManagementTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> nameSr = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManagementTypesCompanion(
                id: id,
                code: code,
                nameEn: nameEn,
                nameSr: nameSr,
                description: description,
                sortOrder: sortOrder,
                active: active,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String nameEn,
                required String nameSr,
                required String description,
                required int sortOrder,
                required bool active,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManagementTypesCompanion.insert(
                id: id,
                code: code,
                nameEn: nameEn,
                nameSr: nameSr,
                description: description,
                sortOrder: sortOrder,
                active: active,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ManagementTypesTable, ManagementType>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ManagementTypesTable,
                    ManagementType
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManagementTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ManagementTypesTable,
      ManagementType,
      $$ManagementTypesTableFilterComposer,
      $$ManagementTypesTableOrderingComposer,
      $$ManagementTypesTableAnnotationComposer,
      $$ManagementTypesTableCreateCompanionBuilder,
      $$ManagementTypesTableUpdateCompanionBuilder,
      (
        ManagementType,
        BaseReferences<_$AppDatabase, $ManagementTypesTable, ManagementType>,
      ),
      ManagementType,
      PrefetchHooks Function()
    >;
typedef $$PlantTaxaTableCreateCompanionBuilder = PlantTaxaCompanion Function({
  required String id,
  required String scientificName,
  required String family,
  required String vernacularName,
  required String vernacularNameEn,
  required String taxonSource,
  required String taxonSourceId,
  required bool active,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$PlantTaxaTableUpdateCompanionBuilder = PlantTaxaCompanion Function({
  Value<String> id,
  Value<String> scientificName,
  Value<String> family,
  Value<String> vernacularName,
  Value<String> vernacularNameEn,
  Value<String> taxonSource,
  Value<String> taxonSourceId,
  Value<bool> active,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$PlantTaxaTableFilterComposer
    extends Composer<_$AppDatabase, $PlantTaxaTable> {
  $$PlantTaxaTableFilterComposer({
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

  ColumnFilters<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vernacularName => $composableBuilder(
    column: $table.vernacularName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vernacularNameEn => $composableBuilder(
    column: $table.vernacularNameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonSource => $composableBuilder(
    column: $table.taxonSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonSourceId => $composableBuilder(
    column: $table.taxonSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlantTaxaTableOrderingComposer
    extends Composer<_$AppDatabase, $PlantTaxaTable> {
  $$PlantTaxaTableOrderingComposer({
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

  ColumnOrderings<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vernacularName => $composableBuilder(
    column: $table.vernacularName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vernacularNameEn => $composableBuilder(
    column: $table.vernacularNameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonSource => $composableBuilder(
    column: $table.taxonSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonSourceId => $composableBuilder(
    column: $table.taxonSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlantTaxaTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlantTaxaTable> {
  $$PlantTaxaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get family =>
      $composableBuilder(column: $table.family, builder: (column) => column);

  GeneratedColumn<String> get vernacularName => $composableBuilder(
    column: $table.vernacularName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vernacularNameEn => $composableBuilder(
    column: $table.vernacularNameEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonSource => $composableBuilder(
    column: $table.taxonSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonSourceId => $composableBuilder(
    column: $table.taxonSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$PlantTaxaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlantTaxaTable,
          PlantTaxon,
          $$PlantTaxaTableFilterComposer,
          $$PlantTaxaTableOrderingComposer,
          $$PlantTaxaTableAnnotationComposer,
          $$PlantTaxaTableCreateCompanionBuilder,
          $$PlantTaxaTableUpdateCompanionBuilder,
          (
            PlantTaxon,
            BaseReferences<_$AppDatabase, $PlantTaxaTable, PlantTaxon>,
          ),
          PlantTaxon,
          PrefetchHooks Function()
        > {
  $$PlantTaxaTableTableManager(_$AppDatabase db, $PlantTaxaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlantTaxaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlantTaxaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlantTaxaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scientificName = const Value.absent(),
                Value<String> family = const Value.absent(),
                Value<String> vernacularName = const Value.absent(),
                Value<String> vernacularNameEn = const Value.absent(),
                Value<String> taxonSource = const Value.absent(),
                Value<String> taxonSourceId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantTaxaCompanion(
                id: id,
                scientificName: scientificName,
                family: family,
                vernacularName: vernacularName,
                vernacularNameEn: vernacularNameEn,
                taxonSource: taxonSource,
                taxonSourceId: taxonSourceId,
                active: active,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scientificName,
                required String family,
                required String vernacularName,
                required String vernacularNameEn,
                required String taxonSource,
                required String taxonSourceId,
                required bool active,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlantTaxaCompanion.insert(
                id: id,
                scientificName: scientificName,
                family: family,
                vernacularName: vernacularName,
                vernacularNameEn: vernacularNameEn,
                taxonSource: taxonSource,
                taxonSourceId: taxonSourceId,
                active: active,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlantTaxaTable, PlantTaxon>(table),
                  BaseReferences<_$AppDatabase, $PlantTaxaTable, PlantTaxon>(
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

typedef $$PlantTaxaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlantTaxaTable,
      PlantTaxon,
      $$PlantTaxaTableFilterComposer,
      $$PlantTaxaTableOrderingComposer,
      $$PlantTaxaTableAnnotationComposer,
      $$PlantTaxaTableCreateCompanionBuilder,
      $$PlantTaxaTableUpdateCompanionBuilder,
      (PlantTaxon, BaseReferences<_$AppDatabase, $PlantTaxaTable, PlantTaxon>),
      PlantTaxon,
      PrefetchHooks Function()
    >;
typedef $$ProjectProtocolsTableCreateCompanionBuilder =
    ProjectProtocolsCompanion Function({
      required String projectId,
      required String id,
      required String protocolVersion,
      required String surveyMethod,
      required DateTime seasonStart,
      required DateTime seasonEnd,
      required String dayStartTime,
      required String dayEndTime,
      required double minTemperatureC,
      required double sunnyTemperatureC,
      required int maxCloudCoverPctIfCool,
      required int maxWindBeaufort,
      required bool allowPrecipitation,
      required int targetVisitsPerSeason,
      required double maxDistanceFromTransectM,
      required int observationTimeToleranceMin,
      required int gpsIntervalS,
      required int gpsIntervalBatterySaverS,
      required double gpsAccuracyWarningM,
      required int gpsGapS,
      required int highCountThreshold,
      required int minCoveragePct,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProjectProtocolsTableUpdateCompanionBuilder =
    ProjectProtocolsCompanion Function({
      Value<String> projectId,
      Value<String> id,
      Value<String> protocolVersion,
      Value<String> surveyMethod,
      Value<DateTime> seasonStart,
      Value<DateTime> seasonEnd,
      Value<String> dayStartTime,
      Value<String> dayEndTime,
      Value<double> minTemperatureC,
      Value<double> sunnyTemperatureC,
      Value<int> maxCloudCoverPctIfCool,
      Value<int> maxWindBeaufort,
      Value<bool> allowPrecipitation,
      Value<int> targetVisitsPerSeason,
      Value<double> maxDistanceFromTransectM,
      Value<int> observationTimeToleranceMin,
      Value<int> gpsIntervalS,
      Value<int> gpsIntervalBatterySaverS,
      Value<double> gpsAccuracyWarningM,
      Value<int> gpsGapS,
      Value<int> highCountThreshold,
      Value<int> minCoveragePct,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$ProjectProtocolsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProjectProtocolsTable, ProjectProtocol> {
  $$ProjectProtocolsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('project_protocol__project_id__project__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProjectProtocolsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectProtocolsTable> {
  $$ProjectProtocolsTableFilterComposer({
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

  ColumnFilters<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyMethod => $composableBuilder(
    column: $table.surveyMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get seasonStart => $composableBuilder(
    column: $table.seasonStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get seasonEnd => $composableBuilder(
    column: $table.seasonEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayStartTime => $composableBuilder(
    column: $table.dayStartTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayEndTime => $composableBuilder(
    column: $table.dayEndTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minTemperatureC => $composableBuilder(
    column: $table.minTemperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sunnyTemperatureC => $composableBuilder(
    column: $table.sunnyTemperatureC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxCloudCoverPctIfCool => $composableBuilder(
    column: $table.maxCloudCoverPctIfCool,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxWindBeaufort => $composableBuilder(
    column: $table.maxWindBeaufort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowPrecipitation => $composableBuilder(
    column: $table.allowPrecipitation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetVisitsPerSeason => $composableBuilder(
    column: $table.targetVisitsPerSeason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxDistanceFromTransectM => $composableBuilder(
    column: $table.maxDistanceFromTransectM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observationTimeToleranceMin => $composableBuilder(
    column: $table.observationTimeToleranceMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gpsIntervalS => $composableBuilder(
    column: $table.gpsIntervalS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gpsIntervalBatterySaverS => $composableBuilder(
    column: $table.gpsIntervalBatterySaverS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gpsAccuracyWarningM => $composableBuilder(
    column: $table.gpsAccuracyWarningM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gpsGapS => $composableBuilder(
    column: $table.gpsGapS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get highCountThreshold => $composableBuilder(
    column: $table.highCountThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minCoveragePct => $composableBuilder(
    column: $table.minCoveragePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectProtocolsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectProtocolsTable> {
  $$ProjectProtocolsTableOrderingComposer({
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

  ColumnOrderings<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyMethod => $composableBuilder(
    column: $table.surveyMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get seasonStart => $composableBuilder(
    column: $table.seasonStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get seasonEnd => $composableBuilder(
    column: $table.seasonEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayStartTime => $composableBuilder(
    column: $table.dayStartTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayEndTime => $composableBuilder(
    column: $table.dayEndTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minTemperatureC => $composableBuilder(
    column: $table.minTemperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sunnyTemperatureC => $composableBuilder(
    column: $table.sunnyTemperatureC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxCloudCoverPctIfCool => $composableBuilder(
    column: $table.maxCloudCoverPctIfCool,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxWindBeaufort => $composableBuilder(
    column: $table.maxWindBeaufort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowPrecipitation => $composableBuilder(
    column: $table.allowPrecipitation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetVisitsPerSeason => $composableBuilder(
    column: $table.targetVisitsPerSeason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxDistanceFromTransectM => $composableBuilder(
    column: $table.maxDistanceFromTransectM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observationTimeToleranceMin => $composableBuilder(
    column: $table.observationTimeToleranceMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gpsIntervalS => $composableBuilder(
    column: $table.gpsIntervalS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gpsIntervalBatterySaverS => $composableBuilder(
    column: $table.gpsIntervalBatterySaverS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gpsAccuracyWarningM => $composableBuilder(
    column: $table.gpsAccuracyWarningM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gpsGapS => $composableBuilder(
    column: $table.gpsGapS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get highCountThreshold => $composableBuilder(
    column: $table.highCountThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minCoveragePct => $composableBuilder(
    column: $table.minCoveragePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectProtocolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectProtocolsTable> {
  $$ProjectProtocolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get surveyMethod => $composableBuilder(
    column: $table.surveyMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get seasonStart => $composableBuilder(
    column: $table.seasonStart,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get seasonEnd =>
      $composableBuilder(column: $table.seasonEnd, builder: (column) => column);

  GeneratedColumn<String> get dayStartTime => $composableBuilder(
    column: $table.dayStartTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dayEndTime => $composableBuilder(
    column: $table.dayEndTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minTemperatureC => $composableBuilder(
    column: $table.minTemperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sunnyTemperatureC => $composableBuilder(
    column: $table.sunnyTemperatureC,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxCloudCoverPctIfCool => $composableBuilder(
    column: $table.maxCloudCoverPctIfCool,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxWindBeaufort => $composableBuilder(
    column: $table.maxWindBeaufort,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowPrecipitation => $composableBuilder(
    column: $table.allowPrecipitation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetVisitsPerSeason => $composableBuilder(
    column: $table.targetVisitsPerSeason,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxDistanceFromTransectM => $composableBuilder(
    column: $table.maxDistanceFromTransectM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get observationTimeToleranceMin => $composableBuilder(
    column: $table.observationTimeToleranceMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gpsIntervalS => $composableBuilder(
    column: $table.gpsIntervalS,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gpsIntervalBatterySaverS => $composableBuilder(
    column: $table.gpsIntervalBatterySaverS,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gpsAccuracyWarningM => $composableBuilder(
    column: $table.gpsAccuracyWarningM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gpsGapS =>
      $composableBuilder(column: $table.gpsGapS, builder: (column) => column);

  GeneratedColumn<int> get highCountThreshold => $composableBuilder(
    column: $table.highCountThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minCoveragePct => $composableBuilder(
    column: $table.minCoveragePct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectProtocolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectProtocolsTable,
          ProjectProtocol,
          $$ProjectProtocolsTableFilterComposer,
          $$ProjectProtocolsTableOrderingComposer,
          $$ProjectProtocolsTableAnnotationComposer,
          $$ProjectProtocolsTableCreateCompanionBuilder,
          $$ProjectProtocolsTableUpdateCompanionBuilder,
          (ProjectProtocol, $$ProjectProtocolsTableReferences),
          ProjectProtocol,
          PrefetchHooks Function({bool projectId})
        > {
  $$ProjectProtocolsTableTableManager(
    _$AppDatabase db,
    $ProjectProtocolsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectProtocolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectProtocolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectProtocolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> projectId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> protocolVersion = const Value.absent(),
                Value<String> surveyMethod = const Value.absent(),
                Value<DateTime> seasonStart = const Value.absent(),
                Value<DateTime> seasonEnd = const Value.absent(),
                Value<String> dayStartTime = const Value.absent(),
                Value<String> dayEndTime = const Value.absent(),
                Value<double> minTemperatureC = const Value.absent(),
                Value<double> sunnyTemperatureC = const Value.absent(),
                Value<int> maxCloudCoverPctIfCool = const Value.absent(),
                Value<int> maxWindBeaufort = const Value.absent(),
                Value<bool> allowPrecipitation = const Value.absent(),
                Value<int> targetVisitsPerSeason = const Value.absent(),
                Value<double> maxDistanceFromTransectM = const Value.absent(),
                Value<int> observationTimeToleranceMin = const Value.absent(),
                Value<int> gpsIntervalS = const Value.absent(),
                Value<int> gpsIntervalBatterySaverS = const Value.absent(),
                Value<double> gpsAccuracyWarningM = const Value.absent(),
                Value<int> gpsGapS = const Value.absent(),
                Value<int> highCountThreshold = const Value.absent(),
                Value<int> minCoveragePct = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectProtocolsCompanion(
                projectId: projectId,
                id: id,
                protocolVersion: protocolVersion,
                surveyMethod: surveyMethod,
                seasonStart: seasonStart,
                seasonEnd: seasonEnd,
                dayStartTime: dayStartTime,
                dayEndTime: dayEndTime,
                minTemperatureC: minTemperatureC,
                sunnyTemperatureC: sunnyTemperatureC,
                maxCloudCoverPctIfCool: maxCloudCoverPctIfCool,
                maxWindBeaufort: maxWindBeaufort,
                allowPrecipitation: allowPrecipitation,
                targetVisitsPerSeason: targetVisitsPerSeason,
                maxDistanceFromTransectM: maxDistanceFromTransectM,
                observationTimeToleranceMin: observationTimeToleranceMin,
                gpsIntervalS: gpsIntervalS,
                gpsIntervalBatterySaverS: gpsIntervalBatterySaverS,
                gpsAccuracyWarningM: gpsAccuracyWarningM,
                gpsGapS: gpsGapS,
                highCountThreshold: highCountThreshold,
                minCoveragePct: minCoveragePct,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String projectId,
                required String id,
                required String protocolVersion,
                required String surveyMethod,
                required DateTime seasonStart,
                required DateTime seasonEnd,
                required String dayStartTime,
                required String dayEndTime,
                required double minTemperatureC,
                required double sunnyTemperatureC,
                required int maxCloudCoverPctIfCool,
                required int maxWindBeaufort,
                required bool allowPrecipitation,
                required int targetVisitsPerSeason,
                required double maxDistanceFromTransectM,
                required int observationTimeToleranceMin,
                required int gpsIntervalS,
                required int gpsIntervalBatterySaverS,
                required double gpsAccuracyWarningM,
                required int gpsGapS,
                required int highCountThreshold,
                required int minCoveragePct,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectProtocolsCompanion.insert(
                projectId: projectId,
                id: id,
                protocolVersion: protocolVersion,
                surveyMethod: surveyMethod,
                seasonStart: seasonStart,
                seasonEnd: seasonEnd,
                dayStartTime: dayStartTime,
                dayEndTime: dayEndTime,
                minTemperatureC: minTemperatureC,
                sunnyTemperatureC: sunnyTemperatureC,
                maxCloudCoverPctIfCool: maxCloudCoverPctIfCool,
                maxWindBeaufort: maxWindBeaufort,
                allowPrecipitation: allowPrecipitation,
                targetVisitsPerSeason: targetVisitsPerSeason,
                maxDistanceFromTransectM: maxDistanceFromTransectM,
                observationTimeToleranceMin: observationTimeToleranceMin,
                gpsIntervalS: gpsIntervalS,
                gpsIntervalBatterySaverS: gpsIntervalBatterySaverS,
                gpsAccuracyWarningM: gpsAccuracyWarningM,
                gpsGapS: gpsGapS,
                highCountThreshold: highCountThreshold,
                minCoveragePct: minCoveragePct,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectProtocolsTable, ProjectProtocol>(table),
                  $$ProjectProtocolsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
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
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$ProjectProtocolsTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$ProjectProtocolsTableReferences
                            ._projectIdTable(db)
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

typedef $$ProjectProtocolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectProtocolsTable,
      ProjectProtocol,
      $$ProjectProtocolsTableFilterComposer,
      $$ProjectProtocolsTableOrderingComposer,
      $$ProjectProtocolsTableAnnotationComposer,
      $$ProjectProtocolsTableCreateCompanionBuilder,
      $$ProjectProtocolsTableUpdateCompanionBuilder,
      (ProjectProtocol, $$ProjectProtocolsTableReferences),
      ProjectProtocol,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$SyncConflictsTableCreateCompanionBuilder =
    SyncConflictsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String operation,
      required String conflictingFields,
      required DateTime createdAt,
      Value<DateTime?> resolvedAt,
      required String resolutionNote,
      required String status,
      Value<String?> projectId,
      Value<SyncStatus> syncStatus,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$SyncConflictsTableUpdateCompanionBuilder =
    SyncConflictsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> conflictingFields,
      Value<DateTime> createdAt,
      Value<DateTime?> resolvedAt,
      Value<String> resolutionNote,
      Value<String> status,
      Value<String?> projectId,
      Value<SyncStatus> syncStatus,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$SyncConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictingFields => $composableBuilder(
    column: $table.conflictingFields,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolutionNote => $composableBuilder(
    column: $table.resolutionNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictingFields => $composableBuilder(
    column: $table.conflictingFields,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolutionNote => $composableBuilder(
    column: $table.resolutionNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConflictsTable> {
  $$SyncConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get conflictingFields => $composableBuilder(
    column: $table.conflictingFields,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolutionNote => $composableBuilder(
    column: $table.resolutionNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SyncConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncConflictsTable,
          SyncConflict,
          $$SyncConflictsTableFilterComposer,
          $$SyncConflictsTableOrderingComposer,
          $$SyncConflictsTableAnnotationComposer,
          $$SyncConflictsTableCreateCompanionBuilder,
          $$SyncConflictsTableUpdateCompanionBuilder,
          (
            SyncConflict,
            BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflict>,
          ),
          SyncConflict,
          PrefetchHooks Function()
        > {
  $$SyncConflictsTableTableManager(_$AppDatabase db, $SyncConflictsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> conflictingFields = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String> resolutionNote = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                conflictingFields: conflictingFields,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                resolutionNote: resolutionNote,
                status: status,
                projectId: projectId,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String operation,
                required String conflictingFields,
                required DateTime createdAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                required String resolutionNote,
                required String status,
                Value<String?> projectId = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncConflictsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                conflictingFields: conflictingFields,
                createdAt: createdAt,
                resolvedAt: resolvedAt,
                resolutionNote: resolutionNote,
                status: status,
                projectId: projectId,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncConflictsTable, SyncConflict>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncConflictsTable,
                    SyncConflict
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncConflictsTable,
      SyncConflict,
      $$SyncConflictsTableFilterComposer,
      $$SyncConflictsTableOrderingComposer,
      $$SyncConflictsTableAnnotationComposer,
      $$SyncConflictsTableCreateCompanionBuilder,
      $$SyncConflictsTableUpdateCompanionBuilder,
      (
        SyncConflict,
        BaseReferences<_$AppDatabase, $SyncConflictsTable, SyncConflict>,
      ),
      SyncConflict,
      PrefetchHooks Function()
    >;
typedef $$TransectsTableCreateCompanionBuilder = TransectsCompanion Function({
  required String id,
  required String projectId,
  required String code,
  required String name,
  required String description,
  Value<double?> targetLengthM,
  required String habitatSummary,
  required bool active,
  required String geometry,
  required double lengthM,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$TransectsTableUpdateCompanionBuilder = TransectsCompanion Function({
  Value<String> id,
  Value<String> projectId,
  Value<String> code,
  Value<String> name,
  Value<String> description,
  Value<double?> targetLengthM,
  Value<String> habitatSummary,
  Value<bool> active,
  Value<String> geometry,
  Value<double> lengthM,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$TransectsTableReferences
    extends BaseReferences<_$AppDatabase, $TransectsTable, Transect> {
  $$TransectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('transect__project_id__project__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SurveyVisitsTable, List<SurveyVisit>>
  _surveyVisitsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.surveyVisits,
    aliasName: 'transect__id__survey_visit__transect_id',
  );

  $$SurveyVisitsTableProcessedTableManager get surveyVisitsRefs {
    final manager = $$SurveyVisitsTableTableManager(
      $_db,
      $_db.surveyVisits,
    ).filter((f) => f.transectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_surveyVisitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransectSectionsTable, List<TransectSection>>
  _transectSectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transectSections,
    aliasName: 'transect__id__transect_section__transect_id',
  );

  $$TransectSectionsTableProcessedTableManager get transectSectionsRefs {
    final manager = $$TransectSectionsTableTableManager(
      $_db,
      $_db.transectSections,
    ).filter((f) => f.transectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _transectSectionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TransectsTableFilterComposer
    extends Composer<_$AppDatabase, $TransectsTable> {
  $$TransectsTableFilterComposer({
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

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetLengthM => $composableBuilder(
    column: $table.targetLengthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitatSummary => $composableBuilder(
    column: $table.habitatSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lengthM => $composableBuilder(
    column: $table.lengthM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> surveyVisitsRefs(
    Expression<bool> Function($$SurveyVisitsTableFilterComposer f) f,
  ) {
    final $$SurveyVisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surveyVisits,
      getReferencedColumn: (t) => t.transectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveyVisitsTableFilterComposer(
            $db: $db,
            $table: $db.surveyVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transectSectionsRefs(
    Expression<bool> Function($$TransectSectionsTableFilterComposer f) f,
  ) {
    final $$TransectSectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transectSections,
      getReferencedColumn: (t) => t.transectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectSectionsTableFilterComposer(
            $db: $db,
            $table: $db.transectSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransectsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransectsTable> {
  $$TransectsTableOrderingComposer({
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

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetLengthM => $composableBuilder(
    column: $table.targetLengthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitatSummary => $composableBuilder(
    column: $table.habitatSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lengthM => $composableBuilder(
    column: $table.lengthM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransectsTable> {
  $$TransectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetLengthM => $composableBuilder(
    column: $table.targetLengthM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get habitatSummary => $composableBuilder(
    column: $table.habitatSummary,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get geometry =>
      $composableBuilder(column: $table.geometry, builder: (column) => column);

  GeneratedColumn<double> get lengthM =>
      $composableBuilder(column: $table.lengthM, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> surveyVisitsRefs<T extends Object>(
    Expression<T> Function($$SurveyVisitsTableAnnotationComposer a) f,
  ) {
    final $$SurveyVisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.surveyVisits,
      getReferencedColumn: (t) => t.transectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveyVisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.surveyVisits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transectSectionsRefs<T extends Object>(
    Expression<T> Function($$TransectSectionsTableAnnotationComposer a) f,
  ) {
    final $$TransectSectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transectSections,
      getReferencedColumn: (t) => t.transectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectSectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transectSections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TransectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransectsTable,
          Transect,
          $$TransectsTableFilterComposer,
          $$TransectsTableOrderingComposer,
          $$TransectsTableAnnotationComposer,
          $$TransectsTableCreateCompanionBuilder,
          $$TransectsTableUpdateCompanionBuilder,
          (Transect, $$TransectsTableReferences),
          Transect,
          PrefetchHooks Function({
            bool projectId,
            bool surveyVisitsRefs,
            bool transectSectionsRefs,
          })
        > {
  $$TransectsTableTableManager(_$AppDatabase db, $TransectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double?> targetLengthM = const Value.absent(),
                Value<String> habitatSummary = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> geometry = const Value.absent(),
                Value<double> lengthM = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransectsCompanion(
                id: id,
                projectId: projectId,
                code: code,
                name: name,
                description: description,
                targetLengthM: targetLengthM,
                habitatSummary: habitatSummary,
                active: active,
                geometry: geometry,
                lengthM: lengthM,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String projectId,
                required String code,
                required String name,
                required String description,
                Value<double?> targetLengthM = const Value.absent(),
                required String habitatSummary,
                required bool active,
                required String geometry,
                required double lengthM,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransectsCompanion.insert(
                id: id,
                projectId: projectId,
                code: code,
                name: name,
                description: description,
                targetLengthM: targetLengthM,
                habitatSummary: habitatSummary,
                active: active,
                geometry: geometry,
                lengthM: lengthM,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransectsTable, Transect>(table),
                  $$TransectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                projectId = false,
                surveyVisitsRefs = false,
                transectSectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (surveyVisitsRefs) db.surveyVisits,
                    if (transectSectionsRefs) db.transectSections,
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
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$TransectsTableReferences
                                ._projectIdTable(db),
                            referencedColumn: $$TransectsTableReferences
                                ._projectIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (surveyVisitsRefs)
                        await $_getPrefetchedData<
                          Transect,
                          $TransectsTable,
                          SurveyVisit
                        >(
                          currentTable: table,
                          referencedTable: $$TransectsTableReferences
                              ._surveyVisitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransectsTableReferences(
                                db,
                                table,
                                p0,
                              ).surveyVisitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (transectSectionsRefs)
                        await $_getPrefetchedData<
                          Transect,
                          $TransectsTable,
                          TransectSection
                        >(
                          currentTable: table,
                          referencedTable: $$TransectsTableReferences
                              ._transectSectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TransectsTableReferences(
                                db,
                                table,
                                p0,
                              ).transectSectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.transectId == item.id,
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

typedef $$TransectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransectsTable,
      Transect,
      $$TransectsTableFilterComposer,
      $$TransectsTableOrderingComposer,
      $$TransectsTableAnnotationComposer,
      $$TransectsTableCreateCompanionBuilder,
      $$TransectsTableUpdateCompanionBuilder,
      (Transect, $$TransectsTableReferences),
      Transect,
      PrefetchHooks Function({
        bool projectId,
        bool surveyVisitsRefs,
        bool transectSectionsRefs,
      })
    >;
typedef $$SurveyVisitsTableCreateCompanionBuilder =
    SurveyVisitsCompanion Function({
      Value<int?> serverVersion,
      Value<SyncStatus> syncStatus,
      Value<DateTime?> deletedAt,
      required String id,
      required String projectId,
      required String transectId,
      required String observerId,
      required String protocolVersion,
      Value<String> surveyMethod,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
      Value<int> pausedSeconds,
      Value<double?> distanceWalkedM,
      Value<int> observerCount,
      Value<String> observerNames,
      Value<double?> temperatureStartC,
      Value<double?> temperatureEndC,
      Value<int?> windBeaufortStart,
      Value<int?> windBeaufortEnd,
      Value<int?> cloudCoverStartPct,
      Value<int?> cloudCoverEndPct,
      Value<String> precipitation,
      Value<bool?> weatherSuitable,
      Value<String> weatherMissingReason,
      Value<bool> zeroObservationConfirmed,
      Value<String> notes,
      Value<String> status,
      Value<String> cancelReason,
      Value<bool> batterySaverUsed,
      Value<String> deviceId,
      Value<bool> createdOffline,
      required DateTime createdAt,
      Value<DateTime?> pausedAt,
      Value<int> rowid,
    });
typedef $$SurveyVisitsTableUpdateCompanionBuilder =
    SurveyVisitsCompanion Function({
      Value<int?> serverVersion,
      Value<SyncStatus> syncStatus,
      Value<DateTime?> deletedAt,
      Value<String> id,
      Value<String> projectId,
      Value<String> transectId,
      Value<String> observerId,
      Value<String> protocolVersion,
      Value<String> surveyMethod,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<int?> durationSeconds,
      Value<int> pausedSeconds,
      Value<double?> distanceWalkedM,
      Value<int> observerCount,
      Value<String> observerNames,
      Value<double?> temperatureStartC,
      Value<double?> temperatureEndC,
      Value<int?> windBeaufortStart,
      Value<int?> windBeaufortEnd,
      Value<int?> cloudCoverStartPct,
      Value<int?> cloudCoverEndPct,
      Value<String> precipitation,
      Value<bool?> weatherSuitable,
      Value<String> weatherMissingReason,
      Value<bool> zeroObservationConfirmed,
      Value<String> notes,
      Value<String> status,
      Value<String> cancelReason,
      Value<bool> batterySaverUsed,
      Value<String> deviceId,
      Value<bool> createdOffline,
      Value<DateTime> createdAt,
      Value<DateTime?> pausedAt,
      Value<int> rowid,
    });

final class $$SurveyVisitsTableReferences
    extends BaseReferences<_$AppDatabase, $SurveyVisitsTable, SurveyVisit> {
  $$SurveyVisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('survey_visit__project_id__project__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TransectsTable _transectIdTable(_$AppDatabase db) =>
      db.transects.createAlias('survey_visit__transect_id__transect__id');

  $$TransectsTableProcessedTableManager get transectId {
    final $_column = $_itemColumn<String>('transect_id')!;

    final manager = $$TransectsTableTableManager(
      $_db,
      $_db.transects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SurveyVisitsTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyVisitsTable> {
  $$SurveyVisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncStatus, SyncStatus, String>
  get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observerId => $composableBuilder(
    column: $table.observerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyMethod => $composableBuilder(
    column: $table.surveyMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceWalkedM => $composableBuilder(
    column: $table.distanceWalkedM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observerCount => $composableBuilder(
    column: $table.observerCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observerNames => $composableBuilder(
    column: $table.observerNames,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureStartC => $composableBuilder(
    column: $table.temperatureStartC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureEndC => $composableBuilder(
    column: $table.temperatureEndC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windBeaufortStart => $composableBuilder(
    column: $table.windBeaufortStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windBeaufortEnd => $composableBuilder(
    column: $table.windBeaufortEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudCoverStartPct => $composableBuilder(
    column: $table.cloudCoverStartPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cloudCoverEndPct => $composableBuilder(
    column: $table.cloudCoverEndPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get precipitation => $composableBuilder(
    column: $table.precipitation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get weatherSuitable => $composableBuilder(
    column: $table.weatherSuitable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weatherMissingReason => $composableBuilder(
    column: $table.weatherMissingReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get zeroObservationConfirmed => $composableBuilder(
    column: $table.zeroObservationConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get batterySaverUsed => $composableBuilder(
    column: $table.batterySaverUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get createdOffline => $composableBuilder(
    column: $table.createdOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransectsTableFilterComposer get transectId {
    final $$TransectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transectId,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableFilterComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurveyVisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyVisitsTable> {
  $$SurveyVisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observerId => $composableBuilder(
    column: $table.observerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyMethod => $composableBuilder(
    column: $table.surveyMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceWalkedM => $composableBuilder(
    column: $table.distanceWalkedM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observerCount => $composableBuilder(
    column: $table.observerCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observerNames => $composableBuilder(
    column: $table.observerNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureStartC => $composableBuilder(
    column: $table.temperatureStartC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureEndC => $composableBuilder(
    column: $table.temperatureEndC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windBeaufortStart => $composableBuilder(
    column: $table.windBeaufortStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windBeaufortEnd => $composableBuilder(
    column: $table.windBeaufortEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudCoverStartPct => $composableBuilder(
    column: $table.cloudCoverStartPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cloudCoverEndPct => $composableBuilder(
    column: $table.cloudCoverEndPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get precipitation => $composableBuilder(
    column: $table.precipitation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get weatherSuitable => $composableBuilder(
    column: $table.weatherSuitable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weatherMissingReason => $composableBuilder(
    column: $table.weatherMissingReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get zeroObservationConfirmed => $composableBuilder(
    column: $table.zeroObservationConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get batterySaverUsed => $composableBuilder(
    column: $table.batterySaverUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get createdOffline => $composableBuilder(
    column: $table.createdOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransectsTableOrderingComposer get transectId {
    final $$TransectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transectId,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableOrderingComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurveyVisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyVisitsTable> {
  $$SurveyVisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncStatus, String> get syncStatus =>
      $composableBuilder(
        column: $table.syncStatus,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get observerId => $composableBuilder(
    column: $table.observerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get protocolVersion => $composableBuilder(
    column: $table.protocolVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get surveyMethod => $composableBuilder(
    column: $table.surveyMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pausedSeconds => $composableBuilder(
    column: $table.pausedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceWalkedM => $composableBuilder(
    column: $table.distanceWalkedM,
    builder: (column) => column,
  );

  GeneratedColumn<int> get observerCount => $composableBuilder(
    column: $table.observerCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observerNames => $composableBuilder(
    column: $table.observerNames,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureStartC => $composableBuilder(
    column: $table.temperatureStartC,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureEndC => $composableBuilder(
    column: $table.temperatureEndC,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windBeaufortStart => $composableBuilder(
    column: $table.windBeaufortStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windBeaufortEnd => $composableBuilder(
    column: $table.windBeaufortEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudCoverStartPct => $composableBuilder(
    column: $table.cloudCoverStartPct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cloudCoverEndPct => $composableBuilder(
    column: $table.cloudCoverEndPct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get precipitation => $composableBuilder(
    column: $table.precipitation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get weatherSuitable => $composableBuilder(
    column: $table.weatherSuitable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weatherMissingReason => $composableBuilder(
    column: $table.weatherMissingReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get zeroObservationConfirmed => $composableBuilder(
    column: $table.zeroObservationConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get batterySaverUsed => $composableBuilder(
    column: $table.batterySaverUsed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get createdOffline => $composableBuilder(
    column: $table.createdOffline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TransectsTableAnnotationComposer get transectId {
    final $$TransectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transectId,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableAnnotationComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SurveyVisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurveyVisitsTable,
          SurveyVisit,
          $$SurveyVisitsTableFilterComposer,
          $$SurveyVisitsTableOrderingComposer,
          $$SurveyVisitsTableAnnotationComposer,
          $$SurveyVisitsTableCreateCompanionBuilder,
          $$SurveyVisitsTableUpdateCompanionBuilder,
          (SurveyVisit, $$SurveyVisitsTableReferences),
          SurveyVisit,
          PrefetchHooks Function({bool projectId, bool transectId})
        > {
  $$SurveyVisitsTableTableManager(_$AppDatabase db, $SurveyVisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyVisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyVisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyVisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int?> serverVersion = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> transectId = const Value.absent(),
                Value<String> observerId = const Value.absent(),
                Value<String> protocolVersion = const Value.absent(),
                Value<String> surveyMethod = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<double?> distanceWalkedM = const Value.absent(),
                Value<int> observerCount = const Value.absent(),
                Value<String> observerNames = const Value.absent(),
                Value<double?> temperatureStartC = const Value.absent(),
                Value<double?> temperatureEndC = const Value.absent(),
                Value<int?> windBeaufortStart = const Value.absent(),
                Value<int?> windBeaufortEnd = const Value.absent(),
                Value<int?> cloudCoverStartPct = const Value.absent(),
                Value<int?> cloudCoverEndPct = const Value.absent(),
                Value<String> precipitation = const Value.absent(),
                Value<bool?> weatherSuitable = const Value.absent(),
                Value<String> weatherMissingReason = const Value.absent(),
                Value<bool> zeroObservationConfirmed = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> cancelReason = const Value.absent(),
                Value<bool> batterySaverUsed = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> createdOffline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveyVisitsCompanion(
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                id: id,
                projectId: projectId,
                transectId: transectId,
                observerId: observerId,
                protocolVersion: protocolVersion,
                surveyMethod: surveyMethod,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                pausedSeconds: pausedSeconds,
                distanceWalkedM: distanceWalkedM,
                observerCount: observerCount,
                observerNames: observerNames,
                temperatureStartC: temperatureStartC,
                temperatureEndC: temperatureEndC,
                windBeaufortStart: windBeaufortStart,
                windBeaufortEnd: windBeaufortEnd,
                cloudCoverStartPct: cloudCoverStartPct,
                cloudCoverEndPct: cloudCoverEndPct,
                precipitation: precipitation,
                weatherSuitable: weatherSuitable,
                weatherMissingReason: weatherMissingReason,
                zeroObservationConfirmed: zeroObservationConfirmed,
                notes: notes,
                status: status,
                cancelReason: cancelReason,
                batterySaverUsed: batterySaverUsed,
                deviceId: deviceId,
                createdOffline: createdOffline,
                createdAt: createdAt,
                pausedAt: pausedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<int?> serverVersion = const Value.absent(),
                Value<SyncStatus> syncStatus = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String id,
                required String projectId,
                required String transectId,
                required String observerId,
                required String protocolVersion,
                Value<String> surveyMethod = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> pausedSeconds = const Value.absent(),
                Value<double?> distanceWalkedM = const Value.absent(),
                Value<int> observerCount = const Value.absent(),
                Value<String> observerNames = const Value.absent(),
                Value<double?> temperatureStartC = const Value.absent(),
                Value<double?> temperatureEndC = const Value.absent(),
                Value<int?> windBeaufortStart = const Value.absent(),
                Value<int?> windBeaufortEnd = const Value.absent(),
                Value<int?> cloudCoverStartPct = const Value.absent(),
                Value<int?> cloudCoverEndPct = const Value.absent(),
                Value<String> precipitation = const Value.absent(),
                Value<bool?> weatherSuitable = const Value.absent(),
                Value<String> weatherMissingReason = const Value.absent(),
                Value<bool> zeroObservationConfirmed = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> cancelReason = const Value.absent(),
                Value<bool> batterySaverUsed = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> createdOffline = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveyVisitsCompanion.insert(
                serverVersion: serverVersion,
                syncStatus: syncStatus,
                deletedAt: deletedAt,
                id: id,
                projectId: projectId,
                transectId: transectId,
                observerId: observerId,
                protocolVersion: protocolVersion,
                surveyMethod: surveyMethod,
                startedAt: startedAt,
                endedAt: endedAt,
                durationSeconds: durationSeconds,
                pausedSeconds: pausedSeconds,
                distanceWalkedM: distanceWalkedM,
                observerCount: observerCount,
                observerNames: observerNames,
                temperatureStartC: temperatureStartC,
                temperatureEndC: temperatureEndC,
                windBeaufortStart: windBeaufortStart,
                windBeaufortEnd: windBeaufortEnd,
                cloudCoverStartPct: cloudCoverStartPct,
                cloudCoverEndPct: cloudCoverEndPct,
                precipitation: precipitation,
                weatherSuitable: weatherSuitable,
                weatherMissingReason: weatherMissingReason,
                zeroObservationConfirmed: zeroObservationConfirmed,
                notes: notes,
                status: status,
                cancelReason: cancelReason,
                batterySaverUsed: batterySaverUsed,
                deviceId: deviceId,
                createdOffline: createdOffline,
                createdAt: createdAt,
                pausedAt: pausedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SurveyVisitsTable, SurveyVisit>(table),
                  $$SurveyVisitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, transectId = false}) {
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
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$SurveyVisitsTableReferences
                            ._projectIdTable(db),
                        referencedColumn: $$SurveyVisitsTableReferences
                            ._projectIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (transectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transectId,
                        referencedTable: $$SurveyVisitsTableReferences
                            ._transectIdTable(db),
                        referencedColumn: $$SurveyVisitsTableReferences
                            ._transectIdTable(db)
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

typedef $$SurveyVisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurveyVisitsTable,
      SurveyVisit,
      $$SurveyVisitsTableFilterComposer,
      $$SurveyVisitsTableOrderingComposer,
      $$SurveyVisitsTableAnnotationComposer,
      $$SurveyVisitsTableCreateCompanionBuilder,
      $$SurveyVisitsTableUpdateCompanionBuilder,
      (SurveyVisit, $$SurveyVisitsTableReferences),
      SurveyVisit,
      PrefetchHooks Function({bool projectId, bool transectId})
    >;
typedef $$TaxaTableCreateCompanionBuilder = TaxaCompanion Function({
  required String id,
  required String author,
  required String rank,
  required String genus,
  required String family,
  required String vernacularNameSr,
  required String vernacularNameEn,
  required String taxonSource,
  required String taxonSourceId,
  required bool active,
  required bool photoRequired,
  Value<String?> identificationNotes,
  Value<String?> acceptedNameId,
  required String introducedInId,
  Value<String?> retiredInId,
  required String scientificName,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$TaxaTableUpdateCompanionBuilder = TaxaCompanion Function({
  Value<String> id,
  Value<String> author,
  Value<String> rank,
  Value<String> genus,
  Value<String> family,
  Value<String> vernacularNameSr,
  Value<String> vernacularNameEn,
  Value<String> taxonSource,
  Value<String> taxonSourceId,
  Value<bool> active,
  Value<bool> photoRequired,
  Value<String?> identificationNotes,
  Value<String?> acceptedNameId,
  Value<String> introducedInId,
  Value<String?> retiredInId,
  Value<String> scientificName,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

class $$TaxaTableFilterComposer extends Composer<_$AppDatabase, $TaxaTable> {
  $$TaxaTableFilterComposer({
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

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genus => $composableBuilder(
    column: $table.genus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vernacularNameSr => $composableBuilder(
    column: $table.vernacularNameSr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vernacularNameEn => $composableBuilder(
    column: $table.vernacularNameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonSource => $composableBuilder(
    column: $table.taxonSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxonSourceId => $composableBuilder(
    column: $table.taxonSourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get photoRequired => $composableBuilder(
    column: $table.photoRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identificationNotes => $composableBuilder(
    column: $table.identificationNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acceptedNameId => $composableBuilder(
    column: $table.acceptedNameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get introducedInId => $composableBuilder(
    column: $table.introducedInId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get retiredInId => $composableBuilder(
    column: $table.retiredInId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaxaTableOrderingComposer extends Composer<_$AppDatabase, $TaxaTable> {
  $$TaxaTableOrderingComposer({
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

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rank => $composableBuilder(
    column: $table.rank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genus => $composableBuilder(
    column: $table.genus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get family => $composableBuilder(
    column: $table.family,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vernacularNameSr => $composableBuilder(
    column: $table.vernacularNameSr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vernacularNameEn => $composableBuilder(
    column: $table.vernacularNameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonSource => $composableBuilder(
    column: $table.taxonSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxonSourceId => $composableBuilder(
    column: $table.taxonSourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get photoRequired => $composableBuilder(
    column: $table.photoRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identificationNotes => $composableBuilder(
    column: $table.identificationNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acceptedNameId => $composableBuilder(
    column: $table.acceptedNameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get introducedInId => $composableBuilder(
    column: $table.introducedInId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retiredInId => $composableBuilder(
    column: $table.retiredInId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaxaTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaxaTable> {
  $$TaxaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get rank =>
      $composableBuilder(column: $table.rank, builder: (column) => column);

  GeneratedColumn<String> get genus =>
      $composableBuilder(column: $table.genus, builder: (column) => column);

  GeneratedColumn<String> get family =>
      $composableBuilder(column: $table.family, builder: (column) => column);

  GeneratedColumn<String> get vernacularNameSr => $composableBuilder(
    column: $table.vernacularNameSr,
    builder: (column) => column,
  );

  GeneratedColumn<String> get vernacularNameEn => $composableBuilder(
    column: $table.vernacularNameEn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonSource => $composableBuilder(
    column: $table.taxonSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxonSourceId => $composableBuilder(
    column: $table.taxonSourceId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<bool> get photoRequired => $composableBuilder(
    column: $table.photoRequired,
    builder: (column) => column,
  );

  GeneratedColumn<String> get identificationNotes => $composableBuilder(
    column: $table.identificationNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acceptedNameId => $composableBuilder(
    column: $table.acceptedNameId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get introducedInId => $composableBuilder(
    column: $table.introducedInId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get retiredInId => $composableBuilder(
    column: $table.retiredInId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scientificName => $composableBuilder(
    column: $table.scientificName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TaxaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaxaTable,
          Taxon,
          $$TaxaTableFilterComposer,
          $$TaxaTableOrderingComposer,
          $$TaxaTableAnnotationComposer,
          $$TaxaTableCreateCompanionBuilder,
          $$TaxaTableUpdateCompanionBuilder,
          (Taxon, BaseReferences<_$AppDatabase, $TaxaTable, Taxon>),
          Taxon,
          PrefetchHooks Function()
        > {
  $$TaxaTableTableManager(_$AppDatabase db, $TaxaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaxaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaxaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaxaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> author = const Value.absent(),
                Value<String> rank = const Value.absent(),
                Value<String> genus = const Value.absent(),
                Value<String> family = const Value.absent(),
                Value<String> vernacularNameSr = const Value.absent(),
                Value<String> vernacularNameEn = const Value.absent(),
                Value<String> taxonSource = const Value.absent(),
                Value<String> taxonSourceId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<bool> photoRequired = const Value.absent(),
                Value<String?> identificationNotes = const Value.absent(),
                Value<String?> acceptedNameId = const Value.absent(),
                Value<String> introducedInId = const Value.absent(),
                Value<String?> retiredInId = const Value.absent(),
                Value<String> scientificName = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaxaCompanion(
                id: id,
                author: author,
                rank: rank,
                genus: genus,
                family: family,
                vernacularNameSr: vernacularNameSr,
                vernacularNameEn: vernacularNameEn,
                taxonSource: taxonSource,
                taxonSourceId: taxonSourceId,
                active: active,
                photoRequired: photoRequired,
                identificationNotes: identificationNotes,
                acceptedNameId: acceptedNameId,
                introducedInId: introducedInId,
                retiredInId: retiredInId,
                scientificName: scientificName,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String author,
                required String rank,
                required String genus,
                required String family,
                required String vernacularNameSr,
                required String vernacularNameEn,
                required String taxonSource,
                required String taxonSourceId,
                required bool active,
                required bool photoRequired,
                Value<String?> identificationNotes = const Value.absent(),
                Value<String?> acceptedNameId = const Value.absent(),
                required String introducedInId,
                Value<String?> retiredInId = const Value.absent(),
                required String scientificName,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaxaCompanion.insert(
                id: id,
                author: author,
                rank: rank,
                genus: genus,
                family: family,
                vernacularNameSr: vernacularNameSr,
                vernacularNameEn: vernacularNameEn,
                taxonSource: taxonSource,
                taxonSourceId: taxonSourceId,
                active: active,
                photoRequired: photoRequired,
                identificationNotes: identificationNotes,
                acceptedNameId: acceptedNameId,
                introducedInId: introducedInId,
                retiredInId: retiredInId,
                scientificName: scientificName,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaxaTable, Taxon>(table),
                  BaseReferences<_$AppDatabase, $TaxaTable, Taxon>(
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

typedef $$TaxaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaxaTable,
      Taxon,
      $$TaxaTableFilterComposer,
      $$TaxaTableOrderingComposer,
      $$TaxaTableAnnotationComposer,
      $$TaxaTableCreateCompanionBuilder,
      $$TaxaTableUpdateCompanionBuilder,
      (Taxon, BaseReferences<_$AppDatabase, $TaxaTable, Taxon>),
      Taxon,
      PrefetchHooks Function()
    >;
typedef $$TaxonListVersionsTableCreateCompanionBuilder =
    TaxonListVersionsCompanion Function({
      required String id,
      required String versionLabel,
      required String source,
      required DateTime publishedAt,
      required bool isCurrent,
      required String notes,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TaxonListVersionsTableUpdateCompanionBuilder =
    TaxonListVersionsCompanion Function({
      Value<String> id,
      Value<String> versionLabel,
      Value<String> source,
      Value<DateTime> publishedAt,
      Value<bool> isCurrent,
      Value<String> notes,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$TaxonListVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $TaxonListVersionsTable> {
  $$TaxonListVersionsTableFilterComposer({
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

  ColumnFilters<String> get versionLabel => $composableBuilder(
    column: $table.versionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaxonListVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaxonListVersionsTable> {
  $$TaxonListVersionsTableOrderingComposer({
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

  ColumnOrderings<String> get versionLabel => $composableBuilder(
    column: $table.versionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCurrent => $composableBuilder(
    column: $table.isCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaxonListVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaxonListVersionsTable> {
  $$TaxonListVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get versionLabel => $composableBuilder(
    column: $table.versionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCurrent =>
      $composableBuilder(column: $table.isCurrent, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TaxonListVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaxonListVersionsTable,
          TaxonListVersion,
          $$TaxonListVersionsTableFilterComposer,
          $$TaxonListVersionsTableOrderingComposer,
          $$TaxonListVersionsTableAnnotationComposer,
          $$TaxonListVersionsTableCreateCompanionBuilder,
          $$TaxonListVersionsTableUpdateCompanionBuilder,
          (
            TaxonListVersion,
            BaseReferences<
              _$AppDatabase,
              $TaxonListVersionsTable,
              TaxonListVersion
            >,
          ),
          TaxonListVersion,
          PrefetchHooks Function()
        > {
  $$TaxonListVersionsTableTableManager(
    _$AppDatabase db,
    $TaxonListVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaxonListVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaxonListVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaxonListVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> versionLabel = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> publishedAt = const Value.absent(),
                Value<bool> isCurrent = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaxonListVersionsCompanion(
                id: id,
                versionLabel: versionLabel,
                source: source,
                publishedAt: publishedAt,
                isCurrent: isCurrent,
                notes: notes,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String versionLabel,
                required String source,
                required DateTime publishedAt,
                required bool isCurrent,
                required String notes,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaxonListVersionsCompanion.insert(
                id: id,
                versionLabel: versionLabel,
                source: source,
                publishedAt: publishedAt,
                isCurrent: isCurrent,
                notes: notes,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaxonListVersionsTable, TaxonListVersion>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TaxonListVersionsTable,
                    TaxonListVersion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaxonListVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaxonListVersionsTable,
      TaxonListVersion,
      $$TaxonListVersionsTableFilterComposer,
      $$TaxonListVersionsTableOrderingComposer,
      $$TaxonListVersionsTableAnnotationComposer,
      $$TaxonListVersionsTableCreateCompanionBuilder,
      $$TaxonListVersionsTableUpdateCompanionBuilder,
      (
        TaxonListVersion,
        BaseReferences<
          _$AppDatabase,
          $TaxonListVersionsTable,
          TaxonListVersion
        >,
      ),
      TaxonListVersion,
      PrefetchHooks Function()
    >;
typedef $$TransectSectionsTableCreateCompanionBuilder =
    TransectSectionsCompanion Function({
      required String id,
      required String transectId,
      required String sectionCode,
      required int sequenceNumber,
      required String notes,
      Value<String?> habitatTypeId,
      Value<String?> managementTypeId,
      required String geometry,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TransectSectionsTableUpdateCompanionBuilder =
    TransectSectionsCompanion Function({
      Value<String> id,
      Value<String> transectId,
      Value<String> sectionCode,
      Value<int> sequenceNumber,
      Value<String> notes,
      Value<String?> habitatTypeId,
      Value<String?> managementTypeId,
      Value<String> geometry,
      Value<int?> serverVersion,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$TransectSectionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TransectSectionsTable, TransectSection> {
  $$TransectSectionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TransectsTable _transectIdTable(_$AppDatabase db) =>
      db.transects.createAlias('transect_section__transect_id__transect__id');

  $$TransectsTableProcessedTableManager get transectId {
    final $_column = $_itemColumn<String>('transect_id')!;

    final manager = $$TransectsTableTableManager(
      $_db,
      $_db.transects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_transectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransectSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransectSectionsTable> {
  $$TransectSectionsTableFilterComposer({
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

  ColumnFilters<String> get sectionCode => $composableBuilder(
    column: $table.sectionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitatTypeId => $composableBuilder(
    column: $table.habitatTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managementTypeId => $composableBuilder(
    column: $table.managementTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TransectsTableFilterComposer get transectId {
    final $$TransectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transectId,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableFilterComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransectSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransectSectionsTable> {
  $$TransectSectionsTableOrderingComposer({
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

  ColumnOrderings<String> get sectionCode => $composableBuilder(
    column: $table.sectionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitatTypeId => $composableBuilder(
    column: $table.habitatTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managementTypeId => $composableBuilder(
    column: $table.managementTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geometry => $composableBuilder(
    column: $table.geometry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TransectsTableOrderingComposer get transectId {
    final $$TransectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transectId,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableOrderingComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransectSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransectSectionsTable> {
  $$TransectSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sectionCode => $composableBuilder(
    column: $table.sectionCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequenceNumber => $composableBuilder(
    column: $table.sequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get habitatTypeId => $composableBuilder(
    column: $table.habitatTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managementTypeId => $composableBuilder(
    column: $table.managementTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geometry =>
      $composableBuilder(column: $table.geometry, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$TransectsTableAnnotationComposer get transectId {
    final $$TransectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.transectId,
      referencedTable: $db.transects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransectsTableAnnotationComposer(
            $db: $db,
            $table: $db.transects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransectSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransectSectionsTable,
          TransectSection,
          $$TransectSectionsTableFilterComposer,
          $$TransectSectionsTableOrderingComposer,
          $$TransectSectionsTableAnnotationComposer,
          $$TransectSectionsTableCreateCompanionBuilder,
          $$TransectSectionsTableUpdateCompanionBuilder,
          (TransectSection, $$TransectSectionsTableReferences),
          TransectSection,
          PrefetchHooks Function({bool transectId})
        > {
  $$TransectSectionsTableTableManager(
    _$AppDatabase db,
    $TransectSectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransectSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransectSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransectSectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transectId = const Value.absent(),
                Value<String> sectionCode = const Value.absent(),
                Value<int> sequenceNumber = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> habitatTypeId = const Value.absent(),
                Value<String?> managementTypeId = const Value.absent(),
                Value<String> geometry = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransectSectionsCompanion(
                id: id,
                transectId: transectId,
                sectionCode: sectionCode,
                sequenceNumber: sequenceNumber,
                notes: notes,
                habitatTypeId: habitatTypeId,
                managementTypeId: managementTypeId,
                geometry: geometry,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transectId,
                required String sectionCode,
                required int sequenceNumber,
                required String notes,
                Value<String?> habitatTypeId = const Value.absent(),
                Value<String?> managementTypeId = const Value.absent(),
                required String geometry,
                Value<int?> serverVersion = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransectSectionsCompanion.insert(
                id: id,
                transectId: transectId,
                sectionCode: sectionCode,
                sequenceNumber: sequenceNumber,
                notes: notes,
                habitatTypeId: habitatTypeId,
                managementTypeId: managementTypeId,
                geometry: geometry,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransectSectionsTable, TransectSection>(table),
                  $$TransectSectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transectId = false}) {
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
                    if (transectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.transectId,
                        referencedTable: $$TransectSectionsTableReferences
                            ._transectIdTable(db),
                        referencedColumn: $$TransectSectionsTableReferences
                            ._transectIdTable(db)
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

typedef $$TransectSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransectSectionsTable,
      TransectSection,
      $$TransectSectionsTableFilterComposer,
      $$TransectSectionsTableOrderingComposer,
      $$TransectSectionsTableAnnotationComposer,
      $$TransectSectionsTableCreateCompanionBuilder,
      $$TransectSectionsTableUpdateCompanionBuilder,
      (TransectSection, $$TransectSectionsTableReferences),
      TransectSection,
      PrefetchHooks Function({bool transectId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SkeletonPingsTableTableManager get skeletonPings =>
      $$SkeletonPingsTableTableManager(_db, _db.skeletonPings);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncStateEntriesTableTableManager get syncStateEntries =>
      $$SyncStateEntriesTableTableManager(_db, _db.syncStateEntries);
  $$HabitatTypesTableTableManager get habitatTypes =>
      $$HabitatTypesTableTableManager(_db, _db.habitatTypes);
  $$ManagementTypesTableTableManager get managementTypes =>
      $$ManagementTypesTableTableManager(_db, _db.managementTypes);
  $$PlantTaxaTableTableManager get plantTaxa =>
      $$PlantTaxaTableTableManager(_db, _db.plantTaxa);
  $$ProjectProtocolsTableTableManager get projectProtocols =>
      $$ProjectProtocolsTableTableManager(_db, _db.projectProtocols);
  $$SyncConflictsTableTableManager get syncConflicts =>
      $$SyncConflictsTableTableManager(_db, _db.syncConflicts);
  $$TransectsTableTableManager get transects =>
      $$TransectsTableTableManager(_db, _db.transects);
  $$SurveyVisitsTableTableManager get surveyVisits =>
      $$SurveyVisitsTableTableManager(_db, _db.surveyVisits);
  $$TaxaTableTableManager get taxa => $$TaxaTableTableManager(_db, _db.taxa);
  $$TaxonListVersionsTableTableManager get taxonListVersions =>
      $$TaxonListVersionsTableTableManager(_db, _db.taxonListVersions);
  $$TransectSectionsTableTableManager get transectSections =>
      $$TransectSectionsTableTableManager(_db, _db.transectSections);
}
