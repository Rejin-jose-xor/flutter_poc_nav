class Profile {
  final String name;
  final String email;
  final String avatarPath; // local file path

  const Profile({
    required this.name,
    required this.email,
    required this.avatarPath,
  });

  Profile copyWith({
    String? name,
    String? email,
    String? avatarPath,
  }) {
    return Profile(
      name: name ?? this.name,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  // Convert to map for Hive
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'avatarPath': avatarPath,
    };
  }

  // Create model from map
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      avatarPath: map['avatarPath'] ?? '',
    );
  }

  @override
  String toString() =>
      'Profile(name: $name, email: $email, avatarPath: $avatarPath)';
}
