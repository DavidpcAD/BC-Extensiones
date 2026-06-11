# Material Operations — Flujo completo (consumo, devolución y traslado)

> Documento de referencia para entender la API `materialOperations` y su orquestador en BC.
> Cubre las 3 operaciones de material: **consumir** desde almacén general a un proyecto,
> **trasladar** material ya consumido entre proyectos, y **devolver** material de un proyecto al almacén general.

---

## 1. Visión general

Toda operación de material se modela como **una fila** en la tabla `GJW Material Operation` (50220),
expuesta vía la página API `materialOperations` (page 50220). El cliente (Power Apps / Power Automate / HTTP)
**crea la fila** con los datos de la operación y luego **dispara los pasos** poniendo en `true` unos campos
booleanos "comando" (`executeNext`, `executeUntilStop`, `retryFailed`).

La lógica vive en el codeunit `GJW Material Op Orchestrator` (50220), que implementa una **máquina de estados**.
Cada paso postea documentos reales en BC (Item Journal / Job Journal) reutilizando dos codeunits de trabajo:

- `GJW Item Transfer Bulk` (50159) → movimiento físico de inventario entre ubicaciones (Item Journal, Entry Type = Transfer).
- `GJW Material Consumption` (50186) → consumo contra el proyecto (Job Journal, Entry Type = Usage).

Cada intento de paso se audita en la tabla `GJW Material Operation Step` (un registro por intento, con éxito/error y JSON de respuesta).

---

## 2. La tabla / entidad `materialOperation`

Campos de **entrada** (los manda el cliente al crear):

| Campo API | Campo BC | Notas |
|---|---|---|
| `operationType` | `Operation Type` | `ConsumeFromGeneral` (0), `TransferConsumedBetweenJobs` (1), `ReturnConsumedToGeneral` (2) |
| `itemNo` | `Item No.` | **Obligatorio** |
| `variantCode` | `Variant Code` | Opcional |
| `quantity` | `Quantity` | **> 0 obligatorio** (siempre positivo; el signo lo pone el orquestador) |
| `sourceJobNo` | `Source Job No.` | Proyecto origen |
| `sourceJobTaskNo` | `Source Job Task No.` | Tarea origen |
| `sourceLocationCode` | `Source Location Code` | **Obligatorio** — ubicación de donde sale |
| `destinationJobNo` | `Destination Job No.` | Proyecto destino |
| `destinationJobTaskNo` | `Destination Job Task No.` | Tarea destino |
| `destinationLocationCode` | `Destination Location Code` | **Obligatorio** — ubicación a donde entra |
| `documentNo` | `Document No.` | Opcional; si va vacío se autogenera `OP-yyyyMMddHHmmss` |

Campos de **estado / salida** (los gestiona BC, son `Editable = false`):

| Campo API | Campo BC | Notas |
|---|---|---|
| `operationId` | `Operation Id` | GUID, PK. Se autogenera. |
| `status` | `Status` | `PendingReverse`, `ReverseDone`, `PhysicalDone`, `FinalConsumeDone`, `Closed`, `Failed` |
| `currentStep` | `Current Step` | `Reverse`, `Physical`, `FinalConsume`, `Close` |
| `requiresFinalConsume` | `Requires Final Consume` | Lo decide el orquestador según el tipo |
| `lastError` | `Last Error` | Mensaje del último fallo |
| `lastBCEntryNos` | `Last BC Entry Nos` | Item Ledger Entry Nos de destino generados en el paso físico (separados por coma). **Insumo del consumo final.** |
| `lastActionMessage` | `Last Action Message` | Texto del último comando ejecutado |

Campos **comando** (booleanos que el cliente pone en `true` para disparar acción — se auto-resetean a `false`):

| Campo API | Acción |
|---|---|
| `executeNext` | Ejecuta **el siguiente paso** según el `status` actual |
| `executeUntilStop` | Ejecuta pasos en cadena (máx. 5) hasta llegar a `Closed` o `Failed` |
| `retryFailed` | Reintenta el paso que quedó en `Failed` |
| `statusJson` (drilldown) | Devuelve un JSON con el estado actual |

`OnInsert` de la tabla autogenera `Operation Id`, `Document No.`, `Correlation Id`, y deja
`Status = PendingReverse`, `Current Step = Reverse`. Luego `OnInsertRecord` de la página llama a
`StartOperation`, que **ajusta el estado inicial según el tipo de operación** (ver abajo).

---

## 3. La máquina de estados

```
                 StartOperation()              ExecuteNextStep() recorre los estados
                       │
   ConsumeFromGeneral  ▼
   ┌─────────────────────────────┐   (salta Reverse — no hay nada que revertir)
   │ Status = ReverseDone        │
   │ Step   = Physical           │
   │ RequiresFinalConsume = true │
   └─────────────────────────────┘

   Transfer / Return   ▼
   ┌─────────────────────────────┐
   │ Status = PendingReverse     │
   │ Step   = Reverse            │
   └─────────────────────────────┘

   Estados (ExecuteNextStep):
   PendingReverse ──RunReverse──▶ ReverseDone ──RunPhysical──▶ PhysicalDone
        │                                                          │
        │                                          ┌───────────────┴───────────────┐
        │                              RequiresFinalConsume?                        │
        │                                   sí │                              no   │
        │                                      ▼                                   ▼
        │                            RunFinalConsume                            CloseOp
        │                                      │                                   │
        │                                      ▼                                   ▼
        │                              FinalConsumeDone ──CloseOp──▶ Closed     Closed
        └─ (si algo falla en cualquier paso) ──▶ Failed  ──retryFailed──▶ vuelve al paso
```

Los tres pasos de trabajo:

### Paso `Reverse` → `RunReverse` / `TryRunReverseContable`
Postea una **Job Journal Line de tipo Usage con cantidad NEGATIVA** contra el proyecto **origen**.
Esto "devuelve" contablemente el material que estaba consumido en el proyecto, dejándolo listo para moverse.
- Usa un **batch temporal** `PROJECT / TMPxxxxxxx` que crea y borra al instante.
- Postea con `Job Jnl.-Post Line`.
- **Aquí está el fix de dimensiones** (ver sección 5).

### Paso `Physical` → `RunPhysical` / `TryRunPhysicalTransfer`
Mueve el inventario **físicamente** entre ubicaciones llamando a `GJW Item Transfer Bulk`.
Arma un JSON de transferencia con `itemNo, locationCode (origen), newLocationCode (destino), quantity,
documentNo` y, si aplica, `taskNo / newJobNo / newJobTaskNo`.
- Internamente crea una línea de **Item Journal (Entry Type = Transfer)** en el batch `TRANSFEREN / GENERICO` y la postea con `Item Jnl.-Post Batch`.
- Captura el **Item Ledger Entry No. de destino** (el "receipt") comparando el último Entry No. antes/después del posting, y lo devuelve en el JSON de resultados como `destination.entryNoALM`.
- El orquestador extrae esos entry nos con `ParseDestinationEntryNos` y los guarda en `Last BC Entry Nos`.
- Si hay `newJobNo + newJobTaskNo`, además actualiza/crea el registro `GomJob Warehouse Quantity` (la tabla que mapea ILE ↔ proyecto/tarea/cantidad).

### Paso `FinalConsume` → `RunFinalConsume` / `TryRunFinalConsume`
Solo corre si `Requires Final Consume = true`. Llama a `GJW Material Consumption.ConsumeWarehouseMaterials`
pasando los `Last BC Entry Nos`, el proyecto y la tarea destino, y el `Document No.`.
- Por cada ILE, busca en `GomJob Warehouse Quantity` las tareas asociadas y postea una **Job Journal Line de tipo Usage** (Line Type = Budget) contra el proyecto destino, aplicando contra el ILE (`Applies-to Entry`).
- Valida que el material esté en el almacén del proyecto (`ItemLedgerEntry."Location Code" = JobNo`) y que tenga `Remaining Quantity > 0`.

### `CloseOp`
Marca `Status = Closed`, `Result JSON = {"closed":true}`.

---

## 4. Qué pasos corre cada tipo de operación

| Tipo | Reverse | Physical | FinalConsume | Resultado |
|---|:---:|:---:|:---:|---|
| **ConsumeFromGeneral** (almacén general → proyecto) | ❌ (se salta) | ✅ traslada de `sourceLocation` (ALM-GRAL) al almacén del proyecto destino | ✅ consume contra el proyecto destino | Material consumido en el proyecto |
| **TransferConsumedBetweenJobs** (proyecto A → proyecto B) | ✅ revierte consumo en proyecto origen | ✅ traslada al almacén del proyecto destino | ✅ consume contra el proyecto destino | Material movido de A a B |
| **ReturnConsumedToGeneral** (proyecto → almacén general) | ✅ revierte consumo en proyecto origen | ✅ traslada al almacén general (`destinationLocation`) | ❌ (no se vuelve a consumir) | Material devuelto a stock general |

Reglas de validación clave (`ValidateStart`):
- `ConsumeFromGeneral` exige `destinationJobNo` + `destinationJobTaskNo`.
- `Transfer`/`Return` exigen `sourceJobNo` + `sourceJobTaskNo`.
- `ReturnConsumedToGeneral` exige `destinationJobNo` **VACÍO** (va a stock, no a proyecto).
- Siempre: `itemNo`, `quantity > 0`, `sourceLocationCode`, `destinationLocationCode`.

---

## 5. El fix de dimensiones (CC del proyecto)

**Problema:** al postear el paso Reverse, BC reconstruye las default dimensions en cada `Validate`.
El `Validate("Location Code")` (p.ej. ALM-GRAL) inyecta su dimensión por defecto **CC = INV**, que pisa
la dimensión que el proyecto exige (CC = "Igual al código", p.ej. VN-K.27). El posteo se bloquea con:
`The Dimension Value Code must be VN-K.27 for Dimension Code CC for Project VN-K.27`.

**Solución (`ForceJobDimensions`, en el orquestador):** justo antes del `Insert` de la Job Journal Line,
se reconstruye el `Dimension Set ID` de la línea:
1. Se cargan las dimensiones que la línea ya heredó (incluido el CC=INV) en una `Dimension Set Entry` temporal.
2. Se leen las **Default Dimension del Job** (`Table ID = Job`, valor fijo no vacío) y se **sobrescriben** sobre la temporal — CC vuelve a VN-K.27.
3. Se recalcula con `DimensionManagement.GetDimensionSetID` y se asigna a la línea.

Es genérico (no hardcodea proyecto ni dimensión) y solo afecta el paso Reverse.
> ⚠️ Asume que el proyecto define CC como "Igual al código" (valor fijo en su Default Dimension).
> Si fuera "Code Mandatory" sin valor fijo, habría que decidir el valor de otra forma.

---

## 6. Cómo consumirla desde el cliente (Power Apps / HTTP)

**Endpoint OData V4:**
```
.../api/adelante/operations/v1.0/companies({companyId})/materialOperations
```

### Patrón de uso
1. **POST** para crear la operación con los campos de entrada (`operationType`, `itemNo`, `quantity`, locations y jobs según el tipo).
   - La respuesta trae `operationId` y `status` inicial.
2. **PATCH** sobre esa `operationId` poniendo `executeUntilStop = true` → corre toda la cadena hasta `Closed` o `Failed`.
   - (Alternativa: `executeNext = true` paso a paso, útil para depurar.)
3. **GET** la fila para leer `status`, `lastError`, `lastBCEntryNos`, `resultJson`.
4. Si `status = Failed`: revisar `lastError`, corregir la causa, y **PATCH** `retryFailed = true` (reanuda desde el paso que falló).

### Ejemplo — consumir material de almacén general a un proyecto
```jsonc
// POST materialOperations
{
  "operationType": "ConsumeFromGeneral",
  "itemNo": "M01-0146",
  "quantity": 5,
  "sourceLocationCode": "ALM-GRAL",
  "destinationLocationCode": "VN-K.27",      // almacén del proyecto destino
  "destinationJobNo": "VN-K.27",
  "destinationJobTaskNo": "1000"
}
// luego: PATCH { "executeUntilStop": true }
```

### Ejemplo — devolver material de un proyecto al almacén general
```jsonc
{
  "operationType": "ReturnConsumedToGeneral",
  "itemNo": "M10-0054",
  "quantity": 2,
  "sourceJobNo": "VN-K.27",
  "sourceJobTaskNo": "1000",
  "sourceLocationCode": "VN-K.27",
  "destinationLocationCode": "ALM-GRAL",
  "destinationJobNo": ""                      // DEBE ir vacío
}
```

### Ejemplo — trasladar material consumido entre proyectos
```jsonc
{
  "operationType": "TransferConsumedBetweenJobs",
  "itemNo": "M01-0146",
  "quantity": 3,
  "sourceJobNo": "VN-K.27",
  "sourceJobTaskNo": "1000",
  "sourceLocationCode": "VN-K.27",
  "destinationLocationCode": "OTRO-PROY",
  "destinationJobNo": "OTRO-PROY",
  "destinationJobTaskNo": "1000"
}
```

---

## 7. Notas de implementación / gotchas para el otro asistente

- **Idempotencia / reintentos:** los pasos están envueltos en `[TryFunction]`. Si un paso falla, el estado pasa a `Failed` con `lastError` y NO avanza. `retryFailed` reposiciona el `status` al estado previo del paso (`Reverse→PendingReverse`, `Physical→ReverseDone`, `FinalConsume→PhysicalDone`) y reejecuta.
- **`Commit()` explícitos:** tanto el Reverse como el transfer hacen `Commit()` antes de postear. Esto es necesario para el posteo pero implica que un fallo posterior no revierte lo ya commiteado — el diseño se apoya en el reintento por pasos, no en una transacción única.
- **`Last BC Entry Nos` es el pegamento** entre Physical y FinalConsume: si el transfer no logra identificar el ILE destino (`entryNoALM = 0`), el FinalConsume falla con "No hay Item Ledger Entries de destino".
- **`GomJob Warehouse Quantity`** es la tabla que vincula un Item Ledger Entry con (proyecto, tarea, cantidad). El transfer la escribe y el consumo la lee. Es central para saber "cuánto de este ILE pertenece a qué tarea".
- **Batches usados:** Reverse → `PROJECT/TMPxxxx` (temporal, autoborrado). Physical → `TRANSFEREN/GENERICO` (se limpia al inicio de cada corrida). FinalConsume → `PROJECT/DEFAULT`.
- **Costo en el consumo:** `Unit Cost` se calcula desde `Cost Amount (Actual)/Quantity` del ILE, o como fallback `GomJob Cost per Unit`.
- **Descripción del material:** `GetMaterialDescription` usa, en orden: descripción de la variante → descripción del ítem → descripción del ILE.
- **Auditoría:** cada intento queda en `GJW Material Operation Step` con `Attempt No.` incremental por (operación, paso).
