import 'dart:convert';

import 'package:intl/intl.dart';

T _enumFromString<T>(String? raw, List<T> values, {required T fallback}) {
  if (raw == null) return fallback;
  final up = raw.toUpperCase();
  for (final v in values) {
    final name = v.toString().split('.').last.toUpperCase();
    if (name == up) return v;
  }
  return fallback;
}

String enumToApi(dynamic e) => e.toString().split('.').last.toUpperCase();

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return fallback;
}

String? _asString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value;
  if (value != null) {
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  if (value is String && value.trim().isNotEmpty) {
    final decoded = jsonDecode(value);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

enum MealAmount { bem, metade, menosDaMetade, recusou }

MealAmount? mealAmountFromString(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final normalized = value.toUpperCase();
  switch (normalized) {
    case 'BEM':
      return MealAmount.bem;
    case 'METADE':
      return MealAmount.metade;
    case 'MENOS_DA_METADE':
      return MealAmount.menosDaMetade;
    case 'RECUSOU':
      return MealAmount.recusou;
  }
  return null;
}

String mealAmountLabel(MealAmount value) {
  switch (value) {
    case MealAmount.bem:
      return 'Bem';
    case MealAmount.metade:
      return 'Metade';
    case MealAmount.menosDaMetade:
      return 'Menos da metade';
    case MealAmount.recusou:
      return 'Recusou';
  }
}

class DiaryClockTime {
  final int hour;
  final int minute;

  const DiaryClockTime({required this.hour, required this.minute});

  factory DiaryClockTime.parse(String raw) {
    final parts = raw.split(':');
    return DiaryClockTime(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String toApi() => '${label}:00';
}

class DiaryMealGroup {
  final MealAmount? breakfast;
  final MealAmount? lunch;
  final MealAmount? bottle;
  final MealAmount? fruit;
  final MealAmount? dinner;
  final MealAmount? supper;

  const DiaryMealGroup({
    this.breakfast,
    this.lunch,
    this.bottle,
    this.fruit,
    this.dinner,
    this.supper,
  });

  factory DiaryMealGroup.fromJson(Map<String, dynamic> json) {
    return DiaryMealGroup(
      breakfast: mealAmountFromString(json['breakfast'] as String?),
      lunch: mealAmountFromString(json['lunch'] as String?),
      bottle: mealAmountFromString(json['bottle'] as String?),
      fruit: mealAmountFromString(json['fruit'] as String?),
      dinner: mealAmountFromString(json['dinner'] as String?),
      supper: mealAmountFromString(json['supper'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'breakfast': breakfast == null ? null : enumToApi(breakfast),
        'lunch': lunch == null ? null : enumToApi(lunch),
        'bottle': bottle == null ? null : enumToApi(bottle),
        'fruit': fruit == null ? null : enumToApi(fruit),
        'dinner': dinner == null ? null : enumToApi(dinner),
        'supper': supper == null ? null : enumToApi(supper),
      };

  int get selectedCount => [
        breakfast,
        lunch,
        bottle,
        fruit,
        dinner,
        supper,
      ].whereType<MealAmount>().length;
}

class DiarySleepPeriod {
  final bool slept;
  final DiaryClockTime? startTime;
  final DiaryClockTime? endTime;

  const DiarySleepPeriod({
    required this.slept,
    this.startTime,
    this.endTime,
  });

  factory DiarySleepPeriod.fromJson(Map<String, dynamic> json) {
    return DiarySleepPeriod(
      slept: _asBool(json['slept']),
      startTime: _asString(json['startTime']) == null ? null : DiaryClockTime.parse(json['startTime'] as String),
      endTime: _asString(json['endTime']) == null ? null : DiaryClockTime.parse(json['endTime'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'slept': slept,
        'startTime': startTime?.toApi(),
        'endTime': endTime?.toApi(),
      };

  String get summary {
    if (!slept) return 'Não dormiu';
    if (startTime != null && endTime != null) return '${startTime!.label} até ${endTime!.label}';
    return 'Dormiu';
  }
}

class DiarySleepGroup {
  final DiarySleepPeriod morning;
  final DiarySleepPeriod afternoon;

  const DiarySleepGroup({
    required this.morning,
    required this.afternoon,
  });

  factory DiarySleepGroup.fromJson(Map<String, dynamic> json) {
    return DiarySleepGroup(
      morning: DiarySleepPeriod.fromJson(_asMap(json['morning'])),
      afternoon: DiarySleepPeriod.fromJson(_asMap(json['afternoon'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'morning': morning.toJson(),
        'afternoon': afternoon.toJson(),
      };
}

class DiaryPedagogicalProposals {
  final bool pedagogicalActivity;
  final bool music;
  final bool patio;
  final bool freePlay;

  const DiaryPedagogicalProposals({
    required this.pedagogicalActivity,
    required this.music,
    required this.patio,
    required this.freePlay,
  });

  factory DiaryPedagogicalProposals.fromJson(Map<String, dynamic> json) {
    return DiaryPedagogicalProposals(
      pedagogicalActivity: _asBool(json['pedagogicalActivity']),
      music: _asBool(json['music']),
      patio: _asBool(json['patio']),
      freePlay: _asBool(json['freePlay']),
    );
  }

  Map<String, dynamic> toJson() => {
        'pedagogicalActivity': pedagogicalActivity,
        'music': music,
        'patio': patio,
        'freePlay': freePlay,
      };
}

class DiaryCountableNeed {
  final bool selected;
  final int count;

  const DiaryCountableNeed({
    required this.selected,
    required this.count,
  });

  factory DiaryCountableNeed.fromJson(Map<String, dynamic> json) {
    return DiaryCountableNeed(
      selected: _asBool(json['selected']),
      count: _asInt(json['count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'selected': selected,
        'count': count,
      };
}

class DiaryNeeds {
  final DiaryCountableNeed pee;
  final DiaryCountableNeed poop;

  const DiaryNeeds({
    required this.pee,
    required this.poop,
  });

  factory DiaryNeeds.fromJson(Map<String, dynamic> json) {
    return DiaryNeeds(
      pee: DiaryCountableNeed.fromJson(_asMap(json['pee'])),
      poop: DiaryCountableNeed.fromJson(_asMap(json['poop'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'pee': pee.toJson(),
        'poop': poop.toJson(),
      };
}

class DiaryBringTomorrow {
  final bool diaper;
  final bool wipes;
  final bool ointment;
  final bool toothpaste;
  final String? other;

  const DiaryBringTomorrow({
    required this.diaper,
    required this.wipes,
    required this.ointment,
    required this.toothpaste,
    required this.other,
  });

  factory DiaryBringTomorrow.fromJson(Map<String, dynamic> json) {
    return DiaryBringTomorrow(
      diaper: _asBool(json['diaper']),
      wipes: _asBool(json['wipes']),
      ointment: _asBool(json['ointment']),
      toothpaste: _asBool(json['toothpaste']),
      other: _asString(json['other']),
    );
  }

  Map<String, dynamic> toJson() => {
        'diaper': diaper,
        'wipes': wipes,
        'ointment': ointment,
        'toothpaste': toothpaste,
        'other': other,
      };
}

class DiaryV2Payload {
  final DiaryMealGroup meals;
  final DiarySleepGroup sleep;
  final DiaryPedagogicalProposals pedagogicalProposals;
  final DiaryNeeds needs;
  final DiaryBringTomorrow bringTomorrow;
  final String? teacherNote;

  const DiaryV2Payload({
    required this.meals,
    required this.sleep,
    required this.pedagogicalProposals,
    required this.needs,
    required this.bringTomorrow,
    required this.teacherNote,
  });

  factory DiaryV2Payload.empty() {
    return DiaryV2Payload(
      meals: const DiaryMealGroup(),
      sleep: const DiarySleepGroup(
        morning: DiarySleepPeriod(slept: false),
        afternoon: DiarySleepPeriod(slept: false),
      ),
      pedagogicalProposals: const DiaryPedagogicalProposals(
        pedagogicalActivity: false,
        music: false,
        patio: false,
        freePlay: false,
      ),
      needs: const DiaryNeeds(
        pee: DiaryCountableNeed(selected: false, count: 0),
        poop: DiaryCountableNeed(selected: false, count: 0),
      ),
      bringTomorrow: const DiaryBringTomorrow(
        diaper: false,
        wipes: false,
        ointment: false,
        toothpaste: false,
        other: null,
      ),
      teacherNote: null,
    );
  }

  factory DiaryV2Payload.fromJson(Map<String, dynamic> json) {
    return DiaryV2Payload(
      meals: DiaryMealGroup.fromJson(_asMap(json['meals'])),
      sleep: DiarySleepGroup.fromJson(_asMap(json['sleep'])),
      pedagogicalProposals: DiaryPedagogicalProposals.fromJson(_asMap(json['pedagogicalProposals'])),
      needs: DiaryNeeds.fromJson(_asMap(json['needs'])),
      bringTomorrow: DiaryBringTomorrow.fromJson(_asMap(json['bringTomorrow'])),
      teacherNote: _asString(json['teacherNote']),
    );
  }

  Map<String, dynamic> toJson() => {
        'meals': meals.toJson(),
        'sleep': sleep.toJson(),
        'pedagogicalProposals': pedagogicalProposals.toJson(),
        'needs': needs.toJson(),
        'bringTomorrow': bringTomorrow.toJson(),
        'teacherNote': teacherNote,
      };
}

class Diary {
  final String id;
  final String studentId;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final bool read;
  final DateTime? readAt;
  final String? readById;
  final int version;
  final DiaryV2Payload payload;

  Diary({
    required this.id,
    required this.studentId,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.read,
    required this.readAt,
    required this.readById,
    required this.version,
    required this.payload,
  });

  factory Diary.fromJson(Map<String, dynamic> json) {
    final payloadMap = _asMap(json['payload']);

    return Diary(
      id: _asString(json['id']) ?? '',
      studentId: _asString(json['studentId']) ?? '',
      createdById: _asString(json['createdById']) ?? '',
      createdByName: _asString(json['createdByName']) ?? '',
      createdAt: DateTime.tryParse(_asString(json['createdAt']) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      read: _asBool(json['read']),
      readAt: _parseDateTime(json['readAt']),
      readById: _asString(json['readById']),
      version: _asInt(json['version'], fallback: 2),
      payload: DiaryV2Payload.fromJson(payloadMap),
    );
  }

  String get createdAtLabel => DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toLocal());

  String get listSummary {
    final parts = <String>[];
    if (payload.sleep.morning.slept || payload.sleep.afternoon.slept) {
      parts.add('Sono');
    }
    if (payload.meals.selectedCount > 0) {
      parts.add('${payload.meals.selectedCount} refeições');
    }
    if (payload.teacherNote != null && payload.teacherNote!.trim().isNotEmpty) {
      parts.add('Recado');
    }
    if (parts.isEmpty) return 'Registro completo do dia';
    return parts.join('  |  ');
  }
}

class DiaryCreateRequest {
  final String studentId;
  final DiaryV2Payload payload;

  DiaryCreateRequest({
    required this.studentId,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'payload': payload.toJson(),
      };
}

class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  bool get isLast => page >= totalPages - 1;
}
