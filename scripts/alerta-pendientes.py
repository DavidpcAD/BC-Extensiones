#!/usr/bin/env python3
"""Vigía del importe pendiente de producción.

Busca en las líneas de obra (GomJob Works Production Line) las descuadres que
generan asientos contables de más cuando alguien le da «Registrar», porque el
report 70720583 postea EL PENDIENTE, no la cantidad.

El guard 50261 (desde AdelanteAPI 1.2.15.0) evita que se creen nuevas, pero:
  - solo actúa al insertar o modificar: lo escrito ANTES sigue sucio;
  - y el pendiente se puede inflar por otros caminos que este chequeo también mira.

Uso:
  python3 scripts/alerta-pendientes.py [Production|Sandbox] [--umbral 1000]

Sale con código 1 si encuentra algo, para poder colgarlo de una tarea programada.
Credenciales: las mismas de bc-deploy.py (no imprime ningún secreto).
"""
import importlib.util
import sys
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("bcd", RAIZ / "bc-deploy.py")
bcd = importlib.util.module_from_spec(spec)
_argv, sys.argv = sys.argv, ["bc-deploy.py"]
spec.loader.exec_module(bcd)
sys.argv = _argv

COMPANY = "ADELANTE_DESARROLLOS_NUEVA"
PAGINA = "Obra_Production_Lines"


def num(v) -> float:
    return float(v or 0)


def lineas(entorno: str, token: str, tenant: str) -> list[dict]:
    url = (f"https://api.businesscentral.dynamics.com/v2.0/{tenant}/{entorno}"
           f"/ODataV4/Company('{COMPANY}')/{PAGINA}?$top=5000")
    out: list[dict] = []
    while url:
        status, resp = bcd.http("GET", url, token)
        if status != 200:
            bcd.die(f"{entorno}: {PAGINA} -> HTTP {status}: {str(resp)[:300]}")
        out += resp.get("value", [])
        url = resp.get("@odata.nextLink")
    return out


# Cada regla: (clave, título, aplica_a, función que devuelve el desvío en colones).
# `aplica_a` = None es toda línea; "Posting" solo las de registro, porque las
# estructurales (Heading, Total, Begin-Total, End-Total) llevan importes acumulados
# de sus hijas y no cumplen las identidades de cantidad x precio.
REGLAS = [
    ("pendiente_inflado",
     "Importe pendiente ≠ Cantidad pendiente × precio  ← el que genera el asiento de más",
     None,
     lambda L: abs(num(L["Outstanding_Amount"]) - num(L["Outstanding_Quantity"]) * num(L["Unit_Amount"]))),

    ("cantidad_pendiente_desalineada",
     "Cantidad pendiente ≠ Cantidad − Registrado  ← la línea nació con la cantidad en cero",
     "Posting",
     lambda L: abs(num(L["Outstanding_Quantity"]) - (num(L["Quantity"]) - num(L["Registered_Quantity"]))) * num(L["Unit_Amount"])),

    ("pendiente_mayor_que_la_linea",
     "Importe pendiente MAYOR que el importe de la línea entera",
     "Posting",
     lambda L: max(0.0, num(L["Outstanding_Amount"]) - num(L["Line_Amount"]))),

    ("sobre_registrado",
     "Registrado MÁS que lo solicitado",
     "Posting",
     lambda L: max(0.0, num(L["Registered_Quantity"]) - num(L["Quantity"])) * num(L["Unit_Amount"])),

    ("importe_linea_descuadrado",
     "Importe de línea ≠ Cantidad × precio",
     "Posting",
     lambda L: abs(num(L["Line_Amount"]) - num(L["Quantity"]) * num(L["Unit_Amount"]))),

    ("registrado_descuadrado",
     "Importe registrado ≠ Registrado × precio",
     "Posting",
     lambda L: abs(num(L["Registered_Amount"]) - num(L["Registered_Quantity"]) * num(L["Unit_Amount"]))),
]


def revisar(entorno: str, umbral: float) -> int:
    env = bcd.load_env()
    token = bcd.get_token(env)
    filas = lineas(entorno, token, env["BC_TENANT_ID"])

    print(f"\n{'=' * 78}")
    print(f"  {entorno} · {len(filas)} líneas de producción revisadas · umbral ₡{umbral:,.0f}")
    print(f"{'=' * 78}")

    hallazgos = 0
    for clave, titulo, aplica, medir in REGLAS:
        por_obra: dict[str, list] = defaultdict(lambda: [0, 0.0])
        casos = []
        for L in filas:
            if aplica and L["Task_Type"] != aplica:
                continue
            desvio = medir(L)
            if desvio > umbral:
                por_obra[L["Works_No"]][0] += 1
                por_obra[L["Works_No"]][1] += desvio
                casos.append((desvio, L))
        if not por_obra:
            print(f"\n  ✅ {titulo}\n     sin hallazgos")
            continue
        hallazgos += 1
        total = sum(v[1] for v in por_obra.values())
        n = sum(v[0] for v in por_obra.values())
        print(f"\n  🔴 {titulo}")
        print(f"     {n} líneas en {len(por_obra)} obras · ₡{total:,.2f}")
        for obra, (cuenta, monto) in sorted(por_obra.items(), key=lambda kv: -kv[1][1])[:10]:
            print(f"       {obra:<14} {cuenta:>3} líneas   ₡{monto:>16,.2f}")
        casos.sort(key=lambda c: -c[0])
        peor = casos[0][1]
        print(f"       peor caso: {peor['Works_No']} línea {peor['Task_No']} · "
              f"Cant={num(peor['Quantity'])} Reg={num(peor['Registered_Quantity'])} "
              f"CantPend={num(peor['Outstanding_Quantity'])} "
              f"PU=₡{num(peor['Unit_Amount']):,.2f} ImpPend=₡{num(peor['Outstanding_Amount']):,.2f}")
    return hallazgos


def main() -> None:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    entornos = [args[0]] if args else ["Production", "Sandbox"]
    umbral = 1000.0
    if "--umbral" in sys.argv:
        umbral = float(sys.argv[sys.argv.index("--umbral") + 1])

    total = sum(revisar(e, umbral) for e in entornos)
    print()
    if total:
        print(f"⚠️  {total} tipo(s) de descuadre encontrados. Nadie debería registrar esas obras "
              f"hasta sanearlas: el report postea el pendiente.")
        sys.exit(1)
    print("✅ Sin descuadres por encima del umbral.")


if __name__ == "__main__":
    main()
