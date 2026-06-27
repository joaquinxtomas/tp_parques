import configparser
import os
import pyodbc
from db import fetch, print_table, input_str, ok, err


def menu():
    opciones = {
        "1": ("Importar parques desde KML",       _importar_kml),
        "2": ("Importar visitas desde CSV",        _importar_csv),
        "3": ("Ver log de importaciones",          _ver_log),
        "0": ("Volver",                            None),
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
    ruta = input_str("Ruta del archivo en el servidor (ej. C:\\datos\\parques.kml): ")
    conn = _get_impor_conn()
    if conn is None:
        return
    cursor = conn.cursor()
    try:
        cursor.execute("EXEC importacion.ImportarParquesKML @ruta_archivo=?", (ruta,))
        conn.commit()
        ok("Importación KML completada.")
        _ver_log()
    except pyodbc.Error as e:
        msg = str(e)
        if '[SQL Server]' in msg:
            msg = msg.split('[SQL Server]')[-1].split('(')[0].strip()
        err(msg)


def _importar_csv():
    print("  El archivo CSV debe ser accesible desde el servidor SQL.")
    ruta = input_str("Ruta del archivo en el servidor (ej. C:\\datos\\visitas.csv): ")
    conn = _get_impor_conn()
    if conn is None:
        return
    cursor = conn.cursor()
    try:
        cursor.execute("EXEC importacion.ImportarVisitasCSV @ruta_archivo=?", (ruta,))
        conn.commit()
        ok("Importación CSV completada.")
        _ver_log()
    except pyodbc.Error as e:
        msg = str(e)
        if '[SQL Server]' in msg:
            msg = msg.split('[SQL Server]')[-1].split('(')[0].strip()
        err(msg)


def _ver_log():
    cols, rows = fetch("""
        SELECT TOP 20 id_log, tipo_archivo, fecha_proceso,
                      leidos, insertados, actualizados, errores
        FROM   importacion.LogImportacion
        ORDER  BY id_log DESC
    """)
    print_table(cols, rows)


def _get_impor_conn():
    """Conexión separada con el usuario de importación (tiene permisos sobre el schema importacion)."""
    cfg = configparser.ConfigParser()
    cfg.read(os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config.ini'))
    db = cfg['database']
    try:
        conn_str = (
            f"DRIVER={{{db['driver']}}};"
            f"SERVER={db['server']};"
            f"DATABASE={db['database']};"
            "UID=parques_impor;"
            "PWD=Importacion#Parques2026!;"
            "TrustServerCertificate=yes;"
        )
        return pyodbc.connect(conn_str, autocommit=False)
    except pyodbc.Error as e:
        err(f"No se pudo conectar con el usuario de importación: {e}")
        return None
