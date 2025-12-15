import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile_model.dart' show Profile;

class ProfileNotifier extends Notifier<Profile?> {
  static const String _boxName = 'expensesBox';
  static const String _key = 'profile';

  Box get _box => Hive.box(_boxName);

  @override
  Profile? build() {
    final stored = _box.get(_key);
    if (stored == null) return null;

    return Profile.fromMap(Map<String, dynamic>.from(stored));
  }

  // Save or update profile
  void saveProfile(Profile profile) {
    _box.put(_key, profile.toMap());
    state = profile;
  }

  // Update fields individually
  void updateProfile({
    String? name,
    String? email,
    String? avatarPath,
  }) {
    if (state == null) return;

    final updated = state!.copyWith(
      name: name,
      email: email,
      avatarPath: avatarPath,
    );

    saveProfile(updated);
  }

  // Clear profile
  void clearProfile() {
    _box.delete(_key);
    state = null;
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);
