import 'dart:convert';

class User {
  final String id;
  final String nom;
  final String prenom;
  final String username;
  final String email;
  final String? photo; // Optionnel

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.username,
    required this.email,
    this.photo,
  });

  // ✨ Convertir JSON en User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      photo: json['photo'],
    );
  }

  // ✨ Convertir User en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'username': username,
      'email': email,
      'photo': photo,
    };
  }

  // ✨ Convertir User en String (pour SharedPreferences)
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // ✨ Créer User à partir d'une String JSON
  factory User.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString);
    return User.fromJson(json);
  }

  // ✨ Obtenir le nom complet
  String get fullName => '$prenom $nom';

  @override
  String toString() => 'User(id: $id, nom: $nom, prenom: $prenom, username: $username, email: $email)';
}