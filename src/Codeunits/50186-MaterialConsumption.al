codeunit 50186 "GJW Material Consumption"
{
    procedure ConsumeWarehouseMaterials(ItemLedgerEntryNos: Text; JobNo: Code[20]; JobTaskNo: Code[20]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GomJobWarehouseQty: Record "GomJob Warehouse Quantity";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        EntryNoList: List of [Text];
        EntryNoText: Text;
        EntryNo: Integer;
        LineNo: Integer;
        ProcessedCount: Integer;
        TotalQuantity: Decimal;
        TasksProcessed: Integer;
        ErrorMsg: Text;
    begin
        // Validar parámetros
        if ItemLedgerEntryNos = '' then
            Error('No se especificaron movimientos de almacén para consumir');

        if JobNo = '' then
            Error('Debe especificar el número de proyecto');

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

        // Procesar cada Item Ledger Entry
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

                    if GomJobWarehouseQty.FindSet() then begin
                        // Crear una línea por cada tarea
                        repeat
                            if GomJobWarehouseQty.Quantity > 0 then begin
                                // Crear línea de Job Journal
                                Clear(JobJnlLine);
                                JobJnlLine.Init();
                                JobJnlLine."Journal Template Name" := 'PROJECT';
                                JobJnlLine."Journal Batch Name" := 'DEFAULT';
                                JobJnlLine."Line No." := LineNo;
                                JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
                                JobJnlLine.Validate("Posting Date", Today);
                                JobJnlLine."Document No." := 'CONS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');

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
                                // Vincular el consumo al ILE original
                                JobJnlLine."Applies-to Entry" := ItemLedgerEntry."Entry No.";

                                // Costo unitario
                                if ItemLedgerEntry."Cost Amount (Actual)" <> 0 then
                                    JobJnlLine."Unit Cost" := ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity
                                else if ItemLedgerEntry."GomJob Cost per Unit" <> 0 then
                                    JobJnlLine."Unit Cost" := ItemLedgerEntry."GomJob Cost per Unit";

                                JobJnlLine."Line Type" := JobJnlLine."Line Type"::Budget;

                                // Copiar dimensiones del Item Ledger Entry
                                JobJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
                                JobJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";

                                // Intentar insertar y registrar
                                if JobJnlLine.Insert(true) then begin
                                    // Registrar la línea inmediatamente
                                    JobJnlPostLine.RunWithCheck(JobJnlLine);

                                    TasksProcessed += 1;
                                    TotalQuantity += JobJnlLine.Quantity;

                                    LineNo += 10000;
                                end else
                                    Error('Error al crear línea de diario para Entry %1, Tarea %2', EntryNo, GomJobWarehouseQty."Job Task No.");
                            end;
                        until GomJobWarehouseQty.Next() = 0;

                        ProcessedCount += 1;
                    end else
                        Error('No se encontraron tareas asignadas para el material %1 (Entry %2)', ItemLedgerEntry."Item No.", EntryNo);
                end else
                    Error('No se encontró el Item Ledger Entry %1', EntryNo);
            end;
        end;

        if ProcessedCount = 0 then
            Error('No se procesó ningún material');


        exit(StrSubstNo('✓ Se consumieron %1 materiales distribuidos en %2 tareas (Cantidad total: %3) del proyecto %4',
            ProcessedCount, TasksProcessed, TotalQuantity, JobNo));
    end;

    local procedure ValidateJobTask(JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    var
        JobTask: Record "Job Task";
    begin
        exit(JobTask.Get(JobNo, JobTaskNo));
    end;
}
