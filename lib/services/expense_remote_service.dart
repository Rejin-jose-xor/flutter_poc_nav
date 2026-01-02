import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart' show Expense;

class ExpenseRemoteService {
  static const _baseUrl =
      'flutter-expenses-2d46b-default-rtdb.firebaseio.com';

  // CREATE
  static Future<void> createExpense(Expense expense) async {
    final url = Uri.https(_baseUrl, '/expenses/${expense.id}.json');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(expense.toMap()),
    );
    print("inside api call of add expense");
    if (response.statusCode >= 400) {
      throw Exception('Create failed');
    }
  }

  // DELETE
  static Future<void> deleteExpense(String id) async {
    final url = Uri.https(_baseUrl, '/expenses/$id.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      throw Exception('Delete failed');
    }
  }

  // UPDATE (replace)
  static Future<void> updateExpense(Expense expense) async {
    final url = Uri.https(_baseUrl, '/expenses/${expense.id}.json');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(expense.toMap()),
    );

    if (response.statusCode >= 400) {
      throw Exception('Update failed');
    }
  }

  // CLEAR
  static Future<void> clearAll() async {
    final url = Uri.https(_baseUrl, '/expenses.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      throw Exception('Clear failed');
    }
  }

  static Future<List<Expense>> fetchExpensesPage({
    int? endAt, // cursor
    required int pageSize,
  }) async {
    final params = <String, String>{
      'orderBy': '"enteredAt"',
      'limitToLast': pageSize.toString(),
    };

    if (endAt != null) {
      params['endAt'] = endAt.toString();
    }

    final url = Uri.https(
      _baseUrl,
      '/expenses.json',
      params,
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Fetch failed');
    }

    if (response.body == 'null') {
      return [];
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    // expenses will give the values from old to new [600,700,800]
    final expenses = data.values
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // Sort newest → oldest  [800,700,600]
    expenses.sort((a, b) => b.enteredAt.compareTo(a.enteredAt));

    return expenses;
  }

}
