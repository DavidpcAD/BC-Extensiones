page 50163 "GJW Post Command API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'postCommand';
    EntitySetName = 'postCommands';

    SourceTable = "GJW Post Command";
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(commandId; Rec."Command ID")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(commandData; Rec."Command Data")
                {
                    ApplicationArea = All;
                }
                field(linesPosted; Rec."Lines Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(successMessage; Rec."Success Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(jsonResults; Rec."JSON Results")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(postingStatus; Rec."Posting Status")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(errorDetails; Rec."Error Details")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(processingStarted; Rec."Processing Started")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(processingCompleted; Rec."Processing Completed")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(durationMs; Rec."Duration (ms)")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        UserSetup: Record "User Setup";
        GLSetup: Record "General Ledger Setup";
        LineCount: Integer;
        PostedEntriesCount: Integer;
        BatchName: Code[20];
        TemplateName: Code[10];
        ErrorText: Text;
        StartTime: DateTime;
        EndTime: DateTime;
        DocumentNo: Code[20];
        LastEntryNoBefore: Integer;
        CleanJnlLine: Record "Item Journal Line";
        SavedUserAllowFrom: Date;
        SavedUserAllowTo: Date;
        SavedGLAllowFrom: Date;
        SavedGLAllowTo: Date;
        UserSetupExists: Boolean;
        BatchSnapshotJson: Text;
    begin
        // Generar Command ID si no viene del cliente
        if IsNullGuid(Rec."Command ID") then
            Rec."Command ID" := CreateGuid();

        // 📊 Iniciar medición de tiempo
        StartTime := CurrentDateTime();
        Rec."Processing Started" := StartTime;
        Rec."Posting Status" := Rec."Posting Status"::Processing;

        // Validar que se recibió un batch name
        if Rec."Command Data" = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: El nombre del batch es requerido. Command Data está vacío.';
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := 'Command Data vacío';
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := CurrentDateTime() - StartTime;
            exit(true);
        end;

        // El Command Data contiene el BatchName directamente
        BatchName := CopyStr(Rec."Command Data", 1, 20);
        TemplateName := 'TRANSFEREN';

        // Obtener líneas del batch
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindSet() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: No se encontraron líneas en Template: %1, Batch: %2', TemplateName, BatchName);
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := StrSubstNo('Batch no encontrado: %1/%2', TemplateName, BatchName);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
            exit(true);
        end;

        // Contar líneas ANTES del posting
        LineCount := ItemJnlLine.Count();

        // Capturar snapshot del batch para devolver mapeo origen/destino útil a Power Apps.
        BatchSnapshotJson := BuildBatchSnapshotJson(ItemJnlLine);

        // ✅ CAPTURAR DOCUMENT NO ANTES DEL POSTING
        DocumentNo := ItemJnlLine."Document No.";

        // 🛡️ VALIDAR QUE TODAS LAS LÍNEAS TIENEN CANTIDAD
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        if ItemJnlLine.FindSet() then
            repeat
                if ItemJnlLine.Quantity = 0 then begin
                    Rec."Lines Posted" := 0;
                    Rec."Success Message" := StrSubstNo('ERROR: La línea %1 no tiene cantidad. Ítem: %2', ItemJnlLine."Line No.", ItemJnlLine."Item No.");
                    Rec."Posting Status" := Rec."Posting Status"::Failed;
                    Rec."Error Details" := StrSubstNo('Línea %1 sin cantidad (Ítem %2)', ItemJnlLine."Line No.", ItemJnlLine."Item No.");
                    Rec."Processing Completed" := CurrentDateTime();
                    Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
                    exit(true);
                end;
                if ItemJnlLine."Item No." = '' then begin
                    Rec."Lines Posted" := 0;
                    Rec."Success Message" := StrSubstNo('ERROR: La línea %1 no tiene número de ítem', ItemJnlLine."Line No.");
                    Rec."Posting Status" := Rec."Posting Status"::Failed;
                    Rec."Error Details" := StrSubstNo('Línea %1 sin Item No.', ItemJnlLine."Line No.");
                    Rec."Processing Completed" := CurrentDateTime();
                    Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
                    exit(true);
                end;
            until ItemJnlLine.Next() = 0;

        // 🛡️ VALIDACIÓN DE LÍMITE (evitar timeouts)
        if LineCount > 200 then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR: Demasiadas líneas (%1). Máximo permitido: 200. Divida en batches más pequeños.', LineCount);
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := StrSubstNo('Límite excedido: %1 líneas (máx 200)', LineCount);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
            exit(true);
        end;

        // ✅ CAPTURAR EL ÚLTIMO ENTRY NO. ANTES DE POSTEAR (con orden correcto)
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Entry No.");
        ItemLedgerEntry.Ascending(true);
        if ItemLedgerEntry.FindLast() then
            LastEntryNoBefore := ItemLedgerEntry."Entry No."
        else
            LastEntryNoBefore := 0;

        // ✅ EJECUTAR POSTING CON MANEJO DE ERRORES
        Clear(ItemJnlPostBatch);

        // Resetear el recordset antes de postear
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);

        if not ItemJnlLine.FindFirst() then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: No se pudieron cargar las líneas para registrar';
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := 'FindFirst falló antes del posting';
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
            exit(true);
        end;

        // ✅ DESACTIVAR RESTRICCIONES DE FECHA (User Setup + GL Setup) antes del posting
        // El error "Posting Date is not within your range" ocurre en líneas internas temporales
        // que BC crea durante el posting. La solución es suspender el rango permitido.
        UserSetupExists := UserSetup.Get(UserId());
        if UserSetupExists then begin
            SavedUserAllowFrom := UserSetup."Allow Posting From";
            SavedUserAllowTo := UserSetup."Allow Posting To";
            if (SavedUserAllowFrom <> 0D) or (SavedUserAllowTo <> 0D) then begin
                UserSetup."Allow Posting From" := 0D;
                UserSetup."Allow Posting To" := 0D;
                UserSetup.Modify(false);
            end;
        end;

        GLSetup.Get();
        SavedGLAllowFrom := GLSetup."Allow Posting From";
        SavedGLAllowTo := GLSetup."Allow Posting To";
        if (SavedGLAllowFrom <> 0D) or (SavedGLAllowTo <> 0D) then begin
            GLSetup."Allow Posting From" := 0D;
            GLSetup."Allow Posting To" := 0D;
            GLSetup.Modify(false);
        end;

        Commit();

        // Reposicionar el recordset tras el Commit para el posting
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine.FindFirst();

        // Usar Codeunit.Run para mejor manejo en API
        if not Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJnlLine) then begin
            // Capturar error del posting
            ErrorText := GetLastErrorText();
            Rec."Lines Posted" := 0;
            Rec."Success Message" := StrSubstNo('ERROR AL REGISTRAR: %1', ErrorText);
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := CopyStr(ErrorText, 1, 2048);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
            ClearLastError();
            // 🔄 RESTAURAR restricciones de fecha aunque haya fallado
            RestorePostingDates(UserSetup, GLSetup, UserSetupExists,
                SavedUserAllowFrom, SavedUserAllowTo, SavedGLAllowFrom, SavedGLAllowTo);
            exit(true);
        end;

        // ✅✅✅ NUEVA LÓGICA: VERIFICAR POR ITEM LEDGER ENTRIES (Entry No. > LastEntryNoBefore) ✅✅✅
        Sleep(500);  // Pequeña pausa para asegurar que se crearon los entries

        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Entry No.");
        ItemLedgerEntry.Ascending(true);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetFilter("Entry No.", '>%1', LastEntryNoBefore);

        PostedEntriesCount := ItemLedgerEntry.Count();

        // Verificar éxito del posting por movimientos creados
        if PostedEntriesCount > 0 then begin
            // ✅ ÉXITO: Se crearon movimientos - Construir JSON con detalles
            EndTime := CurrentDateTime();
            Rec."Lines Posted" := LineCount;

            // Mensaje de éxito
            Rec."Success Message" := StrSubstNo('✅ %1 líneas registradas exitosamente. %2 movimientos de inventario creados', LineCount, PostedEntriesCount);

            // Ordenar por Entry No. antes de construir el JSON
            ItemLedgerEntry.SetCurrentKey("Entry No.");
            ItemLedgerEntry.Ascending(true);
            // Construir JSON array con entry origen consumible + entry destino registrado.
            Rec."JSON Results" := BuildPostedEntriesJson(ItemLedgerEntry, BatchSnapshotJson);

            Rec."Posting Status" := Rec."Posting Status"::Success;
            Rec."Error Details" := '';
            Rec."Processing Completed" := EndTime;
            Rec."Duration (ms)" := Round((EndTime - StartTime) / 1000, 1);
        end else begin
            // ❌ No se crearon movimientos (posting falló silenciosamente)
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: El posting no creó movimientos de inventario';
            Rec."Posting Status" := Rec."Posting Status"::Failed;
            Rec."Error Details" := StrSubstNo('No se encontraron Item Ledger Entries para Doc No: %1', DocumentNo);
            Rec."Processing Completed" := CurrentDateTime();
            Rec."Duration (ms)" := Round((CurrentDateTime() - StartTime) / 1000, 1);
        end;

        // Limpieza automática de líneas vacías en el diario de reclasificación
        CleanJnlLine.Reset();
        CleanJnlLine.SetRange("Journal Template Name", TemplateName);
        CleanJnlLine.SetRange("Journal Batch Name", BatchName);
        CleanJnlLine.SetRange("Item No.", '');
        CleanJnlLine.SetRange(Quantity, 0);
        if CleanJnlLine.FindFirst() then
            repeat
                CleanJnlLine.Delete();
            until CleanJnlLine.Next() = 0;

        // 🔄 RESTAURAR restricciones de fecha en cualquier caso
        RestorePostingDates(UserSetup, GLSetup, UserSetupExists,
            SavedUserAllowFrom, SavedUserAllowTo, SavedGLAllowFrom, SavedGLAllowTo);

        exit(true);
    end;

    local procedure RestorePostingDates(
        var UserSetup: Record "User Setup";
        var GLSetup: Record "General Ledger Setup";
        UserSetupExists: Boolean;
        SavedUserFrom: Date; SavedUserTo: Date;
        SavedGLFrom: Date; SavedGLTo: Date)
    begin
        // Restaurar User Setup
        if UserSetupExists then begin
            if (UserSetup."Allow Posting From" <> SavedUserFrom) or
               (UserSetup."Allow Posting To" <> SavedUserTo) then begin
                UserSetup."Allow Posting From" := SavedUserFrom;
                UserSetup."Allow Posting To" := SavedUserTo;
                UserSetup.Modify(false);
            end;
        end;

        // Restaurar GL Setup
        if (GLSetup."Allow Posting From" <> SavedGLFrom) or
           (GLSetup."Allow Posting To" <> SavedGLTo) then begin
            GLSetup."Allow Posting From" := SavedGLFrom;
            GLSetup."Allow Posting To" := SavedGLTo;
            GLSetup.Modify(false);
        end;

        Commit();
    end;

    local procedure BuildBatchSnapshotJson(var ItemJnlLine: Record "Item Journal Line"): Text
    var
        SnapshotArray: JsonArray;
        SnapshotObject: JsonObject;
        SnapshotText: Text;
    begin
        if ItemJnlLine.FindSet() then
            repeat
                Clear(SnapshotObject);
                SnapshotObject.Add('lineNo', ItemJnlLine."Line No.");
                SnapshotObject.Add('itemNo', ItemJnlLine."Item No.");
                SnapshotObject.Add('documentNo', ItemJnlLine."Document No.");
                SnapshotObject.Add('postingDate', Format(ItemJnlLine."Posting Date", 0, 9));
                SnapshotObject.Add('quantity', Format(ItemJnlLine.Quantity, 0, 9));
                SnapshotObject.Add('locationCode', ItemJnlLine."Location Code");
                SnapshotObject.Add('newLocationCode', ItemJnlLine."New Location Code");
                SnapshotObject.Add('taskNo', ItemJnlLine."Task No.");
                SnapshotObject.Add('newJobNo', ItemJnlLine."New Job No.");
                SnapshotObject.Add('newJobTaskNo', ItemJnlLine."New Job Task No.");
                SnapshotObject.Add('appliesFromEntry', ItemJnlLine."Applies-from Entry");
                SnapshotObject.Add('appliesToEntry', ItemJnlLine."Applies-to Entry");
                SnapshotArray.Add(SnapshotObject);
            until ItemJnlLine.Next() = 0;

        SnapshotArray.WriteTo(SnapshotText);
        exit(SnapshotText);
    end;

    local procedure BuildPostedEntriesJson(var ItemLedgerEntry: Record "Item Ledger Entry"; BatchSnapshotJson: Text): Text
    var
        SnapshotArray: JsonArray;
        SnapshotToken: JsonToken;
        SnapshotObject: JsonObject;
        ValueToken: JsonToken;
        ResultArray: JsonArray;
        ResultObject: JsonObject;
        SourceObject: JsonObject;
        DestinationObject: JsonObject;
        ResultText: Text;
        ItemNo: Code[20];
        DocumentNo: Code[20];
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        TaskNo: Code[20];
        NewJobNo: Code[20];
        NewJobTaskNo: Code[20];
        LineNo: Integer;
        AppliesFromEntry: Integer;
        AppliesToEntry: Integer;
        SourceAnchorEntry: Integer;
        QuantityPosted: Decimal;
        SourceEntryConsumable: Integer;
        RemainingQty: Decimal;
        DestEntryNo: Integer;
        HasExplicitSource: Boolean;
    begin
        if (BatchSnapshotJson = '') or (not SnapshotArray.ReadFrom(BatchSnapshotJson)) then
            exit('[]');

        foreach SnapshotToken in SnapshotArray do begin
            if not SnapshotToken.IsObject() then
                continue;

            SnapshotObject := SnapshotToken.AsObject();
            Clear(ItemNo);
            Clear(DocumentNo);
            Clear(LocationCode);
            Clear(NewLocationCode);
            Clear(TaskNo);
            Clear(NewJobNo);
            Clear(NewJobTaskNo);
            LineNo := 0;
            AppliesFromEntry := 0;
            AppliesToEntry := 0;
            SourceAnchorEntry := 0;
            QuantityPosted := 0;
            SourceEntryConsumable := 0;
            RemainingQty := 0;
            DestEntryNo := 0;
            HasExplicitSource := false;

            if SnapshotObject.Get('itemNo', ValueToken) then
                ItemNo := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(ItemNo));
            if SnapshotObject.Get('documentNo', ValueToken) then
                DocumentNo := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(DocumentNo));
            if SnapshotObject.Get('locationCode', ValueToken) then
                LocationCode := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(LocationCode));
            if SnapshotObject.Get('newLocationCode', ValueToken) then
                NewLocationCode := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(NewLocationCode));
            if SnapshotObject.Get('taskNo', ValueToken) then
                TaskNo := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(TaskNo));
            if SnapshotObject.Get('newJobNo', ValueToken) then
                NewJobNo := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(NewJobNo));
            if SnapshotObject.Get('newJobTaskNo', ValueToken) then
                NewJobTaskNo := CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(NewJobTaskNo));
            if SnapshotObject.Get('lineNo', ValueToken) then
                LineNo := ValueToken.AsValue().AsInteger();
            if SnapshotObject.Get('appliesFromEntry', ValueToken) then
                AppliesFromEntry := ValueToken.AsValue().AsInteger();
            if SnapshotObject.Get('appliesToEntry', ValueToken) then
                AppliesToEntry := ValueToken.AsValue().AsInteger();
            if SnapshotObject.Get('quantity', ValueToken) then
                Evaluate(QuantityPosted, ValueToken.AsValue().AsText());

            SourceAnchorEntry := AppliesFromEntry;
            if SourceAnchorEntry = 0 then
                SourceAnchorEntry := AppliesToEntry;

            HasExplicitSource := SourceAnchorEntry <> 0;

            DestEntryNo := FindPostedDestinationEntry(ItemLedgerEntry, ItemNo, DocumentNo, NewLocationCode, QuantityPosted);
            SourceEntryConsumable := FindConsumableSourceEntry(ItemNo, LocationCode, SourceAnchorEntry);
            RemainingQty := GetRemainingQuantity(SourceEntryConsumable);

            Clear(ResultObject);
            Clear(SourceObject);
            Clear(DestinationObject);

            ResultObject.Add('lineNo', LineNo);
            ResultObject.Add('itemNo', ItemNo);
            ResultObject.Add('documentNo', DocumentNo);
            ResultObject.Add('quantityPosted', QuantityPosted);

            SourceObject.Add('locationCode', LocationCode);
            SourceObject.Add('taskNo', TaskNo);
            SourceObject.Add('entryNoOriginal', SourceAnchorEntry);
            SourceObject.Add('entryNoConsumible', SourceEntryConsumable);
            SourceObject.Add('remainingQuantity', RemainingQty);

            DestinationObject.Add('locationCode', NewLocationCode);
            DestinationObject.Add('jobNo', NewJobNo);
            DestinationObject.Add('jobTaskNo', NewJobTaskNo);
            DestinationObject.Add('entryNoPosted', DestEntryNo);

            ResultObject.Add('source', SourceObject);
            ResultObject.Add('destination', DestinationObject);
            ResultObject.Add('ok', HasExplicitSource and (SourceEntryConsumable <> 0));

            if not HasExplicitSource then
                ResultObject.Add('message', '❌ No se recibió appliesFromEntry/appliesToEntry; mapeo no confiable')
            else
                if SourceEntryConsumable = 0 then
                    ResultObject.Add('message', '❌ El entry ancla no quedó consumible tras el post')
                else
                    ResultObject.Add('message', StrSubstNo('✅ Entry consumible %1 con remanente %2', SourceEntryConsumable, Format(RemainingQty, 0, 9)));

            ResultArray.Add(ResultObject);
        end;

        ResultArray.WriteTo(ResultText);
        exit(ResultText);
    end;

    local procedure FindPostedDestinationEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; DocumentNo: Code[20]; NewLocationCode: Code[10]; QuantityPosted: Decimal): Integer
    begin
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetCurrentKey("Entry No.");
        ItemLedgerEntry.Ascending(false);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Location Code", NewLocationCode);
        ItemLedgerEntry.SetRange(Positive, true);
        if QuantityPosted <> 0 then
            ItemLedgerEntry.SetRange(Quantity, Abs(QuantityPosted));

        if ItemLedgerEntry.FindFirst() then
            exit(ItemLedgerEntry."Entry No.");

        exit(0);
    end;

    local procedure FindConsumableSourceEntry(ItemNo: Code[20]; SourceLocationCode: Code[10]; PreferredEntryNo: Integer): Integer
    var
        SourceILE: Record "Item Ledger Entry";
    begin
        // When caller provides applies-from entry, map strictly to that entry only.
        // This avoids selecting unrelated open entries in the same location.
        if PreferredEntryNo <> 0 then begin
            if SourceILE.Get(PreferredEntryNo) then
                if (SourceILE."Item No." = ItemNo) and
                   (SourceILE."Location Code" = SourceLocationCode) and
                   SourceILE.Positive and
                   (SourceILE."Remaining Quantity" > 0)
                then
                    exit(SourceILE."Entry No.");

            exit(0);
        end;

        SourceILE.Reset();
        SourceILE.SetCurrentKey("Item No.", Open, Positive, "Location Code", "Variant Code", "Drop Shipment", "Package No.", "Lot No.", "Serial No.", "Posting Date");
        SourceILE.SetRange("Item No.", ItemNo);
        SourceILE.SetRange("Location Code", SourceLocationCode);
        SourceILE.SetRange(Open, true);
        SourceILE.SetRange(Positive, true);
        SourceILE.SetFilter("Remaining Quantity", '>%1', 0);
        if SourceILE.FindFirst() then
            exit(SourceILE."Entry No.");

        exit(0);
    end;

    local procedure GetRemainingQuantity(EntryNo: Integer): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if (EntryNo <> 0) and ItemLedgerEntry.Get(EntryNo) then
            exit(ItemLedgerEntry."Remaining Quantity");

        exit(0);
    end;
}