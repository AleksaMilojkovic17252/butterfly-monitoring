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
          ..write('area: $area, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [skeletonPings, projects];
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
  Value<String?> area,
  Value<int?> serverVersion,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

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

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
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
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
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
                area: area,
                serverVersion: serverVersion,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  BaseReferences<_$AppDatabase, $ProjectsTable, Project>(
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
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SkeletonPingsTableTableManager get skeletonPings =>
      $$SkeletonPingsTableTableManager(_db, _db.skeletonPings);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
}
