# 📦 API de Transferencias de Almacén - Documentación

## Descripción General

Este API permite transferir materiales entre almacenes u obras de forma masiva (bulk) usando el Item Reclassification Journal de Business Central.

## Arquitectura

### 📁 Archivos Creados

1. **Page 50191** - `GJW Item Transfer Singleton`
   - Tipo: API Singleton
   - Endpoint: `itemTransferBulks`
   - Función: Recibe JSON con transferencias y dispara el proceso

2. **Codeunit 50159** - `GJW Item Transfer Bulk`
   - Función: Procesa JSON, crea líneas en Item Reclass Journal y ejecuta posting
   - Método público: `ProcessTransfers(transfersJSON: Text): Text`

3. **PowerApps-ItemTransfer-Bulk.txt**
   - Código de Power Apps listo para copiar/pegar

---

## 🎯 Flujo Completo

```
Power Apps
    ↓
    | 1. Construye JSON con transferencias
    ↓
itemTransferBulks (API 50191)
    ↓
    | 2. Recibe JSON + ejecutar: true
    ↓
GJW Item Transfer Bulk (Codeunit 50159)
    ↓
    | 3. Limpia batch TRANSFEREN/GENERICO
    | 4. Crea líneas en Item Journal Line
    | 5. Valida campos
    | 6. Ejecuta Item Jnl.-Post Batch
    ↓
Business Central - Item Ledger Entry
    ↓
    | 7. Materiales transferidos
    ↓
Power Apps - Resultado "✅ X transferencias registradas"
```

---

## 📝 Formato del JSON

### Estructura Base
```json
[
  {
    "itemNo": "M01-0013",
    "locationCode": "ALM-GRAL",
    "newLocationCode": "VN-D.17",
    "quantity": 3,
    "taskNo": "001",
    "description": "Transferencia a obra VN-D.17"
  },
  {
    "itemNo": "M01-0015",
    "locationCode": "ALM-GRAL",
    "newLocationCode": "VN-B.27",
    "quantity": 5.5,
    "taskNo": "002",
    "description": "Material para tarea 002"
  }
]
```

### Campos

| Campo | Tipo | Obligatorio | Descripción | Ejemplo |
|-------|------|-------------|-------------|---------|
| `itemNo` | Code[20] | ✅ Sí | Número de producto | "M01-0013" |
| `locationCode` | Code[10] | ✅ Sí | Almacén ORIGEN | "ALM-GRAL" |
| `newLocationCode` | Code[10] | ✅ Sí | Almacén DESTINO (obra u otro) | "VN-D.17" |
| `quantity` | Decimal | ✅ Sí | Cantidad (> 0) | 3 |
| `taskNo` | Code[20] | ❌ No | Tarea de obra (si aplica) | "001" |
| `description` | Text[100] | ❌ No | Descripción del movimiento | "Transfer a obra" |
| `postingDate` | Date | ❌ No | Fecha de registro (default: hoy) | "2026-01-11" |
| `documentNo` | Code[20] | ❌ No | Número de documento (autogenerado si vacío) | "TRANS-001" |
| `variantCode` | Code[10] | ❌ No | Código de variante del producto | "AZUL" |

---

## 🚀 Ejemplo de Uso en Power Apps

### Transferencia Única
```powerapps
Patch(
    itemTransferBulks,
    First(itemTransferBulks),
    {
        transfersJSON: "[{""itemNo"":""M01-0013"",""locationCode"":""ALM-GRAL"",""newLocationCode"":""VN-D.17"",""quantity"":3}]",
        ejecutar: true
    }
)
```

### Transferencias Múltiples (Bulk)
```powerapps
// 1. Construir JSON
Set(varTransfersJSON, 
    "[" & Concat(
        colTransferencias,
        "{" &
        """itemNo"":""" & itemNo & """," &
        """locationCode"":""" & locationCode & """," &
        """newLocationCode"":""" & newLocationCode & """," &
        """quantity"":" & Text(quantity) &
        "}"
    , ",") & "]"
);

// 2. Ejecutar
Set(varResultado, 
    Patch(
        itemTransferBulks,
        First(itemTransferBulks),
        {
            transfersJSON: varTransfersJSON,
            ejecutar: true
        }
    )
);

// 3. Validar
If(
    StartsWith(varResultado.resultado, "✅"),
    Notify(varResultado.resultado, NotificationType.Success),
    Notify(varResultado.resultado, NotificationType.Error)
);
```

---

## ✅ Validaciones Automáticas

El API valida:
- `itemNo` no puede estar vacío
- `quantity` debe ser mayor a 0
- `locationCode` no puede estar vacío
- `newLocationCode` no puede estar vacío
- El producto debe existir en Business Central
- Los almacenes deben existir

**Comportamiento:**
- Si hay **algún error**, NO se registra nada (todo o nada)
- Si todas las líneas son válidas, se ejecuta el posting completo
- Retorna mensaje con resultado

---

## 📊 Mensajes de Respuesta

### Éxito
```
"✅ 5 transferencias registradas correctamente"
```

### Error en Validación
```
"3 líneas creadas, 2 errores. No se ejecutó el registro."
```

### Error en Posting
```
"ERROR al registrar: The Item No. M01-9999 does not exist."
```

---

## 🔧 Configuración Técnica

### Item Reclass. Journal
- **Template Name**: `TRANSFEREN`
- **Batch Name**: `GENERICO`
- **Entry Type**: `Transfer` (Transferencia)

### Codeunit de Posting
- `Item Jnl.-Post Batch` (Codeunit estándar de BC)

### Permisos Requeridos
- `GJW Item Transfer Singleton` (Page 50191) = X
- `GJW Item Transfer Bulk` (Codeunit 50159) = X
- `Item Journal Line` (Table 83) = RIMD

---

## 🎯 Ventajas vs Método Manual

| Aspecto | Método Manual | API Bulk |
|---------|---------------|----------|
| Transferencias | 1 por vez | Múltiples simultáneas |
| Velocidad | Lento | Rápido (1 llamada) |
| Interfaz | Business Central UI | Power Apps |
| Validación | Manual | Automática |
| Limpieza de batch | Manual | Automática |
| Transaccionalidad | No garantizada | Todo o nada |

---

## 🔗 Endpoint API

```
https://api.businesscentral.dynamics.com/v2.0/{tenant}/Production/api/adelante/construction/v1.0/itemTransferBulks
```

**Método**: PATCH  
**Body**:
```json
{
  "transfersJSON": "[{...}]",
  "ejecutar": true
}
```

---

## ⚠️ Notas Importantes

1. **Limpieza automática**: El codeunit limpia el batch `GENERICO` antes de crear las líneas
2. **Unit of Measure**: Si no se especifica, usa la unidad base del producto
3. **Document No.**: Si está vacío, Business Central lo autogenera con la serie del batch
4. **Posting Date**: Si no se envía, usa la fecha actual
5. **Task No.**: Solo se llena si la transferencia va a una obra específica
6. **Commit**: El posting hace commit automáticamente

---

## 🐛 Troubleshooting

### "ERROR: JSON inválido"
- Verifica que el JSON esté bien formado
- Usa `Text()` para números decimales
- Escapa las comillas dobles: `""`

### "ERROR: No se recibió JSON de transferencias"
- El campo `transfersJSON` está vacío
- Verifica que la variable en Power Apps tenga datos

### "ERROR al registrar: ..."
- Business Central retorna el error específico
- Puede ser: producto no existe, almacén no existe, cantidad insuficiente, etc.

---

## 📞 Soporte

Para dudas o problemas con este API, contacta al equipo de desarrollo.

Versión: 1.0  
Fecha: 11 de enero de 2026
