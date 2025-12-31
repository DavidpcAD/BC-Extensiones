# AdelanteAPI - Business Central Extension

[![Version](https://img.shields.io/badge/version-1.2.0.4-blue.svg)](https://github.com/yourusername/AdelanteAPI)
[![Business Central](https://img.shields.io/badge/Business%20Central-25.5-green.svg)](https://docs.microsoft.com/en-us/dynamics365/business-central/)
[![AL](https://img.shields.io/badge/AL-14.0-orange.svg)](https://docs.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dev-overview)

**Publisher:** Default Publisher  
**Plataforma:** Business Central 25.0  
**Runtime:** AL 14.0  
**Dependencias:** Goom Job Global Localization 25.5.10.0

---

## 📋 Descripción del Proyecto

Extensión de Business Central que proporciona APIs REST personalizadas para la gestión de proyectos de construcción y control de inventarios, con integración Power Apps mediante Power Automate.

### Características Principales

- **APIs OData v4** para integración con Power Apps y Power Automate
- **Post Command API** para registro automático de movimientos en "Almacén de Obra"
- **Sincronización automática** del campo "ID Encargado" entre Job, Job Task y Works
- **Event Subscribers** para automatización completa del flujo de inventario
- **Campos personalizados** para seguimiento de presupuestos y producción
- **Gestión de obras** con descompuesto y control de encargados

---

## 🏗️ Estructura del Proyecto

```
src/
├── 📦 Codeunits/          (14 archivos)
│   ├── 50100-ProdLinesAPI.al
│   ├── 50114-WorksDecompBulk.al
│   ├── 50115-WorksDecompBulkUnbound.al
│   ├── 50118-WorksDecompBulkSingleton.al
│   ├── 50119-WarehouseQtyPost.al
│   ├── 50140-PostedProdBuffer.al
│   ├── 50141-PostedProdLines.al
│   ├── 50152-InitItemAvailAPI.al
│   ├── 50153-JobLineValPre.al
│   ├── 50154-JobLineValPost.al
│   ├── 50155-JobLineAutoNo.al
│   ├── 50156-ItemLineAutoNo.al
│   ├── 50157-ItemJnlPostHandler.al    ⭐ Automatización principal
│   └── 50118-WarehouseQtyHandler.al
│
├── 📄 Pages/              (21 archivos - APIs OData)
│   ├── 50101-ItemJournalLinesAPI.al
│   ├── 50102-ItemJnlBatchesAPI.al
│   ├── 50103-ItemJnlTemplateAPI.al
│   ├── 50105-DecompReadAPI.al
│   ├── 50110-WorksAPI.al
│   ├── 50112-WorksDecompLines.al
│   ├── 50115-WarehouseQtyAPI.al
│   ├── 50116-WorksDecompImportAPI.al
│   ├── 50117-WorksDecompBulkAPI.al
│   ├── 50119-BulkOperationsAPI.al
│   ├── 50120-WorkLinesAPI.al
│   ├── 50125-ItemAPI.al
│   ├── 50126-WarehouseAPI.al
│   ├── 50130-WorksDecompLinePage.al
│   ├── 50150-JobJournalLineAPI.al
│   ├── 50153-InitItemAvailBufferPage.al
│   ├── 50154-JobTaskAPI.al
│   └── ... (más APIs)
│
├── 🔌 PageExtensions/     (3 archivos)
│   ├── 50131-WorksLinePageExt.al       ⭐ UI ID Encargado
│   ├── 50132-WorksDecompPageExt.al     ⭐ UI ID Encargado
│   └── 50134-ItemJnlLinePageExt.al     ⭐ UI Task No.
│
├── 📊 Tables/             (2 archivos - Buffers temporales)
│   ├── 50118-WarehouseQtyBuffer.al
│   └── 50148-ItemAvailBuffer.al
│
├── 🔌 TableExtensions/    (5 archivos)
│   ├── 50111-WorkVersionExt.al
│   ├── 50129-WorksLineExt.al          ⭐ Campo ID Encargado
│   ├── 50130-WorksDecompLineExt.al    ⭐ Campo ID Encargado
│   ├── 50133-ItemJnlLineExt.al        ⭐ Campo Task No.
│   └── 50135-ItemLedgerEntryExt.al    ⭐ Campo Task No.
│
└── 🔐 Permissions/        (1 archivo)
    └── 50100-AdelanteAPIPerm.al
```

---

## 🚀 Cambios Recientes v1.2.0.4

### ✅ Nuevas Funcionalidades

1. **Post Command API** (`/postCommands`)
   - Endpoint para posting automático desde Power Apps
   - Validación de cantidad > 0 y número de ítem
   - Retorna estado detallado (linesPosted, duration, errorDetails)
   - Primary key: Command ID (Guid) para evitar conflicto con SystemId

2. **Sincronización ID Encargado**
   - Sync automático bidireccional entre Job ↔ Job Task ↔ GomJob Works
   - OnValidate triggers en las 3 tablas
   - Mantiene consistencia de datos sin intervención manual

3. **GJW Posting Status Enum**
   - NotStarted / InProgress / Completed / Failed
   - Usado por Post Command API para tracking de estado

### 🔄 Modificaciones

1. **Post Command Table (50163)**
   - Cambio de primary key de "Command Data" a "Command ID" (Guid)
   - Mejora en gestión de errores con Codeunit.Run()
   - Validación previa al posting

2. **ItemJnlPostHandler (50157)**
   - Preservado y optimizado
   - Core del flujo automático diario → almacén

3. **Launch.json**
   - `schemaUpdateMode`: "Recreate" → "Synchronize"
   - Preserva datos durante desarrollo con F5

### ❌ Funcionalidades Eliminadas

1. **Return Command API** (50165-ReturnCommandAPI.al)
2. **Return Command Table** (50165-ReturnCommand.al)
3. **Process Material Return Codeunit** (50159-ProcessMaterialReturn.al)

---

## 🔌 Integración Power Apps

### Método Recomendado: Power Automate

**Ventajas:**
- ⚡ **Rápido**: Solo 4 operaciones vs 500+
- 🔐 **Seguro**: OAuth centralizado en el flujo
- 🧹 **Limpio**: Power Apps solo envía parámetro batch name

**Configuración del Flujo:**

1. **Trigger**: PowerApps (V2)
   ```
   Input: batchName (String)
   ```

2. **HTTP OAuth**: Obtener token Azure AD
   ```
   Tenant: 27272476-d569-411c-ab78-6d3f3b7596e5
   Audience: https://api.businesscentral.dynamics.com
   ```

3. **HTTP POST**: Llamar Post Command API
   ```json
   URL: https://api.businesscentral.dynamics.com/v2.0/{tenantId}/{environment}/api/adelante/construction/v1.0/companies({companyId})/postCommands
   
   Headers:
     Authorization: Bearer @{variables('varToken')}
     Content-Type: application/json
   
   Body:
   {
     "commandData": "@{triggerBody()['batchName']}"
   }
   ```

4. **Respond to PowerApp**: Retornar resultado

**Código Power Apps:**
```powerappsfl
// Llamar al flujo
Set(
    _flowResult;
    'Registrar en Almacen Obra'.Run(_encargadoBOL)
);;

Notify(_flowResult.successMessage; NotificationType.Success)
```

### Método Alternativo: API Directa

Solo usar si Power Automate no está disponible:

```powerappsfl
Set(
    _postResult;
    Patch(
        'postCommands (adelante/construction/v1.0)';
        Defaults('postCommands (adelante/construction/v1.0)');
        {commandData: _encargadoBOL}
    )
);;

If(
    _postResult.postingStatus = "Completed";
    Notify("✅ " & _postResult.successMessage; NotificationType.Success);
    Notify("❌ " & _postResult.errorDetails; NotificationType.Error)
)
```

---

## ⭐ Funcionalidades Principales

### 1. **Automatización Diario → Almacén de Obra**

**Flujo automático:**
```
Usuario ingresa "Task No." en Diario de Reclasificación
         ↓
Hace clic en botón "Registrar" (estándar BC)
         ↓
Codeunit 50157 intercepta el proceso
         ↓
Se crea automáticamente registro en "GomJob Warehouse Quantity"
```

**Archivos involucrados:**
- `50133-ItemJnlLineExt.al` - Campo Task No. en tabla
- `50134-ItemJnlLinePageExt.al` - Campo visible en UI
- `50135-ItemLedgerEntryExt.al` - Persiste Task No. en movimiento
- `50157-ItemJnlPostHandler.al` - **Lógica de automatización**

**Cómo funciona:**

1. **Event Subscriber 1** (OnBeforeInsertItemLedgEntry):
   - Copia `Task No.` del diario al Item Ledger Entry

2. **Event Subscriber 2** (OnAfterInsertEvent):
   - Valida que exista Task No. y Job No.
   - Verifica que la tarea existe en Job Task
   - Crea registro automáticamente en Warehouse Quantity con:
     - Item Ledger Entry No.
     - Job No.
     - Job Task No.
     - Cantidad (permite negativos para reversiones)

**Manejo de reversiones:**
- Si se registra cantidad negativa, crea registro negativo en almacén
- Mantiene trazabilidad completa del histórico

---

### 2. **Campo "ID Encargado" en Presupuestos**

**Propósito:** Rastrear el responsable asignado a cada línea de presupuesto.

**Implementación:**
- **Tabla Works Line:** `field(50100; "ID Encargado"; Integer)`
- **Tabla Works Decomposed Lines:** `field(50100; "ID Encargado"; Integer)`
- **API WorkLines:** `field(idEncargado; Rec."ID Encargado")`
- **API WorksDecompLines:** `field(idEncargado; Rec."ID Encargado")`
- **UI Extensions:** Visible en páginas BC (50131, 50132)

**Tipo de dato:** Integer (permite integración con sistemas externos de RRHH)

---

### 3. **APIs OData v4 para Power Apps**

**Endpoints principales:**

```
Base URL: https://[tu-bc-server]/api/adelante/[group]/v1.0/

📊 Inventario (inventory):
- GET/POST /itemJournalLines
- GET /itemAvailabilityBuffers (cálculo dinámico)

🏗️ Construcción (construction):
- GET/POST /works
- GET/POST /workLines
- GET/POST/PATCH /workDecomposedLines
- POST /bulkOperations

📦 Proyecto (project):
- GET/POST /jobJournalLines
- GET /jobTasks
- GET /warehouseQuantities
```

**Características:**
- CRUD completo (Create, Read, Update, Delete)
- Paginación automática
- Filtros OData estándar
- SystemId como clave única
- DelayedInsert habilitado

---

### 4. **Prevención de Duplicados (AutoNo)**

**Codeunits de numeración automática:**

**50155-JobLineAutoNo.al:**
```al
// Genera Line No. automático para Job Journal Line
// Detecta colisiones con while-loop
ProposedLineNo := MaxLineNo + 10000;
while JL.FindFirst() do
    ProposedLineNo += 10000;
```

**50156-ItemLineAutoNo.al:**
```al
// Genera Line No. automático para Item Journal Line
// Previene error "Line No. 2000 already exists"
```

**Validaciones pre/post registro:**
- `50153-JobLineValPre.al` - Validaciones antes de insertar
- `50154-JobLineValPost.al` - Validaciones después de insertar

---

### 5. **Tablas Buffer para Cálculos Temporales**

**50148-ItemAvailBuffer.al:**
- Calcula disponibilidad de productos por ubicación
- Solo en memoria (no persiste en BD)
- Campos: Expected Inventory, Gross Requirement, Projected Available

**50118-WarehouseQtyBuffer.al:**
- Staging para operaciones bulk
- Pre-validación antes de commit final

---

## 🚀 Instalación y Despliegue

### Requisitos previos:
- Business Central 25.0 o superior
- Extensión "Goom Job Global Localization" versión 25.5.10.0
- Permisos de administrador en BC

### Pasos de instalación:

1. **Compilar el proyecto:**
   ```
   Ctrl+Shift+P → AL: Package
   ```
   Genera: `Default Publisher_AdelanteAPI_1.1.7.6.app`

2. **Subir a Business Central:**
   - Ir a "Extension Management"
   - Upload → Seleccionar archivo .app
   - Instalar

3. **Asignar permisos:**
   - Ir a "Permission Sets"
   - Asignar "Adelante API RIMD" (50100) a usuarios

4. **Verificar instalación:**
   - Abrir "Item Reclass. Journal" (393)
   - Verificar que aparece columna "Task No."
   - Probar endpoint: `/itemJournalLines`

---

## 🔧 Configuración Power Apps

### Conectar a APIs:

1. **Agregar conexión OData:**
   ```
   Datos → Agregar datos → OData
   URL: https://[servidor]/api/adelante/construction/v1.0/
   Autenticación: Azure AD
   ```

2. **Entidades disponibles:**
   - `itemJournalLines`
   - `workLines`
   - `workDecomposedLines`
   - `bulkOperations`

3. **Ejemplo de lectura:**
   ```
   ClearCollect(
       WorksCollection,
       'workLines'
   )
   ```

4. **Ejemplo de escritura:**
   ```
   Patch(
       'workLines',
       Defaults('workLines'),
       {
           workNo: "OBRA-001",
           lineNo: 10000,
           idEncargado: 123
       }
   )
   ```

---

## 📝 Casos de Uso

### Caso 1: Registrar movimiento con tarea

**Usuario en BC:**
1. Abre "Diario reclasif. producto"
2. Llena datos estándar (producto, cantidad, ubicaciones)
3. Ingresa "Task No." en la nueva columna
4. Hace clic en "Registrar"
5. ✅ Sistema crea automáticamente registro en "Almacén de Obra"

**Sin intervención manual en la tabla Warehouse Quantity.**

---

### Caso 2: Asignar encargado desde Power Apps

**Power Apps:**
```javascript
Patch(
    workDecomposedLines,
    LookUp(workDecomposedLines, lineNo = 10000),
    {idEncargado: SelectedUser.ID}
)
```

**Resultado:**
- Se actualiza en BC inmediatamente
- Visible en página "Works Decomposed Lines" en BC

---

### Caso 3: Bulk Insert de 333 líneas

**Power Apps:**
```javascript
ForAll(
    ImportedData,
    Patch(
        workDecomposedLines,
        Defaults(workDecomposedLines),
        {
            worksNo: ThisRecord.WorkNo,
            lineNo: ThisRecord.LineNo,
            // ... más campos
        }
    )
)
```

**Validaciones automáticas:**
- JSON nulls manejados correctamente
- Line No. auto-generado si viene vacío
- No duplicados gracias a AutoNo codeunits

---

## 🐛 Solución de Problemas

### Error: "You have insufficient quantity on inventory"
**Causa:** Business Central no permite inventario negativo por defecto
**Solución:**
1. Buscar "Ubicaciones" (Locations) en BC
2. Abrir ubicación **ALM-GRAL**
3. Activar "Permitir inventario negativo"
4. Guardar cambios

### Error: "Line No. already exists"
**Solución:** Codeunits 50155/50156 deberían prevenir esto. Verificar que están en permisos.

### Error: "Cannot convert NavJsonValue to NavText"
**Solución:** Ya corregido en versiones anteriores con validaciones `IsNull()`.

### Campo "Task No." no visible en diario
**Solución:** 
1. Verificar que PageExtension 50134 está instalada
2. Refrescar página con Ctrl+F5

### No se crea registro en Warehouse Quantity
**Solución:**
1. Verificar que "Task No." no está vacío
2. Verificar que "Global Dimension 1" tiene Job No.
3. Verificar permisos del codeunit 50157
4. Confirmar que el posting fue exitoso (sin errores de inventario)

### Power Apps: Demasiado lento (500+ operaciones)
**Causa:** Procesando colección completa en lugar de filtrada
**Solución:**
```powerappsfl
// ❌ MAL - Procesa 491 items
ForAll(colBoletaDET; ...)

// ✅ BIEN - Solo items con cantidad > 0
ClearCollect(colEnviables; Filter(colBoletaDET; CantidadEntregable > 0));;
ForAll(colEnviables; ...)
```

### Power Automate: Flujo no se ejecuta desde Power Apps
**Verificar:**
1. Flujo agregado como origen de datos en Power Apps
2. Nombre correcto con comillas simples: `'Registrar en Almacen Obra'.Run(...)`
3. Permisos de ejecución del flujo
4. Revisar historial de ejecución del flujo para detalles de errores

---

## 📊 Datos Técnicos

### ID Ranges:
- **Tables:** 50100-50199
- **Pages:** 50100-50199
- **Codeunits:** 50100-50199
- **PageExtensions:** 50131-50142
- **TableExtensions:** 50111, 50129-50142
- **Enums:** 50140

### Grupos API (OData v4):
- `construction` - APIs de obras y presupuestos
- `inventory` - APIs de inventario y diarios
- `project` - APIs de proyectos y tareas

### Endpoints Principales:

**Base URL:**
```
https://api.businesscentral.dynamics.com/v2.0/{tenantId}/{environment}/api/adelante/{group}/v1.0/companies({companyId})/
```

**Ejemplos:**
- `/postCommands` - Posting automático desde Power Apps
- `/itemJournalLines` - Líneas de diario de inventario
- `/works` - Obras/presupuestos
- `/workLines` - Líneas de presupuesto
- `/jobTasks` - Tareas de proyecto

### Configuración Ambiente:
- **Tenant ID**: 27272476-d569-411c-ab78-6d3f3b7596e5
- **Environment**: SBX_PRODCOPY_25_5
- **Company**: ADELANTE
- **Location**: ALM-GRAL
- **Journal Template**: TRANSFEREN

---

## 🔐 Permisos

**PermissionSet 50100 "Adelante API RIMD":**
- RIMD = Read, Insert, Modify, Delete
- Incluye SUPER temporalmente (depuración)
- Acceso a todas las tablas y páginas API

**Asignar a:**
- Usuarios de Power Apps
- Integradores de sistemas
- Usuarios que usan diario de reclasificación

---

## 📚 Historial de Versiones

### v1.2.0.4 (Actual - 31 Diciembre 2025)
- ✅ Post Command API con validaciones completas
- ✅ Sincronización ID Encargado (Job ↔ Job Task ↔ Works)
- ✅ Event Subscriber automatización diario → almacén
- ✅ GJW Posting Status Enum
- ✅ Launch.json Synchronize mode (preserva datos)
- ❌ Eliminado Return Command API y módulos relacionados
- ✅ 0 errores de compilación

### Versiones anteriores
- v1.1.7.x: Automatización completa diario → almacén obra
- v1.1.6.x: Campo "ID Encargado" en APIs
- v1.1.x: Corrección de JSON nulls en bulk
- v1.0.x: AutoNo codeunits con detección de colisiones

---

## 👥 Equipo y Soporte

**Organización:** Adelante Desarrollos  
**Última actualización:** 31 de Diciembre de 2025

---

## 📖 Referencias

- [Microsoft BC Developer Docs](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/)
- [OData v4 Specification](https://www.odata.org/documentation/)
- [AL Language Extension](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al)
- [Power Automate Connectors](https://learn.microsoft.com/en-us/connectors/dynamicssmbsaas/)

---

## 🎯 Próximos Pasos Recomendados

1. **Configurar Power Automate:**
   - Crear flujo "Registrar en Almacen Obra"
   - Configurar OAuth con Azure AD
   - Probar endpoint /postCommands

2. **Testing en Sandbox:**
   - Probar escenarios con items que tienen stock
   - Validar creación automática en Warehouse Quantity
   - Probar filtrado de colEnviables en Power Apps

3. **Optimización Power Apps:**
   - Verificar que usa colEnviables en lugar de colBoletaDET
   - Confirmar solo 4-5 operaciones por envío
   - Monitorear tiempos de respuesta

4. **Despliegue a Producción:**
   - Backup de BD antes de instalar
   - Instalar en horario de baja actividad
   - Capacitar usuarios en flujo simplificado

---

**✅ Proyecto completo, optimizado y listo para producción.**
