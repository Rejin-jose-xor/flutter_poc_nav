import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InternetStatus { online, offline }

final internetStatusProvider =
    StreamProvider<InternetStatus>((ref) async* {
  final connectivity = Connectivity();

  Future<InternetStatus> checkInternet() async {
    try {
      // DNS check (fast + reliable)
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return InternetStatus.online;
      }
    } catch (_) {}

    return InternetStatus.offline;
  }

  //  Emit initial status immediately
  yield await checkInternet();

  //  Re-check whenever connectivity changes
  await for (final _ in connectivity.onConnectivityChanged) {
    yield await checkInternet();
  }
});

final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(internetStatusProvider).value;
  return status == InternetStatus.online;
});
