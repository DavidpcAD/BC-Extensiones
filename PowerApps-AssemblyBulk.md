# Assembly Bulk API - Power Apps Integration

## 📋 Descripción
API para crear y postear múltiples Assembly Orders (órdenes de ensamblaje) desde Power Apps con asignación de lotes.

## 🔌 Endpoint
```
POST https://api.businesscentral.dynamics.com/v2.0/{tenant}/Production/api/adelante/production/v1.0/assemblyBulkOperations
```

## 📥 Request Body

### Estructura JSON
```json
{
    "productsJson": "[{\"IDPro\":1,\"cantidad\":2,\"productItemNo\":\"M09-0168\",\"productDescription\":\"COSTILLA TECA\",\"almacenDestino\":\"F-PRODUCTO\",\"unitOfMeasure\":\"M3\"}]",
    "componentsJson": "[{\"IDPro\":1,\"almacenOrigen\":\"F-MADERAS\",\"componentItemNo\":\"M09-0033\",\"componentQty\":0.1,\"loteseleccionado\":\"339015\",\"type\":\"Item\",\"unitOfMeasure\":\"M3\"}]"
}
```

### Products JSON Fields
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `IDPro` | Integer | ✅ | Identificador único del producto |
| `cantidad` | Decimal | ✅ | Cantidad a ensamblar |
| `productItemNo` | Text | ✅ | Código del artículo a producir |
| `productDescription` | Text | ❌ | Descripción del producto |
| `almacenDestino` | Text | ⚠️ | Almacén donde quedará el producto ensamblado |
| `unitOfMeasure` | Text | ❌ | Unidad de medida |

### Components JSON Fields
| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `IDPro` | Integer | ✅ | Relaciona con el producto |
| `componentItemNo` | Text | ✅ | Código del componente |
| `componentQty` | Decimal | ✅ | Cantidad del componente |
| `type` | Text | ✅ | "Item" o "Resource" |
| `almacenOrigen` | Text | ❌ | Código de ubicación |
| `loteseleccionado` | Text | ⚠️ | Lote (requerido si Item tiene tracking) |
| `unitOfMeasure` | Text | ❌ | Unidad de medida |

## 📤 Response

### Success Response
```json
{
    "resultJson": "{\"results\":[{\"IDPro\":1,\"success\":true,\"assemblyOrderNo\":\"AO-001\",\"postedDocumentNo\":\"PAO-001\",\"productItemNo\":\"M09-0168\",\"productDescription\":\"COSTILLA TECA\",\"errorMessage\":\"\"}],\"totalProcessed\":1}",
    "success": true,
    "totalProcessed": 1
}
```

### Error Response
```json
{
    "resultJson": "{\"results\":[{\"IDPro\":1,\"success\":false,\"assemblyOrderNo\":\"AO-001\",\"postedDocumentNo\":\"\",\"productItemNo\":\"M09-0168\",\"errorMessage\":\"Item M09-0033 does not have Item Tracking Code configured\"}],\"totalProcessed\":1}",
    "success": true,
    "totalProcessed": 1
}
```

## 💻 Power Apps Code

### Ejemplo Completo
```javascript
// 1. Preparar colecciones
ClearCollect(
    colProductos,
    {IDPro: 1, cantidad: 2, productItemNo: "M09-0168", productDescription: "COSTILLA TECA", unitOfMeasure: "M3"},
    {IDPro: 2, cantidad: 2, productItemNo: "M09-0166", productDescription: "CUBO TECA", unitOfMeasure: "M3"}
);

ClearCollect(
    colComponentes,
    {IDPro: 1, almacenOrigen: "F-MADERAS", componentItemNo: "M09-0033", componentQty: 0.1, loteseleccionado: "339015", type: "Item", unitOfMeasure: "M3"},
    {IDPro: 2, almacenOrigen: "F-MADERAS", componentItemNo: "M09-0033", componentQty: 0.1, loteseleccionado: "339033", type: "Item", unitOfMeasure: "M3"},
    {IDPro: 2, almacenOrigen: "F-MADERAS", componentItemNo: "EQ-0133", componentQty: 1, loteseleccionado: "", type: "Resource", unitOfMeasure: "M"}
);

// 2. Llamar al API
ClearCollect(
    colResultadoAPI,
    'adelante-production-v1.0'.assemblyBulkOperations.POST({
        productsJson: JSON(colProductos, JSONFormat.IgnoreBinaryData),
        componentsJson: JSON(colComponentes, JSONFormat.IgnoreBinaryData)
    })
);

// 3. Parsear resultado
Set(varResultJson, ParseJSON(First(colResultadoAPI).resultJson));

// 4. Crear colección de resultados individuales
ClearCollect(
    colResultados,
    ForAll(
        varResultJson.results,
        {
            IDPro: Value(Text(ThisRecord.IDPro)),
            Success: Boolean(ThisRecord.success),
            AssemblyOrderNo: Text(ThisRecord.assemblyOrderNo),
            PostedDocNo: Text(ThisRecord.postedDocumentNo),
            ProductItemNo: Text(ThisRecord.productItemNo),
            ErrorMessage: Text(ThisRecord.errorMessage)
        }
    )
);

// 5. Mostrar notificaciones
ForAll(
    colResultados,
    If(
        ThisRecord.Success,
        Notify(
            "✅ Pedido " & ThisRecord.IDPro & " completado: " & ThisRecord.PostedDocNo,
            NotificationType.Success
        ),
        Notify(
            "❌ Error en pedido " & ThisRecord.IDPro & ": " & ThisRecord.ErrorMessage,
            NotificationType.Error
        )
    )
);
```

### Botón de Envío
```javascript
OnSelect = 
// Validar que hay datos
If(
    CountRows(colProductos) = 0,
    Notify("No hay productos para procesar", NotificationType.Warning),
    CountRows(colComponentes) = 0,
    Notify("No hay componentes para procesar", NotificationType.Warning),
    
    // Procesar
    ClearCollect(
        colResultadoAPI,
        'adelante-production-v1.0'.assemblyBulkOperations.POST({
            productsJson: JSON(colProductos, JSONFormat.IgnoreBinaryData),
            componentsJson: JSON(colComponentes, JSONFormat.IgnoreBinaryData)
        })
    );
    
    // Mostrar resultado
    Set(varTotalProcesados, First(colResultadoAPI).totalProcessed);
    Notify(
        "Procesados: " & varTotalProcesados & " productos",
        NotificationType.Information
    )
)
```

### Gallery de Resultados
```javascript
Items = colResultados

// Icono condicional
Icon = If(ThisItem.Success, Icon.CheckBadge, Icon.CancelBadge)
IconColor = If(ThisItem.Success, Color.Green, Color.Red)

// Texto
Text = "Producto: " & ThisItem.ProductItemNo & 
       If(ThisItem.Success, 
          " ✅ Doc: " & ThisItem.PostedDocNo,
          " ❌ " & ThisItem.ErrorMessage)
```

## ⚠️ Validaciones Importantes

### En Business Central
1. **Assembly Setup**: "Assembly Order Nos." debe estar configurado
2. **Item Tracking**: Items deben tener "Item Tracking Code" si usan lotes
3. **Location Codes**: Deben existir en el sistema
4. **BOM**: El producto debe tener una BOM configurada (se valida automáticamente)

### En Power Apps
1. Validar que `loteseleccionado` no esté vacío para Items con tracking
2. Verificar que `type` sea exactamente "Item" o "Resource"
3. Asegurar que cada componente tenga su `IDPro` correcto

## 🔍 Troubleshooting

| Error | Causa | Solución |
|-------|-------|----------|
| "Invalid products JSON format" | JSON malformado | Verificar sintaxis JSON |
| "Item does not have Item Tracking Code configured" | Falta configuración de tracking | Agregar Item Tracking Code al item |
| "Invalid line type" | Type no es "Item" o "Resource" | Corregir el campo type |
| "Assembly Order has no component lines" | No hay componentes para ese IDPro | Verificar que IDPro coincida |
| "Quantity to Assemble must be greater than 0" | Cantidad inválida | Verificar campo cantidad > 0 |

## 📊 Flujo Completo

```
Power Apps
    │
    ├─ colProductos (3 productos con IDPro 1, 2, 3)
    ├─ colComponentes (5 componentes relacionados)
    │
    ▼
POST assemblyBulkOperations
    │
    ▼
Business Central - Assembly Bulk Processor
    │
    ├─ Para IDPro 1:
    │   ├─ Crear Assembly Order AO-001
    │   ├─ Crear línea Item con lote 339015
    │   ├─ Liberar pedido
    │   └─ Postear → PAO-001 ✅
    │
    ├─ Para IDPro 2:
    │   ├─ Crear Assembly Order AO-002
    │   ├─ Crear línea Item con lote 339033
    │   ├─ Crear línea Resource
    │   ├─ Liberar pedido
    │   └─ Postear → PAO-002 ✅
    │
    └─ Para IDPro 3:
        ├─ Crear Assembly Order AO-003
        ├─ Error: lote inválido ❌
        └─ Retornar error
    │
    ▼
Response JSON con resultados individuales
    │
    ▼
Power Apps - Mostrar resultados
```
