class Account {
  final String id;
  final String name;
  final String email;
  final String username;
  final String password;
  final String notes;

  const Account({
    required this.id,
    required this.name,
    this.email = '',
    this.username = '',
    required this.password,
    this.notes = '',
  });

  /// Creates a new Account with a generated ID.
  factory Account.create({
    required String name,
    String email = '',
    String username = '',
    required String password,
    String notes = '',
  }) =>
      Account(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        email: email,
        username: username,
        password: password,
        notes: notes,
      );

  Account copyWith({
    String? name,
    String? email,
    String? username,
    String? password,
    String? notes,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        username: username ?? this.username,
        password: password ?? this.password,
        notes: notes ?? this.notes,
      );

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String? ?? '',
        username: json['username'] as String? ?? '',
        password: json['password'] as String,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'password': password,
        'notes': notes,
      };
}
