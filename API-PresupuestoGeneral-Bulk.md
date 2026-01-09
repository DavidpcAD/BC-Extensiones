# API de Presupuesto General (Works Lines) - Carga Masiva

## Descripción
Esta API permite enviar todas las líneas del presupuesto general de una obra de una sola vez. **Solo inserta nuevas líneas** (no elimina las anteriores). Ideal para Power Apps que maneja versiones (REESTUDIO #).

## Archivos Involucrados

### Existentes (ya implementados)
- **50124-WorkLinesBulk.al** - Codeunit con lógica de importación masiva
- **50125-WorkLinesBulkUnbound.al** - Wrapper unbound
- **50127-WorkLinesBulkAPI.al** - API con método BulkImport

### Nuevo
- **50190-WorkLinesBulkSingleton.al** - API singleton simplificada (solo inserta)

## Endpoint Principal

**Endpoint:** `/api/adelante/construction/v1.0/workLineBulks`

**Método:** PATCH

**Comportamiento:**
1. Valida que se haya especificado Works No.
2. Inserta todas las líneas del JSON (sin eliminar las anteriores)
3. Retorna el resultado con contadores

**Ideal para:** Power Apps con versionado automático (REESTUDIO1, REESTUDIO2, etc.)

## Estructura de Datos

### Campos de Work Line
```json
{
  "worksNo": "OBRA-001",           // Requerido
  "versionCode": "V1",             // Opcional
  "lineNo": 10000,                 // Se genera automático si no se envía
  "lineType": "Item",              // Item, Resource, GLAccount, etc.
  "taskType": "Posting",           // Posting, Heading, Total
  "taskNo": "1.1",                 // Código de tarea
  "description": "Materiales",     
  "quantity": 100.0,
  "unitAmount": 25.50,
  "lineAmount": 2550.0,
  "quantityToProduce": 100.0,
  "unitOfMeasure": "UND",
  "codeOrder": "001",
  "idEncargado": 0,
  "reStudy": false
}
```

## Ejemplos de Uso

### Enviar presupuesto completo (reemplaza el anterior)

```http
PATCH /api/adelante/construction/v1.0/workLineBulks(1)
Content-Type: application/json

{
  "worksNo": "VN-B.27",
  "lineasJSON": "[{\"worksNo\":\"VN-B.27\",\"lineType\":\"Item\",\"taskType\":\"Posting\",\"taskNo\":\"1.1\",\"description\":\"Cemento\",\"quantity\":50,\"unitAmount\":25.5},{\"worksNo\":\"VN-B.27\",\"lineType\":\"Item\",\"taskType\":\"Posting\",\"taskNo\":\"1.2\",\"description\":\"Arena\",\"quantity\":100,\"unitAmount\":15.0}]",
  "ejecutar": true
}
```

**Respuesta:**
```json
{
  "id": 1,
  "worksNo": "VN-B.27",
  "resultado": "Eliminadas: 15 | Insertados: 2 | Actualizados: 0 | Eliminados: 0 | Errores: 0"
}
```

### Ejemplo con presupuesto completo

```json
{
  "worksNo": "VN-B.27",
  "lineasJSON": "[
    {
      \"worksNo\": \"VN-B.27\",
      \"versionCode\": \"V1\",
      \"lineType\": \"Heading\",
      \"taskType\": \"Heading\",
      \"taskNo\": \"1\",
      \"description\": \"ESTRUCTURA\"
    },
    {
      \"worksNo\": \"VN-B.27\",
      \"versionCode\": \"V1\",
      \"lineType\": \"Item\",
      \"taskType\": \"Posting\",
      \"taskNo\": \"1.1\",
      \"description\": \"VARILLA #3 DEFORME G40\",
      \"quantity\": 1000.0,
      \"unitAmount\": 1.228,
      \"lineAmount\": 1228.0,
      \"unitOfMeasure\": \"UND\"
    },
    {
      \"worksNo\": \"VN-B.27\",
      \"versionCode\": \"V1\",
      \"lineType\": \"Item\",
      \"taskType\": \"Posting\",
      \"taskNo\": \"1.2\",
      \"description\": \"CEMENTO PORTLAND TIPO I\",
      \"quantity\": 500.0,
      \"unitAmount\": 8.5,
      \"lineAmount\": 4250.0,
      \"unitOfMeasure\": \"BOLSA\"
    },
    {
      \"worksNo\": \"VN-B.27\",
      \"versionCode\": \"V1\",
      \"lineType\": \"Total\",
      \"taskType\": \"Total\",
      \"taskNo\": \"1.TOTAL\",
      \"description\": \"TOTAL ESTRUCTURA\",
      \"lineAmount\": 5478.0
    }
  ]",
  "ejecutar": true
}
```

## Flujo de Trabajo Recomendado

1. **Exportar líneas existentes** (si hay):
   ```http
   GET /api/adelante/construction/v1.0/workLines?$filter=worksNo eq 'OBRA-001'
   ```

2. **Preparar JSON con cambios**:
   - Nuevas líneas: sin `id`
   - Ediciones: con `id` del SystemId
   - Eliminaciones: solo el `id`

3. **Enviar operación bulk**:
   ```http
   PATCH /api/adelante/construction/v1.0/workLineBulks(1)
   ```

4. **Revisar resultado**:
   - El campo `resultado` indica insertados/actualizados/eliminados/errores

## Valores de Enums

### Line Type (Tipo de Línea)
- `Item` - Artículo
- `Resource` - Recurso
- `GLAccount` - Cuenta contable
- `Text` - Texto

### Task Type (Tipo de Tarea)
- `Posting` - Línea de registro
- `Heading` - Encabezado
- `Total` - Total

4. **Commits Automáticos**: Cada inserción exitosa hace commit para evitar pérdida de datos en caso de error

5. **Versiones**: El campo `versionCode` es opcional y se usa para control de versiones de presupuestos

6. **Performance**: Esta API está optimizada para enviar cientos o miles de líneas de una sola vez

## Valores de Enums

### Error: "worksNo es obligatorio"
- Asegúrate de que todas las líneas tengan el campo `worksNo`

### Error: "No se p

1. **Preparar JSON con todas las líneas del presupuesto**:
   - Incluir todas las líneas que debe tener la obra
   - No es necesario obtener las existentes (se borran automáticamente)

2. **Enviar operación bulk**:
   ```http
   PATCH /api/adelante/construction/v1.0/workLineBulks(1)
   {
     "worksNo": "VN-B.27",
     "lineasJSON": "[...]",
     "ejecutar": true
   }
   ```

3. **Revisar resultado**:
   - El campo `resultado` indica cuántas líneas antiguas se eliminaron y cuántas nuevas se insertaron

## Consideraciones Importantes

⚠️ **ATENCIÓN**: Esta API **elimina todas las líneas existentes** de la obra antes de insertar las nuevas. Asegúrate de enviar el presupuesto completo en cada llamada.

1. **Works No. Obligatorio**: Siempre debes especificar `worksNo` en el request principal

2. **Reemplazo Total**: No es una actualización incremental, es un reemplazo completo

3. **Line No. Automático**: Si no se envía `lineNo`, se genera automáticamente (incrementos de 10000)