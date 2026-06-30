"""
Script standalone de importación. Usar main.py opción 5 como alternativa.
"""
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

import db
from modules.importacion import menu


def main():
    print("Conectando con usuario de importación...")
    try:
        db.get_connection('importador')
        print("Conexión OK.\n")
    except Exception as e:
        print(f"Error al conectar: {e}")
        print("Revisá config.ini sección [importador].")
        sys.exit(1)
    menu()


if __name__ == "__main__":
    main()
