# Changelog - Versión 1.2.1.5

**Fecha:** 6 de febrero de 2026  
**Autor:** David PC (davidpc@adelante.cr)

## 🎯 Resumen de Cambios

Esta versión corrige el problema crítico donde las transferencias de materiales desde obras al almacén general no sumaban correctamente en el destino. También incluye mejoras en el API de consumo de materiales.

---

## 🔧 Cambios en Business Central

### 1. **Codeunit 50159 - Item Transfer Bulk** 
**Archivo:** `src/Codeunits/50159-ItemTransferBulk.al`

#### Problema:
- Transferencias obra→obra funcionaban correctamente
- Transferencias obra→almacén general solo restaban del origen, no sumaban en destino

#### Solución:
**a) Limpieza de campos de proyecto (Líneas 313-319)**
```al
// Limpiar campos de proyecto en origen si van a almacén general
if (NewJobNo = '') and (NewJobTaskNo = '') then begin
    ItemJnlLine."Job No." := '';
    ItemJnlLine."Job Task No." := '';
    ItemJnlLine."Task No." := '';
end;
```

**b) Uso del codeunit correcto (Línea 241)**
```al
// Cambio de "Item Jnl.-Post Line" a "Item Jnl.-Post Batch"
if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then
```

#### Resultado:
- ✅ Transferencias obra→almacén general ahora crean **ambos movimientos** (salida + entrada)
- ✅ Transferencias obra→obra siguen funcionando correctamente

---

### 2. **Material Consumption API**
**Archivos:**
- `src/Pages/50194-MaterialConsumpSingleton.al`
- `src/Codeunits/50186-MaterialConsumption.al`

#### Cambio:
El campo `documentNo` ahora es **obligatorio** en lugar de generar un GUID automáticamente.

#### Razón:
Permite trazabilidad desde PowerApps usando el número de Boleta de Entrega (BE000XXX).

#### Código PowerApps actualizado:
```powerapps
Set(_docNoConsumo; "BE" & Text(_BoletaEntrega.IDEntrega; "000000"));;

Patch(
    'materialConsumptionOperations (adelante/inventory/v1.0)';
    Defaults('materialConsumptionOperations (adelante/inventory/v1.0)');
    {
        itemLedgerEntryNos: varSelectedEntries;
        jobNo: _BoletaEntrega.IDObraBC;
        jobTaskNo: Text(First(colDETBoleta).TaskNo);
        documentNo: _docNoConsumo;  // ← NUEVO
        executeConsumption: true
    }
)
```

---

### 3. **Versión actualizada**
**Archivo:** `app.json`

```json
{
  "version": "1.2.1.5"
}
```

---

## 💻 Cambios en PowerApps

### 1. **Lógica de Devolución y Traslado**

#### Componentes:
- **Tab "Devolución"**: Devolver material consumido al almacén general (ALM-GRAL)
- **Tab "Traslado"**: Transferir material consumido a otra obra

#### Flujo implementado:

**PASO 1:** Devolución del proyecto (común para ambos modos)
```powerapps
Patch(
    'postJobJournals (adelante/project/v1.0)';
    {
        quantity: -_qtyDevolver;  // Negativo = devolución
        projectNo: _jobOrigen;
        projectTaskNo: _taskOrigen;
        locationCode: _jobOrigen;
    }
)
```

**PASO 2:** Transferencia al destino (solo si Devolución o Traslado)
```powerapps
If(_tipomovimiento="Traslado" || _tipomovimiento="Devolucion";
    // Construir JSON según destino
    If(_locDestino = "ALM-GRAL";
        // Sin campos de proyecto destino
        Set(varTransfersJSON; "[{...}]");
        ,
        // Con campos de proyecto destino
        Set(varTransfersJSON; "[{...newJobNo...newJobTaskNo...}]")
    )
)
```

#### Diferencias clave:

| Modo | Destino | JSON enviado |
|---|---|---|
| **Devolución** | ALM-GRAL | Sin `newJobNo`/`newJobTaskNo` |
| **Traslado** | Otra obra | Con `newJobNo`/`newJobTaskNo` |

---

## 📋 Archivos Modificados

### Business Central:
```
src/
├── Codeunits/
│   ├── 50159-ItemTransferBulk.al          [MODIFICADO]
│   └── 50186-MaterialConsumption.al       [MODIFICADO]
├── Pages/
│   └── 50194-MaterialConsumpSingleton.al  [MODIFICADO]
└── app.json                                [MODIFICADO]
```

### PowerApps:
- Botón Tab "Devolución": `Set(_tipomovimiento; "Devolucion")`
- Botón Tab "Traslado": `Set(_tipomovimiento; "Traslado")`
- Botón "Enviar": Lógica completa de devolución + transferencia

---

## 🧪 Casos de Prueba

### Caso 1: Devolución a almacén general
**Entrada:**
- Material consumido: M10-0047 CEMENTO INDUSTRIAL (3 KG)
- Proyecto origen: VN-C.01
- Destino: ALM-GRAL

**Resultado esperado:**
```
Job Ledger (VN-C.01):  -3 KG (devuelto)
Item Ledger (VN-C.01): 0 KG (sin cambio neto)
Item Ledger (ALM-GRAL): +3 KG ✅
```

### Caso 2: Traslado a otra obra
**Entrada:**
- Material consumido: M10-0047 CEMENTO INDUSTRIAL (2 KG)
- Proyecto origen: VN-C.01
- Destino: VN-B.27, Tarea "Fundaciones"

**Resultado esperado:**
```
Job Ledger (VN-C.01):  -2 KG (devuelto)
Item Ledger (VN-C.01): 0 KG (sin cambio neto)
Item Ledger (VN-B.27): +2 KG ✅ (vinculado a proyecto)
```

---

## 🚀 Instrucciones de Despliegue

### 1. Compilar extensión
```powershell
Ctrl+Shift+B  # En VS Code
```

### 2. Publicar al Sandbox
```powershell
# Desde VS Code: F5 o usar launch.json
# O manualmente:
Publish-BcContainerApp -containerName "SBX_ProdCopy_25_5" `
    -appFile "Default Publisher_AdelanteAPI_1.2.1.5.app" `
    -sync -install -upgrade
```

### 3. Actualizar PowerApps
- Copiar código actualizado de botones "Devolución", "Traslado" y "Enviar"
- Verificar que `_tipomovimiento` se establece correctamente

---

## ⚠️ Notas Importantes

1. **Tabla 50105 eliminada**: Si existe `50105-DecompReadAPITmp.al`, debe eliminarse antes de compilar para evitar errores de campo SystemId.

2. **Campos obsoletos**: Los campos `ID Encargado` (Integer) permanecen marcados como `ObsoleteState=Pending`. Se eliminará en versión futura.

3. **Compatibilidad**: Esta versión requiere actualización de PowerApps para usar el nuevo campo `documentNo` en consumos.

---

## 📞 Soporte

Para dudas o problemas:
- Email: davidpc@adelante.cr
- Sandbox: SBX_ProdCopy_25_5
- Environment ID: 27272476-d569-411c-ab78-6d3f3b7596e5

---

## 🔗 Referencias

- **Issue original**: Transferencias a almacén general no sumaban en destino
- **Versión anterior**: 1.2.1.4
- **Plataforma**: Business Central 27.0.0.0
- **Runtime**: 16.0
