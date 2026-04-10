class Usuario {
    int id;
    String nomUsuario;
    String email;
    String tipoUsuario;
    String estado;

    Usuario({
        required this.id,
        required this.nomUsuario,
        required this.email,
        required this.tipoUsuario,
        required this.estado,
    });

    factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json["id"],
        nomUsuario: json["nom_usuario"],
        email: json["email"],
        tipoUsuario: json["tipo_usuario"],
        estado: json["estado"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nom_usuario": nomUsuario,
        "email": email,
        "tipo_usuario": tipoUsuario,
        "estado": estado,
    };
}
