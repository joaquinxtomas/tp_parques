from db import exec_sp, fetch, print_table, input_int, input_str, ok, err


def menu():
    opciones = {
        "1": ("Ver atracciones",              _ver_atracciones),
        "2": ("Alta atracción",               _atraccion_nueva),
        "3": ("Modificar atracción",          _atraccion_modificar),
        "4": ("Dar de baja atracción",        _atraccion_eliminar),
        "5": ("Registrar ticket actividad",   _ticket_nuevo),
        "6": ("Cancelar ticket actividad",    _ticket_cancelar),
        "7": ("Ver tours / guías asignados",  _ver_tours),
        "8": ("Asignar guía a atracción",     _tour_nuevo),
        "9": ("Eliminar asignación de guía",  _tour_eliminar),
        "0": ("Volver",                       None),
    }
    while True:
        print("\n--- ACTIVIDADES ---")
        for k, (label, _) in opciones.items():
            print(f"  {k}. {label}")
        op = input("Opción: ").strip()
        if op == "0":
            break
        if op in opciones and opciones[op][1]:
            opciones[op][1]()


# ── Atracciones ────────────────────────────────────────────────────────────────

def _ver_atracciones():
    cols, rows = fetch("""
        SELECT a.id_atraccion, p.nombre AS parque, a.nombre, a.tipo,
               a.costo, a.duracion, a.cupo_maximo, a.estado
        FROM   actividades.Atraccion a
        JOIN   parques.Parque        p ON p.id_parque = a.id_parque
        ORDER  BY a.id_atraccion
    """)
    print_table(cols, rows)


def _atraccion_nueva():
    _ver_parques()
    id_p  = input_int("ID parque: ")
    nombre = input_str("Nombre: ")
    print("  Tipos: paga / gratuita")
    tipo  = input_str("Tipo: ")
    costo = float(input("Costo: ").strip())
    dur   = input("Duración en minutos (vacío=sin límite): ").strip()
    cupo  = input("Cupo máximo (vacío=sin límite): ").strip()
    turno = input_str("Horario del turno (HH:MM): ")
    success, msg = exec_sp(
        "EXEC actividades.InsertarAtraccion @id_parque=?, @nombre=?, @costo=?, @duracion=?, @cupo_maximo=?, @tipo=?, @turno=?",
        (id_p, nombre, costo, int(dur) if dur else None, int(cupo) if cupo else None, tipo, turno)
    )
    ok("Atracción creada.") if success else err(msg)


def _atraccion_modificar():
    _ver_atracciones()
    id_a   = input_int("ID atracción a modificar: ")
    nombre = input_str("Nuevo nombre: ")
    print("  Tipos: paga / gratuita")
    tipo   = input_str("Tipo: ")
    costo  = float(input("Nuevo costo: ").strip())
    dur    = input("Nueva duración en minutos (vacío=sin límite): ").strip()
    cupo   = input("Nuevo cupo máximo (vacío=sin límite): ").strip()
    success, msg = exec_sp(
        "EXEC actividades.ActualizarAtraccion @id_atraccion=?, @nombre=?, @costo=?, @duracion=?, @cupo_maximo=?, @tipo=?",
        (id_a, nombre, costo, int(dur) if dur else None, int(cupo) if cupo else None, tipo)
    )
    ok("Atracción modificada.") if success else err(msg)


def _atraccion_eliminar():
    _ver_atracciones()
    id_a = input_int("ID atracción a dar de baja: ")
    success, msg = exec_sp("EXEC actividades.EliminarAtraccion @id_atraccion=?", (id_a,))
    ok("Atracción dada de baja.") if success else err(msg)


# ── Tickets de actividad ───────────────────────────────────────────────────────

def _ticket_nuevo():
    _ver_atracciones()
    id_a   = input_int("ID atracción: ")
    cant   = input_int("Cantidad de visitantes: ")
    fecha  = input_str("Fecha de la actividad (YYYY-MM-DD): ")
    success, msg = exec_sp(
        "EXEC actividades.RegistrarTicketActividad @id_atraccion=?, @cantidad=?, @fecha_actividad=?",
        (id_a, cant, fecha)
    )
    ok("Ticket registrado.") if success else err(msg)


def _ticket_cancelar():
    cols, rows = fetch("""
        SELECT id_ticket_atraccion, id_atraccion, fecha, cantidad, subtotal, estado
        FROM   actividades.TicketsAtraccion
        WHERE  estado = 0
        ORDER  BY id_ticket_atraccion
    """)
    print_table(cols, rows)
    id_t = input_int("ID ticket a cancelar: ")
    success, msg = exec_sp("EXEC actividades.CancelarTicketActividad @id_ticketAtraccion=?", (id_t,))
    ok("Ticket cancelado.") if success else err(msg)


# ── Tours / asignación de guías ────────────────────────────────────────────────

def _ver_tours():
    cols, rows = fetch("""
        SELECT tg.id_tour_guia, g.nombre AS guia, a.nombre AS atraccion, tg.estado
        FROM   actividades.TourGuia    tg
        JOIN   personal.GuiaAutorizado g ON g.id_guia      = tg.id_guia
        JOIN   actividades.Atraccion   a ON a.id_atraccion = tg.id_atraccion
        ORDER  BY tg.id_tour_guia
    """)
    print_table(cols, rows)


def _tour_nuevo():
    _ver_guias()
    id_g = input_int("ID guía: ")
    _ver_atracciones()
    id_a = input_int("ID atracción: ")
    success, msg = exec_sp(
        "EXEC actividades.InsertarTourGuia @id_guia=?, @id_atraccion=?",
        (id_g, id_a)
    )
    ok("Guía asignado a atracción.") if success else err(msg)


def _tour_eliminar():
    _ver_tours()
    id_tg = input_int("ID asignación a eliminar: ")
    success, msg = exec_sp("EXEC actividades.EliminarTourGuia @id_tour_guia=?", (id_tg,))
    ok("Asignación eliminada.") if success else err(msg)


# ── helpers ────────────────────────────────────────────────────────────────────

def _ver_parques():
    cols, rows = fetch("SELECT id_parque, nombre FROM parques.Parque WHERE estado = 0 ORDER BY id_parque")
    print_table(cols, rows)


def _ver_guias():
    cols, rows = fetch("SELECT id_guia, nombre, especialidad FROM personal.GuiaAutorizado WHERE estado = 0 ORDER BY id_guia")
    print_table(cols, rows)
