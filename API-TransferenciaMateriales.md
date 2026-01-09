# API de Transferencia de Materiales de Proyecto

## Descripción
Esta API permite mover materiales que tienen "Ajuste negativo" desde un almacén de proyecto a otra obra o almacén general.

## Archivos Creados

### 1. `50185-ProjectMaterialTransferAPI.al`
Página API para crear líneas individuales de transferencia de materiales.

**Endpoint:** `/api/adelante/inventory/v1.0/projectMaterialTransfers`

**Campos principales:**
- `sourceEntryNo`: Número de movimiento del Item Ledger Entry de origen
- `sourceProjectNo`: Número de proyecto origen (solo lectura)
- `sourceLocationCode`: Código de ubicación origen (solo lectura)
- `destinationType`: Tipo de destino (`Project` o `GeneralWarehouse`)
- `destinationProjectNo`: Número de proyecto destino
- `destinationTaskNo`: Número de tarea destino
- `destinationLocationCode`: Código de ubicación destino
- `quantity`: Cantidad a transferir
- `itemNo`: Número de artículo

### 2. `50185-ProjMaterialTransfer.al`
Codeunit con funciones auxiliares para operaciones bulk.

**Funciones:**
- `CreateTransferFromNegativeAdjustments()`: Crea automáticamente líneas de transferencia para todos los ajustes negativos de un proyecto
- `GetNegativeAdjustmentsByProject()`: Obtiene lista JSON de ajustes negativos de un proyecto

### 3. `50186-ProjTransferSingleton.al`
Página API singleton para ejecutar operaciones bulk.

**Endpoint:** `/api/adelante/inventory/v1.0/projectMaterialTransferOperations`

## Casos de Uso

### Caso 1: Obtener lista de ajustes negativos de un proyecto

**Request:**
```http
PATCH /api/adelante/inventory/v1.0/projectMaterialTransferOperations(1)
Content-Type: application/json

{
    "sourceProjectNo": "VN-B.27",
    "sourceLocationCode": "1.1",
    "getNegativeAdjustments": true
}
```

**Response:**
```json
{
    "id": 1,
    "sourceProjectNo": "VN-B.27",
    "sourceLocationCode": "1.1",
    "result": "Negative adjustments retrieved successfully",
    "negativeAdjustmentsJson": "[{\"entryNo\":62386,\"itemNo\":\"M01-0147\",\"description\":\"VARILLA #3 DEFORME G40\",...}]"
}
```

### Caso 2: Crear transferencias automáticas a almacén general

**Request:**
```http
PATCH /api/adelante/inventory/v1.0/projectMaterialTransferOperations(1)
Content-Type: application/json

{
    "sourceProjectNo": "VN-B.27",
    "sourceLocationCode": "1.1",
    "destinationType": "GeneralWarehouse",
    "destinationLocationCode": "ALMACEN",
    "createTransfers": true
}
```

**Response:**
```json
{
    "id": 1,
    "result": "Se crearon 15 líneas de transferencia en el diario TRANSFEREN-GENERICO"
}
```

### Caso 3: Crear transferencias a otra obra específica

**Request:**
```http
PATCH /api/adelante/inventory/v1.0/projectMaterialTransferOperations(1)
Content-Type: application/json

{
    "sourceProjectNo": "VN-B.27",
    "sourceLocationCode": "1.1",
    "destinationType": "Project",
    "destinationProjectNo": "VN-C.15",
    "destinationTaskNo": "1.1",
    "destinationLocationCode": "VN-C.15",
    "createTransfers": true
}
```

### Caso 4: Crear transferencia individual de un movimiento específico

**Request:**
```http
POST /api/adelante/inventory/v1.0/projectMaterialTransfers
Content-Type: application/json

{
    "sourceEntryNo": 62386,
    "destinationType": "Project",
    "destinationProjectNo": "VN-C.15",
    "destinationTaskNo": "1.1",
    "destinationLocationCode": "VN-C.15",
    "postingDate": "2026-01-09"
}
```

## Flujo de Trabajo

1. **Consultar ajustes negativos:**
   - Usar `projectMaterialTransferOperations` con `getNegativeAdjustments = true`
   - Revisar el JSON devuelto con la lista de movimientos

2. **Crear transferencias:**
   - **Opción A (Bulk):** Usar `projectMaterialTransferOperations` con `createTransfers = true`
   - **Opción B (Individual):** Usar `projectMaterialTransfers` con `sourceEntryNo`

3. **Revisar líneas creadas:**
   - Ir al diario de reclasificación TRANSFEREN-GENERICO en Business Central
   - Revisar y ajustar las líneas si es necesario

4. **Registrar el diario:**
   - Usar la API de posting existente o registrar manualmente desde Business Central

## Notas Importantes

- Las transferencias se crean en el diario `TRANSFEREN-GENERICO`
- El Entry Type se establece automáticamente como `Transfer`
- Si se transfiere a almacén general, las dimensiones de proyecto se limpian
- Si se transfiere a otro proyecto, se establecen las nuevas dimensiones
- El campo `Applies-from Entry` mantiene la referencia al movimiento original
- La cantidad se convierte a positivo automáticamente (valor absoluto)

## Tablas Relacionadas

- **Item Ledger Entry**: Tabla origen con los ajustes negativos
- **Item Journal Line**: Tabla destino donde se crean las líneas de transferencia
- **Job Task**: Para validar proyectos y tareas de destino
- **Location**: Para validar ubicaciones de destino
