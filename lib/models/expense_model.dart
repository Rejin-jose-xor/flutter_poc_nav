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

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
  }) : id = id ?? uuid.v4();

   /// copyWith → create updated immutable copy (preserving ID)
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    String? description,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  // ——————————————————————————————————————————
  //  Category serialization helpers
  // ——————————————————————————————————————————
  static String categoryToString(Category c) => c.name;

  static Category categoryFromString(String s) {
    return Category.values.firstWhere(
      (e) => e.name == s,
      orElse: () => Category.food, // fallback
    );
  }

  // ——————————————————————————————————————————
  //  Map / JSON helpers (useful for persistence)
  // ——————————————————————————————————————————
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': categoryToString(category),
      'description': description,
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
    );
  }

  // ——————————————————————————————————————————
  //  Equality & hashing — value-based equality
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
            other.description == description);
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      category.hashCode ^
      description.hashCode;

  @override
  String toString() {
    return 'Expense(id: $id, title: $title, amount: $amount, date: $date, category: $category, description: $description)';
  }

}