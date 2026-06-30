import requests
import datetime

_feriados_cache = {}   # year (int) -> set of date strings 'YYYY-MM-DD'


def is_feriado(date: datetime.date) -> bool:
    """
    Devuelve True si la fecha es feriado o puente en Argentina.
    Cachea la lista del año para no repetir la request en la misma sesión.
    Si la API falla, asume que NO es feriado (no aplica recargo por error).
    """
    year = date.year
    if year not in _feriados_cache:
        try:
            r = requests.get(
                f"https://api.argentinadatos.com/v1/feriados/{year}",
                timeout=5
            )
            r.raise_for_status()
            _feriados_cache[year] = {f["fecha"] for f in r.json()}
        except Exception as e:
            print(f"  AVISO: no se pudo consultar feriados ({e}). Recargo no aplicado.")
            _feriados_cache[year] = set()
    return date.isoformat() in _feriados_cache[year]


def get_dolar_oficial_venta() -> float | None:
    """
    Devuelve el precio de venta del dólar oficial (BNA).
    Retorna None si la API no responde.
    """
    try:
        r = requests.get("https://dolarapi.com/v1/dolares/oficial", timeout=5)
        r.raise_for_status()
        return float(r.json()["venta"])
    except Exception:
        return None
