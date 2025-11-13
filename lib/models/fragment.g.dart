// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fragment.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFragmentCollection on Isar {
  IsarCollection<Fragment> get fragments => this.collection();
}

const FragmentSchema = CollectionSchema(
  name: r'Fragment',
  id: 1200370221157439991,
  properties: {
    r'content': PropertySchema(id: 0, name: r'content', type: IsarType.string),
    r'created_at': PropertySchema(
      id: 1,
      name: r'created_at',
      type: IsarType.dateTime,
    ),
    r'deleted': PropertySchema(id: 2, name: r'deleted', type: IsarType.bool),
    r'event_time': PropertySchema(
      id: 3,
      name: r'event_time',
      type: IsarType.dateTime,
    ),
    r'event_time_source': PropertySchema(
      id: 4,
      name: r'event_time_source',
      type: IsarType.string,
    ),
    r'media_urls': PropertySchema(
      id: 5,
      name: r'media_urls',
      type: IsarType.stringList,
    ),
    r'refresh_at': PropertySchema(
      id: 6,
      name: r'refresh_at',
      type: IsarType.dateTime,
    ),
    r'remote_id': PropertySchema(
      id: 7,
      name: r'remote_id',
      type: IsarType.string,
    ),
    r'synced': PropertySchema(id: 8, name: r'synced', type: IsarType.bool),
    r'tags': PropertySchema(id: 9, name: r'tags', type: IsarType.stringList),
    r'timestamp': PropertySchema(
      id: 10,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'updated_at': PropertySchema(
      id: 11,
      name: r'updated_at',
      type: IsarType.dateTime,
    ),
    r'user_id': PropertySchema(id: 12, name: r'user_id', type: IsarType.string),
    r'user_tags': PropertySchema(
      id: 13,
      name: r'user_tags',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _fragmentEstimateSize,
  serialize: _fragmentSerialize,
  deserialize: _fragmentDeserialize,
  deserializeProp: _fragmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'user_id': IndexSchema(
      id: -3074470405631881311,
      name: r'user_id',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'user_id',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'event_time': IndexSchema(
      id: 2598929006402368359,
      name: r'event_time',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'event_time',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'remote_id': IndexSchema(
      id: -8889844212826224990,
      name: r'remote_id',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'remote_id',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'created_at': IndexSchema(
      id: 6296488693525790031,
      name: r'created_at',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'created_at',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'refresh_at': IndexSchema(
      id: 8104220179918393502,
      name: r'refresh_at',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'refresh_at',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'synced': IndexSchema(
      id: -4832663256418428922,
      name: r'synced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'synced',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'deleted': IndexSchema(
      id: 2416515181749931262,
      name: r'deleted',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deleted',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _fragmentGetId,
  getLinks: _fragmentGetLinks,
  attach: _fragmentAttach,
  version: '3.3.0-dev.1',
);

int _fragmentEstimateSize(
  Fragment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.eventTimeSource.length * 3;
  bytesCount += 3 + object.mediaUrls.length * 3;
  {
    for (var i = 0; i < object.mediaUrls.length; i++) {
      final value = object.mediaUrls[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.remoteID.length * 3;
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userTags.length * 3;
  {
    for (var i = 0; i < object.userTags.length; i++) {
      final value = object.userTags[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _fragmentSerialize(
  Fragment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.content);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.deleted);
  writer.writeDateTime(offsets[3], object.eventTime);
  writer.writeString(offsets[4], object.eventTimeSource);
  writer.writeStringList(offsets[5], object.mediaUrls);
  writer.writeDateTime(offsets[6], object.refreshAt);
  writer.writeString(offsets[7], object.remoteID);
  writer.writeBool(offsets[8], object.synced);
  writer.writeStringList(offsets[9], object.tags);
  writer.writeDateTime(offsets[10], object.timestamp);
  writer.writeDateTime(offsets[11], object.updatedAt);
  writer.writeString(offsets[12], object.userId);
  writer.writeStringList(offsets[13], object.userTags);
}

Fragment _fragmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Fragment();
  object.content = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deleted = reader.readBool(offsets[2]);
  object.eventTime = reader.readDateTime(offsets[3]);
  object.eventTimeSource = reader.readString(offsets[4]);
  object.mediaUrls = reader.readStringList(offsets[5]) ?? [];
  object.refreshAt = reader.readDateTimeOrNull(offsets[6]);
  object.remoteID = reader.readString(offsets[7]);
  object.synced = reader.readBool(offsets[8]);
  object.tags = reader.readStringList(offsets[9]) ?? [];
  object.timestamp = reader.readDateTime(offsets[10]);
  object.updatedAt = reader.readDateTime(offsets[11]);
  object.userId = reader.readStringOrNull(offsets[12]);
  object.userTags = reader.readStringList(offsets[13]) ?? [];
  return object;
}

P _fragmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringList(offset) ?? []) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readStringList(offset) ?? []) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _fragmentGetId(Fragment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _fragmentGetLinks(Fragment object) {
  return [];
}

void _fragmentAttach(IsarCollection<dynamic> col, Id id, Fragment object) {}

extension FragmentByIndex on IsarCollection<Fragment> {
  Future<Fragment?> getByRemoteID(String remoteID) {
    return getByIndex(r'remote_id', [remoteID]);
  }

  Fragment? getByRemoteIDSync(String remoteID) {
    return getByIndexSync(r'remote_id', [remoteID]);
  }

  Future<bool> deleteByRemoteID(String remoteID) {
    return deleteByIndex(r'remote_id', [remoteID]);
  }

  bool deleteByRemoteIDSync(String remoteID) {
    return deleteByIndexSync(r'remote_id', [remoteID]);
  }

  Future<List<Fragment?>> getAllByRemoteID(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return getAllByIndex(r'remote_id', values);
  }

  List<Fragment?> getAllByRemoteIDSync(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'remote_id', values);
  }

  Future<int> deleteAllByRemoteID(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'remote_id', values);
  }

  int deleteAllByRemoteIDSync(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'remote_id', values);
  }

  Future<Id> putByRemoteID(Fragment object) {
    return putByIndex(r'remote_id', object);
  }

  Id putByRemoteIDSync(Fragment object, {bool saveLinks = true}) {
    return putByIndexSync(r'remote_id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteID(List<Fragment> objects) {
    return putAllByIndex(r'remote_id', objects);
  }

  List<Id> putAllByRemoteIDSync(
    List<Fragment> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'remote_id', objects, saveLinks: saveLinks);
  }
}

extension FragmentQueryWhereSort on QueryBuilder<Fragment, Fragment, QWhere> {
  QueryBuilder<Fragment, Fragment, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhere> anyEventTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'event_time'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'created_at'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhere> anyRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'refresh_at'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhere> anySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'synced'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhere> anyDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deleted'),
      );
    });
  }
}

extension FragmentQueryWhere on QueryBuilder<Fragment, Fragment, QWhereClause> {
  QueryBuilder<Fragment, Fragment, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'user_id', value: [null]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'user_id',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> userIdEqualTo(
    String? userId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'user_id', value: [userId]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> userIdNotEqualTo(
    String? userId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'user_id',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'user_id',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'user_id',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'user_id',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> timestampEqualTo(
    DateTime timestamp,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'timestamp', value: [timestamp]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> timestampNotEqualTo(
    DateTime timestamp,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [],
                upper: [timestamp],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [timestamp],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [timestamp],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'timestamp',
                lower: [],
                upper: [timestamp],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'timestamp',
          lower: [timestamp],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'timestamp',
          lower: [],
          upper: [timestamp],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'timestamp',
          lower: [lowerTimestamp],
          includeLower: includeLower,
          upper: [upperTimestamp],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> eventTimeEqualTo(
    DateTime eventTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'event_time', value: [eventTime]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> eventTimeNotEqualTo(
    DateTime eventTime,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'event_time',
                lower: [],
                upper: [eventTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'event_time',
                lower: [eventTime],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'event_time',
                lower: [eventTime],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'event_time',
                lower: [],
                upper: [eventTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> eventTimeGreaterThan(
    DateTime eventTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'event_time',
          lower: [eventTime],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> eventTimeLessThan(
    DateTime eventTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'event_time',
          lower: [],
          upper: [eventTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> eventTimeBetween(
    DateTime lowerEventTime,
    DateTime upperEventTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'event_time',
          lower: [lowerEventTime],
          includeLower: includeLower,
          upper: [upperEventTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> remoteIDEqualTo(
    String remoteID,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remote_id', value: [remoteID]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> remoteIDNotEqualTo(
    String remoteID,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remote_id',
                lower: [],
                upper: [remoteID],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remote_id',
                lower: [remoteID],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remote_id',
                lower: [remoteID],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remote_id',
                lower: [],
                upper: [remoteID],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'created_at', value: [createdAt]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> createdAtNotEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'created_at',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'created_at',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'created_at',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'created_at',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> createdAtGreaterThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'created_at',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'created_at',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'created_at',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'refresh_at', value: [null]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'refresh_at',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtEqualTo(
    DateTime? refreshAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'refresh_at', value: [refreshAt]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtNotEqualTo(
    DateTime? refreshAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'refresh_at',
                lower: [],
                upper: [refreshAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'refresh_at',
                lower: [refreshAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'refresh_at',
                lower: [refreshAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'refresh_at',
                lower: [],
                upper: [refreshAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtGreaterThan(
    DateTime? refreshAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'refresh_at',
          lower: [refreshAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtLessThan(
    DateTime? refreshAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'refresh_at',
          lower: [],
          upper: [refreshAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> refreshAtBetween(
    DateTime? lowerRefreshAt,
    DateTime? upperRefreshAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'refresh_at',
          lower: [lowerRefreshAt],
          includeLower: includeLower,
          upper: [upperRefreshAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> syncedEqualTo(
    bool synced,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'synced', value: [synced]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> syncedNotEqualTo(
    bool synced,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [],
                upper: [synced],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [synced],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [synced],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'synced',
                lower: [],
                upper: [synced],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> deletedEqualTo(
    bool deleted,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deleted', value: [deleted]),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterWhereClause> deletedNotEqualTo(
    bool deleted,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deleted',
                lower: [],
                upper: [deleted],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deleted',
                lower: [deleted],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deleted',
                lower: [deleted],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deleted',
                lower: [],
                upper: [deleted],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension FragmentQueryFilter
    on QueryBuilder<Fragment, Fragment, QFilterCondition> {
  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'created_at', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'created_at',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'created_at',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'created_at',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> deletedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deleted', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> eventTimeEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'event_time', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> eventTimeGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'event_time',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> eventTimeLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'event_time',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> eventTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'event_time',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'event_time_source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'event_time_source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'event_time_source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'event_time_source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'event_time_source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'event_time_source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'event_time_source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'event_time_source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'event_time_source', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  eventTimeSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'event_time_source', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'media_urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'media_urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'media_urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'media_urls',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'media_urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'media_urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'media_urls',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'media_urls',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'media_urls', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'media_urls', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'media_urls', length, true, length, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> mediaUrlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'media_urls', 0, true, 0, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'media_urls', 0, false, 999999, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'media_urls', 0, true, length, include);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'media_urls', length, include, 999999, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  mediaUrlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'media_urls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> refreshAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'refresh_at'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> refreshAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'refresh_at'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> refreshAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refresh_at', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> refreshAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'refresh_at',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> refreshAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'refresh_at',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> refreshAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'refresh_at',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remote_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remote_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remote_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remote_id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remote_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remote_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remote_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remote_id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remote_id', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> remoteIDIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remote_id', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> syncedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'synced', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, true, length, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, 0, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, length, include);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, include, 999999, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> timestampEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updated_at', value: value),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updated_at',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updated_at',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updated_at',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'user_id'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'user_id'),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'user_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'user_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'user_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'user_id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'user_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'user_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'user_id',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'user_id',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'user_id', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'user_id', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'user_tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'user_tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'user_tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'user_tags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'user_tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'user_tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'user_tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'user_tags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'user_tags', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'user_tags', value: ''),
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userTagsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'user_tags', length, true, length, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'user_tags', 0, true, 0, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'user_tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'user_tags', 0, true, length, include);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition>
  userTagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'user_tags', length, include, 999999, true);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterFilterCondition> userTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'user_tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension FragmentQueryObject
    on QueryBuilder<Fragment, Fragment, QFilterCondition> {}

extension FragmentQueryLinks
    on QueryBuilder<Fragment, Fragment, QFilterCondition> {}

extension FragmentQuerySortBy on QueryBuilder<Fragment, Fragment, QSortBy> {
  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByEventTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByEventTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByEventTimeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time_source', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByEventTimeSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time_source', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByRefreshAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByRemoteID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByRemoteIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.desc);
    });
  }
}

extension FragmentQuerySortThenBy
    on QueryBuilder<Fragment, Fragment, QSortThenBy> {
  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByEventTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByEventTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByEventTimeSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time_source', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByEventTimeSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'event_time_source', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByRefreshAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByRemoteID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByRemoteIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.desc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.asc);
    });
  }

  QueryBuilder<Fragment, Fragment, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.desc);
    });
  }
}

extension FragmentQueryWhereDistinct
    on QueryBuilder<Fragment, Fragment, QDistinct> {
  QueryBuilder<Fragment, Fragment, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created_at');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deleted');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByEventTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'event_time');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByEventTimeSource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'event_time_source',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByMediaUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'media_urls');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refresh_at');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByRemoteID({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remote_id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updated_at');
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'user_id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Fragment, Fragment, QDistinct> distinctByUserTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'user_tags');
    });
  }
}

extension FragmentQueryProperty
    on QueryBuilder<Fragment, Fragment, QQueryProperty> {
  QueryBuilder<Fragment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Fragment, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<Fragment, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created_at');
    });
  }

  QueryBuilder<Fragment, bool, QQueryOperations> deletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deleted');
    });
  }

  QueryBuilder<Fragment, DateTime, QQueryOperations> eventTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'event_time');
    });
  }

  QueryBuilder<Fragment, String, QQueryOperations> eventTimeSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'event_time_source');
    });
  }

  QueryBuilder<Fragment, List<String>, QQueryOperations> mediaUrlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'media_urls');
    });
  }

  QueryBuilder<Fragment, DateTime?, QQueryOperations> refreshAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refresh_at');
    });
  }

  QueryBuilder<Fragment, String, QQueryOperations> remoteIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remote_id');
    });
  }

  QueryBuilder<Fragment, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<Fragment, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<Fragment, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<Fragment, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updated_at');
    });
  }

  QueryBuilder<Fragment, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'user_id');
    });
  }

  QueryBuilder<Fragment, List<String>, QQueryOperations> userTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'user_tags');
    });
  }
}
