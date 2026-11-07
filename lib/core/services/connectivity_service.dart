import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// True when the device has any network interface. Firestore handles the
/// actual retry; this only drives the Arabic sync banner.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final c = ref.watch(connectivityProvider);
  bool online(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);
  try {
    yield online(await c.checkConnectivity());
  } catch (_) {
    yield true;
  }
  yield* c.onConnectivityChanged.map(online);
});
