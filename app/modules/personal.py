from db import exec_sp, fetch, print_table, input_int, input_str, ok, err


def menu():
    opciones = {
        "1": ("Ver guías autorizados",        _ver_guias),
        "2": ("Alta guía autorizado",         _guia_nuevo),
        "3": ("Ver guardaparques",            _ver_guardaparques),
        "4": ("Ver asignaciones",             _ver_asignaciones),
        "5": ("Alta asignación GP",           _asignacion_nueva),
        "0": ("Volver",                       None),
    }
    while True:
        print("\n--- PERSONAL ---")
        for k, (label, _) in opciones.items():
            print(f"  {k}. {label}")
        op = input("Opción: ").strip()
        if op == "0":
            break
        if op in opciones and opciones[op][1]:
            opciones[op][1]()


# ── Guías autorizados ──────────────────────────────────────────────────────────

def _ver_guias():
    cols, rows = fetch("""
        SELECT id_guia, nombre, dni, especialidad, titulo, vigencia_desde, vigencia_hasta, activo
        FROM   personal.GuiaAutorizado
        ORDER  BY id_guia
    """)
    print_table(cols, rows)


def _guia_nuevo():
    nombre      = input_str("Nombre: ")
    dni         = input_str("DNI: ")
    especialidad = input_str("Especialidad (vacío=ninguna): ", allow_empty=True)
    titulo      = input_str("Título (vacío=ninguno): ", allow_empty=True)
    v_desde     = input_str("Vigencia desde (YYYY-MM-DD): ")
    v_hasta     = input_str("Vigencia hasta (YYYY-MM-DD, vacío=indefinida): ", allow_empty=True)
    success, msg = exec_sp(
        "EXEC personal.guiaAutorizado_alta @nombre=?, @dni=?, @especialidad=?, @titulo=?, @vigencia_desde=?, @vigencia_hasta=?",
        (nombre, dni, especialidad, titulo, v_desde, v_hasta)
    )
    ok("Guía creado.") if success else err(msg)


# ── Guardaparques ──────────────────────────────────────────────────────────────

def _ver_guardaparques():
    cols, rows = fetch("""
        SELECT id_guardaparque, nombre, dni, vigencia_desde, vigencia_hasta, activo
        FROM   personal.Guardaparque
        ORDER  BY id_guardaparque
    """)
    print_table(cols, rows)


# ── Asignaciones ───────────────────────────────────────────────────────────────

def _ver_asignaciones():
    cols, rows = fetch("""
        SELECT a.id_asignacion, gp.nombre AS guardaparque, p.nombre AS parque,
               g.nombre AS guia, a.fecha_desde, a.fecha_hasta, a.motivo
        FROM   personal.AsignacionGP       a
        JOIN   parques.Parque              p  ON p.id_parque         = a.id_parque
        LEFT   JOIN personal.Guardaparque  gp ON gp.id_guardaparque  = a.id_guardaparque
        LEFT   JOIN personal.GuiaAutorizado g  ON g.id_guia          = a.id_guia
        ORDER  BY a.id_asignacion
    """)
    print_table(cols, rows)


def _asignacion_nueva():
    _ver_guardaparques()
    id_gp  = input_int("ID guardaparque (0=ninguno): ")
    _ver_parques()
    id_p   = input_int("ID parque: ")
    _ver_guias()
    id_g   = input("ID guía (vacío=ninguno): ").strip()
    f_ini  = input_str("Fecha desde (YYYY-MM-DD): ")
    f_fin  = input_str("Fecha hasta (YYYY-MM-DD, vacío=indefinida): ", allow_empty=True)
    motivo = input_str("Motivo: ")
    success, msg = exec_sp(
        "EXEC personal.asignacionGP_alta @id_guardaparque=?, @id_parque=?, @id_guia=?, @fecha_desde=?, @fecha_hasta=?, @motivo=?",
        (id_gp if id_gp != 0 else None, id_p, int(id_g) if id_g else None, f_ini, f_fin, motivo)
    )
    ok("Asignación creada.") if success else err(msg)


# ── helpers ────────────────────────────────────────────────────────────────────

def _ver_parques():
    cols, rows = fetch("SELECT id_parque, nombre FROM parques.Parque WHERE estado = 0 ORDER BY id_parque")
    print_table(cols, rows)


def _ver_guias():
    cols, rows = fetch("SELECT id_guia, nombre FROM personal.GuiaAutorizado WHERE activo = 1 ORDER BY id_guia")
    print_table(cols, rows)
