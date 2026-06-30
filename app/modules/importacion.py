from db import exec_import, fetch, print_table, input_str, ok, err


def menu():
    opciones = {
        "1": ("Importar parques desde KML",  _importar_kml),
        "2": ("Importar visitas desde CSV",   _importar_csv),
        "3": ("Ver log de importaciones",     _ver_log),
        "0": ("Volver",                       None),
    }
    while True:
        print("\n--- IMPORTACIÓN ---")
        for k, (label, _) in opciones.items():
            print(f"  {k}. {label}")
        op = input("Opción: ").strip()
        if op == "0":
            break
        if op in opciones and opciones[op][1]:
            opciones[op][1]()


def _importar_kml():
    print("  El archivo KML debe ser accesible desde el servidor SQL.")
    print("  No incluir comillas en la ruta.")
    ruta = input_str("Ruta del archivo en el servidor (ej. C:\\datos\\parques.kml): ")
    ruta = ruta.strip('"').strip("'")
    print("  Procesando, aguardá...")
    success, msg = exec_import("EXEC importacion.ImportarParquesKML @ruta_archivo=?", (ruta,))
    if not success:
        err(msg)
        return
    _mostrar_resultado_import('SIB_KML')


def _importar_csv():
    print("  El archivo CSV debe ser accesible desde el servidor SQL.")
    print("  No incluir comillas en la ruta.")
    ruta = input_str("Ruta del archivo en el servidor (ej. C:\\datos\\visitas.csv): ")
    ruta = ruta.strip('"').strip("'")
    print("  Procesando, aguardá...")
    success, msg = exec_import("EXEC importacion.ImportarVisitasCSV @ruta_archivo=?", (ruta,))
    if not success:
        err(msg)
        return
    _mostrar_resultado_import('YVERA_VISITAS')


def _mostrar_resultado_import(tipo):
    """Lee el último registro del log para ese tipo y reporta éxito o error."""
    cols, rows = fetch(
        "SELECT TOP 1 detalle, errores, registros_ok "
        "FROM importacion.LogImportacion "
        "WHERE tipo_archivo = ? "
        "ORDER BY id_log DESC",
        (tipo,)
    )
    if not rows:
        err("No se encontró registro en el log.")
        return
    detalle, errores, registros_ok = rows[0]
    if detalle and detalle.startswith('Error'):
        err(detalle)
    elif detalle == 'En proceso':
        err("El proceso no finalizó correctamente.")
    else:
        ok(f"Completado — {detalle}")
    _ver_log()


def _ver_log():
    cols, rows = fetch("""
        SELECT TOP 20 id_log, tipo_archivo, nombre_archivo, fecha,
                      registros_ok, errores, detalle
        FROM   importacion.LogImportacion
        ORDER  BY id_log DESC
    """)
    print_table(cols, rows)
