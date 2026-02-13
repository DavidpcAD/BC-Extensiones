codeunit 50186 "GJW Material Consumption"
{
    procedure ConsumeWarehouseMaterials(ItemLedgerEntryNos: Text; JobNo: Code[20]; JobTaskNo: Code[20]; DocumentNo: Code[20]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GomJobWarehouseQty: Record "GomJob Warehouse Quantity";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        JobLedgEntry: Record "Job Ledger Entry";

        EntryNoList: List of [Text];
        EntryNoText: Text;
        EntryNo: Integer;
        LineNo: Integer;

        ProcessedCount: Integer;
        TotalQuantity: Decimal;
        TasksProcessed: Integer;

        // JSON
        Arr: JsonArray;
        Row: JsonObject;

        DocNo: Code[20];
        GuidTxt: Text;
        NewLedgerEntryNo: Integer;
        NewJobEntryNo: Integer;
    begin
        // Validar parámetros
        if ItemLedgerEntryNos = '' then
            Error('No se especificaron movimientos de almacén para consumir');

        if JobNo = '' then
            Error('Debe especificar el número de proyecto');

        // Document No: usar el recibido como parámetro
        DocNo := DocumentNo;

        // Separar la lista de Entry Nos
        EntryNoList := ItemLedgerEntryNos.Split(',');

        // Obtener siguiente número de línea
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'PROJECT');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if JobJnlLine.FindLast() then
            LineNo := JobJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        ProcessedCount := 0;
        TotalQuantity := 0;
        TasksProcessed := 0;

        Clear(Arr); // inicializar el array

        foreach EntryNoText in EntryNoList do begin
            if Evaluate(EntryNo, EntryNoText.Trim()) then begin
                if ItemLedgerEntry.Get(EntryNo) then begin

                    // Validar que el material está en el almacén del proyecto
                    if ItemLedgerEntry."Location Code" <> JobNo then
                        Error('El material %1 (Entry %2) no está en el almacén del proyecto %3',
                            ItemLedgerEntry."Item No.", EntryNo, JobNo);

                    // Validar que tiene cantidad disponible
                    if ItemLedgerEntry."Remaining Quantity" <= 0 then
                        Error('El material %1 (Entry %2) no tiene cantidad disponible para consumir',
                            ItemLedgerEntry."Item No.", EntryNo);

                    // Buscar TODAS las tareas asociadas a este material
                    GomJobWarehouseQty.Reset();
                    GomJobWarehouseQty.SetRange("Item Ledger Entry No.", EntryNo);
                    GomJobWarehouseQty.SetRange("Job No.", JobNo);
                    // Si se especifica una tarea destino desde Power Apps, filtrar por esa tarea
                    if JobTaskNo <> '' then
                        GomJobWarehouseQty.SetRange("Job Task No.", JobTaskNo);

                    if GomJobWarehouseQty.FindSet() then begin
                        repeat
                            if GomJobWarehouseQty.Quantity > 0 then begin

                                Clear(JobJnlLine);
                                JobJnlLine.Init();
                                JobJnlLine."Journal Template Name" := 'PROJECT';
                                JobJnlLine."Journal Batch Name" := 'DEFAULT';
                                JobJnlLine."Line No." := LineNo;
                                JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
                                JobJnlLine.Validate("Posting Date", Today);

                                // 🔥 Document No único para rastrear EXACTO este consumo
                                JobJnlLine."Document No." := DocNo;

                                // Datos del proyecto
                                JobJnlLine."Job No." := JobNo;
                                JobJnlLine."Job Task No." := GomJobWarehouseQty."Job Task No.";

                                // Datos del material
                                JobJnlLine.Type := JobJnlLine.Type::Item;
                                JobJnlLine.Validate("No.", ItemLedgerEntry."Item No.");
                                JobJnlLine.Description := ItemLedgerEntry.Description;
                                JobJnlLine."Variant Code" := ItemLedgerEntry."Variant Code";
                                JobJnlLine.Validate(Quantity, GomJobWarehouseQty.Quantity);
                                JobJnlLine."Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";
                                JobJnlLine."Location Code" := ItemLedgerEntry."Location Code";
                                JobJnlLine."Applies-to Entry" := ItemLedgerEntry."Entry No.";

                                // Costos
                                if ItemLedgerEntry."Cost Amount (Actual)" <> 0 then
                                    JobJnlLine."Unit Cost" := ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity
                                else if ItemLedgerEntry."GomJob Cost per Unit" <> 0 then
                                    JobJnlLine."Unit Cost" := ItemLedgerEntry."GomJob Cost per Unit";

                                JobJnlLine."Line Type" := JobJnlLine."Line Type"::Budget;

                                // Dimensiones
                                JobJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
                                JobJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

                                if JobJnlLine.Insert(true) then begin
                                    // Post
                                    JobJnlPostLine.RunWithCheck(JobJnlLine);

                                    // ✅ Buscar el Job Ledger Entry recién creado
                                    JobLedgEntry.Reset();
                                    JobLedgEntry.SetRange("Job No.", JobNo);
                                    JobLedgEntry.SetRange("Job Task No.", JobJnlLine."Job Task No.");
                                    JobLedgEntry.SetRange("Posting Date", JobJnlLine."Posting Date");
                                    JobLedgEntry.SetRange("Document No.", DocNo);
                                    JobLedgEntry.SetRange("No.", ItemLedgerEntry."Item No.");
                                    // Si querés más precisión:
                                    // JobLedgEntry.SetRange("User ID", UserId);

                                    NewLedgerEntryNo := 0;
                                    NewJobEntryNo := 0;

                                    if JobLedgEntry.FindLast() then begin
                                        // (1018) Ledger Entry No.
                                        NewLedgerEntryNo := JobLedgEntry."Ledger Entry No.";
                                        // Job Ledger Entry Entry No.
                                        NewJobEntryNo := JobLedgEntry."Entry No.";
                                    end;

                                    // Agregar al JSON results con MISMA estructura que postCommands
                                    Clear(Row);
                                    Row.Add('itemNo', ItemLedgerEntry."Item No.");
                                    Row.Add('entryNo', NewLedgerEntryNo); // usar Ledger Entry No. (1018) como entryNo
                                    Row.Add('locationCode', ItemLedgerEntry."Location Code");
                                    Row.Add('quantity', Format(JobJnlLine.Quantity, 0, 9));
                                    Row.Add('documentNo', DocNo);
                                    Arr.Add(Row);

                                    TasksProcessed += 1;
                                    TotalQuantity += JobJnlLine.Quantity;
                                    LineNo += 10000;
                                end else
                                    Error('Error al crear línea de diario para Entry %1, Tarea %2', EntryNo, GomJobWarehouseQty."Job Task No.");
                            end;

                        until GomJobWarehouseQty.Next() = 0;

                        ProcessedCount += 1;
                    end else begin
                        if JobTaskNo <> '' then
                            Error('No se encontraron tareas asignadas para el material %1 (Entry %2) en la tarea %3', ItemLedgerEntry."Item No.", EntryNo, JobTaskNo)
                        else
                            Error('No se encontraron tareas asignadas para el material %1 (Entry %2)', ItemLedgerEntry."Item No.", EntryNo);
                    end;
                end else
                    Error('No se encontró el Item Ledger Entry %1', EntryNo);
            end;
        end;

        if ProcessedCount = 0 then
            Error('No se procesó ningún material');

        // Devolver solo jsonResults como arreglo (texto JSON) para Power Apps
        exit(Format(Arr));
    end;
}
