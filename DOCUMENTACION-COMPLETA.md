# 📚 Documentación Completa - Adelante Business Central Extensions

> **Versión**: 1.2.0.5  
> **Publisher**: Adelante Desarrollos  
> **Fecha última actualización**: 26 de enero de 2026

---

## 📑 Índice

1. [Descripción General](#descripción-general)
2. [Arquitectura de la Solución](#arquitectura-de-la-solución)
3. [APIs Disponibles](#apis-disponibles)
4. [Codeunits y Procesamiento](#codeunits-y-procesamiento)
5. [Extensiones de Tablas](#extensiones-de-tablas)
6. [Extensiones de Páginas](#extensiones-de-páginas)
7. [Tablas Personalizadas](#tablas-personalizadas)
8. [Permisos](#permisos)
9. [Integración con Power Apps](#integración-con-power-apps)
10. [Casos de Uso](#casos-de-uso)
11. [Guía de Despliegue](#guía-de-despliegue)

---

## 🎯 Descripción General

Esta extensión para Microsoft Dynamics 365 Business Central proporciona APIs REST y funcionalidades automatizadas para:

- **Gestión de presupuestos y obras** (Works/Projects)
- **Control de inventario y almacenes** (Warehouse Management)
- **Transferencias de materiales** entre proyectos y almacenes
- **Ensamblaje de productos** con tracking de lotes
- **Desensamblaje de materiales** (Material Disassembly)
- **Consumo de materiales** en proyectos
- **Registro automático de diarios** (Item Journal, Job Journal)

### Características principales:

✅ **APIs REST completas** para integración con Power Apps  
✅ **Procesamiento masivo** (bulk operations)  
✅ **Tracking de lotes automático** para productos con seguimiento  
✅ **Asignación automática de dimensiones** por ubicación  
✅ **Validaciones de negocio** antes del posting  
✅ **Manejo robusto de errores** con mensajes descriptivos  

---

## 🏗️ Arquitectura de la Solución

### Estructura de Directorios

```
BusinessCentral-Extensions/
├── src/
│   ├── Codeunits/          # Lógica de negocio
│   ├── Pages/              # APIs REST
│   ├── TableExtensions/    # Extensiones de tablas estándar
│   ├── PageExtensions/     # Extensiones de páginas estándar
│   ├── Tables/             # Tablas personalizadas
│   ├── Enums/              # Enumeraciones
│   └── Permissions/        # Conjuntos de permisos
├── API-*.md               # Documentación específica de APIs
├── PowerApps-*.md         # Guías de integración Power Apps
└── app.json               # Manifiesto de la extensión
```

### Grupos de API

Las APIs están organizadas en grupos funcionales:

| Grupo | Propósito | Endpoint Base |
|-------|-----------|---------------|
| **construction** | Presupuestos y obras | `/api/adelante/construction/v1.0` |
| **inventory** | Gestión de inventario | `/api/adelante/inventory/v1.0` |
| **production** | Ensamblaje y manufactura | `/api/adelante/production/v1.0` |
| **project** | Proyectos y tareas | `/api/adelante/project/v1.0` |
| **returns** | Devoluciones y ajustes | `/api/adelante/returns/v1.0` |

---

## 📡 APIs Disponibles

### 🏗️ **CONSTRUCTION - Obras y Presupuestos**

#### 1. Works API (50110)
**Endpoint**: `/works`  
**Tabla**: `GomJob Works`  
**Operaciones**: CRUD completo

Gestiona las obras/presupuestos del sistema.

**Campos principales**:
- `no` - Número de obra
- `description` - Descripción
- `idEncargado` - ID del encargado
- `quantityLines` - Cantidad de líneas

**Ejemplo**:
```http
GET /api/adelante/construction/v1.0/works
GET /api/adelante/construction/v1.0/works('{id}')
POST /api/adelante/construction/v1.0/works
PATCH /api/adelante/construction/v1.0/works('{id}')
```

#### 2. Work Lines API (50120)
**Endpoint**: `/workLines`  
**Tabla**: `GomJob Works Line`  
**Operaciones**: CRUD completo

Líneas de detalle de las obras.

**Campos principales**:
- `worksNo` - Número de obra
- `taskNo` - Número de tarea
- `description` - Descripción
- `quantity` - Cantidad
- `unitAmount` - Precio unitario
- `lineAmount` - Importe total

#### 3. Work Lines Bulk API (50127, 50190)
**Endpoint**: `/workLinesBulks`  
**Operaciones**: Creación masiva de líneas

Permite crear múltiples líneas de obra en una sola petición.

**Ejemplo**:
```json
{
    "worksNo": "OBRA-001",
    "lineasJSON": "[{...},{...}]",
    "ejecutar": true
}
```

#### 4. Works Decomposed Read API (50105)
**Endpoint**: `/gomJobWorksDecomposedRead`  
**Tabla**: `GomJob Works Decomposed Lines`  
**Operaciones**: Solo lectura

API de consulta optimizada para líneas descompuestas.

#### 5. Works Decomposition Import/Bulk APIs (50116, 50117)
**Endpoints**: `/worksDecompImport`, `/worksDecompBulk`  
**Operaciones**: Importación masiva de descomposición

---

### 📦 **INVENTORY - Gestión de Inventario**

#### 6. Item Journal Lines API (50101)
**Endpoint**: `/itemJournalLines`  
**Tabla**: `Item Journal Line`  
**Operaciones**: CRUD completo

Creación y gestión de líneas de diario de inventario.

**Campos clave**:
- `itemNo` - Código de producto
- `locationCode` - Almacén
- `quantity` - Cantidad
- `entryType` - Tipo de movimiento
- `taskNo` - Tarea de proyecto
- `lotNo` - Número de lote

**Ejemplo**:
```json
{
    "journalTemplateName": "PRODUCT",
    "journalBatchName": "DEFAULT",
    "entryType": "Positive Adjmt.",
    "itemNo": "M01-0147",
    "quantity": 10,
    "locationCode": "VN-B.27"
}
```

#### 7. Item Journal Batches API (50102)
**Endpoint**: `/itemJournalBatches`  
**Tabla**: `Item Journal Batch`

Gestión de lotes de diario.

#### 8. Item Journal Templates API (50103)
**Endpoint**: `/itemJournalTemplates`  
**Tabla**: `Item Journal Template`

Gestión de plantillas de diario.

#### 9. Item Ledger Entry API (50114)
**Endpoint**: `/itemLedgerEntriesWithTasks`  
**Tabla**: `Item Ledger Entry`  
**Operaciones**: Solo lectura (con campos calculados)

Movimientos de inventario con información de tareas.

**Campos adicionales**:
- `vendorName` - Nombre del proveedor
- `jobTaskNo` - Tareas asociadas
- `stock` - Stock disponible

#### 10. Item Transfer Bulk API (50191)
**Endpoint**: `/itemTransferBulkOperations`  
**Operaciones**: Transferencias masivas

Traslado masivo de materiales entre almacenes.

**Campos**:
- `itemNo` - Producto
- `locationCode` - Almacén origen
- `newLocationCode` - Almacén destino
- `quantity` - Cantidad
- `taskNo` - Tarea (opcional)
- `appliesFromEntry` - Movimiento a liquidar

**Ejemplo**:
```json
{
    "itemsJson": "[{
        \"itemNo\": \"M01-0147\",
        \"locationCode\": \"ALM-GRAL\",
        \"newLocationCode\": \"VN-B.27\",
        \"quantity\": 5,
        \"taskNo\": \"001\"
    }]",
    "executeTransfer": true
}
```

#### 11. Item Reclassification Journal API (50182, 50185, 50186)
**Endpoints**: `/itemReclassJournalLines`, `/itemReclassBatches`  
**Tabla**: `Item Journal Line`

Reclasificación de inventario (cambio de dimensiones).

#### 12. Warehouse Quantity APIs (50115, 50118)
**Endpoints**: `/warehouseQuantities`, `/warehouseQtyBuffer`  
**Tabla**: `GomJob Warehouse Quantity`

Cantidades de inventario por tarea de proyecto.

#### 13. Item Availability APIs (50104, 50149, 50180)
**Endpoints**: 
- `/itemAvailabilityByLocation`
- `/itemAvailabilityBuffer`
- `/itemAvailLocationSimple`

Disponibilidad de productos por ubicación.

#### 14. Item API (50125)
**Endpoint**: `/items`  
**Tabla**: `Item`

Catálogo de productos.

#### 15. Item Tracking Summary API (50166)
**Endpoint**: `/itemTrackingSummary`  
**Tabla**: `Entry Summary`

Resumen de números de lote/serie disponibles.

---

### 🏭 **PRODUCTION - Ensamblaje y Manufactura**

#### 16. Assembly Bulk Operations API (50171)
**Endpoint**: `/assemblyBulkOperations`  
**Operaciones**: Creación masiva de pedidos de ensamblaje

**Funcionalidad completa**:
- Crea Assembly Orders desde Power Apps
- Asigna dimensiones por ubicación
- Tracking automático de lotes
- Release y posting automático
- Manejo de errores por producto

**Estructura JSON**:
```json
{
    "productsJson": [{
        "IDPro": 1,
        "productItemNo": "M09-0166",
        "cantidad": 2,
        "almacenDestino": "VN-B.27",
        "unitOfMeasure": "M3"
    }],
    "componentsJson": [{
        "IDPro": 1,
        "componentItemNo": "M09-0033",
        "componentQty": 0.1,
        "loteseleccionado": 339017,
        "almacenOrigen": "F-MADERAS",
        "type": "Item"
    }],
    "ejecutar": true
}
```

**Respuesta**:
```json
{
    "resultado": {
        "results": [{
            "IDPro": 1,
            "success": true,
            "assemblyOrderNo": "PENS0986",
            "postedDocumentNo": "PENREG1005",
            "productItemNo": "M09-0166",
            "productDescription": "CUBO TECA",
            "errorMessage": ""
        }],
        "totalProcessed": 1
    }
}
```

#### 17. Assembly Orders API (50197)
**Endpoint**: `/assemblyOrders`  
**Tabla**: `Assembly Header`  
**Operaciones**: CRUD completo

Gestión individual de pedidos de ensamblaje.

**Campos clave**:
- `documentType` - Tipo de documento
- `no` - Número de pedido
- `itemNo` - Producto a ensamblar
- `quantity` - Cantidad (multiplica componentes)
- `quantityToAssemble` - Cantidad pendiente
- `locationCode` - Ubicación destino
- `status` - Estado del pedido

**SubPage**: Assembly Lines (líneas de componentes)

#### 18. Assembly Lines API (50198)
**Endpoint**: `/assemblyLines`  
**Tabla**: `Assembly Line`  
**Operaciones**: CRUD completo

Líneas de componentes de un pedido de ensamblaje.

**Campos principales**:
- `documentNo` - Número de pedido
- `lineNo` - Número de línea
- `type` - Tipo (Item/Resource)
- `no` - Código del componente
- `quantityPer` - Cantidad por unidad ✏️ **EDITABLE**
- `quantity` - Cantidad total (calculado automáticamente)
- `locationCode` - Ubicación origen

**Cálculo automático**: 
```
Line.Quantity = Header.Quantity × Line.Quantity per
```

#### 19. BOM Component API (50167)
**Endpoint**: `/bomComponents`  
**Tabla**: `BOM Component`

Lista de materiales (Bill of Materials).

#### 20. Items with BOM API (50168)
**Endpoint**: `/itemsWithBOM`

Productos que tienen lista de materiales definida.

#### 21. Material Disassembly API (50195, 50196)
**Endpoints**: `/materialDisassemblyOperations`, `/disassemblyComponents`  
**Operaciones**: Desensamblaje de productos

Desmonta un producto ensamblado en sus componentes.

**Ejemplo**:
```json
{
    "itemLedgerEntryNo": 62450,
    "quantity": 1,
    "componentsJson": "[...]",
    "destinationLocation": "F-MADERAS",
    "executeDisassembly": true
}
```

---

### 📊 **PROJECT - Proyectos y Tareas**

#### 22. Job API (50170)
**Endpoint**: `/jobs`  
**Tabla**: `Job`  
**Operaciones**: CRUD completo

Gestión de proyectos.

**Campos**:
- `no` - Número de proyecto
- `description` - Descripción
- `idEncargado` - ID del encargado
- `status` - Estado

#### 23. Job Task API (50154)
**Endpoint**: `/jobTasks`  
**Tabla**: `Job Task`

Tareas de proyectos.

**Campos**:
- `jobNo` - Número de proyecto
- `jobTaskNo` - Número de tarea
- `description` - Descripción
- `jobTaskType` - Tipo de tarea
- `idEncargado` - Encargado

#### 24. Job Journal Line API (50150)
**Endpoint**: `/jobJournalLines`  
**Tabla**: `Job Journal Line`

Líneas de diario de proyectos.

#### 25. Job Journal Batch API (50161)
**Endpoint**: `/jobJournalBatches`  
**Tabla**: `Job Journal Batch`

#### 26. Job Journal Template API (50160)
**Endpoint**: `/jobJournalTemplates`  
**Tabla**: `Job Journal Template`

#### 27. Post Job Journal API (50184)
**Endpoint**: `/postJobJournalCommands`  
**Operaciones**: Registro de diarios de proyecto

Permite registrar diarios de proyecto desde Power Apps.

**Campos**:
- `templateName` - Plantilla
- `batchName` - Lote
- `projectNo` - Proyecto
- `projectTaskNo` - Tarea
- `type` - Tipo (Item/Resource/G/L Account)
- `no` - Número
- `quantity` - Cantidad
- `unitCost` - Costo unitario
- `executePost` - Flag para ejecutar

#### 28. Job Warehouse API (50187)
**Endpoint**: `/jobWarehouseQuantities`  
**Tabla**: `GomJob Warehouse Quantity`

Inventario por tarea de proyecto.

---

### 🔄 **Transferencias y Consumos**

#### 29. Project Material Transfer API (50188, 50189)
**Endpoints**: 
- `/projectMaterialTransfers` - Líneas individuales
- `/projectMaterialTransferOperations` - Operaciones masivas

Transferencia de materiales entre proyectos o a almacén general.

**Ejemplo**:
```json
{
    "sourceEntryNo": 62386,
    "destinationType": "Project",
    "destinationProjectNo": "VN-C.15",
    "destinationTaskNo": "1.1",
    "quantity": 2
}
```

#### 30. Material Consumption API (50194)
**Endpoint**: `/materialConsumptionOperations`  
**Operaciones**: Consumo masivo de materiales

Registra consumo de materiales del almacén del proyecto a las tareas.

**Ejemplo**:
```json
{
    "itemLedgerEntryNos": "62386,62394,62396",
    "jobNo": "VN-B.27",
    "jobTaskNo": "1.1",
    "executeConsumption": true
}
```

---

### 🗂️ **Administración y Posting**

#### 31. Post Batch Singleton API (50162)
**Endpoint**: `/postBatchSingletons`

API unificada para postear diarios.

#### 32. Post Command API (50163)
**Endpoint**: `/postCommands`  
**Tabla**: `GJW Post Command`

Sistema de comandos asíncronos para posting.

**Estados**:
- `Pending` - Pendiente
- `Processing` - En proceso
- `Completed` - Completado
- `Failed` - Fallido

#### 33. Post Batch Web Service (50164)
**Endpoint**: `/postBatchWebService`

Servicio web para posting de lotes.

#### 34. Warehouse API (50126)
**Endpoint**: `/warehouse`  
**Tabla**: `Item Ledger Entry`

Vista de almacén con campos calculados.

---

## 🔧 Codeunits y Procesamiento

### Codeunits de Procesamiento Masivo

| ID | Nombre | Propósito |
|----|--------|-----------|
| **50114** | WorksDecomp Bulk | Procesamiento masivo de descomposición de obras |
| **50118** | Warehouse Qty Handler | Manejador de cantidades de almacén |
| **50124** | WorkLines Bulk | Creación masiva de líneas de obra |
| **50128** | ProdLines Bulk | Creación masiva de líneas de producción |
| **50159** | Item Transfer Bulk | **Transferencias masivas** de inventario |
| **50185** | Proj Material Transfer | Transferencias entre proyectos |
| **50186** | Material Consumption | **Consumo de materiales** en proyectos |
| **50195** | Material Disassembly | **Desensamblaje** de productos |
| **50197** | Create Assembly Handler | Handler de creación de ensamblajes |
| **50198** | **Assembly Bulk Processor** | **Procesador masivo de ensamblajes** |

### Codeunits de Eventos y Validaciones

| ID | Nombre | Propósito |
|----|--------|-----------|
| **50153** | Job Line Val Pre | Validación previa en líneas de proyecto |
| **50154** | Job Line Val Post | Validación posterior en líneas de proyecto |
| **50155** | Job Line Auto No | Autonumeración de líneas de proyecto |
| **50156** | Item Line Auto No | Autonumeración de líneas de inventario |
| **50157** | Item Jnl Post Handler | Manejador de posting de diarios |
| **50158** | Post Item Journal API | Posting de diarios desde API |
| **50181** | Job Jnl Line Subscriber | **Suscriptor para preservar costos** |

### Codeunit 50198 - Assembly Bulk Processor (Detalle)

**Funciones principales**:

1. **ProcessBulkAssembly** (Entry Point)
   - Recibe JSON de productos y componentes
   - Procesa cada producto individualmente
   - Retorna JSON con resultados

2. **TryProcessProduct**
   - Crea Assembly Order
   - Asigna dimensiones
   - Valida y libera
   - Postea el pedido
   - Maneja errores por producto

3. **CreateAssemblyOrder**
   - Crea el header
   - Valida campos principales
   - Asigna fechas y ubicación

4. **AssignDimensionsByLocation**
   - Asigna dimensiones según el almacén:
     - **F-MADERAS**: AC=PRO FABRICACION, CC=F-MADERAS
     - Otros: Copia dimensiones del header

5. **AssignTrackingToLines**
   - Crea Reservation Entries para componentes
   - Asigna números de lote desde Power Apps

6. **AssignTrackingToOutput**
   - Asigna lote al producto ensamblado

7. **ReleaseAssemblyOrder**
   - Libera el pedido para posting

8. **PostAssemblyOrder**
   - Postea usando Assembly-Post codeunit
   - Obtiene número de documento posteado

9. **ValidateAssemblyOrder**
   - Validaciones previas al posting

---

## 📊 Extensiones de Tablas

### Extensiones de Tablas Estándar

| ID | Tabla Extendida | Campos Agregados |
|----|-----------------|------------------|
| **50111** | GomJob Works Version | Campos de sistema |
| **50129** | GomJob Works Line | Estado de línea |
| **50130** | GomJob Works Decomposed Line | Estado de línea |
| **50133** | **Item Journal Line** | `Task No.`, `Source No.`, triggers |
| **50135** | Item Ledger Entry | Stock |
| **50136** | **Item Journal Batch** | **Trigger Post** (posting desde API) |
| **50137** | **Item Journal Line** | **Post This Line** (posting individual) |
| **50140** | Job | ID Encargado + sincronización |
| **50141** | GomJob Works | ID Encargado + sincronización |
| **50142** | Job Task | ID Encargado + sincronización |
| **50181** | **Job Journal Line** | **Preserve Unit Cost** (preservar costo) |

### Extensión 50133 - Item Journal Line (Detalle)

**Campos agregados**:
- `Task No.` (Code[20]) - Número de tarea de proyecto
- `Source No.` (Code[20]) - Número de origen (proveedor/cliente)

**Triggers**:

1. **OnAfterValidateEvent - "Item No."**
   - Si hay Task No., hereda dimensiones de la tarea
   - Asigna Shortcut Dimension 1 = Job No.
   - Asigna Shortcut Dimension 2 = Task No.

2. **OnAfterValidateEvent - "Location Code"**
   - Si Task No. existe, sobrescribe dimensiones
   - Previene que BC sobrescriba con las del location

### Extensión 50136 - Item Journal Batch (Trigger Post)

**Campo**: `GJW Trigger Post` (Boolean)

**Funcionalidad**:
- Al activar este campo, postea automáticamente el batch completo
- Usado por APIs para posting automático
- Limita a 1000 líneas máximo
- Manejo de errores con mensajes descriptivos

### Extensión 50137 - Item Journal Line (Post This Line)

**Campo**: `GJW Post This Line` (Boolean)

**Funcionalidad**:
- Postea una línea individual junto con todo su batch
- Usado para posting selectivo desde Power Apps

### Extensión 50181 - Job Journal Line (Preserve Unit Cost)

**Campo**: `GJW Preserve Unit Cost` (Decimal)

**Funcionalidad**:
- Preserva el costo unitario cuando se valida el campo "No."
- BC normalmente recalcula el costo desde la ficha del producto
- Este campo permite mantener el costo original del movimiento

---

## 🖼️ Extensiones de Páginas

### Extensiones de Páginas Estándar

| ID | Página Extendida | Propósito |
|----|------------------|-----------|
| **50131** | Works Line Page | Agregar columnas |
| **50132** | Works Decomp Page | Agregar columnas |
| **50134** | Item Journal Line Page | Task No. field |
| **50140** | Job Card | ID Encargado field |
| **50141** | Job List | ID Encargado field |
| **50142** | Works Page | ID Encargado field |
| **50143** | Job Task Lines | ID Encargado field |
| **50144** | Job Task Lines Subform | ID Encargado field |
| **50145** | Works Sub2 | ID Encargado field |
| **50146** | Works Sub3 | ID Encargado field |

---

## 🗄️ Tablas Personalizadas

### Tablas de Buffer/Temporales

| ID | Nombre | Propósito |
|----|--------|-----------|
| **50118** | Warehouse Qty Buffer | Buffer temporal para cantidades |
| **50148** | Item Avail Buffer (V1) | Buffer de disponibilidad |
| **50171** | Item Avail Buffer (V2) | Buffer mejorado |
| **50172** | Item Avail Location Buffer | Por ubicación |

### Tablas de Comandos

| ID | Nombre | Propósito |
|----|--------|-----------|
| **50163** | Post Command | Cola de comandos de posting |
| **50184** | Post Job Journal Command | Posting de diarios de proyecto |
| **50195** | Disassembly Components | Componentes de desensamblaje |

---

## 🔒 Permisos

### Permission Set 50100 - "Adelante API Permission"

Otorga permisos completos (RIMD) sobre:

**Tablas**:
- Item Journal Line, Batch, Template
- Job Ledger Entry, Journal Line, Batch, Template
- Item Ledger Entry, Item, Location
- Job Task, Job
- Assembly Header, Assembly Line
- Reservation Entry
- GomJob Works, Works Line, Decomposed Lines
- GomJob Warehouse Quantity
- Todas las tablas custom (50xxx)

**Páginas API**:
- Todas las páginas API (50xxx) - Execute permission

---

## 💻 Integración con Power Apps

### Colecciones Principales

#### Para Assembly (Ensamblaje):

**colDESProductos**:
```javascript
{
    IDPro: 1,
    productItemNo: "M09-0166",
    productDescription: "CUBO TECA",
    cantidad: 2,              // Quantity (Header - Tabla 900)
    almacenDestino: "VN-B.27",
    unitOfMeasure: "M3"
}
```

**colDESProductosDET**:
```javascript
{
    IDPro: 1,
    componentItemNo: "M09-0033",
    componentDescription: "MADERA TECA TROZA",
    componentQty: 0.1,         // Quantity per (Line - Tabla 901)
    qtyTotal: 0.2,             // Calculado: cantidad × componentQty
    loteseleccionado: 339017,  // Lot tracking
    almacenOrigen: "F-MADERAS",
    type: "Item",
    unitOfMeasure: "M3"
}
```

#### Para Transferencias:

**colTransfers**:
```javascript
{
    itemNo: "M01-0147",
    locationCode: "ALM-GRAL",
    newLocationCode: "VN-B.27",
    quantity: 5,
    taskNo: "001",
    description: "Transfer to project",
    appliesFromEntry: 62450
}
```

### Patrón de Llamada a APIs

```javascript
// 1. Validar datos
If(CountRows(colDESProductos) = 0; Exit());;

// 2. Mostrar indicador de carga
Set(varCargando; true);;

// 3. Llamar al API
ClearCollect(
    colResultadoAPI;
    Patch('assemblyBulkOperations (adelante/production/v1.0)';
       Defaults('assemblyBulkOperations (adelante/production/v1.0)');{
            productsJson: JSON(colDESProductos; JSONFormat.IgnoreBinaryData);
            componentsJson: JSON(colDESProductosDET; JSONFormat.IgnoreBinaryData);
            ejecutar: true
        })
);;

// 4. Parsear resultado
Set(varResultJson; ParseJSON(First(colResultadoAPI).resultado));;

// 5. Procesar resultados
ClearCollect(
    colResultados;
    ForAll(
        Table(varResultJson.results);
        {
            IDPro: Value(Text(ThisRecord.Value.IDPro));
            Success: Boolean(ThisRecord.Value.success);
            AssemblyOrderNo: Text(ThisRecord.Value.assemblyOrderNo);
            PostedDocNo: Text(ThisRecord.Value.postedDocumentNo);
            ErrorMessage: Text(ThisRecord.Value.errorMessage)
        }
    )
);;

// 6. Ocultar carga
Set(varCargando; false);;

// 7. Mostrar resumen
Notify(
    "✅ Procesados: " & CountRows(Filter(colResultados; Success = true));
    NotificationType.Success
);;
```

---

## 📋 Casos de Uso

### Caso 1: Crear Assembly Order desde Power Apps

1. Usuario selecciona producto en Power Apps
2. Power Apps carga BOM del producto
3. Usuario selecciona lotes para cada componente
4. Usuario edita cantidades:
   - `cantidad` (Header): Cuántos productos ensamblar
   - `componentQty` (Line): Cantidad de componente por producto
5. Power Apps envía datos al API
6. BC crea Assembly Order, asigna tracking, postea
7. Power Apps muestra número de pedido posteado

### Caso 2: Transferir materiales entre proyectos

1. Power Apps consulta materiales en almacén del proyecto (Item Ledger)
2. Usuario selecciona materiales a transferir
3. Usuario elige proyecto destino y tarea
4. Power Apps llama a `/projectMaterialTransferOperations`
5. BC crea líneas en Item Journal con Entry Type = Transfer
6. BC asigna nuevas dimensiones (Job No., Task No.)
7. Power Apps puede postear el diario automáticamente

### Caso 3: Consumir materiales de obra

1. Power Apps muestra inventario del almacén del proyecto
2. Usuario selecciona materiales a consumir
3. Usuario elige tarea específica
4. Power Apps llama a `/materialConsumptionOperations`
5. BC crea y postea Job Journal Lines
6. Job Ledger Entries quedan registrados
7. Inventario se reduce en el almacén del proyecto

### Caso 4: Desensambleaje de producto

1. Usuario tiene un producto ensamblado en inventario
2. Power Apps consulta BOM del producto
3. Usuario decide desensamblar 1 unidad
4. Power Apps llama a `/materialDisassemblyOperations`
5. BC:
   - Crea ajuste negativo del producto ensamblado
   - Crea ajustes positivos de cada componente
   - Aplica lot tracking si corresponde
   - Postea ambos diarios
6. Resultado: Producto desaparece, componentes reaparecen

---

## 🚀 Guía de Despliegue

### Prerrequisitos

- Microsoft Dynamics 365 Business Central (Cloud/On-Premise)
- Permisos de administrador
- Visual Studio Code con AL Language Extension

### Instalación

1. **Clonar repositorio**:
```powershell
git clone https://github.com/adelante/businesscentral-extensions.git
cd businesscentral-extensions
```

2. **Configurar launch.json**:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Your BC Server",
            "type": "al",
            "request": "launch",
            "server": "https://businesscentral.dynamics.com",
            "serverInstance": "your-instance",
            "authentication": "AAD",
            "startupObjectId": 50110,
            "startupObjectType": "Page"
        }
    ]
}
```

3. **Descargar símbolos**:
```
AL: Download Symbols
```

4. **Compilar y publicar**:
```
F5 (Visual Studio Code)
```

### Configuración Post-Instalación

1. **Asignar permisos**:
   - Ir a "Permission Sets"
   - Buscar "ADELANTE API PERMISSION"
   - Asignar a los usuarios que usarán las APIs

2. **Configurar dimensiones**:
   - Verificar que AC (Shortcut Dimension 1) existe
   - Verificar que CC (Shortcut Dimension 2) existe
   - Configurar valores de dimensión según proyectos

3. **Configurar locations**:
   - Asignar dimensiones a locations si es necesario
   - Configurar F-MADERAS con las dimensiones requeridas

4. **Configurar Assembly Setup**:
   - Definir serie numérica para Assembly Orders
   - Configurar Assembly Order Nos.

### Integración con Power Apps

1. **Agregar conectores personalizados**:
   - Crear conector para cada grupo de API
   - Base URL: `https://api.businesscentral.dynamics.com/v2.0/{tenant}/Production/api/adelante`
   - Autenticación: OAuth 2.0 (Azure AD)

2. **Configurar autenticación**:
   - Registrar aplicación en Azure AD
   - Agregar permisos API de Dynamics 365 Business Central
   - Configurar redirect URLs

3. **Probar conexión**:
   - Crear app de prueba en Power Apps
   - Agregar conector
   - Probar operaciones GET

---

## 📞 Soporte y Mantenimiento

### Logs y Diagnóstico

Para troubleshooting, revisar:

1. **Job Queue Log Entries** - Trabajos en cola
2. **Item Ledger Entries** - Movimientos de inventario
3. **Job Ledger Entries** - Movimientos de proyectos
4. **Reservation Entries** - Tracking de lotes
5. **Error Messages** - En la tabla de log de BC

### Monitoreo de Performance

APIs que pueden ser lentas con grandes volúmenes:

- `/itemLedgerEntriesWithTasks` - Filtrar por fecha
- `/jobWarehouseQuantities` - Filtrar por proyecto
- `/gomJobWorksDecomposedRead` - Usar solo en campo

### Actualizaciones

Para actualizar la extensión:

1. Incrementar versión en `app.json`
2. Compilar nueva versión
3. Publicar en ambiente de pruebas
4. Sincronizar esquema de BD si hay cambios de tablas
5. Probar APIs críticas
6. Deploy a producción

---

## 📄 Documentación Adicional

- [API-ItemTransfer-Bulk.md](API-ItemTransfer-Bulk.md) - Transferencias masivas
- [API-TransferenciaMateriales.md](API-TransferenciaMateriales.md) - Transferencias entre proyectos
- [API-PresupuestoGeneral-Bulk.md](API-PresupuestoGeneral-Bulk.md) - Presupuestos
- [PowerApps-AssemblyBulk.md](PowerApps-AssemblyBulk.md) - Integración ensamblaje
- [VERIFICAR-ASSEMBLY.md](VERIFICAR-ASSEMBLY.md) - Verificación de Assembly Orders

---

## 🏆 Mejores Prácticas

### Para Desarrollo

1. **Siempre usar Validate()** en campos críticos
2. **Manejar errores con try-catch** en operaciones masivas
3. **Usar transacciones** con Commit() apropiadamente
4. **Documentar parámetros JSON** con ejemplos
5. **Probar con datos reales** antes de deploy

### Para APIs

1. **Usar ODataKeyFields** apropiados
2. **Limitar campos devueltos** en queries grandes
3. **Implementar paginación** cuando sea necesario
4. **Validar permisos** en cada endpoint
5. **Retornar mensajes de error descriptivos**

### Para Power Apps

1. **Cachear datos estáticos** (BOM, Items)
2. **Validar en cliente** antes de llamar API
3. **Mostrar progreso** en operaciones largas
4. **Manejar timeouts** con reintentos
5. **Logging de errores** para diagnóstico

---

## 📊 Estadísticas del Proyecto

- **Total de archivos AL**: 100+
- **Total de APIs**: 70+
- **Total de Codeunits**: 25+
- **Total de extensiones de tablas**: 15+
- **Total de tablas custom**: 10+
- **Líneas de código**: ~15,000+

---

**Última actualización**: 26 de enero de 2026  
**Versión del documento**: 1.0  
**Autor**: Adelante Desarrollos  

---

*Para consultas o soporte, contactar al equipo de desarrollo.*
