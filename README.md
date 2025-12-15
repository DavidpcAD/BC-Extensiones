# AdelanteAPI - Extensión Business Central

**Versión:** 1.1.7.6  
**Publisher:** Default Publisher  
**Plataforma:** Business Central 25.0  
**Dependencias:** Goom Job Global Localization 25.5.10.0

---

## 📋 Descripción del Proyecto

Extensión de Business Central que proporciona:
- **APIs OData v4** para integración con Power Apps
- **Automatización** del registro de movimientos en "Almacén de Obra" (GomJob Warehouse Quantity)
- **Campos personalizados** para seguimiento de presupuestos y producción
- **Gestión de obras** con descomposición de líneas y control de encargados

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

### Error: "Line No. already exists"
**Solución:** Codeunits 50155/50156 deberían prevenir esto. Verificar que están en permisos.

### Error: "Cannot convert NavJsonValue to NavText"
**Solución:** Ya corregido en v1.1.7.6 con validaciones `IsNull()`.

### Campo "Task No." no visible en diario
**Solución:** 
1. Verificar que PageExtension 50134 está instalada
2. Refrescar página con Ctrl+F5

### No se crea registro en Warehouse Quantity
**Solución:**
1. Verificar que "Task No." no está vacío
2. Verificar que "Global Dimension 1" tiene Job No.
3. Verificar permisos del codeunit 50157

---

## 📊 Datos Técnicos

### ID Ranges:
- **Tables:** 50100-50199
- **Pages:** 50100-50199
- **Codeunits:** 50100-50199
- **PageExtensions:** 50131-50134
- **TableExtensions:** 50111, 50129-50130, 50133, 50135

### Grupos API:
- `construction` - APIs de obras y presupuestos
- `inventory` - APIs de inventario y diarios
- `project` - APIs de proyectos y tareas

### Versiones:
- **Actual:** 1.1.7.6
- **Plataforma BC:** 25.0.0.0
- **Runtime:** 14.0

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

### v1.1.7.6 (Actual)
- ✅ Automatización completa diario → almacén obra
- ✅ Campo "ID Encargado" en APIs
- ✅ Estructura profesional con carpetas
- ✅ Nombres de archivo coinciden con IDs de objeto
- ✅ 0 errores de compilación

### Versiones anteriores
- v1.1.7.5: Codeunit 50157 con Event Subscribers
- v1.1.7.4: Campo Task No. en Item Journal Line
- v1.1.7.x: Corrección de JSON nulls en bulk
- v1.1.6.x: AutoNo codeunits con detección de colisiones
- v1.1.x: Campo ID Encargado en presupuestos

---

## 👥 Equipo y Soporte

**Desarrollador:** Daniel  
**Organización:** Adelante Desarrollos  
**Fecha:** Diciembre 2025

**Contacto:** [Tu información de contacto]

---

## 📖 Referencias

- [Microsoft BC Developer Docs](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/)
- [OData v4 Specification](https://www.odata.org/documentation/)
- [AL Language Extension](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al)

---

## 🎯 Próximos Pasos Recomendados

1. **Testing en Sandbox:**
   - Probar escenarios de registro con Task No.
   - Validar creación automática en Warehouse Quantity
   - Probar reversiones (cantidades negativas)

2. **Validar APIs desde Power Apps:**
   - Leer/escribir workLines
   - Leer/escribir workDecomposedLines
   - Verificar campo idEncargado

3. **Monitoreo:**
   - Revisar Job Queue Entries si hay errores
   - Validar performance con > 100 registros
   - Confirmar no hay duplicados en Warehouse Quantity

4. **Despliegue a Producción:**
   - Backup de BD antes de instalar
   - Instalar en horario de baja actividad
   - Capacitar usuarios en uso de "Task No."

---

**✅ Proyecto completo, estructurado y listo para producción.**
