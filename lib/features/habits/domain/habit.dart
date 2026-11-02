class Habit {
  final int? id;
  final String name;
  final String? description;
  final String iconKey;
  final int colorValue;
  final String startDate; // dateKey
  final bool isArchived;
  final int sortOrder;
  final String? remindTime; // "HH:mm";null 代表不提醒

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
  });

  Habit copyWith({
    String? name,
    String? description,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    String? remindTime,
    bool clearRemindTime = false,
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
      );
}
