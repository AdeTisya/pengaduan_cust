// lib/models/user.dart

class User {
  final int id;
  final String nama;
  final String email;
  final String telepon;
  final String? fotoProfil;
  final Role role;
  final Instansi? instansi; 
  final String status;

  User({
    required this.id,
    required this.nama,
    required this.email,
    required this.telepon,
    this.fotoProfil,
    required this.role,
    this.instansi,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id:         json['id'] as int,
      nama:       json['nama'] as String,
      email:      json['email'] as String,
      telepon:    json['telepon'] as String,
      fotoProfil: json['foto_profil'] as String?,
      role:       Role.fromJson(json['role'] as Map<String, dynamic>),
      instansi:   json['instansi'] != null
                    ? Instansi.fromJson(json['instansi'] as Map<String, dynamic>)
                    : null,
      status:     json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'nama':       nama,
    'email':      email,
    'telepon':    telepon,
    'foto_profil':fotoProfil,
    'role':       role.toJson(),
    'instansi':   instansi?.toJson(),
    'status':     status,
  };
}

class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id:   json['id'] as int,
    name: json['name'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Instansi {
  final int id;
  final String namaInstansi;

  Instansi({required this.id, required this.namaInstansi});

  factory Instansi.fromJson(Map<String, dynamic> json) => Instansi(
    id:           json['id'] as int,
    namaInstansi: json['nama_instansi'] as String,
  );

  Map<String, dynamic> toJson() => {'id': id, 'nama_instansi': namaInstansi};
}