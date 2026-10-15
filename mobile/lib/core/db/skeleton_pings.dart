import 'package:drift/drift.dart';

class SkeletonPings extends Table {
  TextColumn get id => text()();
  DateTimeColumn get observedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get sentAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'skeleton_ping';
}
