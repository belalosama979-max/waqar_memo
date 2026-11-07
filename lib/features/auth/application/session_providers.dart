import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/app_user.dart';

/// Raw Firebase auth state.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in user's profile (null when signed out or profile missing).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.value;
  if (user == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchProfile(user.uid);
});

/// Convenience: the profile, throwing if not signed in. Use only below auth guard.
final requireUserProvider = Provider<AppUser>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) throw StateError('No signed-in user');
  return user;
});
