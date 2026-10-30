# Cargos de producto con grupo de IVA (exento) y pago con tarjeta — AdelanteAPI 1.2.24.0 / 1.2.25.0

Codeunit 50230 "Adelante PO Actions", publicado como web service **AdelantePO** (OData V4, S2S).

## El problema

Cuando la factura del transportista viene **exenta**, BC le ponía igual el 13% que trae por defecto
el Item Charge. Caso real: EASYBOX, factura **82120**, se registró como **CFR-011984** por
**₡15.905,88** cuando el papel es **₡14.076,00 exento** (₡1.829,88 de IVA que no existe).

## Por qué son acciones NUEVAS y no un parámetro opcional

AL no tiene parámetros opcionales y BC exige en el body **todos** los parámetros de la firma.
Probado en Sandbox el 30/10/2026 llamando `AdelantePO_GetOrderLines` con `{}`:

```
400  Expected a parameter with name 'orderNo' but it wasn't provided.
```

Si `vatProdPostingGroup` se agregaba a la firma de `PostChargeOnReceipts`, **todo cargo no exento**
(que la app manda sin ese campo) habría empezado a fallar. Por eso, igual que `SetRealizadoPor`,
va en un procedure aparte y las firmas que ya usa Producción **no cambian**.

## Acciones

| Acción | Cambio | Uso |
|---|---|---|
| `AdelantePO_PostChargeOnReceipts` | **Ninguno** (7 parámetros, igual que antes) | Cargo sobre recepciones ya registradas, IVA por defecto del Item Charge |
| `AdelantePO_PostChargeOnReceiptsWithVat` | **Nueva en 1.2.24.0** (+ `vatProdPostingGroup`) | Lo mismo, fijando el grupo de IVA de la línea de cargo (exento) |
| `AdelantePO_PostChargeOnReceiptsWithTarjeta` | **Nueva en 1.2.25.0** (+ `vatProdPostingGroup`, `paymentMethodCode`, `dimCode`, `dimValueCode`) | Lo mismo, y además pagado con tarjeta: forma de pago + dimensión del encabezado |
| `AdelantePO_AddChargeLine` | **Ninguno** | Línea de cargo en un pedido abierto |
| `AdelantePO_AddChargeLineWithVat` | **Nueva en 1.2.24.0** (+ `vatProdPostingGroup`) | Lo mismo, fijando el grupo de IVA de la línea de cargo |

Las acciones se encadenan: `PostChargeOnReceipts` → `…WithVat` (grupo `''`) → `…WithTarjeta`
(tarjeta `''`), que es la que tiene el cuerpo. Con los valores vacíos, cada una se comporta
exactamente igual que antes (1.2.23.0 / 1.2.24.0).

### `AdelantePO_PostChargeOnReceiptsWithVat`

```http
POST .../ODataV4/AdelantePO_PostChargeOnReceiptsWithVat?company={companyId}
Content-Type: application/json

{
  "chargeVendorNo": "PROV-0123",
  "itemChargeNo": "FLETE",
  "chargeAmount": 14076,
  "vendorInvoiceNo": "82120",
  "metodo": "Amount",
  "receiptLinesJson": "[{\"documentNo\":\"CR-000003\",\"lineNo\":10000}]",
  "postingDate": "2026-10-26",
  "vatProdPostingGroup": "EXENTO-BIENES"
}
```

Respuesta: `{ "value": "CFR-0xxxxx" }` (N.º de la factura registrada), igual que la original.

### `AdelantePO_PostChargeOnReceiptsWithTarjeta` (1.2.25.0)

Para los fletes de terceros (EasyBox, DHL, UPS) que se pagan con tarjeta con el mismo TM /
Gasto de Tarjeta que las órdenes de Amazon. Combina con el exento.

```http
POST .../ODataV4/AdelantePO_PostChargeOnReceiptsWithTarjeta?company={companyId}

{
  "chargeVendorNo": "PROV-0123",
  "itemChargeNo": "FLETE",
  "chargeAmount": 14076,
  "vendorInvoiceNo": "82120",
  "metodo": "Amount",
  "receiptLinesJson": "[{\"documentNo\":\"CR-000003\",\"lineNo\":10000}]",
  "postingDate": "2026-10-26",
  "vatProdPostingGroup": "EXENTO-BIENES",
  "paymentMethodCode": "TC LUIS RO",
  "dimCode": "TM",
  "dimValueCode": "G-GASTOS TARJETAS"
}
```

Los 11 parámetros son **requeridos** (BC no acepta que falte uno); la app manda `""` en los que
no apliquen:

| `vatProdPostingGroup` | `paymentMethodCode` / `dimCode` / `dimValueCode` | Resultado |
|---|---|---|
| `""` | los tres `""` | Igual que `PostChargeOnReceipts` |
| `"EXENTO-BIENES"` | los tres `""` | Igual que `…WithVat` (0%) |
| `""` | los tres con valor | IVA normal, pagado con tarjeta |
| `"EXENTO-BIENES"` | los tres con valor | Exento **y** pagado con tarjeta |
| cualquiera | **alguno** vacío y otro con valor | **Error**, no registra nada |

Con tarjeta, antes de registrar hace lo mismo que `SetTarjetaYDimension` (mismo helper,
`AplicarTarjetaYDimension`):

- `Payment Method Code` del encabezado = la tarjeta (tiene que existir en *Formas de pago*).
- La dimensión `dimCode = dimValueCode` en el encabezado (tiene que existir y no estar bloqueada),
  propagada a la línea de cargo con `UpdateAllLineDim`. Se aplica **después** de crear la línea,
  así la dimensión del encabezado gana sobre la que el Item Charge trae por defecto, igual que en
  las órdenes.
- El pedido del cargo es nuevo (Abierto): no se reabre ni se relanza nada, y no toca aprobaciones.

Respuesta: `{ "value": "CFR-0xxxxx" }`, igual que las otras.

### `AdelantePO_AddChargeLineWithVat`

```http
POST .../ODataV4/AdelantePO_AddChargeLineWithVat?company={companyId}

{ "orderNo": "CP-006400", "itemChargeNo": "FLETE", "description": "FLETE / TRANSPORTE",
  "quantity": 1, "directUnitCost": 14076, "vatProdPostingGroup": "EXENTO-BIENES" }
```

Respuesta: el N.º de línea, igual que `AddChargeLine`. Sigue siendo idempotente por `itemChargeNo`:
si el cargo ya está en el pedido, lo actualiza en vez de duplicarlo.

## Cómo se aplica el grupo (`AplicarGrupoIva`)

- `vatProdPostingGroup` **vacío** → no toca nada: línea nueva con el IVA del Item Charge, línea
  existente con el que ya tenía.
- Con valor → `Validate("VAT Prod. Posting Group")` **después** de validar el N.º del cargo (que
  pone el grupo por defecto) y **antes** de cantidad y costo, para que el `Direct Unit Cost` que
  manda la app quede tal cual.
- La combinación **VAT Bus. Posting Group del proveedor × grupo** tiene que existir en
  *Configuración registros IVA* (VAT Posting Setup). Para `EXENTO-BIENES` es la misma combinación a
  0% que usa el botón **Exonerar** de la app (`bcExonerarLineasPedido`). Si no existe, BC corta con
  un error que dice qué combinación falta y **no se registra nada** (la transacción del web
  service revierte también el pedido al transportista).

## Lado de la app (repo OrdenesCompras)

Commit `792d9de` en `main`: `bcPostChargeOnReceipts` (`lib/bc.ts`) llama a
`AdelantePO_PostChargeOnReceiptsWithVat` **solo** cuando el usuario marca **Exento** y manda
`vatProdPostingGroup` = `BC_IVA_GRUPO_EXENTO` (por defecto `EXENTO-BIENES`). Sin marcar, sigue
llamando a `AdelantePO_PostChargeOnReceipts` sin ese campo.

## Compatibilidad y orden de despliegue

| BC \ App | App vieja | App nueva, cargo normal | App nueva, cargo Exento |
|---|---|---|---|
| ≤ 1.2.23.0 | OK | OK | Falla con error claro (la acción no existe); no registra mal |
| 1.2.24.0 | OK | OK | OK, 0% |

Pago con tarjeta (rama de la app `cargo-pago-tarjeta`): usa `…WithTarjeta`, que existe desde
**1.2.25.0**. Con BC 1.2.24.0 o anterior, un cargo con tarjeta falla con error claro (la acción no
existe) y no registra nada; los cargos sin tarjeta no se ven afectados si siguen por
`PostChargeOnReceipts` / `…WithVat`.

Orden: **primero BC (1.2.24.0 para el exento, 1.2.25.0 para la tarjeta), después la app.** En Sandbox AdelanteAPI está publicada como Dev,
así que el upload PTE por `bc-deploy.py` falla ahí; en Production sí entra como PTE.

## Pruebas pendientes tras publicar

1. Cargo **Exento** (caso EASYBOX 82120): ₡14.076,00 tiene que registrarse sin IVA.
2. Cargo **normal**: sigue registrando con 13%.
3. Proveedor sin la combinación × `EXENTO-BIENES` en VAT Posting Setup: error claro, nada registrado.
4. Cargo **con tarjeta** (1.2.25.0): la factura registrada lleva la forma de pago TC * y la línea
   la dimensión TM = G-GASTOS TARJETAS; el movimiento de proveedor queda liquidado por la tarjeta,
   igual que una orden de Amazon.
5. Cargo **exento y con tarjeta** (EasyBox): las dos cosas a la vez.
6. Tarjeta a medias (forma de pago sin dimensión): error, nada registrado.
7. Una orden de Amazon con `SetTarjetaYDimension` sigue igual (se movió su lógica a
   `AplicarTarjetaYDimension`, sin cambiar el comportamiento).
