class Habit {
  /// 每天都做的遮罩(週一到週日全選)
  static const int allDays = 127;

  /// 每日次數上限
  static const int maxDailyTarget = 20;

  final int? id;
  final String name;
  final String? description;
  final String iconKey;
  final int colorValue;
  final String startDate; // dateKey
  final bool isArchived;
  final int sortOrder;
  final String? remindTime; // "HH:mm";null 代表不提醒
  final int weekdays; // 位元遮罩:bit0=週一 … bit6=週日
  final int dailyTarget; // 每天要做幾次,1 代表點一下就完成

  const Habit({
    this.id,
    required this.name,
    this.description,
    this.iconKey = 'book',
    this.colorValue = 0xFF4CAF50,
    required this.startDate,
    this.isArchived = false,
    this.sortOrder = 0,
    this.remindTime,
    this.weekdays = allDays,
    this.dailyTarget = 1,
  });

  /// [weekday] 使用 DateTime.weekday:週一=1 … 週日=7
  bool runsOn(int weekday) => (weekdays & (1 << (weekday - 1))) != 0;

  /// 是否每天都做
  bool get isEveryDay => (weekdays & allDays) == allDays;

  /// 是否需要一天做多次
  bool get isMulti => dailyTarget > 1;

  Habit copyWith({
    String? name,
    String? description,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    String? remindTime,
    bool clearRemindTime = false,
    int? weekdays,
    int? dailyTarget,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        startDate: startDate,
        isArchived: isArchived,
        sortOrder: sortOrder ?? this.sortOrder,
        remindTime: clearRemindTime ? null : (remindTime ?? this.remindTime),
        weekdays: weekdays ?? this.weekdays,
        dailyTarget: dailyTarget ?? this.dailyTarget,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'icon_key': iconKey,
        'color_value': colorValue,
        'start_date': startDate,
        'is_archived': isArchived ? 1 : 0,
        'sort_order': sortOrder,
        'remind_time': remindTime,
        'weekdays': weekdays,
        'daily_target': dailyTarget,
      };

  factory Habit.fromMap(Map<String, Object?> map) => Habit(
        id: map['id'] as int?,
        name: map['name'] as String,
        description: map['description'] as String?,
        iconKey: map['icon_key'] as String,
        colorValue: map['color_value'] as int,
        startDate: map['start_date'] as String,
        isArchived: (map['is_archived'] as int) == 1,
        sortOrder: map['sort_order'] as int,
        remindTime: map['remind_time'] as String?,
        weekdays: (map['weekdays'] as int?) ?? allDays,
        dailyTarget: (map['daily_target'] as int?) ?? 1,
      );
}
