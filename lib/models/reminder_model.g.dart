// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetReminderModelCollection on Isar {
  IsarCollection<ReminderModel> get reminderModels => this.collection();
}

const ReminderModelSchema = CollectionSchema(
  name: r'ReminderModel',
  id: -6553527084112746384,
  properties: {
    r'additionalTimes': PropertySchema(
      id: 0,
      name: r'additionalTimes',
      type: IsarType.stringList,
    ),
    r'customDaysList': PropertySchema(
      id: 1,
      name: r'customDaysList',
      type: IsarType.longList,
    ),
    r'isCompleted': PropertySchema(
      id: 2,
      name: r'isCompleted',
      type: IsarType.bool,
    ),
    r'repeatType': PropertySchema(
      id: 3,
      name: r'repeatType',
      type: IsarType.string,
    ),
    r'specificDate': PropertySchema(
      id: 4,
      name: r'specificDate',
      type: IsarType.long,
    ),
    r'time': PropertySchema(
      id: 5,
      name: r'time',
      type: IsarType.string,
    ),
    r'title': PropertySchema(
      id: 6,
      name: r'title',
      type: IsarType.string,
    )
  },
  estimateSize: _reminderModelEstimateSize,
  serialize: _reminderModelSerialize,
  deserialize: _reminderModelDeserialize,
  deserializeProp: _reminderModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _reminderModelGetId,
  getLinks: _reminderModelGetLinks,
  attach: _reminderModelAttach,
  version: '3.1.0+1',
);

int _reminderModelEstimateSize(
  ReminderModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.additionalTimes.length * 3;
  {
    for (var i = 0; i < object.additionalTimes.length; i++) {
      final value = object.additionalTimes[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.customDaysList;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  bytesCount += 3 + object.repeatType.length * 3;
  bytesCount += 3 + object.time.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _reminderModelSerialize(
  ReminderModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.additionalTimes);
  writer.writeLongList(offsets[1], object.customDaysList);
  writer.writeBool(offsets[2], object.isCompleted);
  writer.writeString(offsets[3], object.repeatType);
  writer.writeLong(offsets[4], object.specificDate);
  writer.writeString(offsets[5], object.time);
  writer.writeString(offsets[6], object.title);
}

ReminderModel _reminderModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ReminderModel();
  object.additionalTimes = reader.readStringList(offsets[0]) ?? [];
  object.customDaysList = reader.readLongList(offsets[1]);
  object.id = id;
  object.isCompleted = reader.readBool(offsets[2]);
  object.repeatType = reader.readString(offsets[3]);
  object.specificDate = reader.readLongOrNull(offsets[4]);
  object.time = reader.readString(offsets[5]);
  object.title = reader.readString(offsets[6]);
  return object;
}

P _reminderModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readLongList(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _reminderModelGetId(ReminderModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _reminderModelGetLinks(ReminderModel object) {
  return [];
}

void _reminderModelAttach(
    IsarCollection<dynamic> col, Id id, ReminderModel object) {
  object.id = id;
}

extension ReminderModelQueryWhereSort
    on QueryBuilder<ReminderModel, ReminderModel, QWhere> {
  QueryBuilder<ReminderModel, ReminderModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ReminderModelQueryWhere
    on QueryBuilder<ReminderModel, ReminderModel, QWhereClause> {
  QueryBuilder<ReminderModel, ReminderModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<ReminderModel, ReminderModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterWhereClause> idBetween(
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

extension ReminderModelQueryFilter
    on QueryBuilder<ReminderModel, ReminderModel, QFilterCondition> {
  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'additionalTimes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'additionalTimes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'additionalTimes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'additionalTimes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'additionalTimes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'additionalTimes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'additionalTimes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'additionalTimes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'additionalTimes',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'additionalTimes',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'additionalTimes',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'additionalTimes',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'additionalTimes',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'additionalTimes',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'additionalTimes',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      additionalTimesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'additionalTimes',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customDaysList',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customDaysList',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customDaysList',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customDaysList',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customDaysList',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customDaysList',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customDaysList',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customDaysList',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customDaysList',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customDaysList',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customDaysList',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      customDaysListLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'customDaysList',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition> idBetween(
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

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      isCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'repeatType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'repeatType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'repeatType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'repeatType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatType',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      repeatTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'repeatType',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      specificDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'specificDate',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      specificDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'specificDate',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      specificDateEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'specificDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      specificDateGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'specificDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      specificDateLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'specificDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      specificDateBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'specificDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition> timeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition> timeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'time',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'time',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition> timeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'time',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      timeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'time',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'title',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'title',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'title',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'title',
        value: '',
      ));
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterFilterCondition>
      titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'title',
        value: '',
      ));
    });
  }
}

extension ReminderModelQueryObject
    on QueryBuilder<ReminderModel, ReminderModel, QFilterCondition> {}

extension ReminderModelQueryLinks
    on QueryBuilder<ReminderModel, ReminderModel, QFilterCondition> {}

extension ReminderModelQuerySortBy
    on QueryBuilder<ReminderModel, ReminderModel, QSortBy> {
  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> sortByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      sortByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> sortByRepeatType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatType', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      sortByRepeatTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatType', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      sortBySpecificDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specificDate', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      sortBySpecificDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specificDate', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> sortByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> sortByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension ReminderModelQuerySortThenBy
    on QueryBuilder<ReminderModel, ReminderModel, QSortThenBy> {
  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      thenByIsCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCompleted', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByRepeatType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatType', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      thenByRepeatTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatType', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      thenBySpecificDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specificDate', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy>
      thenBySpecificDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'specificDate', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }
}

extension ReminderModelQueryWhereDistinct
    on QueryBuilder<ReminderModel, ReminderModel, QDistinct> {
  QueryBuilder<ReminderModel, ReminderModel, QDistinct>
      distinctByAdditionalTimes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'additionalTimes');
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QDistinct>
      distinctByCustomDaysList() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customDaysList');
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QDistinct>
      distinctByIsCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCompleted');
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QDistinct> distinctByRepeatType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QDistinct>
      distinctBySpecificDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'specificDate');
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QDistinct> distinctByTime(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'time', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ReminderModel, ReminderModel, QDistinct> distinctByTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }
}

extension ReminderModelQueryProperty
    on QueryBuilder<ReminderModel, ReminderModel, QQueryProperty> {
  QueryBuilder<ReminderModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ReminderModel, List<String>, QQueryOperations>
      additionalTimesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'additionalTimes');
    });
  }

  QueryBuilder<ReminderModel, List<int>?, QQueryOperations>
      customDaysListProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customDaysList');
    });
  }

  QueryBuilder<ReminderModel, bool, QQueryOperations> isCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCompleted');
    });
  }

  QueryBuilder<ReminderModel, String, QQueryOperations> repeatTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatType');
    });
  }

  QueryBuilder<ReminderModel, int?, QQueryOperations> specificDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'specificDate');
    });
  }

  QueryBuilder<ReminderModel, String, QQueryOperations> timeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'time');
    });
  }

  QueryBuilder<ReminderModel, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }
}
