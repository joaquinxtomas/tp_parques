import pyodbc
import configparser
import os

_conn = None


def get_connection():
    global _conn
    if _conn is None or _conn.closed:
        cfg = configparser.ConfigParser()
        cfg.read(os.path.join(os.path.dirname(__file__), 'config.ini'))
        db = cfg['database']
        conn_str = (
            f"DRIVER={{{db['driver']}}};"
            f"SERVER={db['server']};"
            f"DATABASE={db['database']};"
            f"UID={db['uid']};"
            f"PWD={db['pwd']};"
            "TrustServerCertificate=yes;"
        )
        _conn = pyodbc.connect(conn_str, autocommit=False)
    return _conn


def exec_sp(sql, params=()):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params)
        conn.commit()
        return True, None
    except pyodbc.Error as e:
        try:
            conn.rollback()
        except Exception:
            pass
        msg = str(e)
        if '[SQL Server]' in msg:
            msg = msg.split('[SQL Server]')[-1].strip()
            msg = msg.split('(')[0].strip()
        return False, msg


def fetch(sql, params=()):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute(sql, params)
    cols = [col[0] for col in cursor.description]
    rows = cursor.fetchall()
    return cols, rows


def print_table(cols, rows):
    if not rows:
        print("  (sin resultados)")
        return
    widths = [max(len(str(c)), max((len(str(r[i])) for r in rows), default=0)) for i, c in enumerate(cols)]
    fmt = "  " + "  ".join(f"{{:<{w}}}" for w in widths)
    sep = "  " + "  ".join("-" * w for w in widths)
    print(fmt.format(*cols))
    print(sep)
    for row in rows:
        print(fmt.format(*[str(v) if v is not None else "NULL" for v in row]))


def input_int(prompt, allow_empty=False):
    while True:
        val = input(prompt).strip()
        if allow_empty and val == "":
            return None
        try:
            return int(val)
        except ValueError:
            print("  Ingrese un número entero.")


def input_str(prompt, allow_empty=False):
    while True:
        val = input(prompt).strip()
        if val == "" and not allow_empty:
            print("  El campo no puede estar vacío.")
            continue
        return val if val != "" else None


def ok(msg):
    print(f"  OK: {msg}")


def err(msg):
    print(f"  ERROR: {msg}")
