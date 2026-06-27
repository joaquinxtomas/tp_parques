from db import exec_sp, fetch, print_table, input_int, input_str, ok, err


def menu():
    opciones = {
        "1": ("Ver empresas",                _ver_empresas),
        "2": ("Alta empresa",                _empresa_nueva),
        "3": ("Modificar empresa",           _empresa_modificar),
        "4": ("Dar de baja empresa",         _empresa_eliminar),
        "5": ("Ver concesiones",             _ver_concesiones),
        "6": ("Alta concesión",              _concesion_nueva),
        "7": ("Modificar concesión",         _concesion_modificar),
        "8": ("Dar de baja concesión",       _concesion_eliminar),
        "9": ("Ver pagos",                   _ver_pagos),
        "10":("Registrar pago",              _pago_nuevo),
        "11":("Modificar pago",              _pago_modificar),
        "12":("Dar de baja pago",            _pago_eliminar),
        "0": ("Volver",                      None),
    }
    while True:
        print("\n--- CONCESIONES ---")
        for k, (label, _) in opciones.items():
            print(f"  {k}. {label}")
        op = input("Opción: ").strip()
        if op == "0":
            break
        if op in opciones and opciones[op][1]:
            opciones[op][1]()


# ── Empresas ───────────────────────────────────────────────────────────────────

def _ver_empresas():
    cols, rows = fetch("SELECT id_empresa, razon_social, cuit, contacto, estado FROM concesiones.Empresa ORDER BY id_empresa")
    print_table(cols, rows)


def _empresa_nueva():
    razon   = input_str("Razón social: ")
    cuit    = input_str("CUIT: ")
    contacto = input_str("Contacto: ")
    success, msg = exec_sp(
        "EXEC concesiones.Empresa_Nueva @razon_social=?, @cuit=?, @contacto=?",
        (razon, cuit, contacto)
    )
    ok("Empresa creada.") if success else err(msg)


def _empresa_modificar():
    _ver_empresas()
    id_e    = input_int("ID empresa a modificar: ")
    razon   = input_str("Nueva razón social: ")
    cuit    = input_str("Nuevo CUIT: ")
    contacto = input_str("Nuevo contacto: ")
    success, msg = exec_sp(
        "EXEC concesiones.Empresa_Modificar @id_empresa=?, @razon_social=?, @cuit=?, @contacto=?",
        (id_e, razon, cuit, contacto)
    )
    ok("Empresa modificada.") if success else err(msg)


def _empresa_eliminar():
    _ver_empresas()
    id_e = input_int("ID empresa a dar de baja: ")
    success, msg = exec_sp("EXEC concesiones.Empresa_Eliminar @id_empresa=?", (id_e,))
    ok("Empresa dada de baja.") if success else err(msg)


# ── Concesiones ────────────────────────────────────────────────────────────────

def _ver_concesiones():
    cols, rows = fetch("""
        SELECT c.id_concesion, e.razon_social, pa.nombre AS parque,
               c.tipo_actividad, c.fecha_inicio, c.fecha_fin, c.valor_alquiler, c.estado
        FROM   concesiones.Concesion c
        JOIN   concesiones.Empresa   e  ON e.id_empresa = c.id_empresa
        JOIN   parques.Parque        pa ON pa.id_parque  = c.id_parque
        ORDER  BY c.id_concesion
    """)
    print_table(cols, rows)


def _concesion_nueva():
    _ver_empresas()
    id_e  = input_int("ID empresa: ")
    _ver_parques()
    id_p  = input_int("ID parque: ")
    tipo  = input_str("Tipo de actividad: ")
    f_ini = input_str("Fecha inicio (YYYY-MM-DD): ")
    f_fin = input_str("Fecha fin    (YYYY-MM-DD, vacío=sin vencimiento): ", allow_empty=True)
    valor = float(input("Valor alquiler mensual: ").strip())
    success, msg = exec_sp(
        "EXEC concesiones.Concesion_Nueva @id_empresa=?, @id_parque=?, @tipo_actividad=?, @fecha_inicio=?, @fecha_fin=?, @valor_alquiler=?",
        (id_e, id_p, tipo, f_ini, f_fin, valor)
    )
    ok("Concesión creada.") if success else err(msg)


def _concesion_modificar():
    _ver_concesiones()
    id_c  = input_int("ID concesión a modificar: ")
    f_ini = input_str("Nueva fecha inicio (YYYY-MM-DD): ")
    f_fin = input_str("Nueva fecha fin    (YYYY-MM-DD, vacío=sin vencimiento): ", allow_empty=True)
    valor = float(input("Nuevo valor alquiler: ").strip())
    success, msg = exec_sp(
        "EXEC concesiones.Concesion_Modificar @id_concesion=?, @fecha_inicio=?, @fecha_fin=?, @valor_alquiler=?",
        (id_c, f_ini, f_fin, valor)
    )
    ok("Concesión modificada.") if success else err(msg)


def _concesion_eliminar():
    _ver_concesiones()
    id_c = input_int("ID concesión a dar de baja: ")
    success, msg = exec_sp("EXEC concesiones.Concesion_Eliminar @id_concesion=?", (id_c,))
    ok("Concesión dada de baja.") if success else err(msg)


# ── Pagos ──────────────────────────────────────────────────────────────────────

def _ver_pagos():
    cols, rows = fetch("""
        SELECT pc.id_pago, c.tipo_actividad, e.razon_social,
               pc.periodo, pc.fecha_pago, pc.monto, pc.estado
        FROM   concesiones.PagoConcesion pc
        JOIN   concesiones.Concesion     c  ON c.id_concesion = pc.id_concesion
        JOIN   concesiones.Empresa       e  ON e.id_empresa   = c.id_empresa
        ORDER  BY pc.id_pago
    """)
    print_table(cols, rows)


def _pago_nuevo():
    _ver_concesiones()
    id_c    = input_int("ID concesión: ")
    periodo = input_str("Período (YYYY-MM-DD, cualquier día del mes): ")
    f_pago  = input_str("Fecha de pago (YYYY-MM-DD): ")
    monto   = float(input("Monto: ").strip())
    success, msg = exec_sp(
        "EXEC concesiones.PagoConcesion_Nuevo @id_concesion=?, @periodo=?, @fecha_pago=?, @monto=?",
        (id_c, periodo, f_pago, monto)
    )
    ok("Pago registrado.") if success else err(msg)


def _pago_modificar():
    _ver_pagos()
    id_p   = input_int("ID pago a modificar: ")
    monto  = float(input("Nuevo monto: ").strip())
    f_pago = input_str("Nueva fecha de pago (YYYY-MM-DD): ")
    success, msg = exec_sp(
        "EXEC concesiones.PagoConcesion_Modificar @id_pago=?, @monto=?, @fecha_pago=?",
        (id_p, monto, f_pago)
    )
    ok("Pago modificado.") if success else err(msg)


def _pago_eliminar():
    _ver_pagos()
    id_p = input_int("ID pago a dar de baja: ")
    success, msg = exec_sp("EXEC concesiones.PagoConcesion_Eliminar @id_pago=?", (id_p,))
    ok("Pago dado de baja.") if success else err(msg)


# ── helpers ────────────────────────────────────────────────────────────────────

def _ver_parques():
    cols, rows = fetch("SELECT id_parque, nombre FROM parques.Parque WHERE estado = 0 ORDER BY id_parque")
    print_table(cols, rows)
