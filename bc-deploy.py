#!/usr/bin/env python3
"""Publica un .app (PTE) a un entorno de Business Central vía la Automation API.

Uso:
  python3 bc-deploy.py <Sandbox|Production> <ruta-al-.app>

Credenciales: lee BC_TENANT_ID / BC_CLIENT_ID / BC_CLIENT_SECRET del archivo
  ~/Desktop/adelante/business-central/digitacion-web/.env.local
(el S2S ya registrado en el tenant). No imprime ningún secreto.

Flujo (Microsoft, "Extension Upload" de la Automation API v2.0):
  1. token client_credentials para https://api.businesscentral.dynamics.com/.default
  2. GET  companies                        -> id de ADELANTE_DESARROLLOS_NUEVA
  3. POST companies(id)/extensionUpload    -> registro de subida (schemaSyncMode=Add)
  4. PATCH .../extensionUpload(uid)/content  (binario del .app)
  5. POST .../extensionUpload(uid)/Microsoft.NAV.upload
  6. poll extensionDeploymentStatus hasta Completed/Failed
  7. verifica en .../extensions que la versión quede instalada
"""
import json
import sys
import time
import urllib.request
import urllib.error
import urllib.parse
from pathlib import Path

ENV_FILE = Path.home() / "Desktop/adelante/business-central/digitacion-web/.env.local"
COMPANY_NAME = "ADELANTE_DESARROLLOS_NUEVA"
APP_NAME = "AdelanteAPI"


def die(msg):
    print(f"ERROR: {msg}")
    sys.exit(1)


def load_env():
    vals = {}
    for line in ENV_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, _, v = line.partition("=")
        vals[k.strip()] = v.strip().strip('"').strip("'")
    missing = [k for k in ("BC_TENANT_ID", "BC_CLIENT_ID", "BC_CLIENT_SECRET") if not vals.get(k)]
    if missing:
        die(f"faltan {missing} en {ENV_FILE}")
    return vals


def http(method, url, token=None, body=None, ctype=None, extra=None):
    req = urllib.request.Request(url, data=body, method=method)
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    if ctype:
        req.add_header("Content-Type", ctype)
    for k, v in (extra or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            raw = r.read()
            return r.status, json.loads(raw) if raw and raw.strip().startswith(b"{") else raw
    except urllib.error.HTTPError as e:
        raw = e.read().decode(errors="replace")
        return e.code, raw


def get_token(env):
    data = urllib.parse.urlencode({
        "grant_type": "client_credentials",
        "client_id": env["BC_CLIENT_ID"],
        "client_secret": env["BC_CLIENT_SECRET"],
        "scope": "https://api.businesscentral.dynamics.com/.default",
    }).encode()
    status, resp = http("POST", f"https://login.microsoftonline.com/{env['BC_TENANT_ID']}/oauth2/v2.0/token",
                        body=data, ctype="application/x-www-form-urlencoded")
    if status != 200 or "access_token" not in resp:
        die(f"token AAD falló (HTTP {status}): {str(resp)[:300]}")
    return resp["access_token"]


def main():
    if len(sys.argv) != 3:
        die("uso: bc-deploy.py <Sandbox|Production> <ruta .app>")
    environment, app_path = sys.argv[1], Path(sys.argv[2])
    if not app_path.is_file():
        die(f"no existe {app_path}")
    env = load_env()
    token = get_token(env)
    base = (f"https://api.businesscentral.dynamics.com/v2.0/"
            f"{env['BC_TENANT_ID']}/{environment}/api/microsoft/automation/v2.0")

    status, resp = http("GET", f"{base}/companies", token)
    if status != 200:
        die(f"GET companies {environment} -> HTTP {status}: {str(resp)[:400]}")
    comps = {c["name"]: c["id"] for c in resp["value"]}
    cid = comps.get(COMPANY_NAME) or (list(comps.values())[0] if comps else None)
    if not cid:
        die(f"sin compañías visibles en {environment}")
    print(f"[{environment}] compañía {COMPANY_NAME}: {cid}")

    croot = f"{base}/companies({cid})"
    status, resp = http("POST", f"{croot}/extensionUpload", token,
                        body=json.dumps({"schemaSyncMode": "Add"}).encode(), ctype="application/json")
    if status not in (200, 201):
        die(f"POST extensionUpload -> HTTP {status}: {str(resp)[:400]}")
    uid = resp["systemId"]
    print(f"[{environment}] extensionUpload creado: {uid}")

    status, resp = http("PATCH", f"{croot}/extensionUpload({uid})/extensionContent", token,
                        body=app_path.read_bytes(), ctype="application/octet-stream",
                        extra={"If-Match": "*"})
    if status not in (200, 204):
        die(f"PATCH content -> HTTP {status}: {str(resp)[:400]}")
    print(f"[{environment}] contenido subido ({app_path.stat().st_size} bytes)")

    status, resp = http("POST", f"{croot}/extensionUpload({uid})/Microsoft.NAV.upload", token,
                        body=b"{}", ctype="application/json")
    if status not in (200, 204):
        # algunos entornos disparan el deploy solo con el PATCH; seguir y mirar el status
        print(f"[{environment}] NAV.upload -> HTTP {status} (sigo y reviso el estado): {str(resp)[:200]}")
    else:
        print(f"[{environment}] deployment agendado")

    deadline = time.time() + 600
    final = None
    while time.time() < deadline:
        time.sleep(10)
        status, resp = http("GET",
                            f"{croot}/extensionDeploymentStatus?$orderby=startedOn desc&$top=5", token)
        if status != 200:
            print(f"[{environment}] status HTTP {status}, reintento...")
            continue
        rows = [r for r in resp["value"] if r.get("name") == APP_NAME]
        if not rows:
            continue
        cur = rows[0]
        print(f"[{environment}] {cur.get('name')} {cur.get('appVersion')} -> {cur.get('status')}")
        if cur.get("status") in ("Completed", "Failed"):
            final = cur
            break
    if not final:
        die(f"timeout esperando el deployment en {environment}")
    if final["status"] != "Completed":
        die(f"deployment FAILED en {environment}: revisar Extension Management > Deployment Status")

    status, resp = http("GET", f"{croot}/extensions?$filter=displayName eq '{APP_NAME}'", token)
    if status == 200 and resp.get("value"):
        e = resp["value"][0]
        ver = f"{e['versionMajor']}.{e['versionMinor']}.{e['versionBuild']}.{e['versionRevision']}"
        print(f"[{environment}] instalado: {e['displayName']} v{ver} (isInstalled={e['isInstalled']})")
    print(f"[{environment}] OK")


if __name__ == "__main__":
    main()
