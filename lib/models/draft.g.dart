// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDraftCollection on Isar {
  IsarCollection<Draft> get drafts => this.collection();
}

const DraftSchema = CollectionSchema(
  name: r'Draft',
  id: -1008759047235145202,
  properties: {
    r'created_at': PropertySchema(
      id: 0,
      name: r'created_at',
      type: IsarType.dateTime,
    ),
    r'deleted': PropertySchema(id: 1, name: r'deleted', type: IsarType.bool),
    r'fragment_ids': PropertySchema(
      id: 2,
      name: r'fragment_ids',
      type: IsarType.stringList,
    ),
    r'reason': PropertySchema(id: 3, name: r'reason', type: IsarType.string),
    r'refresh_at': PropertySchema(
      id: 4,
      name: r'refresh_at',
      type: IsarType.dateTime,
    ),
    r'remote_id': PropertySchema(
      id: 5,
      name: r'remote_id',
      type: IsarType.string,
    ),
    r'similarity_score': PropertySchema(
      id: 6,
      name: r'similarity_score',
      type: IsarType.double,
    ),
    r'status': PropertySchema(id: 7, name: r'status', type: IsarType.string),
    r'synced': PropertySchema(id: 8, name: r'synced', type: IsarType.bool),
    r'title': PropertySchema(id: 9, name: r'title', type: IsarType.string),
    r'updated_at': PropertySchema(
      id: 10,
      name: r'updated_at',
      type: IsarType.dateTime,
    ),
    r'user_id': PropertySchema(id: 11, name: r'user_id', type: IsarType.string),
    r'viewed': PropertySchema(id: 12, name: r'viewed', type: IsarType.bool),
  },

  estimateSize: _draftEstimateSize,
  serialize: _draftSerialize,
  deserialize: _draftDeserialize,
  deserializeProp: _draftDeserializeProp,
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
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'viewed': IndexSchema(
      id: 3677605862619085293,
      name: r'viewed',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'viewed',
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

  getId: _draftGetId,
  getLinks: _draftGetLinks,
  attach: _draftAttach,
  version: '3.3.0-dev.1',
);

int _draftEstimateSize(
  Draft object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.fragmentIds.length * 3;
  {
    for (var i = 0; i < object.fragmentIds.length; i++) {
      final value = object.fragmentIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.reason;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.remoteID.length * 3;
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.title.length * 3;
  {
    final value = object.userId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _draftSerialize(
  Draft object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeBool(offsets[1], object.deleted);
  writer.writeStringList(offsets[2], object.fragmentIds);
  writer.writeString(offsets[3], object.reason);
  writer.writeDateTime(offsets[4], object.refreshAt);
  writer.writeString(offsets[5], object.remoteID);
  writer.writeDouble(offsets[6], object.similarityScore);
  writer.writeString(offsets[7], object.status);
  writer.writeBool(offsets[8], object.synced);
  writer.writeString(offsets[9], object.title);
  writer.writeDateTime(offsets[10], object.updatedAt);
  writer.writeString(offsets[11], object.userId);
  writer.writeBool(offsets[12], object.viewed);
}

Draft _draftDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Draft();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.deleted = reader.readBool(offsets[1]);
  object.fragmentIds = reader.readStringList(offsets[2]) ?? [];
  object.reason = reader.readStringOrNull(offsets[3]);
  object.refreshAt = reader.readDateTimeOrNull(offsets[4]);
  object.remoteID = reader.readString(offsets[5]);
  object.similarityScore = reader.readDoubleOrNull(offsets[6]);
  object.status = reader.readString(offsets[7]);
  object.synced = reader.readBool(offsets[8]);
  object.title = reader.readString(offsets[9]);
  object.updatedAt = reader.readDateTime(offsets[10]);
  object.userId = reader.readStringOrNull(offsets[11]);
  object.viewed = reader.readBool(offsets[12]);
  return object;
}

P _draftDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _draftGetId(Draft object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _draftGetLinks(Draft object) {
  return [];
}

void _draftAttach(IsarCollection<dynamic> col, Id id, Draft object) {}

extension DraftByIndex on IsarCollection<Draft> {
  Future<Draft?> getByRemoteID(String remoteID) {
    return getByIndex(r'remote_id', [remoteID]);
  }

  Draft? getByRemoteIDSync(String remoteID) {
    return getByIndexSync(r'remote_id', [remoteID]);
  }

  Future<bool> deleteByRemoteID(String remoteID) {
    return deleteByIndex(r'remote_id', [remoteID]);
  }

  bool deleteByRemoteIDSync(String remoteID) {
    return deleteByIndexSync(r'remote_id', [remoteID]);
  }

  Future<List<Draft?>> getAllByRemoteID(List<String> remoteIDValues) {
    final values = remoteIDValues.map((e) => [e]).toList();
    return getAllByIndex(r'remote_id', values);
  }

  List<Draft?> getAllByRemoteIDSync(List<String> remoteIDValues) {
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

  Future<Id> putByRemoteID(Draft object) {
    return putByIndex(r'remote_id', object);
  }

  Id putByRemoteIDSync(Draft object, {bool saveLinks = true}) {
    return putByIndexSync(r'remote_id', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByRemoteID(List<Draft> objects) {
    return putAllByIndex(r'remote_id', objects);
  }

  List<Id> putAllByRemoteIDSync(List<Draft> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'remote_id', objects, saveLinks: saveLinks);
  }
}

extension DraftQueryWhereSort on QueryBuilder<Draft, Draft, QWhere> {
  QueryBuilder<Draft, Draft, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhere> anyViewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'viewed'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'created_at'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhere> anyRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'refresh_at'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhere> anySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'synced'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhere> anyDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deleted'),
      );
    });
  }
}

extension DraftQueryWhere on QueryBuilder<Draft, Draft, QWhereClause> {
  QueryBuilder<Draft, Draft, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> idBetween(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'user_id', value: [null]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> userIdIsNotNull() {
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> userIdEqualTo(String? userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'user_id', value: [userId]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> userIdNotEqualTo(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> statusEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> statusNotEqualTo(
    String status,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> viewedEqualTo(bool viewed) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'viewed', value: [viewed]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> viewedNotEqualTo(bool viewed) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'viewed',
                lower: [],
                upper: [viewed],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'viewed',
                lower: [viewed],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'viewed',
                lower: [viewed],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'viewed',
                lower: [],
                upper: [viewed],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> remoteIDEqualTo(
    String remoteID,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remote_id', value: [remoteID]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> remoteIDNotEqualTo(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'created_at', value: [createdAt]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> createdAtNotEqualTo(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> createdAtGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> createdAtLessThan(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> createdAtBetween(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'refresh_at', value: [null]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtIsNotNull() {
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtEqualTo(
    DateTime? refreshAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'refresh_at', value: [refreshAt]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtNotEqualTo(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtLessThan(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> refreshAtBetween(
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> syncedEqualTo(bool synced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'synced', value: [synced]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> syncedNotEqualTo(bool synced) {
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

  QueryBuilder<Draft, Draft, QAfterWhereClause> deletedEqualTo(bool deleted) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deleted', value: [deleted]),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterWhereClause> deletedNotEqualTo(
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

extension DraftQueryFilter on QueryBuilder<Draft, Draft, QFilterCondition> {
  QueryBuilder<Draft, Draft, QAfterFilterCondition> createdAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'created_at', value: value),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> deletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deleted', value: value),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fragment_ids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition>
  fragmentIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fragment_ids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fragment_ids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fragment_ids',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition>
  fragmentIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fragment_ids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fragment_ids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsElementContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fragment_ids',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsElementMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fragment_ids',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition>
  fragmentIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fragment_ids', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition>
  fragmentIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fragment_ids', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fragment_ids', length, true, length, true);
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fragment_ids', 0, true, 0, true);
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fragment_ids', 0, false, 999999, true);
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fragment_ids', 0, true, length, include);
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition>
  fragmentIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'fragment_ids', length, include, 999999, true);
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> fragmentIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'fragment_ids',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'reason'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'reason'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'reason',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'reason',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'reason',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'reason', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> reasonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'reason', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> refreshAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'refresh_at'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> refreshAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'refresh_at'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> refreshAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'refresh_at', value: value),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> refreshAtGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> refreshAtLessThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> refreshAtBetween(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDEqualTo(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDLessThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDBetween(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDStartsWith(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDEndsWith(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDContains(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDMatches(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remote_id', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> remoteIDIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remote_id', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> similarityScoreIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'similarity_score'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> similarityScoreIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'similarity_score'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> similarityScoreEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'similarity_score',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> similarityScoreGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'similarity_score',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> similarityScoreLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'similarity_score',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> similarityScoreBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'similarity_score',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> syncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'synced', value: value),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updated_at', value: value),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> updatedAtGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> updatedAtLessThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> updatedAtBetween(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'user_id'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'user_id'),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdEqualTo(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdGreaterThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdLessThan(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdBetween(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdStartsWith(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdEndsWith(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdContains(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdMatches(
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

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'user_id', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'user_id', value: ''),
      );
    });
  }

  QueryBuilder<Draft, Draft, QAfterFilterCondition> viewedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'viewed', value: value),
      );
    });
  }
}

extension DraftQueryObject on QueryBuilder<Draft, Draft, QFilterCondition> {}

extension DraftQueryLinks on QueryBuilder<Draft, Draft, QFilterCondition> {}

extension DraftQuerySortBy on QueryBuilder<Draft, Draft, QSortBy> {
  QueryBuilder<Draft, Draft, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByRefreshAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByRemoteID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByRemoteIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortBySimilarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarity_score', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortBySimilarityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarity_score', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByViewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewed', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> sortByViewedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewed', Sort.desc);
    });
  }
}

extension DraftQuerySortThenBy on QueryBuilder<Draft, Draft, QSortThenBy> {
  QueryBuilder<Draft, Draft, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created_at', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByDeletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleted', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByReason() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByReasonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reason', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByRefreshAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refresh_at', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByRemoteID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByRemoteIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remote_id', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenBySimilarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarity_score', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenBySimilarityScoreDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'similarity_score', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenBySyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'synced', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updated_at', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'user_id', Sort.desc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByViewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewed', Sort.asc);
    });
  }

  QueryBuilder<Draft, Draft, QAfterSortBy> thenByViewedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'viewed', Sort.desc);
    });
  }
}

extension DraftQueryWhereDistinct on QueryBuilder<Draft, Draft, QDistinct> {
  QueryBuilder<Draft, Draft, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created_at');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByDeleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deleted');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByFragmentIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fragment_ids');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByReason({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reason', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByRefreshAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refresh_at');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByRemoteID({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remote_id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctBySimilarityScore() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'similarity_score');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctBySynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'synced');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updated_at');
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'user_id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Draft, Draft, QDistinct> distinctByViewed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'viewed');
    });
  }
}

extension DraftQueryProperty on QueryBuilder<Draft, Draft, QQueryProperty> {
  QueryBuilder<Draft, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Draft, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created_at');
    });
  }

  QueryBuilder<Draft, bool, QQueryOperations> deletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deleted');
    });
  }

  QueryBuilder<Draft, List<String>, QQueryOperations> fragmentIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fragment_ids');
    });
  }

  QueryBuilder<Draft, String?, QQueryOperations> reasonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reason');
    });
  }

  QueryBuilder<Draft, DateTime?, QQueryOperations> refreshAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refresh_at');
    });
  }

  QueryBuilder<Draft, String, QQueryOperations> remoteIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remote_id');
    });
  }

  QueryBuilder<Draft, double?, QQueryOperations> similarityScoreProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'similarity_score');
    });
  }

  QueryBuilder<Draft, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Draft, bool, QQueryOperations> syncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'synced');
    });
  }

  QueryBuilder<Draft, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<Draft, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updated_at');
    });
  }

  QueryBuilder<Draft, String?, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'user_id');
    });
  }

  QueryBuilder<Draft, bool, QQueryOperations> viewedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'viewed');
    });
  }
}
