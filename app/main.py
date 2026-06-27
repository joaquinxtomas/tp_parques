import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

import db
from modules import ventas, concesiones, actividades, personal


def main():
    print("Conectando a ParquesNacionales...")
    try:
        db.get_connection()
        print("Conexión OK.\n")
    except Exception as e:
        print(f"Error al conectar: {e}")
        print("Revisá config.ini (servidor, usuario y contraseña).")
        sys.exit(1)

    opciones = {
        "1": ("Ventas",        ventas.menu),
        "2": ("Concesiones",   concesiones.menu),
        "3": ("Actividades",   actividades.menu),
        "4": ("Personal",      personal.menu),
        "0": ("Salir",         None),
    }

    while True:
        print("\n============================")
        print("   PARQUES NACIONALES - ABM  ")
        print("============================")
        for k, (label, _) in opciones.items():
            print(f"  {k}. {label}")
        op = input("Opción: ").strip()
        if op == "0":
            print("Hasta luego.")
            break
        if op in opciones and opciones[op][1]:
            opciones[op][1]()
        else:
            print("  Opción inválida.")


if __name__ == "__main__":
    main()
