// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50159 "GJW Item Transfer Bulk"
// Propósito: Procesar transferencias masivas de inventario entre almacenes
// Entrada: JSON con array de transferencias
// Salida: Texto con resultado del proceso (éxito o errores)
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50159 "GJW Item Transfer Bulk"
{
    // 🎯 Procesa transferencias bulk de almacén a almacén/obra
    // Crea líneas en Item Reclass Journal y ejecuta posting automáticamente

    // Atributo [ServiceEnabled]: Permite que este procedimiento sea llamado desde APIs REST
    [ServiceEnabled]
    procedure ProcessTransfers(transfersJSON: Text): Text
    var
        // ─── Variables para parseo de JSON ───
        Arr: JsonArray;                  // Array principal que contendrá todas las transferencias del JSON
        Token: JsonToken;                // Token temporal para iterar cada elemento del array
        Obj: JsonObject;                 // Objeto JSON que representa una transferencia individual
        Val: JsonToken;                  // Token temporal para leer valores de propiedades del objeto

        // ─── Variables para acceso a datos de BC ───
        ItemJnlLine: Record "Item Journal Line";      // Tabla para crear líneas de diario de productos
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Line";  // Codeunit que registra lotes de diario

        // ─── Variables de configuración del diario ───
        TemplateName: Code[10];          // Nombre de la plantilla del diario a usar
        BatchName: Code[10];             // Nombre del lote del diario a usar
        LineNo: Integer;                 // Número de línea incremental para cada entrada

        // ─── Variables para datos de cada transferencia ───
        ItemNo: Code[20];                // Código del producto a transferir
        LocationCode: Code[10];          // Código del almacén de origen
        NewLocationCode: Code[10];       // Código del almacén de destino
        TaskNo: Code[20];                // Número de tarea de proyecto origen (opcional)
        NewJobNo: Code[20];              // Número de proyecto destino (opcional)
        NewJobTaskNo: Code[20];          // Número de tarea de proyecto destino (opcional)
        Description: Text[100];          // Descripción de la transferencia
        Quantity: Decimal;               // Cantidad a transferir
        PostingDate: Date;               // Fecha de registro de la transferencia
        DocumentNo: Code[20];            // Número de documento
        VariantCode: Code[10];           // Código de variante del producto (opcional)
        AppliesFromEntry: Integer;       // Número de movimiento para liquidación específica

        // ─── Variables de control de proceso ───
        InsCount: Integer;               // Contador de líneas insertadas correctamente
        ErrorCount: Integer;             // Contador de errores encontrados
        ErrorMsg: Text;                  // Mensaje del último error ocurrido
    begin
        // ═══ PASO 1: Configurar nombres de plantilla y lote del diario ═══
        TemplateName := 'TRANSFEREN';    // Asignar nombre de plantilla para transferencias
        BatchName := 'GENERICO';         // Asignar nombre de lote genérico

        // ═══ PASO 2: Limpiar líneas existentes del batch para evitar duplicados ═══
        ItemJnlLine.Reset();             // Resetear filtros de la tabla
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);  // Filtrar por plantilla
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);       // Filtrar por lote
        if ItemJnlLine.FindSet() then    // Si se encuentran líneas existentes
            ItemJnlLine.DeleteAll(true); // Eliminarlas todas (true = ejecutar triggers)

        // ═══ PASO 3: Validar que se recibió JSON válido ═══
        if transfersJSON = '' then       // Si el parámetro está vacío
            exit('ERROR: No se recibió JSON de transferencias');  // Salir con mensaje de error

        if not Arr.ReadFrom(transfersJSON) then  // Intentar parsear el JSON al array
            exit('ERROR: JSON inválido');        // Si falla el parseo, salir con error

        // ═══ PASO 4: Inicializar contador de línea ═══
        LineNo := 10000;                 // Comenzar en 10000 (estándar BC)

        // ═══ PASO 5: Iterar cada transferencia en el array JSON ═══
        foreach Token in Arr do begin    // Para cada elemento en el array JSON
            if Token.IsObject() then begin  // Verificar que el elemento sea un objeto válido
                Obj := Token.AsObject();    // Convertir el token a objeto JSON

                // ─── Limpiar todas las variables antes de procesar nueva línea ───
                Clear(ItemNo);           // Limpiar código de producto
                Clear(LocationCode);     // Limpiar código de almacén origen
                Clear(NewLocationCode);  // Limpiar código de almacén destino
                Clear(TaskNo);           // Limpiar número de tarea origen
                Clear(NewJobNo);         // Limpiar número de proyecto destino
                Clear(NewJobTaskNo);     // Limpiar número de tarea destino
                Clear(Description);      // Limpiar descripción
                Clear(Quantity);         // Limpiar cantidad
                Clear(PostingDate);      // Limpiar fecha de registro
                Clear(DocumentNo);       // Limpiar número de documento
                Clear(VariantCode);      // Limpiar código de variante
                Clear(AppliesFromEntry); // Limpiar número de movimiento

                // ═══ PASO 6: Leer cada campo del objeto JSON ═══

                // ─── Leer itemNo (código de producto) ───
                if Obj.Get('itemNo', Val) and (not Val.AsValue().IsNull()) then  // Si existe propiedad 'itemNo' y no es null
                    ItemNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(ItemNo));  // Copiar valor limitando a longitud máxima

                // ─── Leer locationCode (almacén de origen) ───
                if Obj.Get('locationCode', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    LocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(LocationCode));  // Copiar código de almacén

                // ─── Leer newLocationCode (almacén de destino) ───
                if Obj.Get('newLocationCode', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    NewLocationCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewLocationCode));  // Copiar nuevo almacén

                // ─── Leer quantity (cantidad a transferir) ───
                if Obj.Get('quantity', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    Quantity := Val.AsValue().AsDecimal();  // Convertir a decimal

                // ─── Leer taskNo (número de tarea origen - opcional) ───
                if Obj.Get('taskNo', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    TaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(TaskNo));  // Copiar número de tarea origen

                // ─── Leer newJobNo (número de proyecto destino - opcional) ───
                if Obj.Get('newJobNo', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    NewJobNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewJobNo));  // Copiar proyecto destino

                // ─── Leer newJobTaskNo (número de tarea destino - opcional) ───
                if Obj.Get('newJobTaskNo', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    NewJobTaskNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(NewJobTaskNo));  // Copiar tarea destino

                // ─── Leer description (descripción - opcional) ───
                if Obj.Get('description', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    Description := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(Description));  // Copiar descripción

                // ─── Leer postingDate (fecha de registro) ───
                if Obj.Get('postingDate', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    Evaluate(PostingDate, Val.AsValue().AsText())  // Convertir texto a fecha
                else
                    PostingDate := Today();  // Si no se especifica, usar fecha de hoy

                // ─── Leer documentNo (número de documento - opcional) ───
                if Obj.Get('documentNo', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    DocumentNo := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(DocumentNo))  // Copiar número documento
                else
                    // Si no se proporciona, generar automáticamente con formato TRANS-YYYYMMDD-HHMMSS
                    DocumentNo := CopyStr('TRANS-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'), 1, 20);

                // ─── Leer variantCode (código de variante del producto - opcional) ───
                if Obj.Get('variantCode', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    VariantCode := CopyStr(Val.AsValue().AsText(), 1, MaxStrLen(VariantCode));  // Copiar código variante

                // ─── Leer appliesFromEntry (número de movimiento para liquidación específica) ───
                if Obj.Get('appliesFromEntry', Val) and (not Val.AsValue().IsNull()) then  // Si existe y no es null
                    AppliesFromEntry := Val.AsValue().AsInteger();  // Convertir a entero

                // ═══ PASO 7: Validar campos obligatorios ═══
                if ItemNo = '' then begin  // Si no se proporcionó código de producto
                    ErrorCount += 1;       // Incrementar contador de errores
                    ErrorMsg := 'ERROR: itemNo es obligatorio';  // Guardar mensaje de error
                end else if Quantity <= 0 then begin  // Si la cantidad es cero o negativa
                    ErrorCount += 1;       // Incrementar contador de errores
                    ErrorMsg := 'ERROR: quantity debe ser mayor que 0';  // Guardar mensaje de error
                end else if LocationCode = '' then begin  // Si no se proporcionó almacén de origen
                    ErrorCount += 1;       // Incrementar contador de errores
                    ErrorMsg := 'ERROR: locationCode es obligatorio';  // Guardar mensaje de error
                end else if NewLocationCode = '' then begin  // Si no se proporcionó almacén de destino
                    ErrorCount += 1;       // Incrementar contador de errores
                    ErrorMsg := 'ERROR: newLocationCode es obligatorio';  // Guardar mensaje de error
                end else begin  // Si todas las validaciones pasaron
                    // ═══ PASO 8: Crear línea de diario de transferencia ═══
                    // Llamar función local para insertar la línea pasando todos los parámetros
                    if InsertTransferLine(ItemJnlLine, TemplateName, BatchName, LineNo, ItemNo, LocationCode,
                        NewLocationCode, Quantity, TaskNo, NewJobNo, NewJobTaskNo, Description, PostingDate, DocumentNo, VariantCode, AppliesFromEntry) then begin
                        InsCount += 1;     // Incrementar contador de líneas insertadas exitosamente
                        LineNo += 10000;   // Incrementar número de línea para la siguiente entrada
                    end else begin  // Si la inserción falló
                        ErrorCount += 1;   // Incrementar contador de errores
                        ErrorMsg := 'ERROR: No se pudo crear la línea de transferencia';  // Guardar mensaje
                    end;
                end;
            end else  // Si el elemento del array no era un objeto
                ErrorCount += 1;  // Incrementar contador de errores
        end;  // Fin del foreach

        // ═══ PASO 9: Verificar si hubo errores durante el procesamiento ═══
        if ErrorCount > 0 then  // Si se encontraron errores
            // Salir retornando resumen con cantidad de líneas creadas, errores y último mensaje
            exit(StrSubstNo('%1 líneas creadas, %2 errores. Último error: %3', InsCount, ErrorCount, ErrorMsg));

        if InsCount = 0 then  // Si no se creó ninguna línea válida
            exit('ERROR: No se crearon líneas para transferir');  // Salir con mensaje de error

        // ═══ PASO 10: Preparar para ejecutar el posting (registro) ═══
        ItemJnlLine.Reset();  // Resetear filtros del recordset
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);  // Filtrar por plantilla
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);  // Filtrar por lote

        if not ItemJnlLine.FindFirst() then  // Buscar primera línea del diario
            exit('ERROR: No se encontraron líneas para registrar');  // Si no hay líneas, salir con error

        // ═══ PASO 11: Debug - Verificar existencia de almacenes antes del posting ═══
        // Validar que el almacén de origen existe en la tabla Location
        if not ValidateLocationExists(ItemJnlLine."Location Code") then
            // Si no existe, retornar mensaje de debug con el código y su longitud
            exit(StrSubstNo('DEBUG: Location origen "%1" (len:%2) no existe antes de posting',
                ItemJnlLine."Location Code", StrLen(ItemJnlLine."Location Code")));

        // Validar que el almacén de destino existe en la tabla Location
        if not ValidateLocationExists(ItemJnlLine."New Location Code") then
            // Si no existe, retornar mensaje de debug con el código y su longitud
            exit(StrSubstNo('DEBUG: Location destino "%1" (len:%2) no existe antes de posting',
                ItemJnlLine."New Location Code", StrLen(ItemJnlLine."New Location Code")));

        Commit();  // Confirmar transacción actual para persistir las líneas creadas

        // ═══ PASO 12: Ejecutar el posting usando Item Jnl.-Post Batch (CRÍTICO) ═══
        // Usar "Item Jnl.-Post Batch" en lugar de "Item Jnl.-Post Line" para transferencias
        Clear(ItemJnlPostBatch);

        // Ejecutar posting en batch (esto crea AMBOS movimientos: salida + entrada)
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        ClearLastError();  // Limpiar cualquier error previo

        // Intentar ejecutar posting capturando cualquier error
        if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
            ErrorMsg := GetLastErrorText();  // Capturar mensaje de error
            if ErrorMsg = '' then
                ErrorMsg := 'Error desconocido durante el posting';
            exit(StrSubstNo('❌ ERROR en posting: %1', ErrorMsg));  // Salir con mensaje de error
        end;

        // ═══ PASO 13: Retornar mensaje de éxito ═══
        // Retornar detalles de los movimientos creados para diagnóstico
        exit(StrSubstNo('✅ %1 transferencias registradas. Verifica Item Ledger Entries con Document No. que comience con TRANS-', InsCount));  // Confirmar éxito
    end;  // Fin del procedimiento ProcessTransfers

    // ══════════════════════════════════════════════════════════════════════════════
    // Procedimiento: InsertTransferLine (Local)
    // Propósito: Crear e insertar una línea en el diario de productos para transferencia
    // Parámetros:
    //   - ItemJnlLine: Registro donde se creará la línea (por referencia)
    //   - TemplateName: Nombre de la plantilla del diario
    //   - BatchName: Nombre del lote del diario
    //   - LineNo: Número de línea secuencial
    //   - ItemNo: Código del producto a transferir
    //   - LocationCode: Código del almacén de origen
    //   - NewLocationCode: Código del almacén de destino
    //   - Quantity: Cantidad a transferir
    //   - TaskNo: Número de tarea de proyecto origen (opcional)
    //   - NewJobNo: Número de proyecto destino (opcional)
    //   - NewJobTaskNo: Número de tarea destino (opcional)
    //   - Description: Descripción de la transferencia
    //   - PostingDate: Fecha de registro
    //   - DocumentNo: Número de documento
    //   - VariantCode: Código de variante del producto (opcional)
    //   - AppliesFromEntry: Número de movimiento para liquidación (opcional)
    // Retorno: Boolean - true si la inserción fue exitosa, false en caso contrario
    // ══════════════════════════════════════════════════════════════════════════════
    local procedure InsertTransferLine(
        var ItemJnlLine: Record "Item Journal Line";  // Parámetro por referencia (var)
        TemplateName: Code[10];        // Nombre de plantilla del diario
        BatchName: Code[10];           // Nombre de lote del diario
        LineNo: Integer;               // Número de línea
        ItemNo: Code[20];              // Código de producto
        LocationCode: Code[10];        // Almacén origen
        NewLocationCode: Code[10];     // Almacén destino
        Quantity: Decimal;             // Cantidad
        TaskNo: Code[20];              // Tarea de proyecto origen
        NewJobNo: Code[20];            // Proyecto destino
        NewJobTaskNo: Code[20];        // Tarea destino
        Description: Text[100];        // Descripción
        PostingDate: Date;             // Fecha de registro
        DocumentNo: Code[20];          // Número de documento
        VariantCode: Code[10];         // Código de variante
        AppliesFromEntry: Integer      // Movimiento a liquidar
    ): Boolean  // Retorna true/false
    var
        Item: Record Item;  // Variable para acceder a la tabla de productos
        ItemLedgerEntry: Record "Item Ledger Entry";  // Para validar el movimiento a liquidar
    begin
        // ═══ PASO 1: Inicializar nuevo registro de línea de diario ═══
        ItemJnlLine.Init();  // Inicializar registro con valores por defecto

        // ═══ PASO 1.5: Validar que el movimiento sea válido para liquidación ═══
        // Si no es válido, simplemente NO asignar appliesFromEntry (BC usará FIFO/LIFO)
        if AppliesFromEntry <> 0 then begin
            if ItemLedgerEntry.Get(AppliesFromEntry) then begin
                if ItemLedgerEntry.Positive or (not ItemLedgerEntry.Open) then
                    AppliesFromEntry := 0;  // Invalidar: resetear a 0 para que BC use FIFO/LIFO
            end else
                AppliesFromEntry := 0;  // Invalidar: el movimiento no existe
        end;

        // ═══ PASO 2: Asignar campos de identificación del diario ═══
        ItemJnlLine."Journal Template Name" := TemplateName;  // Asignar nombre de plantilla
        ItemJnlLine."Journal Batch Name" := BatchName;  // Asignar nombre de lote
        ItemJnlLine."Line No." := LineNo;  // Asignar número de línea secuencial

        // ═══ PASO 3: Configurar tipo de movimiento como transferencia ═══
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;  // Tipo de movimiento = Transferencia

        // ═══ PASO 4: Asignar fecha y número de documento ═══
        ItemJnlLine."Posting Date" := PostingDate;  // Fecha de registro del movimiento
        ItemJnlLine."Document No." := DocumentNo;  // Número de documento para identificación

        // ═══ PASO 5: Validar número de producto (ejecuta lógica de BC) ═══
        ItemJnlLine.Validate("Item No.", ItemNo);  // Validar producto (carga nombre, UoM, etc.)

        // ═══ PASO 6: Asignar location de origen y validar (para obtener dimensiones) ═══
        ItemJnlLine.Validate("Location Code", LocationCode);  // Validar location origen (carga dimensiones)

        // Si el producto existe, usar su UoM base
        if Item.Get(ItemNo) then
            ItemJnlLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");

        // ═══ PASO 6.5: Asignar código de variante ANTES de location destino y cantidad ═══
        // CRÍTICO: Debe asignarse antes para que coincida con el movimiento a liquidar
        if VariantCode <> '' then
            ItemJnlLine.Validate("Variant Code", VariantCode);  // Validar variante

        // ═══ PASO 7: Asignar location de destino (heredará dimensiones del origen) ═══
        ItemJnlLine.Validate("New Location Code", NewLocationCode);  // Validar nuevo location (hereda dimensiones)

        // ═══ PASO 8: Validar cantidad (siempre POSITIVA para Transfer) ═══
        ItemJnlLine.Validate(Quantity, Abs(Quantity));  // Asegurar que sea positiva

        // ═══ PASO 9: Asignar número de tarea de proyecto origen si se proporcionó ═══
        if TaskNo <> '' then  // Si hay tarea especificada
            ItemJnlLine."Task No." := TaskNo;  // Asignar tarea origen (sin validar)

        // ═══ PASO 10: Asignar proyecto y tarea destino para vincular después del posting ═══
        // IMPORTANTE: NO asignar Job No./Task No. si están vacíos (transferencias a almacén general)
        if NewJobNo <> '' then  // Si se especificó proyecto destino
            ItemJnlLine."New Job No." := NewJobNo;  // Guardar para crear vínculo post-registro
        if NewJobTaskNo <> '' then  // Si se especificó tarea destino
            ItemJnlLine."New Job Task No." := NewJobTaskNo;  // Guardar para crear vínculo post-registro

        // ═══ PASO 10.5: CRÍTICO - Limpiar campos de proyecto en origen si van a almacén general ═══
        // Esto evita que BC intente validar proyectos en transferencias simples
        if (NewJobNo = '') and (NewJobTaskNo = '') then begin
            ItemJnlLine."Job No." := '';           // Limpiar proyecto origen
            ItemJnlLine."Job Task No." := '';      // Limpiar tarea origen
            ItemJnlLine."Task No." := '';          // Limpiar task no.
        end;

        // ═══ PASO 11: Asignar descripción de la transferencia ═══
        if Description <> '' then  // Si se proporcionó descripción personalizada
            ItemJnlLine.Description := Description  // Usar la descripción proporcionada
        else
            // Si no, generar descripción automática con los almacenes
            ItemJnlLine.Description
            := StrSubstNo('Transfer %1 → %2', LocationCode, NewLocationCode);

        // ═══ PASO 12: Aplicar liquidación JUSTO ANTES de insertar (evita que se borre) ═══
        // Esto permite consumir stock de un movimiento particular (Liq. por nº orden)
        // Se asigna directamente sin Validate() para evitar que BC lo borre
        if AppliesFromEntry <> 0 then  // Si se especificó número de movimiento
            ItemJnlLine."Applies-from Entry" := AppliesFromEntry;  // Asignar movimiento a liquidar

        // ═══ PASO 13: Insertar registro en la tabla (true = ejecutar triggers) ═══
        exit(ItemJnlLine.Insert(true));  // Retornar true si insertó, false si falló
    end;  // Fin del procedimiento InsertTransferLine

    // ══════════════════════════════════════════════════════════════════════════════
    // Procedimiento: ValidateLocationExists (Local)
    // Propósito: Verificar si un código de almacén existe en la tabla Location
    // Parámetros:
    //   - LocationCode: Código del almacén a verificar
    // Retorno: Boolean - true si el almacén existe, false en caso contrario
    // Uso: Para debug/diagnóstico antes de ejecutar el posting
    // ══════════════════════════════════════════════════════════════════════════════
    local procedure ValidateLocationExists(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;  // Variable para acceder a la tabla Location
    begin
        // ═══ PASO 1: Validar que el código no esté vacío ═══
        if LocationCode = '' then  // Si el código está vacío
            exit(false);  // Retornar false (no es válido)

        // ═══ PASO 2: Intentar obtener el registro de Location ═══
        // Location.Get() retorna true si encuentra el registro, false si no existe
        exit(Location.Get(LocationCode));  // Retornar resultado de la búsqueda
    end;  // Fin del procedimiento ValidateLocationExists
}  // Fin del codeunit "GJW Item Transfer Bulk"

// ══════════════════════════════════════════════════════════════════════════════
// FIN DEL ARCHIVO
// ══════════════════════════════════════════════════════════════════════════════
