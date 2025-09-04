class Rol {
  final int idRol;
  final String nombre;
  final String codigo;
  final int nivel;

  Rol({
    required this.idRol,
    required this.nombre,
    required this.codigo,
    required this.nivel,
  });

  factory Rol.fromJson(Map<String, dynamic> j) => Rol(
    idRol: (j['id_rol'] ?? j['ID_ROL'] ?? j['idRol']) as int,
    nombre: (j['nombre'] ?? j['ROL'] ?? j['rolNombre']) as String,
    codigo: (j['codigo'] ?? j['CODIGO_ROL'] ?? j['codigoRol']) as String,
    nivel: (j['nivel'] ?? j['NIVEL'] ?? j['nivelRol']) as int,
  );
}

class AuthUser {
  final int? idUsuarioAdmin;
  final String usuario;
  final bool? activo;
  final bool? requiereCambioContrasena;
  final Rol rol;

  AuthUser({
    this.idUsuarioAdmin,
    required this.usuario,
    this.activo,
    this.requiereCambioContrasena,
    required this.rol,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    idUsuarioAdmin: (j['id_usuario_admin'] ?? j['ID_USUARIO_ADMIN']) as int?,
    usuario: (j['usuario'] ?? j['USUARIO']) as String,
    activo: (j['activo'] as bool?) ?? (j['ACTIVO'] as bool?),
    requiereCambioContrasena:
        (j['requiere_cambio_contrasena'] as bool?) ??
        (j['REQUIERE_CAMBIO_CONTRASENA'] as bool?),
    rol: Rol.fromJson((j['rol'] ?? {}) as Map<String, dynamic>),
  );
}

class AuthSession {
  final String token;
  final bool requiereCambioContrasena;
  final AuthUser user;

  AuthSession({
    required this.token,
    required this.requiereCambioContrasena,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
    token: j['token'] as String,
    requiereCambioContrasena:
        (j['requiere_cambio_contrasena'] as bool?) ?? false,
    user: AuthUser(
      usuario: j['usuario'] as String,
      rol: Rol.fromJson(j['rol'] as Map<String, dynamic>),
    ),
  );
}
