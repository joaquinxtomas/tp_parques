import datetime
import math
import api
from db import exec_sp, fetch, print_table, input_int, input_float, input_str, ok, err


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
    dolar = api.get_dolar_oficial_venta()
    if dolar is not None:
        print(f"  Dólar oficial (venta): ${dolar:.2f}")
        cols = list(cols) + ['precio_USD']
        rows = [
            list(row) + [f"~USD {math.ceil(row[3] / dolar)}" if row[2] == 'No residente' else '-']
            for row in rows
        ]
    print_table(cols, rows)


def _precio_nuevo_normal():
    _ver_parques()
    id_p   = input_int("ID parque: ")
    _ver_tipos()
    id_tv  = input_int("ID tipo de visitante: ")
    precio = input_float("Precio: ")
    f_ini  = input_str("Fecha de inicio de vigencia (YYYY-MM-DD): ")
    success, msg = exec_sp(
        "EXEC ventas.PrecioEntrada_Nuevo_Normal @id_parque=?, @id_tipo_visitante=?, @precio=?, @fecha_inicio=?",
        (id_p, id_tv, precio, f_ini)
    )
    ok("Precio creado.") if success else err(msg)


def _precio_nuevo_temporada():
    _ver_parques()
    id_p   = input_int("ID parque: ")
    _ver_tipos()
    id_tv  = input_int("ID tipo de visitante: ")
    precio = input_float("Precio: ")
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
    precio = input_float("Nuevo precio: ")
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
    id_p      = input_int("ID parque: ")
    pto_venta = input_int("Punto de venta: ")
    fecha     = input_str("Fecha y hora (YYYY-MM-DD HH:MM:SS): ")

    recargo = 0
    try:
        if api.is_feriado(datetime.date.fromisoformat(fecha[:10])):
            print("  AVISO: feriado — se aplica recargo del 20% (redondeo para arriba).")
            recargo = 1
    except Exception:
        pass

    print("  Formas de pago: Efectivo / Débito / Crédito / Transferencia / QR")
    forma_pago = input_str("Forma de pago: ")

    _ver_tipos()
    id_tipo_1  = input_int("ID tipo visitante 1: ")
    cantidad_1 = input_int("Cantidad tipo 1: ")

    sql    = ("EXEC ventas.Entrada_Nuevo "
              "@id_parque=?, @pto_venta=?, @fecha=?, @forma_pago=?, "
              "@id_tipo_1=?, @cantidad_1=?, @recargo_feriado=?")
    params = [id_p, pto_venta, fecha, forma_pago, id_tipo_1, cantidad_1, recargo]
    tipos_sel = [(id_tipo_1, cantidad_1)]

    for n in range(2, 6):
        if input(f"  ¿Agregar tipo visitante {n}? (s/n): ").strip().lower() != "s":
            break
        id_t = input_int(f"ID tipo visitante {n}: ")
        cant = input_int(f"Cantidad tipo {n}: ")
        sql    += f", @id_tipo_{n}=?, @cantidad_{n}=?"
        params += [id_t, cant]
        tipos_sel.append((id_t, cant))

    success, msg = exec_sp(sql, tuple(params))
    if success:
        ok("Entrada registrada.")
        _mostrar_usd_no_residente(id_p, fecha[:10], tipos_sel, recargo)
    else:
        err(msg)


def _ticket_eliminar():
    cols, rows = fetch("""
        SELECT e.id_entrada, p.nombre AS parque, e.fecha, e.forma_pago, e.total, e.estado
        FROM   ventas.Entrada e
        JOIN   parques.Parque p ON p.id_parque = e.id_parque
        WHERE  e.estado = 0
        ORDER  BY e.id_entrada
    """)
    print_table(cols, rows)
    id_t = input_int("ID entrada a cancelar: ")
    success, msg = exec_sp("EXEC ventas.Ticket_Eliminar @id_ticket=?", (id_t,))
    ok("Entrada cancelada.") if success else err(msg)


# ── helpers ────────────────────────────────────────────────────────────────────

def _ver_parques():
    cols, rows = fetch("SELECT id_parque, nombre FROM parques.Parque WHERE estado = 0 ORDER BY id_parque")
    print_table(cols, rows)


def _mostrar_usd_no_residente(id_p, fecha_str, tipos_sel, recargo):
    """Muestra el equivalente en USD para entradas de tipo 'No residente'."""
    dolar = api.get_dolar_oficial_venta()
    if dolar is None:
        print("  AVISO: no se pudo obtener cotización del dólar oficial.")
        return

    ids = [t[0] for t in tipos_sel]
    placeholders = ','.join('?' * len(ids))
    cols, rows = fetch(
        f"""SELECT tv.id_tipo_visitante, pe.precio
            FROM   ventas.TipoVisitante tv
            JOIN   ventas.PrecioEntrada pe
                ON pe.id_tipo_visitante = tv.id_tipo_visitante
               AND pe.id_parque    = ?
               AND pe.fecha_inicio <= ?
               AND (pe.fecha_fin IS NULL OR pe.fecha_fin >= ?)
               AND pe.estado = 0
            WHERE  tv.id_tipo_visitante IN ({placeholders})
              AND  tv.descripcion = 'No residente'""",
        (id_p, fecha_str, fecha_str) + tuple(ids)
    )
    if not rows:
        return

    for row in rows:
        id_tipo      = row[0]
        precio_ars   = float(row[1])
        if recargo:
            precio_ars = math.ceil(precio_ars * 1.2)
        cant         = next((c for tid, c in tipos_sel if tid == id_tipo), 1)
        precio_usd   = math.ceil(precio_ars / dolar)
        print(f"  No residente: ${precio_ars:.0f} ARS/persona = "
              f"USD {precio_usd}/persona × {cant} = USD {precio_usd * cant} "
              f"(oficial ${dolar:.2f})")
