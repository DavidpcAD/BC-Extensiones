# API de Pedidos de Compra - Documentación

## Descripción General
Esta API permite gestionar el proceso completo de recepción y facturación de Pedidos de Compra desde Power Apps o cualquier aplicación externa.

## Endpoints Disponibles

### 1. Listar Pedidos de Compra
**Endpoint**: `GET /api/adelante/purchasing/v1.0/purchaseOrders`

**Descripción**: Obtiene la lista de pedidos de compra (solo tipo Order)

**Filtros comunes**:
```
?$filter=status eq 'Open'
?$filter=buyFromVendorNo eq 'VENDOR001'
?$filter=postingDate ge 2026-01-01
```

**Respuesta ejemplo**:
```json
{
  "value": [
    {
      "id": "12345678-1234-1234-1234-123456789012",
      "no": "CP-000026",
      "buyFromVendorNo": "PROV-000051",
      "buyFromVendorName": "ACEROS ABONOS AGRO S.A.",
      "documentDate": "2025-08-05",
      "postingDate": "2025-08-05",
      "status": "Open",
      "vendorInvoiceNo": "",
      "amount": 3921502.95,
      "amountIncludingVAT": 4431298.33,
      "completelyReceived": false
    }
  ]
}
```

---

### 2. Obtener Líneas de un Pedido
**Endpoint**: `GET /api/adelante/purchasing/v1.0/purchaseLines`

**Filtro por documento**:
```
?$filter=documentNo eq 'CP-000026'
```

**Respuesta ejemplo**:
```json
{
  "value": [
    {
      "id": "87654321-4321-4321-4321-210987654321",
      "documentType": "Order",
      "documentNo": "CP-000026",
      "lineNo": 10000,
      "type": "Item",
      "no": "ITEM-001",
      "description": "Acero Estructural",
      "quantity": 100,
      "quantityReceived": 0,
      "quantityInvoiced": 0,
      "qtyToReceive": 0,
      "qtyToInvoice": 0,
      "outstandingQuantity": 100,
      "directUnitCost": 150.50,
      "lineAmount": 15050.00,
      "vatPercent": 13,
      "locationCode": "ALMACEN-01"
    }
  ]
}
```

---

### 3. Registrar Pedido (Receive + Invoice)
**Endpoint**: `PATCH /api/adelante/purchasing/v1.0/postPurchaseOrders(1)`

**Método**: PATCH  
**Content-Type**: application/json

**Request Body**:
```json
{
  "requestJSON": "{\"purchaseOrderNo\":\"CP-000026\",\"vendorInvoiceNo\":\"FAC-12345\",\"documentDate\":\"2026-02-02\",\"postingDate\":\"2026-02-02\",\"lines\":[{\"lineSystemId\":\"87654321-4321-4321-4321-210987654321\",\"qtyToReceive\":8},{\"lineSystemId\":\"11111111-2222-3333-4444-555555555555\",\"qtyToReceive\":5}]}",
  "execute": true
}
```

**Estructura del requestJSON (decodificado)**:
```json
{
  "purchaseOrderNo": "CP-000026",
  "vendorInvoiceNo": "FAC-12345",
  "documentDate": "2026-02-02",
  "postingDate": "2026-02-02",
  "lines": [
    {
      "lineSystemId": "87654321-4321-4321-4321-210987654321",
      "qtyToReceive": 8
    },
    {
      "lineSystemId": "11111111-2222-3333-4444-555555555555",
      "qtyToReceive": 5
    }
  ]
}
```

**Response exitoso**:
```json
{
  "id": 1,
  "requestJSON": "...",
  "execute": true,
  "responseJSON": "{\"posted\":true,\"purchaseOrderNo\":\"CP-000026\",\"postedReceiptNo\":\"RCP-000123\",\"postedInvoiceNo\":\"INV-000456\",\"linesProcessed\":2,\"message\":\"✅ Pedido CP-000026 registrado correctamente. Recibo: RCP-000123, Factura: INV-000456\"}"
}
```

**Response error**:
```json
{
  "id": 1,
  "requestJSON": "...",
  "execute": true,
  "responseJSON": "{\"posted\":false,\"error\":\"El pedido CP-000026 no está en estado Open (estado actual: Released)\"}"
}
```

---

## Ejemplo de Uso desde Power Apps

### 1. Obtener Pedidos Abiertos
```powerapps
ClearCollect(
    colPedidosAbiertos,
    Filter(
        'purchaseOrders (adelante/purchasing/v1.0)',
        status = "Open"
    )
)
```

### 2. Obtener Líneas de un Pedido Seleccionado
```powerapps
ClearCollect(
    colLineasPedido,
    Filter(
        'purchaseLines (adelante/purchasing/v1.0)',
        documentNo = Gallery_Pedidos.Selected.no
    )
)
```

### 3. Registrar Pedido
```powerapps
// Variables previas
Set(_purchaseOrderNo, Gallery_Pedidos.Selected.no);
Set(_vendorInvoiceNo, TextInput_FacturaProveedor.Text);

// Construir JSON de líneas
Set(
    _linesJSON,
    "[" &
        Concat(
            Filter(colLineasPedido, qtyToReceiveInput > 0),
            "{\"lineSystemId\":\"" & Text(id) & "\",\"qtyToReceive\":" & qtyToReceiveInput & "}",
            ","
        ) &
    "]"
);

// Construir request completo
Set(
    _requestJSON,
    "{" &
        """purchaseOrderNo"":""" & _purchaseOrderNo & """," &
        """vendorInvoiceNo"":""" & _vendorInvoiceNo & """," &
        """documentDate"":""" & Text(Today(), "yyyy-mm-dd") & """," &
        """postingDate"":""" & Text(Today(), "yyyy-mm-dd") & """," &
        """lines"":" & _linesJSON &
    "}"
);

// Ejecutar posting
Set(
    _resultado,
    Patch(
        'postPurchaseOrders (adelante/purchasing/v1.0)',
        First('postPurchaseOrders (adelante/purchasing/v1.0)'),
        {
            requestJSON: _requestJSON,
            execute: true
        }
    )
);

// Parsear respuesta
Set(_response, ParseJSON(_resultado.responseJSON));

If(
    _response.posted = true,
    Notify("✅ " & _response.message, NotificationType.Success, 8000),
    Notify("❌ Error: " & _response.error, NotificationType.Error, 12000)
);
```

---

## Ejemplo de llamada HTTP (Postman/cURL)

### Autenticación
```
Authorization: Bearer {access_token}
```

### Request PATCH
```http
PATCH https://api.businesscentral.dynamics.com/v2.0/{tenant}/SBX_ProdCopy_25_5/api/adelante/purchasing/v1.0/postPurchaseOrders(1)
Content-Type: application/json

{
  "requestJSON": "{\"purchaseOrderNo\":\"CP-000026\",\"vendorInvoiceNo\":\"FAC-12345\",\"documentDate\":\"2026-02-02\",\"postingDate\":\"2026-02-02\",\"lines\":[{\"lineSystemId\":\"87654321-4321-4321-4321-210987654321\",\"qtyToReceive\":50}]}",
  "execute": true
}
```

---

## Validaciones Implementadas

1. **Pedido debe existir y ser tipo Order**
2. **Pedido debe estar en estado Open**
3. **vendorInvoiceNo es obligatorio**
4. **qtyToReceive no puede exceder la cantidad pendiente**:
   - `qtyToReceive <= (Quantity - Quantity Received)`
5. **Todas las líneas deben tener SystemId válido**
6. **Al menos una línea debe procesarse**

---

## Mensajes de Error Comunes

| Error | Significado |
|-------|-------------|
| `JSON inválido` | El formato del JSON no es correcto |
| `purchaseOrderNo es obligatorio` | Falta el número de pedido |
| `vendorInvoiceNo es obligatorio` | Falta el número de factura del proveedor |
| `Pedido de compra X no encontrado` | El pedido no existe |
| `El pedido X no está en estado Open` | El pedido ya fue liberado/registrado |
| `qtyToReceive (X) excede la cantidad pendiente (Y)` | La cantidad a recibir es mayor a la disponible |
| `lineSystemId es obligatorio para cada línea` | Falta el ID de la línea |

---

## Permisos Necesarios

El usuario que ejecute la API debe tener asignado el **PermissionSet**:
- `GJW Purchase API Access` (ID: 50201)

O tener permisos equivalentes sobre:
- Purchase Header (RIMD)
- Purchase Line (RIMD)
- Purch. Rcpt. Header (R)
- Purch. Inv. Header (R)
- Codeunit "Purch.-Post" (Execute)

---

## Notas Importantes

1. **El proceso es transaccional**: Si alguna validación falla, no se registra nada
2. **Se crean dos documentos**: Recibo de Compra + Factura de Compra
3. **Los números de documentos se generan automáticamente** según las series de numeración configuradas
4. **Después del posting exitoso, el pedido puede quedar**:
   - Completamente cerrado (si se recibió/facturó todo)
   - Parcialmente recibido (si quedan cantidades pendientes)
5. **Las dimensiones del encabezado se copian a las líneas automáticamente**

---

## Archivos Creados

```
src/
├── Pages/
│   ├── 50200-PurchaseOrdersAPI.al
│   ├── 50201-PurchaseLinesAPI.al
│   └── 50202-PostPurchaseOrderAPI.al
├── Codeunits/
│   └── 50200-PurchasePostProcessor.al
└── Permissions/
    └── 50201-PurchaseAPIAccess.al
```
