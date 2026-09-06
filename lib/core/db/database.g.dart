// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TrialEventsTable extends TrialEvents
    with TableInfo<$TrialEventsTable, TrialEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrialEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDifficultyMeta = const VerificationMeta(
    'itemDifficulty',
  );
  @override
  late final GeneratedColumn<double> itemDifficulty = GeneratedColumn<double>(
    'item_difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thetaBeforeMeta = const VerificationMeta(
    'thetaBefore',
  );
  @override
  late final GeneratedColumn<double> thetaBefore = GeneratedColumn<double>(
    'theta_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _initiationMsMeta = const VerificationMeta(
    'initiationMs',
  );
  @override
  late final GeneratedColumn<int> initiationMs = GeneratedColumn<int>(
    'initiation_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movementMsMeta = const VerificationMeta(
    'movementMs',
  );
  @override
  late final GeneratedColumn<int> movementMs = GeneratedColumn<int>(
    'movement_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseTimeMsMeta = const VerificationMeta(
    'responseTimeMs',
  );
  @override
  late final GeneratedColumn<int> responseTimeMs = GeneratedColumn<int>(
    'response_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chosenIdMeta = const VerificationMeta(
    'chosenId',
  );
  @override
  late final GeneratedColumn<String> chosenId = GeneratedColumn<String>(
    'chosen_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorClassMeta = const VerificationMeta(
    'errorClass',
  );
  @override
  late final GeneratedColumn<String> errorClass = GeneratedColumn<String>(
    'error_class',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trialIndexMeta = const VerificationMeta(
    'trialIndex',
  );
  @override
  late final GeneratedColumn<int> trialIndex = GeneratedColumn<int>(
    'trial_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trialContextMeta = const VerificationMeta(
    'trialContext',
  );
  @override
  late final GeneratedColumn<String> trialContext = GeneratedColumn<String>(
    'trial_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hintLevelMeta = const VerificationMeta(
    'hintLevel',
  );
  @override
  late final GeneratedColumn<int> hintLevel = GeneratedColumn<int>(
    'hint_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _metricsMeta = const VerificationMeta(
    'metrics',
  );
  @override
  late final GeneratedColumn<String> metrics = GeneratedColumn<String>(
    'metrics',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tsMeta = const VerificationMeta('ts');
  @override
  late final GeneratedColumn<int> ts = GeneratedColumn<int>(
    'ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hourOfDayMeta = const VerificationMeta(
    'hourOfDay',
  );
  @override
  late final GeneratedColumn<int> hourOfDay = GeneratedColumn<int>(
    'hour_of_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinMeta = const VerificationMeta(
    'tzOffsetMin',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMin = GeneratedColumn<int>(
    'tz_offset_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    gameId,
    domain,
    itemId,
    itemDifficulty,
    thetaBefore,
    correct,
    initiationMs,
    movementMs,
    responseTimeMs,
    chosenId,
    errorClass,
    trialIndex,
    trialContext,
    hintLevel,
    metrics,
    ts,
    hourOfDay,
    tzOffsetMin,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trial_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrialEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_difficulty')) {
      context.handle(
        _itemDifficultyMeta,
        itemDifficulty.isAcceptableOrUnknown(
          data['item_difficulty']!,
          _itemDifficultyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemDifficultyMeta);
    }
    if (data.containsKey('theta_before')) {
      context.handle(
        _thetaBeforeMeta,
        thetaBefore.isAcceptableOrUnknown(
          data['theta_before']!,
          _thetaBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_thetaBeforeMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('initiation_ms')) {
      context.handle(
        _initiationMsMeta,
        initiationMs.isAcceptableOrUnknown(
          data['initiation_ms']!,
          _initiationMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initiationMsMeta);
    }
    if (data.containsKey('movement_ms')) {
      context.handle(
        _movementMsMeta,
        movementMs.isAcceptableOrUnknown(data['movement_ms']!, _movementMsMeta),
      );
    } else if (isInserting) {
      context.missing(_movementMsMeta);
    }
    if (data.containsKey('response_time_ms')) {
      context.handle(
        _responseTimeMsMeta,
        responseTimeMs.isAcceptableOrUnknown(
          data['response_time_ms']!,
          _responseTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseTimeMsMeta);
    }
    if (data.containsKey('chosen_id')) {
      context.handle(
        _chosenIdMeta,
        chosenId.isAcceptableOrUnknown(data['chosen_id']!, _chosenIdMeta),
      );
    }
    if (data.containsKey('error_class')) {
      context.handle(
        _errorClassMeta,
        errorClass.isAcceptableOrUnknown(data['error_class']!, _errorClassMeta),
      );
    }
    if (data.containsKey('trial_index')) {
      context.handle(
        _trialIndexMeta,
        trialIndex.isAcceptableOrUnknown(data['trial_index']!, _trialIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_trialIndexMeta);
    }
    if (data.containsKey('trial_context')) {
      context.handle(
        _trialContextMeta,
        trialContext.isAcceptableOrUnknown(
          data['trial_context']!,
          _trialContextMeta,
        ),
      );
    }
    if (data.containsKey('hint_level')) {
      context.handle(
        _hintLevelMeta,
        hintLevel.isAcceptableOrUnknown(data['hint_level']!, _hintLevelMeta),
      );
    }
    if (data.containsKey('metrics')) {
      context.handle(
        _metricsMeta,
        metrics.isAcceptableOrUnknown(data['metrics']!, _metricsMeta),
      );
    }
    if (data.containsKey('ts')) {
      context.handle(_tsMeta, ts.isAcceptableOrUnknown(data['ts']!, _tsMeta));
    } else if (isInserting) {
      context.missing(_tsMeta);
    }
    if (data.containsKey('hour_of_day')) {
      context.handle(
        _hourOfDayMeta,
        hourOfDay.isAcceptableOrUnknown(data['hour_of_day']!, _hourOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_hourOfDayMeta);
    }
    if (data.containsKey('tz_offset_min')) {
      context.handle(
        _tzOffsetMinMeta,
        tzOffsetMin.isAcceptableOrUnknown(
          data['tz_offset_min']!,
          _tzOffsetMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrialEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrialEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      itemDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}item_difficulty'],
      )!,
      thetaBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}theta_before'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      initiationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initiation_ms'],
      )!,
      movementMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}movement_ms'],
      )!,
      responseTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_time_ms'],
      )!,
      chosenId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chosen_id'],
      ),
      errorClass: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_class'],
      ),
      trialIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trial_index'],
      )!,
      trialContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trial_context'],
      ),
      hintLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hint_level'],
      )!,
      metrics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metrics'],
      ),
      ts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ts'],
      )!,
      hourOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour_of_day'],
      )!,
      tzOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_min'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $TrialEventsTable createAlias(String alias) {
    return $TrialEventsTable(attachedDatabase, alias);
  }
}

class TrialEvent extends DataClass implements Insertable<TrialEvent> {
  final String id;
  final String sessionId;
  final String gameId;
  final String domain;
  final String itemId;
  final double itemDifficulty;
  final double thetaBefore;
  final bool correct;
  final int initiationMs;
  final int movementMs;
  final int responseTimeMs;
  final String? chosenId;
  final String? errorClass;
  final int trialIndex;
  final String? trialContext;
  final int hintLevel;
  final String? metrics;
  final int ts;
  final int hourOfDay;
  final int tzOffsetMin;
  final bool synced;
  const TrialEvent({
    required this.id,
    required this.sessionId,
    required this.gameId,
    required this.domain,
    required this.itemId,
    required this.itemDifficulty,
    required this.thetaBefore,
    required this.correct,
    required this.initiationMs,
    required this.movementMs,
    required this.responseTimeMs,
    this.chosenId,
    this.errorClass,
    required this.trialIndex,
    this.trialContext,
    required this.hintLevel,
    this.metrics,
    required this.ts,
    required this.hourOfDay,
    required this.tzOffsetMin,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['game_id'] = Variable<String>(gameId);
    map['domain'] = Variable<String>(domain);
    map['item_id'] = Variable<String>(itemId);
    map['item_difficulty'] = Variable<double>(itemDifficulty);
    map['theta_before'] = Variable<double>(thetaBefore);
    map['correct'] = Variable<bool>(correct);
    map['initiation_ms'] = Variable<int>(initiationMs);
    map['movement_ms'] = Variable<int>(movementMs);
    map['response_time_ms'] = Variable<int>(responseTimeMs);
    if (!nullToAbsent || chosenId != null) {
      map['chosen_id'] = Variable<String>(chosenId);
    }
    if (!nullToAbsent || errorClass != null) {
      map['error_class'] = Variable<String>(errorClass);
    }
    map['trial_index'] = Variable<int>(trialIndex);
    if (!nullToAbsent || trialContext != null) {
      map['trial_context'] = Variable<String>(trialContext);
    }
    map['hint_level'] = Variable<int>(hintLevel);
    if (!nullToAbsent || metrics != null) {
      map['metrics'] = Variable<String>(metrics);
    }
    map['ts'] = Variable<int>(ts);
    map['hour_of_day'] = Variable<int>(hourOfDay);
    map['tz_offset_min'] = Variable<int>(tzOffsetMin);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  TrialEventsCompanion toCompanion(bool nullToAbsent) {
    return TrialEventsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      gameId: Value(gameId),
      domain: Value(domain),
      itemId: Value(itemId),
      itemDifficulty: Value(itemDifficulty),
      thetaBefore: Value(thetaBefore),
      correct: Value(correct),
      initiationMs: Value(initiationMs),
      movementMs: Value(movementMs),
      responseTimeMs: Value(responseTimeMs),
      chosenId: chosenId == null && nullToAbsent
          ? const Value.absent()
          : Value(chosenId),
      errorClass: errorClass == null && nullToAbsent
          ? const Value.absent()
          : Value(errorClass),
      trialIndex: Value(trialIndex),
      trialContext: trialContext == null && nullToAbsent
          ? const Value.absent()
          : Value(trialContext),
      hintLevel: Value(hintLevel),
      metrics: metrics == null && nullToAbsent
          ? const Value.absent()
          : Value(metrics),
      ts: Value(ts),
      hourOfDay: Value(hourOfDay),
      tzOffsetMin: Value(tzOffsetMin),
      synced: Value(synced),
    );
  }

  factory TrialEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrialEvent(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      gameId: serializer.fromJson<String>(json['gameId']),
      domain: serializer.fromJson<String>(json['domain']),
      itemId: serializer.fromJson<String>(json['itemId']),
      itemDifficulty: serializer.fromJson<double>(json['itemDifficulty']),
      thetaBefore: serializer.fromJson<double>(json['thetaBefore']),
      correct: serializer.fromJson<bool>(json['correct']),
      initiationMs: serializer.fromJson<int>(json['initiationMs']),
      movementMs: serializer.fromJson<int>(json['movementMs']),
      responseTimeMs: serializer.fromJson<int>(json['responseTimeMs']),
      chosenId: serializer.fromJson<String?>(json['chosenId']),
      errorClass: serializer.fromJson<String?>(json['errorClass']),
      trialIndex: serializer.fromJson<int>(json['trialIndex']),
      trialContext: serializer.fromJson<String?>(json['trialContext']),
      hintLevel: serializer.fromJson<int>(json['hintLevel']),
      metrics: serializer.fromJson<String?>(json['metrics']),
      ts: serializer.fromJson<int>(json['ts']),
      hourOfDay: serializer.fromJson<int>(json['hourOfDay']),
      tzOffsetMin: serializer.fromJson<int>(json['tzOffsetMin']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'gameId': serializer.toJson<String>(gameId),
      'domain': serializer.toJson<String>(domain),
      'itemId': serializer.toJson<String>(itemId),
      'itemDifficulty': serializer.toJson<double>(itemDifficulty),
      'thetaBefore': serializer.toJson<double>(thetaBefore),
      'correct': serializer.toJson<bool>(correct),
      'initiationMs': serializer.toJson<int>(initiationMs),
      'movementMs': serializer.toJson<int>(movementMs),
      'responseTimeMs': serializer.toJson<int>(responseTimeMs),
      'chosenId': serializer.toJson<String?>(chosenId),
      'errorClass': serializer.toJson<String?>(errorClass),
      'trialIndex': serializer.toJson<int>(trialIndex),
      'trialContext': serializer.toJson<String?>(trialContext),
      'hintLevel': serializer.toJson<int>(hintLevel),
      'metrics': serializer.toJson<String?>(metrics),
      'ts': serializer.toJson<int>(ts),
      'hourOfDay': serializer.toJson<int>(hourOfDay),
      'tzOffsetMin': serializer.toJson<int>(tzOffsetMin),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  TrialEvent copyWith({
    String? id,
    String? sessionId,
    String? gameId,
    String? domain,
    String? itemId,
    double? itemDifficulty,
    double? thetaBefore,
    bool? correct,
    int? initiationMs,
    int? movementMs,
    int? responseTimeMs,
    Value<String?> chosenId = const Value.absent(),
    Value<String?> errorClass = const Value.absent(),
    int? trialIndex,
    Value<String?> trialContext = const Value.absent(),
    int? hintLevel,
    Value<String?> metrics = const Value.absent(),
    int? ts,
    int? hourOfDay,
    int? tzOffsetMin,
    bool? synced,
  }) => TrialEvent(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    gameId: gameId ?? this.gameId,
    domain: domain ?? this.domain,
    itemId: itemId ?? this.itemId,
    itemDifficulty: itemDifficulty ?? this.itemDifficulty,
    thetaBefore: thetaBefore ?? this.thetaBefore,
    correct: correct ?? this.correct,
    initiationMs: initiationMs ?? this.initiationMs,
    movementMs: movementMs ?? this.movementMs,
    responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    chosenId: chosenId.present ? chosenId.value : this.chosenId,
    errorClass: errorClass.present ? errorClass.value : this.errorClass,
    trialIndex: trialIndex ?? this.trialIndex,
    trialContext: trialContext.present ? trialContext.value : this.trialContext,
    hintLevel: hintLevel ?? this.hintLevel,
    metrics: metrics.present ? metrics.value : this.metrics,
    ts: ts ?? this.ts,
    hourOfDay: hourOfDay ?? this.hourOfDay,
    tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
    synced: synced ?? this.synced,
  );
  TrialEvent copyWithCompanion(TrialEventsCompanion data) {
    return TrialEvent(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      domain: data.domain.present ? data.domain.value : this.domain,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemDifficulty: data.itemDifficulty.present
          ? data.itemDifficulty.value
          : this.itemDifficulty,
      thetaBefore: data.thetaBefore.present
          ? data.thetaBefore.value
          : this.thetaBefore,
      correct: data.correct.present ? data.correct.value : this.correct,
      initiationMs: data.initiationMs.present
          ? data.initiationMs.value
          : this.initiationMs,
      movementMs: data.movementMs.present
          ? data.movementMs.value
          : this.movementMs,
      responseTimeMs: data.responseTimeMs.present
          ? data.responseTimeMs.value
          : this.responseTimeMs,
      chosenId: data.chosenId.present ? data.chosenId.value : this.chosenId,
      errorClass: data.errorClass.present
          ? data.errorClass.value
          : this.errorClass,
      trialIndex: data.trialIndex.present
          ? data.trialIndex.value
          : this.trialIndex,
      trialContext: data.trialContext.present
          ? data.trialContext.value
          : this.trialContext,
      hintLevel: data.hintLevel.present ? data.hintLevel.value : this.hintLevel,
      metrics: data.metrics.present ? data.metrics.value : this.metrics,
      ts: data.ts.present ? data.ts.value : this.ts,
      hourOfDay: data.hourOfDay.present ? data.hourOfDay.value : this.hourOfDay,
      tzOffsetMin: data.tzOffsetMin.present
          ? data.tzOffsetMin.value
          : this.tzOffsetMin,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrialEvent(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('gameId: $gameId, ')
          ..write('domain: $domain, ')
          ..write('itemId: $itemId, ')
          ..write('itemDifficulty: $itemDifficulty, ')
          ..write('thetaBefore: $thetaBefore, ')
          ..write('correct: $correct, ')
          ..write('initiationMs: $initiationMs, ')
          ..write('movementMs: $movementMs, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('chosenId: $chosenId, ')
          ..write('errorClass: $errorClass, ')
          ..write('trialIndex: $trialIndex, ')
          ..write('trialContext: $trialContext, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('metrics: $metrics, ')
          ..write('ts: $ts, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sessionId,
    gameId,
    domain,
    itemId,
    itemDifficulty,
    thetaBefore,
    correct,
    initiationMs,
    movementMs,
    responseTimeMs,
    chosenId,
    errorClass,
    trialIndex,
    trialContext,
    hintLevel,
    metrics,
    ts,
    hourOfDay,
    tzOffsetMin,
    synced,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrialEvent &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.gameId == this.gameId &&
          other.domain == this.domain &&
          other.itemId == this.itemId &&
          other.itemDifficulty == this.itemDifficulty &&
          other.thetaBefore == this.thetaBefore &&
          other.correct == this.correct &&
          other.initiationMs == this.initiationMs &&
          other.movementMs == this.movementMs &&
          other.responseTimeMs == this.responseTimeMs &&
          other.chosenId == this.chosenId &&
          other.errorClass == this.errorClass &&
          other.trialIndex == this.trialIndex &&
          other.trialContext == this.trialContext &&
          other.hintLevel == this.hintLevel &&
          other.metrics == this.metrics &&
          other.ts == this.ts &&
          other.hourOfDay == this.hourOfDay &&
          other.tzOffsetMin == this.tzOffsetMin &&
          other.synced == this.synced);
}

class TrialEventsCompanion extends UpdateCompanion<TrialEvent> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> gameId;
  final Value<String> domain;
  final Value<String> itemId;
  final Value<double> itemDifficulty;
  final Value<double> thetaBefore;
  final Value<bool> correct;
  final Value<int> initiationMs;
  final Value<int> movementMs;
  final Value<int> responseTimeMs;
  final Value<String?> chosenId;
  final Value<String?> errorClass;
  final Value<int> trialIndex;
  final Value<String?> trialContext;
  final Value<int> hintLevel;
  final Value<String?> metrics;
  final Value<int> ts;
  final Value<int> hourOfDay;
  final Value<int> tzOffsetMin;
  final Value<bool> synced;
  final Value<int> rowid;
  const TrialEventsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.gameId = const Value.absent(),
    this.domain = const Value.absent(),
    this.itemId = const Value.absent(),
    this.itemDifficulty = const Value.absent(),
    this.thetaBefore = const Value.absent(),
    this.correct = const Value.absent(),
    this.initiationMs = const Value.absent(),
    this.movementMs = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.chosenId = const Value.absent(),
    this.errorClass = const Value.absent(),
    this.trialIndex = const Value.absent(),
    this.trialContext = const Value.absent(),
    this.hintLevel = const Value.absent(),
    this.metrics = const Value.absent(),
    this.ts = const Value.absent(),
    this.hourOfDay = const Value.absent(),
    this.tzOffsetMin = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TrialEventsCompanion.insert({
    required String id,
    required String sessionId,
    required String gameId,
    required String domain,
    required String itemId,
    required double itemDifficulty,
    required double thetaBefore,
    required bool correct,
    required int initiationMs,
    required int movementMs,
    required int responseTimeMs,
    this.chosenId = const Value.absent(),
    this.errorClass = const Value.absent(),
    required int trialIndex,
    this.trialContext = const Value.absent(),
    this.hintLevel = const Value.absent(),
    this.metrics = const Value.absent(),
    required int ts,
    required int hourOfDay,
    required int tzOffsetMin,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       gameId = Value(gameId),
       domain = Value(domain),
       itemId = Value(itemId),
       itemDifficulty = Value(itemDifficulty),
       thetaBefore = Value(thetaBefore),
       correct = Value(correct),
       initiationMs = Value(initiationMs),
       movementMs = Value(movementMs),
       responseTimeMs = Value(responseTimeMs),
       trialIndex = Value(trialIndex),
       ts = Value(ts),
       hourOfDay = Value(hourOfDay),
       tzOffsetMin = Value(tzOffsetMin);
  static Insertable<TrialEvent> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? gameId,
    Expression<String>? domain,
    Expression<String>? itemId,
    Expression<double>? itemDifficulty,
    Expression<double>? thetaBefore,
    Expression<bool>? correct,
    Expression<int>? initiationMs,
    Expression<int>? movementMs,
    Expression<int>? responseTimeMs,
    Expression<String>? chosenId,
    Expression<String>? errorClass,
    Expression<int>? trialIndex,
    Expression<String>? trialContext,
    Expression<int>? hintLevel,
    Expression<String>? metrics,
    Expression<int>? ts,
    Expression<int>? hourOfDay,
    Expression<int>? tzOffsetMin,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (gameId != null) 'game_id': gameId,
      if (domain != null) 'domain': domain,
      if (itemId != null) 'item_id': itemId,
      if (itemDifficulty != null) 'item_difficulty': itemDifficulty,
      if (thetaBefore != null) 'theta_before': thetaBefore,
      if (correct != null) 'correct': correct,
      if (initiationMs != null) 'initiation_ms': initiationMs,
      if (movementMs != null) 'movement_ms': movementMs,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (chosenId != null) 'chosen_id': chosenId,
      if (errorClass != null) 'error_class': errorClass,
      if (trialIndex != null) 'trial_index': trialIndex,
      if (trialContext != null) 'trial_context': trialContext,
      if (hintLevel != null) 'hint_level': hintLevel,
      if (metrics != null) 'metrics': metrics,
      if (ts != null) 'ts': ts,
      if (hourOfDay != null) 'hour_of_day': hourOfDay,
      if (tzOffsetMin != null) 'tz_offset_min': tzOffsetMin,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TrialEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? gameId,
    Value<String>? domain,
    Value<String>? itemId,
    Value<double>? itemDifficulty,
    Value<double>? thetaBefore,
    Value<bool>? correct,
    Value<int>? initiationMs,
    Value<int>? movementMs,
    Value<int>? responseTimeMs,
    Value<String?>? chosenId,
    Value<String?>? errorClass,
    Value<int>? trialIndex,
    Value<String?>? trialContext,
    Value<int>? hintLevel,
    Value<String?>? metrics,
    Value<int>? ts,
    Value<int>? hourOfDay,
    Value<int>? tzOffsetMin,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return TrialEventsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      gameId: gameId ?? this.gameId,
      domain: domain ?? this.domain,
      itemId: itemId ?? this.itemId,
      itemDifficulty: itemDifficulty ?? this.itemDifficulty,
      thetaBefore: thetaBefore ?? this.thetaBefore,
      correct: correct ?? this.correct,
      initiationMs: initiationMs ?? this.initiationMs,
      movementMs: movementMs ?? this.movementMs,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      chosenId: chosenId ?? this.chosenId,
      errorClass: errorClass ?? this.errorClass,
      trialIndex: trialIndex ?? this.trialIndex,
      trialContext: trialContext ?? this.trialContext,
      hintLevel: hintLevel ?? this.hintLevel,
      metrics: metrics ?? this.metrics,
      ts: ts ?? this.ts,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      tzOffsetMin: tzOffsetMin ?? this.tzOffsetMin,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemDifficulty.present) {
      map['item_difficulty'] = Variable<double>(itemDifficulty.value);
    }
    if (thetaBefore.present) {
      map['theta_before'] = Variable<double>(thetaBefore.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (initiationMs.present) {
      map['initiation_ms'] = Variable<int>(initiationMs.value);
    }
    if (movementMs.present) {
      map['movement_ms'] = Variable<int>(movementMs.value);
    }
    if (responseTimeMs.present) {
      map['response_time_ms'] = Variable<int>(responseTimeMs.value);
    }
    if (chosenId.present) {
      map['chosen_id'] = Variable<String>(chosenId.value);
    }
    if (errorClass.present) {
      map['error_class'] = Variable<String>(errorClass.value);
    }
    if (trialIndex.present) {
      map['trial_index'] = Variable<int>(trialIndex.value);
    }
    if (trialContext.present) {
      map['trial_context'] = Variable<String>(trialContext.value);
    }
    if (hintLevel.present) {
      map['hint_level'] = Variable<int>(hintLevel.value);
    }
    if (metrics.present) {
      map['metrics'] = Variable<String>(metrics.value);
    }
    if (ts.present) {
      map['ts'] = Variable<int>(ts.value);
    }
    if (hourOfDay.present) {
      map['hour_of_day'] = Variable<int>(hourOfDay.value);
    }
    if (tzOffsetMin.present) {
      map['tz_offset_min'] = Variable<int>(tzOffsetMin.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrialEventsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('gameId: $gameId, ')
          ..write('domain: $domain, ')
          ..write('itemId: $itemId, ')
          ..write('itemDifficulty: $itemDifficulty, ')
          ..write('thetaBefore: $thetaBefore, ')
          ..write('correct: $correct, ')
          ..write('initiationMs: $initiationMs, ')
          ..write('movementMs: $movementMs, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('chosenId: $chosenId, ')
          ..write('errorClass: $errorClass, ')
          ..write('trialIndex: $trialIndex, ')
          ..write('trialContext: $trialContext, ')
          ..write('hintLevel: $hintLevel, ')
          ..write('metrics: $metrics, ')
          ..write('ts: $ts, ')
          ..write('hourOfDay: $hourOfDay, ')
          ..write('tzOffsetMin: $tzOffsetMin, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gameIdsMeta = const VerificationMeta(
    'gameIds',
  );
  @override
  late final GeneratedColumn<String> gameIds = GeneratedColumn<String>(
    'game_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _abandonedAtMsMeta = const VerificationMeta(
    'abandonedAtMs',
  );
  @override
  late final GeneratedColumn<int> abandonedAtMs = GeneratedColumn<int>(
    'abandoned_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _demoReplaysMeta = const VerificationMeta(
    'demoReplays',
  );
  @override
  late final GeneratedColumn<int> demoReplays = GeneratedColumn<int>(
    'demo_replays',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startedAt,
    endedAt,
    gameIds,
    completed,
    abandonedAtMs,
    demoReplays,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('game_ids')) {
      context.handle(
        _gameIdsMeta,
        gameIds.isAcceptableOrUnknown(data['game_ids']!, _gameIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdsMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('abandoned_at_ms')) {
      context.handle(
        _abandonedAtMsMeta,
        abandonedAtMs.isAcceptableOrUnknown(
          data['abandoned_at_ms']!,
          _abandonedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('demo_replays')) {
      context.handle(
        _demoReplaysMeta,
        demoReplays.isAcceptableOrUnknown(
          data['demo_replays']!,
          _demoReplaysMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      ),
      gameIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_ids'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      abandonedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}abandoned_at_ms'],
      ),
      demoReplays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}demo_replays'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final int startedAt;
  final int? endedAt;
  final String gameIds;
  final bool completed;
  final int? abandonedAtMs;
  final int demoReplays;
  final bool synced;
  const Session({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.gameIds,
    required this.completed,
    this.abandonedAtMs,
    required this.demoReplays,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['game_ids'] = Variable<String>(gameIds);
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || abandonedAtMs != null) {
      map['abandoned_at_ms'] = Variable<int>(abandonedAtMs);
    }
    map['demo_replays'] = Variable<int>(demoReplays);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      gameIds: Value(gameIds),
      completed: Value(completed),
      abandonedAtMs: abandonedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(abandonedAtMs),
      demoReplays: Value(demoReplays),
      synced: Value(synced),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      gameIds: serializer.fromJson<String>(json['gameIds']),
      completed: serializer.fromJson<bool>(json['completed']),
      abandonedAtMs: serializer.fromJson<int?>(json['abandonedAtMs']),
      demoReplays: serializer.fromJson<int>(json['demoReplays']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'gameIds': serializer.toJson<String>(gameIds),
      'completed': serializer.toJson<bool>(completed),
      'abandonedAtMs': serializer.toJson<int?>(abandonedAtMs),
      'demoReplays': serializer.toJson<int>(demoReplays),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  Session copyWith({
    String? id,
    int? startedAt,
    Value<int?> endedAt = const Value.absent(),
    String? gameIds,
    bool? completed,
    Value<int?> abandonedAtMs = const Value.absent(),
    int? demoReplays,
    bool? synced,
  }) => Session(
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    gameIds: gameIds ?? this.gameIds,
    completed: completed ?? this.completed,
    abandonedAtMs: abandonedAtMs.present
        ? abandonedAtMs.value
        : this.abandonedAtMs,
    demoReplays: demoReplays ?? this.demoReplays,
    synced: synced ?? this.synced,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      gameIds: data.gameIds.present ? data.gameIds.value : this.gameIds,
      completed: data.completed.present ? data.completed.value : this.completed,
      abandonedAtMs: data.abandonedAtMs.present
          ? data.abandonedAtMs.value
          : this.abandonedAtMs,
      demoReplays: data.demoReplays.present
          ? data.demoReplays.value
          : this.demoReplays,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('gameIds: $gameIds, ')
          ..write('completed: $completed, ')
          ..write('abandonedAtMs: $abandonedAtMs, ')
          ..write('demoReplays: $demoReplays, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    startedAt,
    endedAt,
    gameIds,
    completed,
    abandonedAtMs,
    demoReplays,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.gameIds == this.gameIds &&
          other.completed == this.completed &&
          other.abandonedAtMs == this.abandonedAtMs &&
          other.demoReplays == this.demoReplays &&
          other.synced == this.synced);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<String> gameIds;
  final Value<bool> completed;
  final Value<int?> abandonedAtMs;
  final Value<int> demoReplays;
  final Value<bool> synced;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.gameIds = const Value.absent(),
    this.completed = const Value.absent(),
    this.abandonedAtMs = const Value.absent(),
    this.demoReplays = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required int startedAt,
    this.endedAt = const Value.absent(),
    required String gameIds,
    this.completed = const Value.absent(),
    this.abandonedAtMs = const Value.absent(),
    this.demoReplays = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       gameIds = Value(gameIds);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<String>? gameIds,
    Expression<bool>? completed,
    Expression<int>? abandonedAtMs,
    Expression<int>? demoReplays,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (gameIds != null) 'game_ids': gameIds,
      if (completed != null) 'completed': completed,
      if (abandonedAtMs != null) 'abandoned_at_ms': abandonedAtMs,
      if (demoReplays != null) 'demo_replays': demoReplays,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? startedAt,
    Value<int?>? endedAt,
    Value<String>? gameIds,
    Value<bool>? completed,
    Value<int?>? abandonedAtMs,
    Value<int>? demoReplays,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      gameIds: gameIds ?? this.gameIds,
      completed: completed ?? this.completed,
      abandonedAtMs: abandonedAtMs ?? this.abandonedAtMs,
      demoReplays: demoReplays ?? this.demoReplays,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (gameIds.present) {
      map['game_ids'] = Variable<String>(gameIds.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (abandonedAtMs.present) {
      map['abandoned_at_ms'] = Variable<int>(abandonedAtMs.value);
    }
    if (demoReplays.present) {
      map['demo_replays'] = Variable<int>(demoReplays.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('gameIds: $gameIds, ')
          ..write('completed: $completed, ')
          ..write('abandonedAtMs: $abandonedAtMs, ')
          ..write('demoReplays: $demoReplays, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReminderEventsTable extends ReminderEvents
    with TableInfo<$ReminderEventsTable, ReminderEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReminderEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<int> scheduledAt = GeneratedColumn<int>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firedAtMeta = const VerificationMeta(
    'firedAt',
  );
  @override
  late final GeneratedColumn<int> firedAt = GeneratedColumn<int>(
    'fired_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  @override
  late final GeneratedColumn<int> respondedAt = GeneratedColumn<int>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ladderStepMeta = const VerificationMeta(
    'ladderStep',
  );
  @override
  late final GeneratedColumn<int> ladderStep = GeneratedColumn<int>(
    'ladder_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    scheduledAt,
    firedAt,
    respondedAt,
    outcome,
    channel,
    ladderStep,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminder_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReminderEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('fired_at')) {
      context.handle(
        _firedAtMeta,
        firedAt.isAcceptableOrUnknown(data['fired_at']!, _firedAtMeta),
      );
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('ladder_step')) {
      context.handle(
        _ladderStepMeta,
        ladderStep.isAcceptableOrUnknown(data['ladder_step']!, _ladderStepMeta),
      );
    } else if (isInserting) {
      context.missing(_ladderStepMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scheduled_at'],
      )!,
      firedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fired_at'],
      ),
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}responded_at'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      )!,
      ladderStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ladder_step'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $ReminderEventsTable createAlias(String alias) {
    return $ReminderEventsTable(attachedDatabase, alias);
  }
}

class ReminderEvent extends DataClass implements Insertable<ReminderEvent> {
  final String id;
  final String medicationId;
  final int scheduledAt;
  final int? firedAt;
  final int? respondedAt;
  final String? outcome;
  final String channel;
  final int ladderStep;
  final bool synced;
  const ReminderEvent({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    this.firedAt,
    this.respondedAt,
    this.outcome,
    required this.channel,
    required this.ladderStep,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['medication_id'] = Variable<String>(medicationId);
    map['scheduled_at'] = Variable<int>(scheduledAt);
    if (!nullToAbsent || firedAt != null) {
      map['fired_at'] = Variable<int>(firedAt);
    }
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<int>(respondedAt);
    }
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    map['channel'] = Variable<String>(channel);
    map['ladder_step'] = Variable<int>(ladderStep);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ReminderEventsCompanion toCompanion(bool nullToAbsent) {
    return ReminderEventsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      scheduledAt: Value(scheduledAt),
      firedAt: firedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(firedAt),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      channel: Value(channel),
      ladderStep: Value(ladderStep),
      synced: Value(synced),
    );
  }

  factory ReminderEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderEvent(
      id: serializer.fromJson<String>(json['id']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      scheduledAt: serializer.fromJson<int>(json['scheduledAt']),
      firedAt: serializer.fromJson<int?>(json['firedAt']),
      respondedAt: serializer.fromJson<int?>(json['respondedAt']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      channel: serializer.fromJson<String>(json['channel']),
      ladderStep: serializer.fromJson<int>(json['ladderStep']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'medicationId': serializer.toJson<String>(medicationId),
      'scheduledAt': serializer.toJson<int>(scheduledAt),
      'firedAt': serializer.toJson<int?>(firedAt),
      'respondedAt': serializer.toJson<int?>(respondedAt),
      'outcome': serializer.toJson<String?>(outcome),
      'channel': serializer.toJson<String>(channel),
      'ladderStep': serializer.toJson<int>(ladderStep),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  ReminderEvent copyWith({
    String? id,
    String? medicationId,
    int? scheduledAt,
    Value<int?> firedAt = const Value.absent(),
    Value<int?> respondedAt = const Value.absent(),
    Value<String?> outcome = const Value.absent(),
    String? channel,
    int? ladderStep,
    bool? synced,
  }) => ReminderEvent(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    firedAt: firedAt.present ? firedAt.value : this.firedAt,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
    outcome: outcome.present ? outcome.value : this.outcome,
    channel: channel ?? this.channel,
    ladderStep: ladderStep ?? this.ladderStep,
    synced: synced ?? this.synced,
  );
  ReminderEvent copyWithCompanion(ReminderEventsCompanion data) {
    return ReminderEvent(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      firedAt: data.firedAt.present ? data.firedAt.value : this.firedAt,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      channel: data.channel.present ? data.channel.value : this.channel,
      ladderStep: data.ladderStep.present
          ? data.ladderStep.value
          : this.ladderStep,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderEvent(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('firedAt: $firedAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('outcome: $outcome, ')
          ..write('channel: $channel, ')
          ..write('ladderStep: $ladderStep, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    scheduledAt,
    firedAt,
    respondedAt,
    outcome,
    channel,
    ladderStep,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderEvent &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.scheduledAt == this.scheduledAt &&
          other.firedAt == this.firedAt &&
          other.respondedAt == this.respondedAt &&
          other.outcome == this.outcome &&
          other.channel == this.channel &&
          other.ladderStep == this.ladderStep &&
          other.synced == this.synced);
}

class ReminderEventsCompanion extends UpdateCompanion<ReminderEvent> {
  final Value<String> id;
  final Value<String> medicationId;
  final Value<int> scheduledAt;
  final Value<int?> firedAt;
  final Value<int?> respondedAt;
  final Value<String?> outcome;
  final Value<String> channel;
  final Value<int> ladderStep;
  final Value<bool> synced;
  final Value<int> rowid;
  const ReminderEventsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.firedAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.channel = const Value.absent(),
    this.ladderStep = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReminderEventsCompanion.insert({
    required String id,
    required String medicationId,
    required int scheduledAt,
    this.firedAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    required String channel,
    required int ladderStep,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       medicationId = Value(medicationId),
       scheduledAt = Value(scheduledAt),
       channel = Value(channel),
       ladderStep = Value(ladderStep);
  static Insertable<ReminderEvent> custom({
    Expression<String>? id,
    Expression<String>? medicationId,
    Expression<int>? scheduledAt,
    Expression<int>? firedAt,
    Expression<int>? respondedAt,
    Expression<String>? outcome,
    Expression<String>? channel,
    Expression<int>? ladderStep,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (firedAt != null) 'fired_at': firedAt,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (outcome != null) 'outcome': outcome,
      if (channel != null) 'channel': channel,
      if (ladderStep != null) 'ladder_step': ladderStep,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReminderEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? medicationId,
    Value<int>? scheduledAt,
    Value<int?>? firedAt,
    Value<int?>? respondedAt,
    Value<String?>? outcome,
    Value<String>? channel,
    Value<int>? ladderStep,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return ReminderEventsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      firedAt: firedAt ?? this.firedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      outcome: outcome ?? this.outcome,
      channel: channel ?? this.channel,
      ladderStep: ladderStep ?? this.ladderStep,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<int>(scheduledAt.value);
    }
    if (firedAt.present) {
      map['fired_at'] = Variable<int>(firedAt.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<int>(respondedAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (ladderStep.present) {
      map['ladder_step'] = Variable<int>(ladderStep.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReminderEventsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('firedAt: $firedAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('outcome: $outcome, ')
          ..write('channel: $channel, ')
          ..write('ladderStep: $ladderStep, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VoiceMemosTable extends VoiceMemos
    with TableInfo<$VoiceMemosTable, VoiceMemo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VoiceMemosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextTagMeta = const VerificationMeta(
    'contextTag',
  );
  @override
  late final GeneratedColumn<String> contextTag = GeneratedColumn<String>(
    'context_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _uploadedMeta = const VerificationMeta(
    'uploaded',
  );
  @override
  late final GeneratedColumn<bool> uploaded = GeneratedColumn<bool>(
    'uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localPath,
    durationMs,
    recordedAt,
    contextTag,
    uploaded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'voice_memos';
  @override
  VerificationContext validateIntegrity(
    Insertable<VoiceMemo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('context_tag')) {
      context.handle(
        _contextTagMeta,
        contextTag.isAcceptableOrUnknown(data['context_tag']!, _contextTagMeta),
      );
    }
    if (data.containsKey('uploaded')) {
      context.handle(
        _uploadedMeta,
        uploaded.isAcceptableOrUnknown(data['uploaded']!, _uploadedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VoiceMemo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VoiceMemo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
      contextTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_tag'],
      ),
      uploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}uploaded'],
      )!,
    );
  }

  @override
  $VoiceMemosTable createAlias(String alias) {
    return $VoiceMemosTable(attachedDatabase, alias);
  }
}

class VoiceMemo extends DataClass implements Insertable<VoiceMemo> {
  final String id;
  final String localPath;
  final int durationMs;
  final int recordedAt;
  final String? contextTag;
  final bool uploaded;
  const VoiceMemo({
    required this.id,
    required this.localPath,
    required this.durationMs,
    required this.recordedAt,
    this.contextTag,
    required this.uploaded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_path'] = Variable<String>(localPath);
    map['duration_ms'] = Variable<int>(durationMs);
    map['recorded_at'] = Variable<int>(recordedAt);
    if (!nullToAbsent || contextTag != null) {
      map['context_tag'] = Variable<String>(contextTag);
    }
    map['uploaded'] = Variable<bool>(uploaded);
    return map;
  }

  VoiceMemosCompanion toCompanion(bool nullToAbsent) {
    return VoiceMemosCompanion(
      id: Value(id),
      localPath: Value(localPath),
      durationMs: Value(durationMs),
      recordedAt: Value(recordedAt),
      contextTag: contextTag == null && nullToAbsent
          ? const Value.absent()
          : Value(contextTag),
      uploaded: Value(uploaded),
    );
  }

  factory VoiceMemo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VoiceMemo(
      id: serializer.fromJson<String>(json['id']),
      localPath: serializer.fromJson<String>(json['localPath']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      recordedAt: serializer.fromJson<int>(json['recordedAt']),
      contextTag: serializer.fromJson<String?>(json['contextTag']),
      uploaded: serializer.fromJson<bool>(json['uploaded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localPath': serializer.toJson<String>(localPath),
      'durationMs': serializer.toJson<int>(durationMs),
      'recordedAt': serializer.toJson<int>(recordedAt),
      'contextTag': serializer.toJson<String?>(contextTag),
      'uploaded': serializer.toJson<bool>(uploaded),
    };
  }

  VoiceMemo copyWith({
    String? id,
    String? localPath,
    int? durationMs,
    int? recordedAt,
    Value<String?> contextTag = const Value.absent(),
    bool? uploaded,
  }) => VoiceMemo(
    id: id ?? this.id,
    localPath: localPath ?? this.localPath,
    durationMs: durationMs ?? this.durationMs,
    recordedAt: recordedAt ?? this.recordedAt,
    contextTag: contextTag.present ? contextTag.value : this.contextTag,
    uploaded: uploaded ?? this.uploaded,
  );
  VoiceMemo copyWithCompanion(VoiceMemosCompanion data) {
    return VoiceMemo(
      id: data.id.present ? data.id.value : this.id,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      contextTag: data.contextTag.present
          ? data.contextTag.value
          : this.contextTag,
      uploaded: data.uploaded.present ? data.uploaded.value : this.uploaded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VoiceMemo(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('durationMs: $durationMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('contextTag: $contextTag, ')
          ..write('uploaded: $uploaded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, localPath, durationMs, recordedAt, contextTag, uploaded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VoiceMemo &&
          other.id == this.id &&
          other.localPath == this.localPath &&
          other.durationMs == this.durationMs &&
          other.recordedAt == this.recordedAt &&
          other.contextTag == this.contextTag &&
          other.uploaded == this.uploaded);
}

class VoiceMemosCompanion extends UpdateCompanion<VoiceMemo> {
  final Value<String> id;
  final Value<String> localPath;
  final Value<int> durationMs;
  final Value<int> recordedAt;
  final Value<String?> contextTag;
  final Value<bool> uploaded;
  final Value<int> rowid;
  const VoiceMemosCompanion({
    this.id = const Value.absent(),
    this.localPath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.contextTag = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VoiceMemosCompanion.insert({
    required String id,
    required String localPath,
    required int durationMs,
    required int recordedAt,
    this.contextTag = const Value.absent(),
    this.uploaded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localPath = Value(localPath),
       durationMs = Value(durationMs),
       recordedAt = Value(recordedAt);
  static Insertable<VoiceMemo> custom({
    Expression<String>? id,
    Expression<String>? localPath,
    Expression<int>? durationMs,
    Expression<int>? recordedAt,
    Expression<String>? contextTag,
    Expression<bool>? uploaded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localPath != null) 'local_path': localPath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (contextTag != null) 'context_tag': contextTag,
      if (uploaded != null) 'uploaded': uploaded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VoiceMemosCompanion copyWith({
    Value<String>? id,
    Value<String>? localPath,
    Value<int>? durationMs,
    Value<int>? recordedAt,
    Value<String?>? contextTag,
    Value<bool>? uploaded,
    Value<int>? rowid,
  }) {
    return VoiceMemosCompanion(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      durationMs: durationMs ?? this.durationMs,
      recordedAt: recordedAt ?? this.recordedAt,
      contextTag: contextTag ?? this.contextTag,
      uploaded: uploaded ?? this.uploaded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (contextTag.present) {
      map['context_tag'] = Variable<String>(contextTag.value);
    }
    if (uploaded.present) {
      map['uploaded'] = Variable<bool>(uploaded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VoiceMemosCompanion(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('durationMs: $durationMs, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('contextTag: $contextTag, ')
          ..write('uploaded: $uploaded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EscalationRequestsTable extends EscalationRequests
    with TableInfo<$EscalationRequestsTable, EscalationRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EscalationRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderEventIdMeta = const VerificationMeta(
    'reminderEventId',
  );
  @override
  late final GeneratedColumn<String> reminderEventId = GeneratedColumn<String>(
    'reminder_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<int> step = GeneratedColumn<int>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<int> requestedAt = GeneratedColumn<int>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cancelledMeta = const VerificationMeta(
    'cancelled',
  );
  @override
  late final GeneratedColumn<bool> cancelled = GeneratedColumn<bool>(
    'cancelled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cancelled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    reminderEventId,
    medicationId,
    step,
    requestedAt,
    cancelled,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'escalation_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<EscalationRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('reminder_event_id')) {
      context.handle(
        _reminderEventIdMeta,
        reminderEventId.isAcceptableOrUnknown(
          data['reminder_event_id']!,
          _reminderEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderEventIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('cancelled')) {
      context.handle(
        _cancelledMeta,
        cancelled.isAcceptableOrUnknown(data['cancelled']!, _cancelledMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EscalationRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EscalationRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      reminderEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_event_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}requested_at'],
      )!,
      cancelled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cancelled'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $EscalationRequestsTable createAlias(String alias) {
    return $EscalationRequestsTable(attachedDatabase, alias);
  }
}

class EscalationRequest extends DataClass
    implements Insertable<EscalationRequest> {
  final String id;
  final String reminderEventId;
  final String medicationId;
  final int step;
  final int requestedAt;
  final bool cancelled;
  final bool synced;
  const EscalationRequest({
    required this.id,
    required this.reminderEventId,
    required this.medicationId,
    required this.step,
    required this.requestedAt,
    required this.cancelled,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['reminder_event_id'] = Variable<String>(reminderEventId);
    map['medication_id'] = Variable<String>(medicationId);
    map['step'] = Variable<int>(step);
    map['requested_at'] = Variable<int>(requestedAt);
    map['cancelled'] = Variable<bool>(cancelled);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  EscalationRequestsCompanion toCompanion(bool nullToAbsent) {
    return EscalationRequestsCompanion(
      id: Value(id),
      reminderEventId: Value(reminderEventId),
      medicationId: Value(medicationId),
      step: Value(step),
      requestedAt: Value(requestedAt),
      cancelled: Value(cancelled),
      synced: Value(synced),
    );
  }

  factory EscalationRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EscalationRequest(
      id: serializer.fromJson<String>(json['id']),
      reminderEventId: serializer.fromJson<String>(json['reminderEventId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      step: serializer.fromJson<int>(json['step']),
      requestedAt: serializer.fromJson<int>(json['requestedAt']),
      cancelled: serializer.fromJson<bool>(json['cancelled']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'reminderEventId': serializer.toJson<String>(reminderEventId),
      'medicationId': serializer.toJson<String>(medicationId),
      'step': serializer.toJson<int>(step),
      'requestedAt': serializer.toJson<int>(requestedAt),
      'cancelled': serializer.toJson<bool>(cancelled),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  EscalationRequest copyWith({
    String? id,
    String? reminderEventId,
    String? medicationId,
    int? step,
    int? requestedAt,
    bool? cancelled,
    bool? synced,
  }) => EscalationRequest(
    id: id ?? this.id,
    reminderEventId: reminderEventId ?? this.reminderEventId,
    medicationId: medicationId ?? this.medicationId,
    step: step ?? this.step,
    requestedAt: requestedAt ?? this.requestedAt,
    cancelled: cancelled ?? this.cancelled,
    synced: synced ?? this.synced,
  );
  EscalationRequest copyWithCompanion(EscalationRequestsCompanion data) {
    return EscalationRequest(
      id: data.id.present ? data.id.value : this.id,
      reminderEventId: data.reminderEventId.present
          ? data.reminderEventId.value
          : this.reminderEventId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      step: data.step.present ? data.step.value : this.step,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      cancelled: data.cancelled.present ? data.cancelled.value : this.cancelled,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EscalationRequest(')
          ..write('id: $id, ')
          ..write('reminderEventId: $reminderEventId, ')
          ..write('medicationId: $medicationId, ')
          ..write('step: $step, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('cancelled: $cancelled, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    reminderEventId,
    medicationId,
    step,
    requestedAt,
    cancelled,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EscalationRequest &&
          other.id == this.id &&
          other.reminderEventId == this.reminderEventId &&
          other.medicationId == this.medicationId &&
          other.step == this.step &&
          other.requestedAt == this.requestedAt &&
          other.cancelled == this.cancelled &&
          other.synced == this.synced);
}

class EscalationRequestsCompanion extends UpdateCompanion<EscalationRequest> {
  final Value<String> id;
  final Value<String> reminderEventId;
  final Value<String> medicationId;
  final Value<int> step;
  final Value<int> requestedAt;
  final Value<bool> cancelled;
  final Value<bool> synced;
  final Value<int> rowid;
  const EscalationRequestsCompanion({
    this.id = const Value.absent(),
    this.reminderEventId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.step = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.cancelled = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EscalationRequestsCompanion.insert({
    required String id,
    required String reminderEventId,
    required String medicationId,
    required int step,
    required int requestedAt,
    this.cancelled = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       reminderEventId = Value(reminderEventId),
       medicationId = Value(medicationId),
       step = Value(step),
       requestedAt = Value(requestedAt);
  static Insertable<EscalationRequest> custom({
    Expression<String>? id,
    Expression<String>? reminderEventId,
    Expression<String>? medicationId,
    Expression<int>? step,
    Expression<int>? requestedAt,
    Expression<bool>? cancelled,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reminderEventId != null) 'reminder_event_id': reminderEventId,
      if (medicationId != null) 'medication_id': medicationId,
      if (step != null) 'step': step,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (cancelled != null) 'cancelled': cancelled,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EscalationRequestsCompanion copyWith({
    Value<String>? id,
    Value<String>? reminderEventId,
    Value<String>? medicationId,
    Value<int>? step,
    Value<int>? requestedAt,
    Value<bool>? cancelled,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return EscalationRequestsCompanion(
      id: id ?? this.id,
      reminderEventId: reminderEventId ?? this.reminderEventId,
      medicationId: medicationId ?? this.medicationId,
      step: step ?? this.step,
      requestedAt: requestedAt ?? this.requestedAt,
      cancelled: cancelled ?? this.cancelled,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (reminderEventId.present) {
      map['reminder_event_id'] = Variable<String>(reminderEventId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (step.present) {
      map['step'] = Variable<int>(step.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<int>(requestedAt.value);
    }
    if (cancelled.present) {
      map['cancelled'] = Variable<bool>(cancelled.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EscalationRequestsCompanion(')
          ..write('id: $id, ')
          ..write('reminderEventId: $reminderEventId, ')
          ..write('medicationId: $medicationId, ')
          ..write('step: $step, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('cancelled: $cancelled, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AbilityStatesTable extends AbilityStates
    with TableInfo<$AbilityStatesTable, AbilityState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AbilityStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thetaMeta = const VerificationMeta('theta');
  @override
  late final GeneratedColumn<double> theta = GeneratedColumn<double>(
    'theta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nTrialsMeta = const VerificationMeta(
    'nTrials',
  );
  @override
  late final GeneratedColumn<int> nTrials = GeneratedColumn<int>(
    'n_trials',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rtMeanLogMeta = const VerificationMeta(
    'rtMeanLog',
  );
  @override
  late final GeneratedColumn<double> rtMeanLog = GeneratedColumn<double>(
    'rt_mean_log',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rtVarMeta = const VerificationMeta('rtVar');
  @override
  late final GeneratedColumn<double> rtVar = GeneratedColumn<double>(
    'rt_var',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    domain,
    theta,
    nTrials,
    rtMeanLog,
    rtVar,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ability_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<AbilityState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    } else if (isInserting) {
      context.missing(_domainMeta);
    }
    if (data.containsKey('theta')) {
      context.handle(
        _thetaMeta,
        theta.isAcceptableOrUnknown(data['theta']!, _thetaMeta),
      );
    } else if (isInserting) {
      context.missing(_thetaMeta);
    }
    if (data.containsKey('n_trials')) {
      context.handle(
        _nTrialsMeta,
        nTrials.isAcceptableOrUnknown(data['n_trials']!, _nTrialsMeta),
      );
    } else if (isInserting) {
      context.missing(_nTrialsMeta);
    }
    if (data.containsKey('rt_mean_log')) {
      context.handle(
        _rtMeanLogMeta,
        rtMeanLog.isAcceptableOrUnknown(data['rt_mean_log']!, _rtMeanLogMeta),
      );
    } else if (isInserting) {
      context.missing(_rtMeanLogMeta);
    }
    if (data.containsKey('rt_var')) {
      context.handle(
        _rtVarMeta,
        rtVar.isAcceptableOrUnknown(data['rt_var']!, _rtVarMeta),
      );
    } else if (isInserting) {
      context.missing(_rtVarMeta);
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
  Set<GeneratedColumn> get $primaryKey => {domain};
  @override
  AbilityState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AbilityState(
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      )!,
      theta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}theta'],
      )!,
      nTrials: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}n_trials'],
      )!,
      rtMeanLog: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rt_mean_log'],
      )!,
      rtVar: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rt_var'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AbilityStatesTable createAlias(String alias) {
    return $AbilityStatesTable(attachedDatabase, alias);
  }
}

class AbilityState extends DataClass implements Insertable<AbilityState> {
  final String domain;
  final double theta;
  final int nTrials;
  final double rtMeanLog;
  final double rtVar;
  final int updatedAt;
  const AbilityState({
    required this.domain,
    required this.theta,
    required this.nTrials,
    required this.rtMeanLog,
    required this.rtVar,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['domain'] = Variable<String>(domain);
    map['theta'] = Variable<double>(theta);
    map['n_trials'] = Variable<int>(nTrials);
    map['rt_mean_log'] = Variable<double>(rtMeanLog);
    map['rt_var'] = Variable<double>(rtVar);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AbilityStatesCompanion toCompanion(bool nullToAbsent) {
    return AbilityStatesCompanion(
      domain: Value(domain),
      theta: Value(theta),
      nTrials: Value(nTrials),
      rtMeanLog: Value(rtMeanLog),
      rtVar: Value(rtVar),
      updatedAt: Value(updatedAt),
    );
  }

  factory AbilityState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AbilityState(
      domain: serializer.fromJson<String>(json['domain']),
      theta: serializer.fromJson<double>(json['theta']),
      nTrials: serializer.fromJson<int>(json['nTrials']),
      rtMeanLog: serializer.fromJson<double>(json['rtMeanLog']),
      rtVar: serializer.fromJson<double>(json['rtVar']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'domain': serializer.toJson<String>(domain),
      'theta': serializer.toJson<double>(theta),
      'nTrials': serializer.toJson<int>(nTrials),
      'rtMeanLog': serializer.toJson<double>(rtMeanLog),
      'rtVar': serializer.toJson<double>(rtVar),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AbilityState copyWith({
    String? domain,
    double? theta,
    int? nTrials,
    double? rtMeanLog,
    double? rtVar,
    int? updatedAt,
  }) => AbilityState(
    domain: domain ?? this.domain,
    theta: theta ?? this.theta,
    nTrials: nTrials ?? this.nTrials,
    rtMeanLog: rtMeanLog ?? this.rtMeanLog,
    rtVar: rtVar ?? this.rtVar,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AbilityState copyWithCompanion(AbilityStatesCompanion data) {
    return AbilityState(
      domain: data.domain.present ? data.domain.value : this.domain,
      theta: data.theta.present ? data.theta.value : this.theta,
      nTrials: data.nTrials.present ? data.nTrials.value : this.nTrials,
      rtMeanLog: data.rtMeanLog.present ? data.rtMeanLog.value : this.rtMeanLog,
      rtVar: data.rtVar.present ? data.rtVar.value : this.rtVar,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AbilityState(')
          ..write('domain: $domain, ')
          ..write('theta: $theta, ')
          ..write('nTrials: $nTrials, ')
          ..write('rtMeanLog: $rtMeanLog, ')
          ..write('rtVar: $rtVar, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(domain, theta, nTrials, rtMeanLog, rtVar, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbilityState &&
          other.domain == this.domain &&
          other.theta == this.theta &&
          other.nTrials == this.nTrials &&
          other.rtMeanLog == this.rtMeanLog &&
          other.rtVar == this.rtVar &&
          other.updatedAt == this.updatedAt);
}

class AbilityStatesCompanion extends UpdateCompanion<AbilityState> {
  final Value<String> domain;
  final Value<double> theta;
  final Value<int> nTrials;
  final Value<double> rtMeanLog;
  final Value<double> rtVar;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AbilityStatesCompanion({
    this.domain = const Value.absent(),
    this.theta = const Value.absent(),
    this.nTrials = const Value.absent(),
    this.rtMeanLog = const Value.absent(),
    this.rtVar = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AbilityStatesCompanion.insert({
    required String domain,
    required double theta,
    required int nTrials,
    required double rtMeanLog,
    required double rtVar,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : domain = Value(domain),
       theta = Value(theta),
       nTrials = Value(nTrials),
       rtMeanLog = Value(rtMeanLog),
       rtVar = Value(rtVar),
       updatedAt = Value(updatedAt);
  static Insertable<AbilityState> custom({
    Expression<String>? domain,
    Expression<double>? theta,
    Expression<int>? nTrials,
    Expression<double>? rtMeanLog,
    Expression<double>? rtVar,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (domain != null) 'domain': domain,
      if (theta != null) 'theta': theta,
      if (nTrials != null) 'n_trials': nTrials,
      if (rtMeanLog != null) 'rt_mean_log': rtMeanLog,
      if (rtVar != null) 'rt_var': rtVar,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AbilityStatesCompanion copyWith({
    Value<String>? domain,
    Value<double>? theta,
    Value<int>? nTrials,
    Value<double>? rtMeanLog,
    Value<double>? rtVar,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AbilityStatesCompanion(
      domain: domain ?? this.domain,
      theta: theta ?? this.theta,
      nTrials: nTrials ?? this.nTrials,
      rtMeanLog: rtMeanLog ?? this.rtMeanLog,
      rtVar: rtVar ?? this.rtVar,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (theta.present) {
      map['theta'] = Variable<double>(theta.value);
    }
    if (nTrials.present) {
      map['n_trials'] = Variable<int>(nTrials.value);
    }
    if (rtMeanLog.present) {
      map['rt_mean_log'] = Variable<double>(rtMeanLog.value);
    }
    if (rtVar.present) {
      map['rt_var'] = Variable<double>(rtVar.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AbilityStatesCompanion(')
          ..write('domain: $domain, ')
          ..write('theta: $theta, ')
          ..write('nTrials: $nTrials, ')
          ..write('rtMeanLog: $rtMeanLog, ')
          ..write('rtVar: $rtVar, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, PeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _relationshipMeta = const VerificationMeta(
    'relationship',
  );
  @override
  late final GeneratedColumn<String> relationship = GeneratedColumn<String>(
    'relationship',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voicePathMeta = const VerificationMeta(
    'voicePath',
  );
  @override
  late final GeneratedColumn<String> voicePath = GeneratedColumn<String>(
    'voice_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoryPromptMeta = const VerificationMeta(
    'memoryPrompt',
  );
  @override
  late final GeneratedColumn<String> memoryPrompt = GeneratedColumn<String>(
    'memory_prompt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeceasedMeta = const VerificationMeta(
    'isDeceased',
  );
  @override
  late final GeneratedColumn<bool> isDeceased = GeneratedColumn<bool>(
    'is_deceased',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deceased" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    relationship,
    photoPath,
    voicePath,
    memoryPrompt,
    isDeceased,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeopleData> instance, {
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
    if (data.containsKey('relationship')) {
      context.handle(
        _relationshipMeta,
        relationship.isAcceptableOrUnknown(
          data['relationship']!,
          _relationshipMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relationshipMeta);
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('voice_path')) {
      context.handle(
        _voicePathMeta,
        voicePath.isAcceptableOrUnknown(data['voice_path']!, _voicePathMeta),
      );
    }
    if (data.containsKey('memory_prompt')) {
      context.handle(
        _memoryPromptMeta,
        memoryPrompt.isAcceptableOrUnknown(
          data['memory_prompt']!,
          _memoryPromptMeta,
        ),
      );
    }
    if (data.containsKey('is_deceased')) {
      context.handle(
        _isDeceasedMeta,
        isDeceased.isAcceptableOrUnknown(data['is_deceased']!, _isDeceasedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeopleData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      relationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      )!,
      voicePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_path'],
      ),
      memoryPrompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memory_prompt'],
      ),
      isDeceased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deceased'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PeopleData extends DataClass implements Insertable<PeopleData> {
  final String id;
  final String name;
  final String relationship;
  final String photoPath;
  final String? voicePath;
  final String? memoryPrompt;
  final bool isDeceased;
  final int sortOrder;
  const PeopleData({
    required this.id,
    required this.name,
    required this.relationship,
    required this.photoPath,
    this.voicePath,
    this.memoryPrompt,
    required this.isDeceased,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['relationship'] = Variable<String>(relationship);
    map['photo_path'] = Variable<String>(photoPath);
    if (!nullToAbsent || voicePath != null) {
      map['voice_path'] = Variable<String>(voicePath);
    }
    if (!nullToAbsent || memoryPrompt != null) {
      map['memory_prompt'] = Variable<String>(memoryPrompt);
    }
    map['is_deceased'] = Variable<bool>(isDeceased);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(
      id: Value(id),
      name: Value(name),
      relationship: Value(relationship),
      photoPath: Value(photoPath),
      voicePath: voicePath == null && nullToAbsent
          ? const Value.absent()
          : Value(voicePath),
      memoryPrompt: memoryPrompt == null && nullToAbsent
          ? const Value.absent()
          : Value(memoryPrompt),
      isDeceased: Value(isDeceased),
      sortOrder: Value(sortOrder),
    );
  }

  factory PeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeopleData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      relationship: serializer.fromJson<String>(json['relationship']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      voicePath: serializer.fromJson<String?>(json['voicePath']),
      memoryPrompt: serializer.fromJson<String?>(json['memoryPrompt']),
      isDeceased: serializer.fromJson<bool>(json['isDeceased']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'relationship': serializer.toJson<String>(relationship),
      'photoPath': serializer.toJson<String>(photoPath),
      'voicePath': serializer.toJson<String?>(voicePath),
      'memoryPrompt': serializer.toJson<String?>(memoryPrompt),
      'isDeceased': serializer.toJson<bool>(isDeceased),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PeopleData copyWith({
    String? id,
    String? name,
    String? relationship,
    String? photoPath,
    Value<String?> voicePath = const Value.absent(),
    Value<String?> memoryPrompt = const Value.absent(),
    bool? isDeceased,
    int? sortOrder,
  }) => PeopleData(
    id: id ?? this.id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    photoPath: photoPath ?? this.photoPath,
    voicePath: voicePath.present ? voicePath.value : this.voicePath,
    memoryPrompt: memoryPrompt.present ? memoryPrompt.value : this.memoryPrompt,
    isDeceased: isDeceased ?? this.isDeceased,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PeopleData copyWithCompanion(PeopleCompanion data) {
    return PeopleData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      relationship: data.relationship.present
          ? data.relationship.value
          : this.relationship,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      voicePath: data.voicePath.present ? data.voicePath.value : this.voicePath,
      memoryPrompt: data.memoryPrompt.present
          ? data.memoryPrompt.value
          : this.memoryPrompt,
      isDeceased: data.isDeceased.present
          ? data.isDeceased.value
          : this.isDeceased,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeopleData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('relationship: $relationship, ')
          ..write('photoPath: $photoPath, ')
          ..write('voicePath: $voicePath, ')
          ..write('memoryPrompt: $memoryPrompt, ')
          ..write('isDeceased: $isDeceased, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    relationship,
    photoPath,
    voicePath,
    memoryPrompt,
    isDeceased,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeopleData &&
          other.id == this.id &&
          other.name == this.name &&
          other.relationship == this.relationship &&
          other.photoPath == this.photoPath &&
          other.voicePath == this.voicePath &&
          other.memoryPrompt == this.memoryPrompt &&
          other.isDeceased == this.isDeceased &&
          other.sortOrder == this.sortOrder);
}

class PeopleCompanion extends UpdateCompanion<PeopleData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> relationship;
  final Value<String> photoPath;
  final Value<String?> voicePath;
  final Value<String?> memoryPrompt;
  final Value<bool> isDeceased;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.relationship = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.memoryPrompt = const Value.absent(),
    this.isDeceased = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeopleCompanion.insert({
    required String id,
    required String name,
    required String relationship,
    required String photoPath,
    this.voicePath = const Value.absent(),
    this.memoryPrompt = const Value.absent(),
    this.isDeceased = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       relationship = Value(relationship),
       photoPath = Value(photoPath),
       sortOrder = Value(sortOrder);
  static Insertable<PeopleData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? relationship,
    Expression<String>? photoPath,
    Expression<String>? voicePath,
    Expression<String>? memoryPrompt,
    Expression<bool>? isDeceased,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (relationship != null) 'relationship': relationship,
      if (photoPath != null) 'photo_path': photoPath,
      if (voicePath != null) 'voice_path': voicePath,
      if (memoryPrompt != null) 'memory_prompt': memoryPrompt,
      if (isDeceased != null) 'is_deceased': isDeceased,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeopleCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? relationship,
    Value<String>? photoPath,
    Value<String?>? voicePath,
    Value<String?>? memoryPrompt,
    Value<bool>? isDeceased,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PeopleCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      photoPath: photoPath ?? this.photoPath,
      voicePath: voicePath ?? this.voicePath,
      memoryPrompt: memoryPrompt ?? this.memoryPrompt,
      isDeceased: isDeceased ?? this.isDeceased,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (relationship.present) {
      map['relationship'] = Variable<String>(relationship.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (voicePath.present) {
      map['voice_path'] = Variable<String>(voicePath.value);
    }
    if (memoryPrompt.present) {
      map['memory_prompt'] = Variable<String>(memoryPrompt.value);
    }
    if (isDeceased.present) {
      map['is_deceased'] = Variable<bool>(isDeceased.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('relationship: $relationship, ')
          ..write('photoPath: $photoPath, ')
          ..write('voicePath: $voicePath, ')
          ..write('memoryPrompt: $memoryPrompt, ')
          ..write('isDeceased: $isDeceased, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _doseMeta = const VerificationMeta('dose');
  @override
  late final GeneratedColumn<String> dose = GeneratedColumn<String>(
    'dose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pillPhotoPathMeta = const VerificationMeta(
    'pillPhotoPath',
  );
  @override
  late final GeneratedColumn<String> pillPhotoPath = GeneratedColumn<String>(
    'pill_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voicePathMeta = const VerificationMeta(
    'voicePath',
  );
  @override
  late final GeneratedColumn<String> voicePath = GeneratedColumn<String>(
    'voice_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _windowStartMinMeta = const VerificationMeta(
    'windowStartMin',
  );
  @override
  late final GeneratedColumn<int> windowStartMin = GeneratedColumn<int>(
    'window_start_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windowEndMinMeta = const VerificationMeta(
    'windowEndMin',
  );
  @override
  late final GeneratedColumn<int> windowEndMin = GeneratedColumn<int>(
    'window_end_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chosenTimeMinMeta = const VerificationMeta(
    'chosenTimeMin',
  );
  @override
  late final GeneratedColumn<int> chosenTimeMin = GeneratedColumn<int>(
    'chosen_time_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
    'days_of_week',
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
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    dose,
    pillPhotoPath,
    voicePath,
    windowStartMin,
    windowEndMin,
    chosenTimeMin,
    daysOfWeek,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
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
    if (data.containsKey('dose')) {
      context.handle(
        _doseMeta,
        dose.isAcceptableOrUnknown(data['dose']!, _doseMeta),
      );
    } else if (isInserting) {
      context.missing(_doseMeta);
    }
    if (data.containsKey('pill_photo_path')) {
      context.handle(
        _pillPhotoPathMeta,
        pillPhotoPath.isAcceptableOrUnknown(
          data['pill_photo_path']!,
          _pillPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('voice_path')) {
      context.handle(
        _voicePathMeta,
        voicePath.isAcceptableOrUnknown(data['voice_path']!, _voicePathMeta),
      );
    }
    if (data.containsKey('window_start_min')) {
      context.handle(
        _windowStartMinMeta,
        windowStartMin.isAcceptableOrUnknown(
          data['window_start_min']!,
          _windowStartMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowStartMinMeta);
    }
    if (data.containsKey('window_end_min')) {
      context.handle(
        _windowEndMinMeta,
        windowEndMin.isAcceptableOrUnknown(
          data['window_end_min']!,
          _windowEndMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowEndMinMeta);
    }
    if (data.containsKey('chosen_time_min')) {
      context.handle(
        _chosenTimeMinMeta,
        chosenTimeMin.isAcceptableOrUnknown(
          data['chosen_time_min']!,
          _chosenTimeMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chosenTimeMinMeta);
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_daysOfWeekMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dose'],
      )!,
      pillPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pill_photo_path'],
      ),
      voicePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_path'],
      ),
      windowStartMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_start_min'],
      )!,
      windowEndMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_end_min'],
      )!,
      chosenTimeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chosen_time_min'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final String id;
  final String name;
  final String dose;
  final String? pillPhotoPath;
  final String? voicePath;
  final int windowStartMin;
  final int windowEndMin;
  final int chosenTimeMin;
  final String daysOfWeek;
  final bool active;
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    this.pillPhotoPath,
    this.voicePath,
    required this.windowStartMin,
    required this.windowEndMin,
    required this.chosenTimeMin,
    required this.daysOfWeek,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['dose'] = Variable<String>(dose);
    if (!nullToAbsent || pillPhotoPath != null) {
      map['pill_photo_path'] = Variable<String>(pillPhotoPath);
    }
    if (!nullToAbsent || voicePath != null) {
      map['voice_path'] = Variable<String>(voicePath);
    }
    map['window_start_min'] = Variable<int>(windowStartMin);
    map['window_end_min'] = Variable<int>(windowEndMin);
    map['chosen_time_min'] = Variable<int>(chosenTimeMin);
    map['days_of_week'] = Variable<String>(daysOfWeek);
    map['active'] = Variable<bool>(active);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      dose: Value(dose),
      pillPhotoPath: pillPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pillPhotoPath),
      voicePath: voicePath == null && nullToAbsent
          ? const Value.absent()
          : Value(voicePath),
      windowStartMin: Value(windowStartMin),
      windowEndMin: Value(windowEndMin),
      chosenTimeMin: Value(chosenTimeMin),
      daysOfWeek: Value(daysOfWeek),
      active: Value(active),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dose: serializer.fromJson<String>(json['dose']),
      pillPhotoPath: serializer.fromJson<String?>(json['pillPhotoPath']),
      voicePath: serializer.fromJson<String?>(json['voicePath']),
      windowStartMin: serializer.fromJson<int>(json['windowStartMin']),
      windowEndMin: serializer.fromJson<int>(json['windowEndMin']),
      chosenTimeMin: serializer.fromJson<int>(json['chosenTimeMin']),
      daysOfWeek: serializer.fromJson<String>(json['daysOfWeek']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'dose': serializer.toJson<String>(dose),
      'pillPhotoPath': serializer.toJson<String?>(pillPhotoPath),
      'voicePath': serializer.toJson<String?>(voicePath),
      'windowStartMin': serializer.toJson<int>(windowStartMin),
      'windowEndMin': serializer.toJson<int>(windowEndMin),
      'chosenTimeMin': serializer.toJson<int>(chosenTimeMin),
      'daysOfWeek': serializer.toJson<String>(daysOfWeek),
      'active': serializer.toJson<bool>(active),
    };
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    Value<String?> pillPhotoPath = const Value.absent(),
    Value<String?> voicePath = const Value.absent(),
    int? windowStartMin,
    int? windowEndMin,
    int? chosenTimeMin,
    String? daysOfWeek,
    bool? active,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    dose: dose ?? this.dose,
    pillPhotoPath: pillPhotoPath.present
        ? pillPhotoPath.value
        : this.pillPhotoPath,
    voicePath: voicePath.present ? voicePath.value : this.voicePath,
    windowStartMin: windowStartMin ?? this.windowStartMin,
    windowEndMin: windowEndMin ?? this.windowEndMin,
    chosenTimeMin: chosenTimeMin ?? this.chosenTimeMin,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    active: active ?? this.active,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dose: data.dose.present ? data.dose.value : this.dose,
      pillPhotoPath: data.pillPhotoPath.present
          ? data.pillPhotoPath.value
          : this.pillPhotoPath,
      voicePath: data.voicePath.present ? data.voicePath.value : this.voicePath,
      windowStartMin: data.windowStartMin.present
          ? data.windowStartMin.value
          : this.windowStartMin,
      windowEndMin: data.windowEndMin.present
          ? data.windowEndMin.value
          : this.windowEndMin,
      chosenTimeMin: data.chosenTimeMin.present
          ? data.chosenTimeMin.value
          : this.chosenTimeMin,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('pillPhotoPath: $pillPhotoPath, ')
          ..write('voicePath: $voicePath, ')
          ..write('windowStartMin: $windowStartMin, ')
          ..write('windowEndMin: $windowEndMin, ')
          ..write('chosenTimeMin: $chosenTimeMin, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    dose,
    pillPhotoPath,
    voicePath,
    windowStartMin,
    windowEndMin,
    chosenTimeMin,
    daysOfWeek,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.name == this.name &&
          other.dose == this.dose &&
          other.pillPhotoPath == this.pillPhotoPath &&
          other.voicePath == this.voicePath &&
          other.windowStartMin == this.windowStartMin &&
          other.windowEndMin == this.windowEndMin &&
          other.chosenTimeMin == this.chosenTimeMin &&
          other.daysOfWeek == this.daysOfWeek &&
          other.active == this.active);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> dose;
  final Value<String?> pillPhotoPath;
  final Value<String?> voicePath;
  final Value<int> windowStartMin;
  final Value<int> windowEndMin;
  final Value<int> chosenTimeMin;
  final Value<String> daysOfWeek;
  final Value<bool> active;
  final Value<int> rowid;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dose = const Value.absent(),
    this.pillPhotoPath = const Value.absent(),
    this.voicePath = const Value.absent(),
    this.windowStartMin = const Value.absent(),
    this.windowEndMin = const Value.absent(),
    this.chosenTimeMin = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MedicationsCompanion.insert({
    required String id,
    required String name,
    required String dose,
    this.pillPhotoPath = const Value.absent(),
    this.voicePath = const Value.absent(),
    required int windowStartMin,
    required int windowEndMin,
    required int chosenTimeMin,
    required String daysOfWeek,
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       dose = Value(dose),
       windowStartMin = Value(windowStartMin),
       windowEndMin = Value(windowEndMin),
       chosenTimeMin = Value(chosenTimeMin),
       daysOfWeek = Value(daysOfWeek);
  static Insertable<Medication> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? dose,
    Expression<String>? pillPhotoPath,
    Expression<String>? voicePath,
    Expression<int>? windowStartMin,
    Expression<int>? windowEndMin,
    Expression<int>? chosenTimeMin,
    Expression<String>? daysOfWeek,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dose != null) 'dose': dose,
      if (pillPhotoPath != null) 'pill_photo_path': pillPhotoPath,
      if (voicePath != null) 'voice_path': voicePath,
      if (windowStartMin != null) 'window_start_min': windowStartMin,
      if (windowEndMin != null) 'window_end_min': windowEndMin,
      if (chosenTimeMin != null) 'chosen_time_min': chosenTimeMin,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MedicationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? dose,
    Value<String?>? pillPhotoPath,
    Value<String?>? voicePath,
    Value<int>? windowStartMin,
    Value<int>? windowEndMin,
    Value<int>? chosenTimeMin,
    Value<String>? daysOfWeek,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      pillPhotoPath: pillPhotoPath ?? this.pillPhotoPath,
      voicePath: voicePath ?? this.voicePath,
      windowStartMin: windowStartMin ?? this.windowStartMin,
      windowEndMin: windowEndMin ?? this.windowEndMin,
      chosenTimeMin: chosenTimeMin ?? this.chosenTimeMin,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      active: active ?? this.active,
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
    if (dose.present) {
      map['dose'] = Variable<String>(dose.value);
    }
    if (pillPhotoPath.present) {
      map['pill_photo_path'] = Variable<String>(pillPhotoPath.value);
    }
    if (voicePath.present) {
      map['voice_path'] = Variable<String>(voicePath.value);
    }
    if (windowStartMin.present) {
      map['window_start_min'] = Variable<int>(windowStartMin.value);
    }
    if (windowEndMin.present) {
      map['window_end_min'] = Variable<int>(windowEndMin.value);
    }
    if (chosenTimeMin.present) {
      map['chosen_time_min'] = Variable<int>(chosenTimeMin.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dose: $dose, ')
          ..write('pillPhotoPath: $pillPhotoPath, ')
          ..write('voicePath: $voicePath, ')
          ..write('windowStartMin: $windowStartMin, ')
          ..write('windowEndMin: $windowEndMin, ')
          ..write('chosenTimeMin: $chosenTimeMin, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoutineItemsTable extends RoutineItems
    with TableInfo<$RoutineItemsTable, RoutineItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoutineItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeMinMeta = const VerificationMeta(
    'timeMin',
  );
  @override
  late final GeneratedColumn<int> timeMin = GeneratedColumn<int>(
    'time_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelKeyMeta = const VerificationMeta(
    'labelKey',
  );
  @override
  late final GeneratedColumn<String> labelKey = GeneratedColumn<String>(
    'label_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconAssetMeta = const VerificationMeta(
    'iconAsset',
  );
  @override
  late final GeneratedColumn<String> iconAsset = GeneratedColumn<String>(
    'icon_asset',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timeMin, labelKey, iconAsset];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'routine_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RoutineItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('time_min')) {
      context.handle(
        _timeMinMeta,
        timeMin.isAcceptableOrUnknown(data['time_min']!, _timeMinMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMinMeta);
    }
    if (data.containsKey('label_key')) {
      context.handle(
        _labelKeyMeta,
        labelKey.isAcceptableOrUnknown(data['label_key']!, _labelKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_labelKeyMeta);
    }
    if (data.containsKey('icon_asset')) {
      context.handle(
        _iconAssetMeta,
        iconAsset.isAcceptableOrUnknown(data['icon_asset']!, _iconAssetMeta),
      );
    } else if (isInserting) {
      context.missing(_iconAssetMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RoutineItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RoutineItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timeMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_min'],
      )!,
      labelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label_key'],
      )!,
      iconAsset: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_asset'],
      )!,
    );
  }

  @override
  $RoutineItemsTable createAlias(String alias) {
    return $RoutineItemsTable(attachedDatabase, alias);
  }
}

class RoutineItem extends DataClass implements Insertable<RoutineItem> {
  final String id;
  final int timeMin;
  final String labelKey;
  final String iconAsset;
  const RoutineItem({
    required this.id,
    required this.timeMin,
    required this.labelKey,
    required this.iconAsset,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['time_min'] = Variable<int>(timeMin);
    map['label_key'] = Variable<String>(labelKey);
    map['icon_asset'] = Variable<String>(iconAsset);
    return map;
  }

  RoutineItemsCompanion toCompanion(bool nullToAbsent) {
    return RoutineItemsCompanion(
      id: Value(id),
      timeMin: Value(timeMin),
      labelKey: Value(labelKey),
      iconAsset: Value(iconAsset),
    );
  }

  factory RoutineItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RoutineItem(
      id: serializer.fromJson<String>(json['id']),
      timeMin: serializer.fromJson<int>(json['timeMin']),
      labelKey: serializer.fromJson<String>(json['labelKey']),
      iconAsset: serializer.fromJson<String>(json['iconAsset']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timeMin': serializer.toJson<int>(timeMin),
      'labelKey': serializer.toJson<String>(labelKey),
      'iconAsset': serializer.toJson<String>(iconAsset),
    };
  }

  RoutineItem copyWith({
    String? id,
    int? timeMin,
    String? labelKey,
    String? iconAsset,
  }) => RoutineItem(
    id: id ?? this.id,
    timeMin: timeMin ?? this.timeMin,
    labelKey: labelKey ?? this.labelKey,
    iconAsset: iconAsset ?? this.iconAsset,
  );
  RoutineItem copyWithCompanion(RoutineItemsCompanion data) {
    return RoutineItem(
      id: data.id.present ? data.id.value : this.id,
      timeMin: data.timeMin.present ? data.timeMin.value : this.timeMin,
      labelKey: data.labelKey.present ? data.labelKey.value : this.labelKey,
      iconAsset: data.iconAsset.present ? data.iconAsset.value : this.iconAsset,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RoutineItem(')
          ..write('id: $id, ')
          ..write('timeMin: $timeMin, ')
          ..write('labelKey: $labelKey, ')
          ..write('iconAsset: $iconAsset')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeMin, labelKey, iconAsset);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RoutineItem &&
          other.id == this.id &&
          other.timeMin == this.timeMin &&
          other.labelKey == this.labelKey &&
          other.iconAsset == this.iconAsset);
}

class RoutineItemsCompanion extends UpdateCompanion<RoutineItem> {
  final Value<String> id;
  final Value<int> timeMin;
  final Value<String> labelKey;
  final Value<String> iconAsset;
  final Value<int> rowid;
  const RoutineItemsCompanion({
    this.id = const Value.absent(),
    this.timeMin = const Value.absent(),
    this.labelKey = const Value.absent(),
    this.iconAsset = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoutineItemsCompanion.insert({
    required String id,
    required int timeMin,
    required String labelKey,
    required String iconAsset,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timeMin = Value(timeMin),
       labelKey = Value(labelKey),
       iconAsset = Value(iconAsset);
  static Insertable<RoutineItem> custom({
    Expression<String>? id,
    Expression<int>? timeMin,
    Expression<String>? labelKey,
    Expression<String>? iconAsset,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeMin != null) 'time_min': timeMin,
      if (labelKey != null) 'label_key': labelKey,
      if (iconAsset != null) 'icon_asset': iconAsset,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoutineItemsCompanion copyWith({
    Value<String>? id,
    Value<int>? timeMin,
    Value<String>? labelKey,
    Value<String>? iconAsset,
    Value<int>? rowid,
  }) {
    return RoutineItemsCompanion(
      id: id ?? this.id,
      timeMin: timeMin ?? this.timeMin,
      labelKey: labelKey ?? this.labelKey,
      iconAsset: iconAsset ?? this.iconAsset,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timeMin.present) {
      map['time_min'] = Variable<int>(timeMin.value);
    }
    if (labelKey.present) {
      map['label_key'] = Variable<String>(labelKey.value);
    }
    if (iconAsset.present) {
      map['icon_asset'] = Variable<String>(iconAsset.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoutineItemsCompanion(')
          ..write('id: $id, ')
          ..write('timeMin: $timeMin, ')
          ..write('labelKey: $labelKey, ')
          ..write('iconAsset: $iconAsset, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppConfigsTable extends AppConfigs
    with TableInfo<$AppConfigsTable, AppConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppConfigsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppConfig> instance, {
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
  AppConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppConfig(
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
  $AppConfigsTable createAlias(String alias) {
    return $AppConfigsTable(attachedDatabase, alias);
  }
}

class AppConfig extends DataClass implements Insertable<AppConfig> {
  final String key;
  final String value;
  const AppConfig({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppConfigsCompanion toCompanion(bool nullToAbsent) {
    return AppConfigsCompanion(key: Value(key), value: Value(value));
  }

  factory AppConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppConfig(
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

  AppConfig copyWith({String? key, String? value}) =>
      AppConfig(key: key ?? this.key, value: value ?? this.value);
  AppConfig copyWithCompanion(AppConfigsCompanion data) {
    return AppConfig(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppConfig(')
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
      (other is AppConfig &&
          other.key == this.key &&
          other.value == this.value);
}

class AppConfigsCompanion extends UpdateCompanion<AppConfig> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppConfigsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppConfigsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppConfig> custom({
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

  AppConfigsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppConfigsCompanion(
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
    return (StringBuffer('AppConfigsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SmritiDatabase extends GeneratedDatabase {
  _$SmritiDatabase(QueryExecutor e) : super(e);
  $SmritiDatabaseManager get managers => $SmritiDatabaseManager(this);
  late final $TrialEventsTable trialEvents = $TrialEventsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $ReminderEventsTable reminderEvents = $ReminderEventsTable(this);
  late final $VoiceMemosTable voiceMemos = $VoiceMemosTable(this);
  late final $EscalationRequestsTable escalationRequests =
      $EscalationRequestsTable(this);
  late final $AbilityStatesTable abilityStates = $AbilityStatesTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $RoutineItemsTable routineItems = $RoutineItemsTable(this);
  late final $AppConfigsTable appConfigs = $AppConfigsTable(this);
  late final AppConfigsDao appConfigsDao = AppConfigsDao(
    this as SmritiDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trialEvents,
    sessions,
    reminderEvents,
    voiceMemos,
    escalationRequests,
    abilityStates,
    people,
    medications,
    routineItems,
    appConfigs,
  ];
}

typedef $$TrialEventsTableCreateCompanionBuilder =
    TrialEventsCompanion Function({
      required String id,
      required String sessionId,
      required String gameId,
      required String domain,
      required String itemId,
      required double itemDifficulty,
      required double thetaBefore,
      required bool correct,
      required int initiationMs,
      required int movementMs,
      required int responseTimeMs,
      Value<String?> chosenId,
      Value<String?> errorClass,
      required int trialIndex,
      Value<String?> trialContext,
      Value<int> hintLevel,
      Value<String?> metrics,
      required int ts,
      required int hourOfDay,
      required int tzOffsetMin,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$TrialEventsTableUpdateCompanionBuilder =
    TrialEventsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> gameId,
      Value<String> domain,
      Value<String> itemId,
      Value<double> itemDifficulty,
      Value<double> thetaBefore,
      Value<bool> correct,
      Value<int> initiationMs,
      Value<int> movementMs,
      Value<int> responseTimeMs,
      Value<String?> chosenId,
      Value<String?> errorClass,
      Value<int> trialIndex,
      Value<String?> trialContext,
      Value<int> hintLevel,
      Value<String?> metrics,
      Value<int> ts,
      Value<int> hourOfDay,
      Value<int> tzOffsetMin,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$TrialEventsTableFilterComposer
    extends Composer<_$SmritiDatabase, $TrialEventsTable> {
  $$TrialEventsTableFilterComposer({
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

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get itemDifficulty => $composableBuilder(
    column: $table.itemDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thetaBefore => $composableBuilder(
    column: $table.thetaBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initiationMs => $composableBuilder(
    column: $table.initiationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movementMs => $composableBuilder(
    column: $table.movementMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chosenId => $composableBuilder(
    column: $table.chosenId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorClass => $composableBuilder(
    column: $table.errorClass,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get trialIndex => $composableBuilder(
    column: $table.trialIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trialContext => $composableBuilder(
    column: $table.trialContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metrics => $composableBuilder(
    column: $table.metrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMin => $composableBuilder(
    column: $table.tzOffsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TrialEventsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $TrialEventsTable> {
  $$TrialEventsTableOrderingComposer({
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

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get itemDifficulty => $composableBuilder(
    column: $table.itemDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thetaBefore => $composableBuilder(
    column: $table.thetaBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initiationMs => $composableBuilder(
    column: $table.initiationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movementMs => $composableBuilder(
    column: $table.movementMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chosenId => $composableBuilder(
    column: $table.chosenId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorClass => $composableBuilder(
    column: $table.errorClass,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trialIndex => $composableBuilder(
    column: $table.trialIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trialContext => $composableBuilder(
    column: $table.trialContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintLevel => $composableBuilder(
    column: $table.hintLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metrics => $composableBuilder(
    column: $table.metrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ts => $composableBuilder(
    column: $table.ts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hourOfDay => $composableBuilder(
    column: $table.hourOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMin => $composableBuilder(
    column: $table.tzOffsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TrialEventsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $TrialEventsTable> {
  $$TrialEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<double> get itemDifficulty => $composableBuilder(
    column: $table.itemDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<double> get thetaBefore => $composableBuilder(
    column: $table.thetaBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get initiationMs => $composableBuilder(
    column: $table.initiationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get movementMs => $composableBuilder(
    column: $table.movementMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chosenId =>
      $composableBuilder(column: $table.chosenId, builder: (column) => column);

  GeneratedColumn<String> get errorClass => $composableBuilder(
    column: $table.errorClass,
    builder: (column) => column,
  );

  GeneratedColumn<int> get trialIndex => $composableBuilder(
    column: $table.trialIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trialContext => $composableBuilder(
    column: $table.trialContext,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hintLevel =>
      $composableBuilder(column: $table.hintLevel, builder: (column) => column);

  GeneratedColumn<String> get metrics =>
      $composableBuilder(column: $table.metrics, builder: (column) => column);

  GeneratedColumn<int> get ts =>
      $composableBuilder(column: $table.ts, builder: (column) => column);

  GeneratedColumn<int> get hourOfDay =>
      $composableBuilder(column: $table.hourOfDay, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMin => $composableBuilder(
    column: $table.tzOffsetMin,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$TrialEventsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $TrialEventsTable,
          TrialEvent,
          $$TrialEventsTableFilterComposer,
          $$TrialEventsTableOrderingComposer,
          $$TrialEventsTableAnnotationComposer,
          $$TrialEventsTableCreateCompanionBuilder,
          $$TrialEventsTableUpdateCompanionBuilder,
          (
            TrialEvent,
            BaseReferences<_$SmritiDatabase, $TrialEventsTable, TrialEvent>,
          ),
          TrialEvent,
          PrefetchHooks Function()
        > {
  $$TrialEventsTableTableManager(_$SmritiDatabase db, $TrialEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrialEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrialEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrialEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> domain = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<double> itemDifficulty = const Value.absent(),
                Value<double> thetaBefore = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<int> initiationMs = const Value.absent(),
                Value<int> movementMs = const Value.absent(),
                Value<int> responseTimeMs = const Value.absent(),
                Value<String?> chosenId = const Value.absent(),
                Value<String?> errorClass = const Value.absent(),
                Value<int> trialIndex = const Value.absent(),
                Value<String?> trialContext = const Value.absent(),
                Value<int> hintLevel = const Value.absent(),
                Value<String?> metrics = const Value.absent(),
                Value<int> ts = const Value.absent(),
                Value<int> hourOfDay = const Value.absent(),
                Value<int> tzOffsetMin = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrialEventsCompanion(
                id: id,
                sessionId: sessionId,
                gameId: gameId,
                domain: domain,
                itemId: itemId,
                itemDifficulty: itemDifficulty,
                thetaBefore: thetaBefore,
                correct: correct,
                initiationMs: initiationMs,
                movementMs: movementMs,
                responseTimeMs: responseTimeMs,
                chosenId: chosenId,
                errorClass: errorClass,
                trialIndex: trialIndex,
                trialContext: trialContext,
                hintLevel: hintLevel,
                metrics: metrics,
                ts: ts,
                hourOfDay: hourOfDay,
                tzOffsetMin: tzOffsetMin,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String gameId,
                required String domain,
                required String itemId,
                required double itemDifficulty,
                required double thetaBefore,
                required bool correct,
                required int initiationMs,
                required int movementMs,
                required int responseTimeMs,
                Value<String?> chosenId = const Value.absent(),
                Value<String?> errorClass = const Value.absent(),
                required int trialIndex,
                Value<String?> trialContext = const Value.absent(),
                Value<int> hintLevel = const Value.absent(),
                Value<String?> metrics = const Value.absent(),
                required int ts,
                required int hourOfDay,
                required int tzOffsetMin,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TrialEventsCompanion.insert(
                id: id,
                sessionId: sessionId,
                gameId: gameId,
                domain: domain,
                itemId: itemId,
                itemDifficulty: itemDifficulty,
                thetaBefore: thetaBefore,
                correct: correct,
                initiationMs: initiationMs,
                movementMs: movementMs,
                responseTimeMs: responseTimeMs,
                chosenId: chosenId,
                errorClass: errorClass,
                trialIndex: trialIndex,
                trialContext: trialContext,
                hintLevel: hintLevel,
                metrics: metrics,
                ts: ts,
                hourOfDay: hourOfDay,
                tzOffsetMin: tzOffsetMin,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TrialEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $TrialEventsTable,
      TrialEvent,
      $$TrialEventsTableFilterComposer,
      $$TrialEventsTableOrderingComposer,
      $$TrialEventsTableAnnotationComposer,
      $$TrialEventsTableCreateCompanionBuilder,
      $$TrialEventsTableUpdateCompanionBuilder,
      (
        TrialEvent,
        BaseReferences<_$SmritiDatabase, $TrialEventsTable, TrialEvent>,
      ),
      TrialEvent,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required int startedAt,
      Value<int?> endedAt,
      required String gameIds,
      Value<bool> completed,
      Value<int?> abandonedAtMs,
      Value<int> demoReplays,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<int> startedAt,
      Value<int?> endedAt,
      Value<String> gameIds,
      Value<bool> completed,
      Value<int?> abandonedAtMs,
      Value<int> demoReplays,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$SmritiDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
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

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameIds => $composableBuilder(
    column: $table.gameIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get abandonedAtMs => $composableBuilder(
    column: $table.abandonedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get demoReplays => $composableBuilder(
    column: $table.demoReplays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
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

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameIds => $composableBuilder(
    column: $table.gameIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get abandonedAtMs => $composableBuilder(
    column: $table.abandonedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get demoReplays => $composableBuilder(
    column: $table.demoReplays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get gameIds =>
      $composableBuilder(column: $table.gameIds, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get abandonedAtMs => $composableBuilder(
    column: $table.abandonedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get demoReplays => $composableBuilder(
    column: $table.demoReplays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$SmritiDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$SmritiDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> endedAt = const Value.absent(),
                Value<String> gameIds = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int?> abandonedAtMs = const Value.absent(),
                Value<int> demoReplays = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                gameIds: gameIds,
                completed: completed,
                abandonedAtMs: abandonedAtMs,
                demoReplays: demoReplays,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int startedAt,
                Value<int?> endedAt = const Value.absent(),
                required String gameIds,
                Value<bool> completed = const Value.absent(),
                Value<int?> abandonedAtMs = const Value.absent(),
                Value<int> demoReplays = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt,
                gameIds: gameIds,
                completed: completed,
                abandonedAtMs: abandonedAtMs,
                demoReplays: demoReplays,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$SmritiDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$ReminderEventsTableCreateCompanionBuilder =
    ReminderEventsCompanion Function({
      required String id,
      required String medicationId,
      required int scheduledAt,
      Value<int?> firedAt,
      Value<int?> respondedAt,
      Value<String?> outcome,
      required String channel,
      required int ladderStep,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$ReminderEventsTableUpdateCompanionBuilder =
    ReminderEventsCompanion Function({
      Value<String> id,
      Value<String> medicationId,
      Value<int> scheduledAt,
      Value<int?> firedAt,
      Value<int?> respondedAt,
      Value<String?> outcome,
      Value<String> channel,
      Value<int> ladderStep,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$ReminderEventsTableFilterComposer
    extends Composer<_$SmritiDatabase, $ReminderEventsTable> {
  $$ReminderEventsTableFilterComposer({
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

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firedAt => $composableBuilder(
    column: $table.firedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ladderStep => $composableBuilder(
    column: $table.ladderStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReminderEventsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $ReminderEventsTable> {
  $$ReminderEventsTableOrderingComposer({
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

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firedAt => $composableBuilder(
    column: $table.firedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ladderStep => $composableBuilder(
    column: $table.ladderStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReminderEventsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $ReminderEventsTable> {
  $$ReminderEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firedAt =>
      $composableBuilder(column: $table.firedAt, builder: (column) => column);

  GeneratedColumn<int> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<int> get ladderStep => $composableBuilder(
    column: $table.ladderStep,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ReminderEventsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $ReminderEventsTable,
          ReminderEvent,
          $$ReminderEventsTableFilterComposer,
          $$ReminderEventsTableOrderingComposer,
          $$ReminderEventsTableAnnotationComposer,
          $$ReminderEventsTableCreateCompanionBuilder,
          $$ReminderEventsTableUpdateCompanionBuilder,
          (
            ReminderEvent,
            BaseReferences<
              _$SmritiDatabase,
              $ReminderEventsTable,
              ReminderEvent
            >,
          ),
          ReminderEvent,
          PrefetchHooks Function()
        > {
  $$ReminderEventsTableTableManager(
    _$SmritiDatabase db,
    $ReminderEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReminderEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReminderEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReminderEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int> scheduledAt = const Value.absent(),
                Value<int?> firedAt = const Value.absent(),
                Value<int?> respondedAt = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<int> ladderStep = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderEventsCompanion(
                id: id,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                firedAt: firedAt,
                respondedAt: respondedAt,
                outcome: outcome,
                channel: channel,
                ladderStep: ladderStep,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String medicationId,
                required int scheduledAt,
                Value<int?> firedAt = const Value.absent(),
                Value<int?> respondedAt = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                required String channel,
                required int ladderStep,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReminderEventsCompanion.insert(
                id: id,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                firedAt: firedAt,
                respondedAt: respondedAt,
                outcome: outcome,
                channel: channel,
                ladderStep: ladderStep,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReminderEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $ReminderEventsTable,
      ReminderEvent,
      $$ReminderEventsTableFilterComposer,
      $$ReminderEventsTableOrderingComposer,
      $$ReminderEventsTableAnnotationComposer,
      $$ReminderEventsTableCreateCompanionBuilder,
      $$ReminderEventsTableUpdateCompanionBuilder,
      (
        ReminderEvent,
        BaseReferences<_$SmritiDatabase, $ReminderEventsTable, ReminderEvent>,
      ),
      ReminderEvent,
      PrefetchHooks Function()
    >;
typedef $$VoiceMemosTableCreateCompanionBuilder =
    VoiceMemosCompanion Function({
      required String id,
      required String localPath,
      required int durationMs,
      required int recordedAt,
      Value<String?> contextTag,
      Value<bool> uploaded,
      Value<int> rowid,
    });
typedef $$VoiceMemosTableUpdateCompanionBuilder =
    VoiceMemosCompanion Function({
      Value<String> id,
      Value<String> localPath,
      Value<int> durationMs,
      Value<int> recordedAt,
      Value<String?> contextTag,
      Value<bool> uploaded,
      Value<int> rowid,
    });

class $$VoiceMemosTableFilterComposer
    extends Composer<_$SmritiDatabase, $VoiceMemosTable> {
  $$VoiceMemosTableFilterComposer({
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

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextTag => $composableBuilder(
    column: $table.contextTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VoiceMemosTableOrderingComposer
    extends Composer<_$SmritiDatabase, $VoiceMemosTable> {
  $$VoiceMemosTableOrderingComposer({
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

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextTag => $composableBuilder(
    column: $table.contextTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get uploaded => $composableBuilder(
    column: $table.uploaded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VoiceMemosTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $VoiceMemosTable> {
  $$VoiceMemosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextTag => $composableBuilder(
    column: $table.contextTag,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get uploaded =>
      $composableBuilder(column: $table.uploaded, builder: (column) => column);
}

class $$VoiceMemosTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $VoiceMemosTable,
          VoiceMemo,
          $$VoiceMemosTableFilterComposer,
          $$VoiceMemosTableOrderingComposer,
          $$VoiceMemosTableAnnotationComposer,
          $$VoiceMemosTableCreateCompanionBuilder,
          $$VoiceMemosTableUpdateCompanionBuilder,
          (
            VoiceMemo,
            BaseReferences<_$SmritiDatabase, $VoiceMemosTable, VoiceMemo>,
          ),
          VoiceMemo,
          PrefetchHooks Function()
        > {
  $$VoiceMemosTableTableManager(_$SmritiDatabase db, $VoiceMemosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VoiceMemosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VoiceMemosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VoiceMemosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<String?> contextTag = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceMemosCompanion(
                id: id,
                localPath: localPath,
                durationMs: durationMs,
                recordedAt: recordedAt,
                contextTag: contextTag,
                uploaded: uploaded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localPath,
                required int durationMs,
                required int recordedAt,
                Value<String?> contextTag = const Value.absent(),
                Value<bool> uploaded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VoiceMemosCompanion.insert(
                id: id,
                localPath: localPath,
                durationMs: durationMs,
                recordedAt: recordedAt,
                contextTag: contextTag,
                uploaded: uploaded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VoiceMemosTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $VoiceMemosTable,
      VoiceMemo,
      $$VoiceMemosTableFilterComposer,
      $$VoiceMemosTableOrderingComposer,
      $$VoiceMemosTableAnnotationComposer,
      $$VoiceMemosTableCreateCompanionBuilder,
      $$VoiceMemosTableUpdateCompanionBuilder,
      (
        VoiceMemo,
        BaseReferences<_$SmritiDatabase, $VoiceMemosTable, VoiceMemo>,
      ),
      VoiceMemo,
      PrefetchHooks Function()
    >;
typedef $$EscalationRequestsTableCreateCompanionBuilder =
    EscalationRequestsCompanion Function({
      required String id,
      required String reminderEventId,
      required String medicationId,
      required int step,
      required int requestedAt,
      Value<bool> cancelled,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$EscalationRequestsTableUpdateCompanionBuilder =
    EscalationRequestsCompanion Function({
      Value<String> id,
      Value<String> reminderEventId,
      Value<String> medicationId,
      Value<int> step,
      Value<int> requestedAt,
      Value<bool> cancelled,
      Value<bool> synced,
      Value<int> rowid,
    });

class $$EscalationRequestsTableFilterComposer
    extends Composer<_$SmritiDatabase, $EscalationRequestsTable> {
  $$EscalationRequestsTableFilterComposer({
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

  ColumnFilters<String> get reminderEventId => $composableBuilder(
    column: $table.reminderEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EscalationRequestsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $EscalationRequestsTable> {
  $$EscalationRequestsTableOrderingComposer({
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

  ColumnOrderings<String> get reminderEventId => $composableBuilder(
    column: $table.reminderEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cancelled => $composableBuilder(
    column: $table.cancelled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EscalationRequestsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $EscalationRequestsTable> {
  $$EscalationRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get reminderEventId => $composableBuilder(
    column: $table.reminderEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<int> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get cancelled =>
      $composableBuilder(column: $table.cancelled, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$EscalationRequestsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $EscalationRequestsTable,
          EscalationRequest,
          $$EscalationRequestsTableFilterComposer,
          $$EscalationRequestsTableOrderingComposer,
          $$EscalationRequestsTableAnnotationComposer,
          $$EscalationRequestsTableCreateCompanionBuilder,
          $$EscalationRequestsTableUpdateCompanionBuilder,
          (
            EscalationRequest,
            BaseReferences<
              _$SmritiDatabase,
              $EscalationRequestsTable,
              EscalationRequest
            >,
          ),
          EscalationRequest,
          PrefetchHooks Function()
        > {
  $$EscalationRequestsTableTableManager(
    _$SmritiDatabase db,
    $EscalationRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EscalationRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EscalationRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EscalationRequestsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> reminderEventId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<int> step = const Value.absent(),
                Value<int> requestedAt = const Value.absent(),
                Value<bool> cancelled = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EscalationRequestsCompanion(
                id: id,
                reminderEventId: reminderEventId,
                medicationId: medicationId,
                step: step,
                requestedAt: requestedAt,
                cancelled: cancelled,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String reminderEventId,
                required String medicationId,
                required int step,
                required int requestedAt,
                Value<bool> cancelled = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EscalationRequestsCompanion.insert(
                id: id,
                reminderEventId: reminderEventId,
                medicationId: medicationId,
                step: step,
                requestedAt: requestedAt,
                cancelled: cancelled,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EscalationRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $EscalationRequestsTable,
      EscalationRequest,
      $$EscalationRequestsTableFilterComposer,
      $$EscalationRequestsTableOrderingComposer,
      $$EscalationRequestsTableAnnotationComposer,
      $$EscalationRequestsTableCreateCompanionBuilder,
      $$EscalationRequestsTableUpdateCompanionBuilder,
      (
        EscalationRequest,
        BaseReferences<
          _$SmritiDatabase,
          $EscalationRequestsTable,
          EscalationRequest
        >,
      ),
      EscalationRequest,
      PrefetchHooks Function()
    >;
typedef $$AbilityStatesTableCreateCompanionBuilder =
    AbilityStatesCompanion Function({
      required String domain,
      required double theta,
      required int nTrials,
      required double rtMeanLog,
      required double rtVar,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AbilityStatesTableUpdateCompanionBuilder =
    AbilityStatesCompanion Function({
      Value<String> domain,
      Value<double> theta,
      Value<int> nTrials,
      Value<double> rtMeanLog,
      Value<double> rtVar,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AbilityStatesTableFilterComposer
    extends Composer<_$SmritiDatabase, $AbilityStatesTable> {
  $$AbilityStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get theta => $composableBuilder(
    column: $table.theta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nTrials => $composableBuilder(
    column: $table.nTrials,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rtMeanLog => $composableBuilder(
    column: $table.rtMeanLog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rtVar => $composableBuilder(
    column: $table.rtVar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AbilityStatesTableOrderingComposer
    extends Composer<_$SmritiDatabase, $AbilityStatesTable> {
  $$AbilityStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get theta => $composableBuilder(
    column: $table.theta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nTrials => $composableBuilder(
    column: $table.nTrials,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rtMeanLog => $composableBuilder(
    column: $table.rtMeanLog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rtVar => $composableBuilder(
    column: $table.rtVar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AbilityStatesTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $AbilityStatesTable> {
  $$AbilityStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<double> get theta =>
      $composableBuilder(column: $table.theta, builder: (column) => column);

  GeneratedColumn<int> get nTrials =>
      $composableBuilder(column: $table.nTrials, builder: (column) => column);

  GeneratedColumn<double> get rtMeanLog =>
      $composableBuilder(column: $table.rtMeanLog, builder: (column) => column);

  GeneratedColumn<double> get rtVar =>
      $composableBuilder(column: $table.rtVar, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AbilityStatesTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $AbilityStatesTable,
          AbilityState,
          $$AbilityStatesTableFilterComposer,
          $$AbilityStatesTableOrderingComposer,
          $$AbilityStatesTableAnnotationComposer,
          $$AbilityStatesTableCreateCompanionBuilder,
          $$AbilityStatesTableUpdateCompanionBuilder,
          (
            AbilityState,
            BaseReferences<_$SmritiDatabase, $AbilityStatesTable, AbilityState>,
          ),
          AbilityState,
          PrefetchHooks Function()
        > {
  $$AbilityStatesTableTableManager(
    _$SmritiDatabase db,
    $AbilityStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AbilityStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AbilityStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AbilityStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> domain = const Value.absent(),
                Value<double> theta = const Value.absent(),
                Value<int> nTrials = const Value.absent(),
                Value<double> rtMeanLog = const Value.absent(),
                Value<double> rtVar = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AbilityStatesCompanion(
                domain: domain,
                theta: theta,
                nTrials: nTrials,
                rtMeanLog: rtMeanLog,
                rtVar: rtVar,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String domain,
                required double theta,
                required int nTrials,
                required double rtMeanLog,
                required double rtVar,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AbilityStatesCompanion.insert(
                domain: domain,
                theta: theta,
                nTrials: nTrials,
                rtMeanLog: rtMeanLog,
                rtVar: rtVar,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AbilityStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $AbilityStatesTable,
      AbilityState,
      $$AbilityStatesTableFilterComposer,
      $$AbilityStatesTableOrderingComposer,
      $$AbilityStatesTableAnnotationComposer,
      $$AbilityStatesTableCreateCompanionBuilder,
      $$AbilityStatesTableUpdateCompanionBuilder,
      (
        AbilityState,
        BaseReferences<_$SmritiDatabase, $AbilityStatesTable, AbilityState>,
      ),
      AbilityState,
      PrefetchHooks Function()
    >;
typedef $$PeopleTableCreateCompanionBuilder =
    PeopleCompanion Function({
      required String id,
      required String name,
      required String relationship,
      required String photoPath,
      Value<String?> voicePath,
      Value<String?> memoryPrompt,
      Value<bool> isDeceased,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$PeopleTableUpdateCompanionBuilder =
    PeopleCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> relationship,
      Value<String> photoPath,
      Value<String?> voicePath,
      Value<String?> memoryPrompt,
      Value<bool> isDeceased,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$PeopleTableFilterComposer
    extends Composer<_$SmritiDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
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

  ColumnFilters<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voicePath => $composableBuilder(
    column: $table.voicePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memoryPrompt => $composableBuilder(
    column: $table.memoryPrompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeceased => $composableBuilder(
    column: $table.isDeceased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeopleTableOrderingComposer
    extends Composer<_$SmritiDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
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

  ColumnOrderings<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voicePath => $composableBuilder(
    column: $table.voicePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memoryPrompt => $composableBuilder(
    column: $table.memoryPrompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeceased => $composableBuilder(
    column: $table.isDeceased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
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

  GeneratedColumn<String> get relationship => $composableBuilder(
    column: $table.relationship,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get voicePath =>
      $composableBuilder(column: $table.voicePath, builder: (column) => column);

  GeneratedColumn<String> get memoryPrompt => $composableBuilder(
    column: $table.memoryPrompt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeceased => $composableBuilder(
    column: $table.isDeceased,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $PeopleTable,
          PeopleData,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (
            PeopleData,
            BaseReferences<_$SmritiDatabase, $PeopleTable, PeopleData>,
          ),
          PeopleData,
          PrefetchHooks Function()
        > {
  $$PeopleTableTableManager(_$SmritiDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> relationship = const Value.absent(),
                Value<String> photoPath = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                Value<String?> memoryPrompt = const Value.absent(),
                Value<bool> isDeceased = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion(
                id: id,
                name: name,
                relationship: relationship,
                photoPath: photoPath,
                voicePath: voicePath,
                memoryPrompt: memoryPrompt,
                isDeceased: isDeceased,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String relationship,
                required String photoPath,
                Value<String?> voicePath = const Value.absent(),
                Value<String?> memoryPrompt = const Value.absent(),
                Value<bool> isDeceased = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => PeopleCompanion.insert(
                id: id,
                name: name,
                relationship: relationship,
                photoPath: photoPath,
                voicePath: voicePath,
                memoryPrompt: memoryPrompt,
                isDeceased: isDeceased,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $PeopleTable,
      PeopleData,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (PeopleData, BaseReferences<_$SmritiDatabase, $PeopleTable, PeopleData>),
      PeopleData,
      PrefetchHooks Function()
    >;
typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      required String id,
      required String name,
      required String dose,
      Value<String?> pillPhotoPath,
      Value<String?> voicePath,
      required int windowStartMin,
      required int windowEndMin,
      required int chosenTimeMin,
      required String daysOfWeek,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> dose,
      Value<String?> pillPhotoPath,
      Value<String?> voicePath,
      Value<int> windowStartMin,
      Value<int> windowEndMin,
      Value<int> chosenTimeMin,
      Value<String> daysOfWeek,
      Value<bool> active,
      Value<int> rowid,
    });

class $$MedicationsTableFilterComposer
    extends Composer<_$SmritiDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
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

  ColumnFilters<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pillPhotoPath => $composableBuilder(
    column: $table.pillPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voicePath => $composableBuilder(
    column: $table.voicePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowStartMin => $composableBuilder(
    column: $table.windowStartMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowEndMin => $composableBuilder(
    column: $table.windowEndMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chosenTimeMin => $composableBuilder(
    column: $table.chosenTimeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
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

  ColumnOrderings<String> get dose => $composableBuilder(
    column: $table.dose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pillPhotoPath => $composableBuilder(
    column: $table.pillPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voicePath => $composableBuilder(
    column: $table.voicePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowStartMin => $composableBuilder(
    column: $table.windowStartMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowEndMin => $composableBuilder(
    column: $table.windowEndMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chosenTimeMin => $composableBuilder(
    column: $table.chosenTimeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
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

  GeneratedColumn<String> get dose =>
      $composableBuilder(column: $table.dose, builder: (column) => column);

  GeneratedColumn<String> get pillPhotoPath => $composableBuilder(
    column: $table.pillPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voicePath =>
      $composableBuilder(column: $table.voicePath, builder: (column) => column);

  GeneratedColumn<int> get windowStartMin => $composableBuilder(
    column: $table.windowStartMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowEndMin => $composableBuilder(
    column: $table.windowEndMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chosenTimeMin => $composableBuilder(
    column: $table.chosenTimeMin,
    builder: (column) => column,
  );

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $MedicationsTable,
          Medication,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (
            Medication,
            BaseReferences<_$SmritiDatabase, $MedicationsTable, Medication>,
          ),
          Medication,
          PrefetchHooks Function()
        > {
  $$MedicationsTableTableManager(_$SmritiDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dose = const Value.absent(),
                Value<String?> pillPhotoPath = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                Value<int> windowStartMin = const Value.absent(),
                Value<int> windowEndMin = const Value.absent(),
                Value<int> chosenTimeMin = const Value.absent(),
                Value<String> daysOfWeek = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                dose: dose,
                pillPhotoPath: pillPhotoPath,
                voicePath: voicePath,
                windowStartMin: windowStartMin,
                windowEndMin: windowEndMin,
                chosenTimeMin: chosenTimeMin,
                daysOfWeek: daysOfWeek,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String dose,
                Value<String?> pillPhotoPath = const Value.absent(),
                Value<String?> voicePath = const Value.absent(),
                required int windowStartMin,
                required int windowEndMin,
                required int chosenTimeMin,
                required String daysOfWeek,
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                dose: dose,
                pillPhotoPath: pillPhotoPath,
                voicePath: voicePath,
                windowStartMin: windowStartMin,
                windowEndMin: windowEndMin,
                chosenTimeMin: chosenTimeMin,
                daysOfWeek: daysOfWeek,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $MedicationsTable,
      Medication,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (
        Medication,
        BaseReferences<_$SmritiDatabase, $MedicationsTable, Medication>,
      ),
      Medication,
      PrefetchHooks Function()
    >;
typedef $$RoutineItemsTableCreateCompanionBuilder =
    RoutineItemsCompanion Function({
      required String id,
      required int timeMin,
      required String labelKey,
      required String iconAsset,
      Value<int> rowid,
    });
typedef $$RoutineItemsTableUpdateCompanionBuilder =
    RoutineItemsCompanion Function({
      Value<String> id,
      Value<int> timeMin,
      Value<String> labelKey,
      Value<String> iconAsset,
      Value<int> rowid,
    });

class $$RoutineItemsTableFilterComposer
    extends Composer<_$SmritiDatabase, $RoutineItemsTable> {
  $$RoutineItemsTableFilterComposer({
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

  ColumnFilters<int> get timeMin => $composableBuilder(
    column: $table.timeMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labelKey => $composableBuilder(
    column: $table.labelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RoutineItemsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $RoutineItemsTable> {
  $$RoutineItemsTableOrderingComposer({
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

  ColumnOrderings<int> get timeMin => $composableBuilder(
    column: $table.timeMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labelKey => $composableBuilder(
    column: $table.labelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconAsset => $composableBuilder(
    column: $table.iconAsset,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RoutineItemsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $RoutineItemsTable> {
  $$RoutineItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeMin =>
      $composableBuilder(column: $table.timeMin, builder: (column) => column);

  GeneratedColumn<String> get labelKey =>
      $composableBuilder(column: $table.labelKey, builder: (column) => column);

  GeneratedColumn<String> get iconAsset =>
      $composableBuilder(column: $table.iconAsset, builder: (column) => column);
}

class $$RoutineItemsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $RoutineItemsTable,
          RoutineItem,
          $$RoutineItemsTableFilterComposer,
          $$RoutineItemsTableOrderingComposer,
          $$RoutineItemsTableAnnotationComposer,
          $$RoutineItemsTableCreateCompanionBuilder,
          $$RoutineItemsTableUpdateCompanionBuilder,
          (
            RoutineItem,
            BaseReferences<_$SmritiDatabase, $RoutineItemsTable, RoutineItem>,
          ),
          RoutineItem,
          PrefetchHooks Function()
        > {
  $$RoutineItemsTableTableManager(_$SmritiDatabase db, $RoutineItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoutineItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoutineItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoutineItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> timeMin = const Value.absent(),
                Value<String> labelKey = const Value.absent(),
                Value<String> iconAsset = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoutineItemsCompanion(
                id: id,
                timeMin: timeMin,
                labelKey: labelKey,
                iconAsset: iconAsset,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int timeMin,
                required String labelKey,
                required String iconAsset,
                Value<int> rowid = const Value.absent(),
              }) => RoutineItemsCompanion.insert(
                id: id,
                timeMin: timeMin,
                labelKey: labelKey,
                iconAsset: iconAsset,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RoutineItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $RoutineItemsTable,
      RoutineItem,
      $$RoutineItemsTableFilterComposer,
      $$RoutineItemsTableOrderingComposer,
      $$RoutineItemsTableAnnotationComposer,
      $$RoutineItemsTableCreateCompanionBuilder,
      $$RoutineItemsTableUpdateCompanionBuilder,
      (
        RoutineItem,
        BaseReferences<_$SmritiDatabase, $RoutineItemsTable, RoutineItem>,
      ),
      RoutineItem,
      PrefetchHooks Function()
    >;
typedef $$AppConfigsTableCreateCompanionBuilder =
    AppConfigsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppConfigsTableUpdateCompanionBuilder =
    AppConfigsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppConfigsTableFilterComposer
    extends Composer<_$SmritiDatabase, $AppConfigsTable> {
  $$AppConfigsTableFilterComposer({
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

class $$AppConfigsTableOrderingComposer
    extends Composer<_$SmritiDatabase, $AppConfigsTable> {
  $$AppConfigsTableOrderingComposer({
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

class $$AppConfigsTableAnnotationComposer
    extends Composer<_$SmritiDatabase, $AppConfigsTable> {
  $$AppConfigsTableAnnotationComposer({
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

class $$AppConfigsTableTableManager
    extends
        RootTableManager<
          _$SmritiDatabase,
          $AppConfigsTable,
          AppConfig,
          $$AppConfigsTableFilterComposer,
          $$AppConfigsTableOrderingComposer,
          $$AppConfigsTableAnnotationComposer,
          $$AppConfigsTableCreateCompanionBuilder,
          $$AppConfigsTableUpdateCompanionBuilder,
          (
            AppConfig,
            BaseReferences<_$SmritiDatabase, $AppConfigsTable, AppConfig>,
          ),
          AppConfig,
          PrefetchHooks Function()
        > {
  $$AppConfigsTableTableManager(_$SmritiDatabase db, $AppConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppConfigsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppConfigsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$SmritiDatabase,
      $AppConfigsTable,
      AppConfig,
      $$AppConfigsTableFilterComposer,
      $$AppConfigsTableOrderingComposer,
      $$AppConfigsTableAnnotationComposer,
      $$AppConfigsTableCreateCompanionBuilder,
      $$AppConfigsTableUpdateCompanionBuilder,
      (
        AppConfig,
        BaseReferences<_$SmritiDatabase, $AppConfigsTable, AppConfig>,
      ),
      AppConfig,
      PrefetchHooks Function()
    >;

class $SmritiDatabaseManager {
  final _$SmritiDatabase _db;
  $SmritiDatabaseManager(this._db);
  $$TrialEventsTableTableManager get trialEvents =>
      $$TrialEventsTableTableManager(_db, _db.trialEvents);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$ReminderEventsTableTableManager get reminderEvents =>
      $$ReminderEventsTableTableManager(_db, _db.reminderEvents);
  $$VoiceMemosTableTableManager get voiceMemos =>
      $$VoiceMemosTableTableManager(_db, _db.voiceMemos);
  $$EscalationRequestsTableTableManager get escalationRequests =>
      $$EscalationRequestsTableTableManager(_db, _db.escalationRequests);
  $$AbilityStatesTableTableManager get abilityStates =>
      $$AbilityStatesTableTableManager(_db, _db.abilityStates);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$RoutineItemsTableTableManager get routineItems =>
      $$RoutineItemsTableTableManager(_db, _db.routineItems);
  $$AppConfigsTableTableManager get appConfigs =>
      $$AppConfigsTableTableManager(_db, _db.appConfigs);
}
