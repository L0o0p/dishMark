// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dish_mark.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDishMarkCollection on Isar {
  IsarCollection<DishMark> get dishMarks => this.collection();
}

const DishMarkSchema = CollectionSchema(
  name: r'DishMark',
  id: 3981361970841395490,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 1,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'dishName': PropertySchema(
      id: 2,
      name: r'dishName',
      type: IsarType.string,
    ),
    r'experienceNote': PropertySchema(
      id: 3,
      name: r'experienceNote',
      type: IsarType.string,
    ),
    r'flavors': PropertySchema(
      id: 4,
      name: r'flavors',
      type: IsarType.byteList,
      enumMap: _DishMarkflavorsEnumValueMap,
    ),
    r'imagePath': PropertySchema(
      id: 5,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'lastTastedAt': PropertySchema(
      id: 6,
      name: r'lastTastedAt',
      type: IsarType.dateTime,
    ),
    r'priceLevel': PropertySchema(
      id: 7,
      name: r'priceLevel',
      type: IsarType.long,
    ),
    r'storeId': PropertySchema(
      id: 8,
      name: r'storeId',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 9,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _dishMarkEstimateSize,
  serialize: _dishMarkSerialize,
  deserialize: _dishMarkDeserialize,
  deserializeProp: _dishMarkDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _dishMarkGetId,
  getLinks: _dishMarkGetLinks,
  attach: _dishMarkAttach,
  version: '3.1.0+1',
);

int _dishMarkEstimateSize(
  DishMark object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.dishName.length * 3;
  {
    final value = object.experienceNote;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.flavors.length;
  bytesCount += 3 + object.imagePath.length * 3;
  bytesCount += 3 + object.storeId.length * 3;
  return bytesCount;
}

void _dishMarkSerialize(
  DishMark object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.deletedAt);
  writer.writeString(offsets[2], object.dishName);
  writer.writeString(offsets[3], object.experienceNote);
  writer.writeByteList(offsets[4], object.flavors.map((e) => e.index).toList());
  writer.writeString(offsets[5], object.imagePath);
  writer.writeDateTime(offsets[6], object.lastTastedAt);
  writer.writeLong(offsets[7], object.priceLevel);
  writer.writeString(offsets[8], object.storeId);
  writer.writeDateTime(offsets[9], object.updatedAt);
}

DishMark _dishMarkDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DishMark();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[1]);
  object.dishName = reader.readString(offsets[2]);
  object.experienceNote = reader.readStringOrNull(offsets[3]);
  object.flavors = reader
          .readByteList(offsets[4])
          ?.map((e) => _DishMarkflavorsValueEnumMap[e] ?? Flavor.spicy)
          .toList() ??
      [];
  object.id = id;
  object.imagePath = reader.readString(offsets[5]);
  object.lastTastedAt = reader.readDateTimeOrNull(offsets[6]);
  object.priceLevel = reader.readLongOrNull(offsets[7]);
  object.storeId = reader.readString(offsets[8]);
  object.updatedAt = reader.readDateTime(offsets[9]);
  return object;
}

P _dishMarkDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader
              .readByteList(offset)
              ?.map((e) => _DishMarkflavorsValueEnumMap[e] ?? Flavor.spicy)
              .toList() ??
          []) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DishMarkflavorsEnumValueMap = {
  'spicy': 0,
  'sweet': 1,
  'savory': 2,
  'sour': 3,
  'bitter': 4,
  'fresh': 5,
  'greasy': 6,
};
const _DishMarkflavorsValueEnumMap = {
  0: Flavor.spicy,
  1: Flavor.sweet,
  2: Flavor.savory,
  3: Flavor.sour,
  4: Flavor.bitter,
  5: Flavor.fresh,
  6: Flavor.greasy,
};

Id _dishMarkGetId(DishMark object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dishMarkGetLinks(DishMark object) {
  return [];
}

void _dishMarkAttach(IsarCollection<dynamic> col, Id id, DishMark object) {
  object.id = id;
}

extension DishMarkQueryWhereSort on QueryBuilder<DishMark, DishMark, QWhere> {
  QueryBuilder<DishMark, DishMark, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DishMarkQueryWhere on QueryBuilder<DishMark, DishMark, QWhereClause> {
  QueryBuilder<DishMark, DishMark, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DishMark, DishMark, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DishMarkQueryFilter
    on QueryBuilder<DishMark, DishMark, QFilterCondition> {
  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deletedAt',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> deletedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deletedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deletedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dishName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dishName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dishName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dishName',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> dishNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dishName',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'experienceNote',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'experienceNote',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> experienceNoteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'experienceNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'experienceNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'experienceNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> experienceNoteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'experienceNote',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'experienceNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'experienceNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'experienceNote',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> experienceNoteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'experienceNote',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'experienceNote',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      experienceNoteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'experienceNote',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsElementEqualTo(
      Flavor value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flavors',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      flavorsElementGreaterThan(
    Flavor value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flavors',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      flavorsElementLessThan(
    Flavor value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flavors',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsElementBetween(
    Flavor lower,
    Flavor upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flavors',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'flavors',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'flavors',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'flavors',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'flavors',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      flavorsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'flavors',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> flavorsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'flavors',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> lastTastedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastTastedAt',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      lastTastedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastTastedAt',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> lastTastedAtEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastTastedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      lastTastedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastTastedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> lastTastedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastTastedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> lastTastedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastTastedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> priceLevelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'priceLevel',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition>
      priceLevelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'priceLevel',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> priceLevelEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priceLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> priceLevelGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priceLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> priceLevelLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priceLevel',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> priceLevelBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priceLevel',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'storeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'storeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'storeId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'storeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'storeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'storeId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'storeId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'storeId',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> storeIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'storeId',
        value: '',
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> updatedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DishMarkQueryObject
    on QueryBuilder<DishMark, DishMark, QFilterCondition> {}

extension DishMarkQueryLinks
    on QueryBuilder<DishMark, DishMark, QFilterCondition> {}

extension DishMarkQuerySortBy on QueryBuilder<DishMark, DishMark, QSortBy> {
  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByDishName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dishName', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByDishNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dishName', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByExperienceNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienceNote', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByExperienceNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienceNote', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByLastTastedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTastedAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByLastTastedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTastedAt', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByPriceLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceLevel', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByPriceLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceLevel', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByStoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByStoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DishMarkQuerySortThenBy
    on QueryBuilder<DishMark, DishMark, QSortThenBy> {
  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByDishName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dishName', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByDishNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dishName', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByExperienceNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienceNote', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByExperienceNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'experienceNote', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByLastTastedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTastedAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByLastTastedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastTastedAt', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByPriceLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceLevel', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByPriceLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priceLevel', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByStoreId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByStoreIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'storeId', Sort.desc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DishMark, DishMark, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DishMarkQueryWhereDistinct
    on QueryBuilder<DishMark, DishMark, QDistinct> {
  QueryBuilder<DishMark, DishMark, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByDishName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dishName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByExperienceNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'experienceNote',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByFlavors() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flavors');
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByLastTastedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastTastedAt');
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByPriceLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priceLevel');
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByStoreId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'storeId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DishMark, DishMark, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DishMarkQueryProperty
    on QueryBuilder<DishMark, DishMark, QQueryProperty> {
  QueryBuilder<DishMark, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DishMark, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DishMark, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<DishMark, String, QQueryOperations> dishNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dishName');
    });
  }

  QueryBuilder<DishMark, String?, QQueryOperations> experienceNoteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'experienceNote');
    });
  }

  QueryBuilder<DishMark, List<Flavor>, QQueryOperations> flavorsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flavors');
    });
  }

  QueryBuilder<DishMark, String, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<DishMark, DateTime?, QQueryOperations> lastTastedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastTastedAt');
    });
  }

  QueryBuilder<DishMark, int?, QQueryOperations> priceLevelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priceLevel');
    });
  }

  QueryBuilder<DishMark, String, QQueryOperations> storeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'storeId');
    });
  }

  QueryBuilder<DishMark, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
