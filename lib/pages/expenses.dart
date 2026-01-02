import 'package:flutter/material.dart';
import '../sections/expenses_list.dart' show ExpensesSliverList;  
import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerState, ConsumerStatefulWidget, ProviderSubscription, AsyncValue;
import '../provider/expense_provider.dart' show expensesProvider;
import '../provider/internet_status_provider.dart' show internetStatusProvider, InternetStatus;
import '../sections/expenses_paging_header.dart' show ExpensesPagingHeader;

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  late final ProviderSubscription _internetSub;

  @override
  void initState() {
    super.initState();

    // Initial load
    Future.microtask(() {
      ref.read(expensesProvider.notifier).loadFirstPage();
    });

    // Internet listener (REAL internet)
    _internetSub = ref.listenManual<AsyncValue<InternetStatus>>(
      internetStatusProvider,
      (prev, next) async {
        final prevStatus = prev?.value;
        final nextStatus = next.value;

        if (prevStatus == nextStatus || nextStatus == null) return;

        final messenger = ScaffoldMessenger.of(context);
        final notifier = ref.read(expensesProvider.notifier);

        if (nextStatus == InternetStatus.offline) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text("You're offline. Changes will sync later."),
            ),
          );
          notifier.resetLocalPaging();
          await notifier.loadFirstPage();
        }

        if (nextStatus == InternetStatus.online) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Back online. Syncing..."),
            ),
          );

          notifier.resetLocalPaging();
          await notifier.syncPendingOps();
          await notifier.loadFirstPage();
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _internetSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            ExpensesPagingHeader(),
            ExpensesSliverList(),
          ],
        ),
      ),
    );
  }
}