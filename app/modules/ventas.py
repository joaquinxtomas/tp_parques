from db import exec_sp, fetch, print_table, input_int, input_str, ok, err


def menu():
    opciones = {
        "1": ("Ver tipos de visitante",         _ver_tipos),
        "2": ("Alta tipo de visitante",          _tipo_nuevo),
        "3": ("Modificar tipo de visitante",     _tipo_modificar),
        "4": ("Dar de baja tipo de visitante",   _tipo_eliminar),
        "5": ("Ver precios de entrada vigentes", _ver_precios),
        "6": ("Alta precio normal",              _precio_nuevo_normal),
        "7": ("Alta precio temporada",           _precio_nuevo_temporada),
        "8": ("Modificar precio",                _precio_modificar),
        "9": ("Dar de baja precio",              _precio_eliminar),
        "10":("Registrar entrada (venta)",       _entrada_nuevo),
        "11":("Cancelar ticket",                 _ticket_eliminar),
        "0": ("Volver",                          None),
    }
    while True:
        print("\n--- VENTAS ---")
        for k, (label, _) in opciones.items():
            print(f"  {k}. {label}")
        op = input("Opción: ").strip()
        if op == "0":
            break
        if op in opciones and opciones[op][1]:
            opciones[op][1]()


# ── Tipos de visitante ─────────────────────────────────────────────────────────

def _ver_tipos():
    cols, rows = fetch("SELECT id_tipo_visitante, descripcion, estado FROM ventas.TipoVisitante ORDER BY id_tipo_visitante")
    print_table(cols, rows)


def _tipo_nuevo():
    desc = input_str("Descripción: ")
    success, msg = exec_sp("EXEC ventas.TipoVisitante_Nuevo @descripcion=?", (desc,))
    ok("Tipo creado.") if success else err(msg)


def _tipo_modificar():
    _ver_tipos()
    id_tv = input_int("ID tipo a modificar: ")
    desc  = input_str("Nueva descripción: ")
    success, msg = exec_sp("EXEC ventas.TipoVisitante_Modificar @id_tipo_visitante=?, @descripcion=?", (id_tv, desc))
    ok("Tipo modificado.") if success else err(msg)


def _tipo_eliminar():
    _ver_tipos()
    id_tv = input_int("ID tipo a dar de baja: ")
    success, msg = exec_sp("EXEC ventas.TipoVisitante_Eliminar @id_tipo_visitante=?", (id_tv,))
    ok("Tipo dado de baja.") if success else err(msg)


# ── Precios de entrada ─────────────────────────────────────────────────────────

def _ver_precios():
    cols, rows = fetch("""
        SELECT pe.id_precio, pa.nombre AS parque, tv.descripcion AS tipo,
               pe.precio, pe.fecha_inicio, pe.fecha_fin, pe.estado
        FROM   ventas.PrecioEntrada pe
        JOIN   parques.Parque       pa ON pa.id_parque          = pe.id_parque
        JOIN   ventas.TipoVisitante tv ON tv.id_tipo_visitante  = pe.id_tipo_visitante
        ORDER  BY pe.id_precio
    """)
    print_table(cols, rows)


def _precio_nuevo_normal():
    _ver_parques()
    id_p  = input_int("ID parque: ")
    _ver_tipos()
    id_tv = input_int("ID tipo de visitante: ")
    precio = float(input("Precio: ").strip())
    success, msg = exec_sp(
        "EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque=?, @id_tipo_visitante=?, @precio=?",
        (id_p, id_tv, precio)
    )
    ok("Precio creado.") if success else err(msg)


def _precio_nuevo_temporada():
    _ver_parques()
    id_p   = input_int("ID parque: ")
    _ver_tipos()
    id_tv  = input_int("ID tipo de visitante: ")
    precio = float(input("Precio: ").strip())
    f_ini  = input_str("Fecha inicio (YYYY-MM-DD): ")
    f_fin  = input_str("Fecha fin    (YYYY-MM-DD): ")
    success, msg = exec_sp(
        "EXEC ventas.PrecioEntrada_Nuevo_Temporada @id_parque=?, @id_tipo_visitante=?, @precio=?, @fecha_inicio=?, @fecha_fin=?",
        (id_p, id_tv, precio, f_ini, f_fin)
    )
    ok("Precio temporada creado.") if success else err(msg)


def _precio_modificar():
    _ver_precios()
    id_pr  = input_int("ID precio a modificar: ")
    precio = float(input("Nuevo precio: ").strip())
    success, msg = exec_sp(
        "EXEC ventas.PrecioEntrada_Modificar_Precio @id_precio=?, @precio=?",
        (id_pr, precio)
    )
    ok("Precio modificado.") if success else err(msg)


def _precio_eliminar():
    _ver_precios()
    id_pr = input_int("ID precio a dar de baja: ")
    success, msg = exec_sp("EXEC ventas.PrecioEntrada_Eliminar @id_precio=?", (id_pr,))
    ok("Precio dado de baja.") if success else err(msg)


# ── Entradas / Tickets ─────────────────────────────────────────────────────────

def _entrada_nuevo():
    _ver_parques()
    id_p       = input_int("ID parque: ")
    pto_venta  = input_int("Punto de venta: ")
    fecha      = input_str("Fecha y hora (YYYY-MM-DD HH:MM:SS): ")
    print("  Formas de pago: Efectivo / Débito / Crédito / Transferencia / QR")
    forma_pago = input_str("Forma de pago: ")

    _ver_tipos()
    id_tipo_1   = input_int("ID tipo visitante 1: ")
    cantidad_1  = input_int("Cantidad tipo 1: ")

    params = [id_p, pto_venta, fecha, forma_pago, id_tipo_1, cantidad_1]
    sql    = "EXEC ventas.Entrada_Nuevo @id_parque=?, @pto_venta=?, @fecha=?, @forma_pago=?, @id_tipo_1=?, @cantidad_1=?"

    agregar = input("  ¿Agregar otro tipo de visitante? (s/n): ").strip().lower()
    if agregar == "s":
        id_tipo_2  = input_int("ID tipo visitante 2: ")
        cantidad_2 = input_int("Cantidad tipo 2: ")
        sql    += ", @id_tipo_2=?, @cantidad_2=?"
        params += [id_tipo_2, cantidad_2]

    success, msg = exec_sp(sql, tuple(params))
    ok("Entrada registrada.") if success else err(msg)


def _ticket_eliminar():
    cols, rows = fetch("""
        SELECT t.id_ticket, e.id_entrada, e.fecha, t.id_tipo_visitante, t.cantidad, t.subtotal, t.estado
        FROM   ventas.Ticket      t
        JOIN   ventas.Entrada     e ON e.id_entrada = t.id_entrada
        WHERE  t.estado = 0
        ORDER  BY t.id_ticket
    """)
    print_table(cols, rows)
    id_t = input_int("ID ticket a cancelar: ")
    success, msg = exec_sp("EXEC ventas.Ticket_Eliminar @id_ticket=?", (id_t,))
    ok("Ticket cancelado.") if success else err(msg)


# ── helpers ────────────────────────────────────────────────────────────────────

def _ver_parques():
    cols, rows = fetch("SELECT id_parque, nombre FROM parques.Parque WHERE estado = 0 ORDER BY id_parque")
    print_table(cols, rows)
