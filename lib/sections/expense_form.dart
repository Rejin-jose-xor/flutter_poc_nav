import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../constants/common.dart' show Category;
import '../models/expense_model.dart' show Expense;


class ExpenseForm extends StatefulWidget {
  /// initialExpense: optional. If provided, form is prefilled and when saved
  /// we preserve the original id using copyWith.
  final Expense? initialExpense;
  final void Function(Expense) onSaved;
  final VoidCallback? onCancelled;

  const ExpenseForm({
    super.key,
    this.initialExpense,
    required this.onSaved,
    this.onCancelled,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descController;

  DateTime? selectedDate;
  Category? selectedCategory;

  final _formKey = GlobalKey<FormState>();
  Expense? _originalExpense;

  @override
  void initState() {
    super.initState();
     _originalExpense = widget.initialExpense;
    _titleController = TextEditingController(text: _originalExpense?.title ?? '');
    _amountController = TextEditingController(text: _originalExpense != null ? _originalExpense!.amount.toStringAsFixed(2) : '');
    _descController = TextEditingController(text: _originalExpense?.description ?? '');
    selectedDate = _originalExpense?.date;
    selectedCategory = _originalExpense?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null || selectedCategory == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Missing fields'),
          content: const Text('Please select a date and a category.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    final updated = _originalExpense?.copyWith(
          title: title,
          amount: amount,
          date: selectedDate,
          category: selectedCategory,
          description: desc,
        ) ??
        Expense(
          title: title,
          amount: amount,
          date: selectedDate!,
          category: selectedCategory!,
          description: desc,
        );

    widget.onSaved(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in SingleChildScrollView so small screens & keyboard are fine
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(label: Text('Title')),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),

              // Description (textarea)
              TextFormField(
                controller: _descController,
                minLines: 3,
                maxLines: 7,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: UnderlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Please enter a description' : null,
              ),

              const SizedBox(height: 8),

              // Amount + Date Row
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _amountController,
                      maxLength: 12,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(label: Text('Amount'), prefixText: '₹ '),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Enter amount';
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) return 'Invalid amount';
                        return null;
                      },
                    ),
                  ),
                  const Spacer(),
                  Text(
                    selectedDate == null ? 'Select a date' : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                  IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_sharp)),
                ],
              ),

              const SizedBox(height: 8),

              // Category dropdown
              DropdownButtonFormField<Category>(
                initialValue: selectedCategory,
                hint: const Text('Select Category'),
                isExpanded: true,
                items: Category.values
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat.name.toUpperCase())))
                    .toList(),
                onChanged: (value) => setState(() => selectedCategory = value),
                validator: (value) => value == null ? 'Select a category' : null,
              ),

              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _save, child: const Text('Save Expense')),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: widget.onCancelled ?? () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
