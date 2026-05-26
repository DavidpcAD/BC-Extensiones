# Verificar qué pasó con el Assembly Order

## 1. Ver Assembly Orders creados (sin postear)
En BC, busca: **Assembly Orders** (página 902)
- Filtra por fecha de hoy (23/1/2026)
- Busca los números de pedido que retornó el API
- Estado: ¿Released o Posted?

## 2. Ver Posted Assembly Orders (ya posteados)
En BC, busca: **Posted Assembly Orders** (página 922)
- Filtra por fecha de hoy (23/1/2026)
- Deberías ver el documento BS000057 o similar

## 3. Ver Item Ledger Entries (movimientos de inventario)
En BC, busca: **Item Ledger Entries** (página 38)
- Filtra:
  - Item No: M09-0166 (CUBO TECA)
  - Location: VN-B.27
  - Posting Date: 23/1/2026
  - Entry Type: Assembly Output
- Deberías ver +1 M3 de CUBO TECA

## 4. Ver el consumo de materiales
En BC, busca: **Item Ledger Entries** (página 38)
- Filtra:
  - Item No: M09-0033 (MADERA TECA TROZA)
  - Location: F-MADERAS
  - Posting Date: 23/1/2026
  - Lot No: 339064
  - Entry Type: Assembly Consumption
- Deberías ver -0.1 M3 de consumo

## 5. Revisar errores en BC
Si no ves nada, el posting falló. Revisa:
- Menú: **System** → **Session Events** o **Error Messages**
- Busca errores relacionados con Assembly Post

---

## Problema probable:

El Assembly Order **se creó** pero **NO se posteó** por una de estas razones:

### ❌ Falta de permisos
El usuario de la API no tiene permisos para postear Assembly Orders.

### ❌ Tracking no asignado correctamente
El lote 339064 no se asignó correctamente a las líneas, y BC requiere tracking para postear.

### ❌ Error silencioso capturado
El TryFunction capturó el error y lo reportó como "success: true" incorrectamente.

---

## Solución rápida:

Busca en BC el Assembly Order que se creó y verifica su estado. Si existe pero no está posteado, intenta postearlo manualmente para ver el error real que está ocurriendo.
