import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

import db
from modules import ventas, concesiones, actividades, personal, importacion


def main():
    print("Conectando a ParquesNacionales...")
    errores = []
    for role in ('operador', 'consultas', 'importador'):
        try:
            db.get_connection(role)
        except Exception as e:
            errores.append(f"  [{role}] {e}")
    if errores:
        print("Error al conectar:")
        for e in errores:
            print(e)
        print("Revisá config.ini (usuario y contraseña de cada rol).")
        sys.exit(1)
    print("Conexiones OK.\n")

    opciones = {
        "1": ("Ventas",        ventas.menu),
        "2": ("Concesiones",   concesiones.menu),
        "3": ("Actividades",   actividades.menu),
        "4": ("Personal",      personal.menu),
        "5": ("Importación",   importacion.menu),
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
