import sys
import os
import configparser
import pyodbc

sys.path.insert(0, os.path.dirname(__file__))


def get_connection():
    cfg = configparser.ConfigParser()
    cfg.read(os.path.join(os.path.dirname(__file__), 'config-imp.ini'))
    db = cfg['database']
    conn_str = (
        f"DRIVER={{{db['driver']}}};"
        f"SERVER={db['server']};"
        f"DATABASE={db['database']};"
        "UID=parques_impor;"
        "PWD=Importacion#Parques2026!;"
        "TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str, autocommit=False)


def ver_log(cursor):
    cursor.execute("""
        SELECT TOP 10 id_log, tipo_archivo, fecha_proceso,
                      leidos, insertados, actualizados, errores
        FROM   importacion.LogImportacion
        ORDER  BY id_log DESC
    """)
    cols = [c[0] for c in cursor.description]
    rows = cursor.fetchall()
    if not rows:
        print("  (sin registros en el log)")
        return
    widths = [max(len(str(c)), max((len(str(r[i])) for r in rows), default=0)) for i, c in enumerate(cols)]
    fmt = "  " + "  ".join(f"{{:<{w}}}" for w in widths)
    print(fmt.format(*cols))
    print("  " + "  ".join("-" * w for w in widths))
    for row in rows:
        print(fmt.format(*[str(v) if v is not None else "NULL" for v in row]))


def importar_kml(conn):
    print("  El archivo KML debe ser accesible desde el servidor SQL.")
    ruta = input("  Ruta del archivo (ej. C:\\datos\\parques.kml): ").strip()
    cursor = conn.cursor()
    try:
        cursor.execute("EXEC importacion.ImportarParquesKML @ruta_archivo=?", (ruta,))
        conn.commit()
        print("  OK: Importación KML completada.")
        ver_log(cursor)
    except pyodbc.Error as e:
        conn.rollback()
        msg = str(e)
        if '[SQL Server]' in msg:
            msg = msg.split('[SQL Server]')[-1].split('(')[0].strip()
        print(f"  ERROR: {msg}")


def importar_csv(conn):
    print("  El archivo CSV debe ser accesible desde el servidor SQL.")
    ruta = input("  Ruta del archivo (ej. C:\\datos\\visitas.csv): ").strip()
    cursor = conn.cursor()
    try:
        cursor.execute("EXEC importacion.ImportarVisitasCSV @ruta_archivo=?", (ruta,))
        conn.commit()
        print("  OK: Importación CSV completada.")
        ver_log(cursor)
    except pyodbc.Error as e:
        conn.rollback()
        msg = str(e)
        if '[SQL Server]' in msg:
            msg = msg.split('[SQL Server]')[-1].split('(')[0].strip()
        print(f"  ERROR: {msg}")


def main():
    print("Conectando con usuario de importación...")
    try:
        conn = get_connection()
        print("Conexión OK.\n")
    except pyodbc.Error as e:
        print(f"Error al conectar: {e}")
        sys.exit(1)

    while True:
        print("\n============================")
        print("   PARQUES NACIONALES - IMPORTACIÓN")
        print("============================")
        print("  1. Importar parques desde KML")
        print("  2. Importar visitas desde CSV")
        print("  3. Ver log de importaciones")
        print("  0. Salir")
        op = input("Opción: ").strip()
        if op == "0":
            print("Hasta luego.")
            break
        elif op == "1":
            importar_kml(conn)
        elif op == "2":
            importar_csv(conn)
        elif op == "3":
            ver_log(conn.cursor())
        else:
            print("  Opción inválida.")


if __name__ == "__main__":
    main()
