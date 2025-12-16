import 'package:flutter_poc_nav/models/expense_model.dart' show Expense;
import 'package:flutter_poc_nav/models/profile_model.dart' show Profile;
import 'package:flutter_poc_nav/provider/profile_provider.dart' show ProfileNotifier;
import 'package:flutter_poc_nav/provider/expense_provider.dart' show ExpensesNotifier;

class FakeProfileNotifier extends ProfileNotifier  {
  @override
  Profile? build() {
    return null;
  }
}

class FakeExpensesNotifier extends ExpensesNotifier {
  @override
  List<Expense> build() {
    return <Expense>[];
  }
}
