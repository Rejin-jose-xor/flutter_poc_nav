import 'package:uuid/uuid.dart' show Uuid;
import '../constants/common.dart' show Category;

var uuid = const Uuid();

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;
  final String description;
  final DateTime enteredAt;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    DateTime? enteredAt,
  })  : id = id ?? uuid.v4(),
        enteredAt = enteredAt ?? DateTime.now();

  /// copyWith → create updated immutable copy (preserving ID)
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    String? description,
    DateTime? enteredAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      enteredAt: enteredAt ?? this.enteredAt,
    );
  }

  // ——————————————————————————————————————————
  //  Category serialization helpers
  // ——————————————————————————————————————————
  static String categoryToString(Category c) => c.name;

  static Category categoryFromString(String s) {
    return Category.values.firstWhere(
      (e) => e.name == s,
      orElse: () => Category.food,
    );
  }

  // ——————————————————————————————————————————
  //  Map / JSON helpers
  // ——————————————————————————————————————————
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': categoryToString(category),
      'description': description,
      // ✅ serialize as int
      'enteredAt': enteredAt.millisecondsSinceEpoch,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      category: categoryFromString(map['category'] as String? ?? ''),
      description: map['description'] as String? ?? '',
      // ✅ restore to DateTime
      enteredAt: DateTime.fromMillisecondsSinceEpoch(
        map['enteredAt'] as int,
      ),
    );
  }

  // ——————————————————————————————————————————
  //  Equality & hashing
  // ——————————————————————————————————————————
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Expense &&
            other.id == id &&
            other.title == title &&
            other.amount == amount &&
            other.date == date &&
            other.category == category &&
            other.description == description &&
            other.enteredAt == enteredAt);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      category.hashCode ^
      description.hashCode ^
      enteredAt.hashCode;

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, date: $date, category: $category, description: $description, enteredAt: $enteredAt)';
  }
}
