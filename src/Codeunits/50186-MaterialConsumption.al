codeunit 50186 "GJW Material Consumption"
{
    procedure ConsumeWarehouseMaterials(ItemLedgerEntryNos: Text; JobNo: Code[20]; JobTaskNo: Code[20]): Text
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobJnlLine: Record "Job Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        EntryNoList: List of [Text];
        EntryNoText: Text;
        EntryNo: Integer;
        LineNo: Integer;
        ProcessedCount: Integer;
        TotalQuantity: Decimal;
        ErrorMsg: Text;
    begin
        // Validar parámetros
        if ItemLedgerEntryNos = '' then
            Error('No se especificaron movimientos de almacén para consumir');

        if JobNo = '' then
            Error('Debe especificar el número de proyecto');

        if JobTaskNo = '' then
            Error('Debe especificar el número de tarea');

        // Verificar que la tarea existe
        if not ValidateJobTask(JobNo, JobTaskNo) then
            Error('La tarea %1 no existe en el proyecto %2', JobTaskNo, JobNo);

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

                    // Crear línea de Job Journal
                    Clear(JobJnlLine);
                    JobJnlLine.Init();
                    JobJnlLine."Journal Template Name" := 'PROJECT';
                    JobJnlLine."Journal Batch Name" := 'DEFAULT';
                    JobJnlLine."Line No." := LineNo;
                    JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;
                    JobJnlLine."Posting Date" := WorkDate();
                    JobJnlLine."Document No." := 'CONS-' + Format(Today, 0, '<Year4><Month,2><Day,2>');

                    // Datos del proyecto
                    JobJnlLine."Job No." := JobNo;
                    JobJnlLine."Job Task No." := JobTaskNo;

                    // Datos del material
                    JobJnlLine.Type := JobJnlLine.Type::Item;
                    JobJnlLine."No." := ItemLedgerEntry."Item No.";
                    JobJnlLine.Description := ItemLedgerEntry.Description;
                    JobJnlLine."Variant Code" := ItemLedgerEntry."Variant Code";
                    JobJnlLine.Quantity := ItemLedgerEntry."Remaining Quantity";
                    JobJnlLine."Unit of Measure Code" := ItemLedgerEntry."Unit of Measure Code";
                    JobJnlLine."Location Code" := ItemLedgerEntry."Location Code";

                    // Costo unitario
                    if ItemLedgerEntry."Cost Amount (Actual)" <> 0 then
                        JobJnlLine."Unit Cost" := ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity
                    else if ItemLedgerEntry."GomJob Cost per Unit" <> 0 then
                        JobJnlLine."Unit Cost" := ItemLedgerEntry."GomJob Cost per Unit";

                    JobJnlLine."Line Type" := JobJnlLine."Line Type"::Budget;

                    // Intentar insertar y registrar
                    if JobJnlLine.Insert(true) then begin
                        // Registrar la línea inmediatamente
                        JobJnlPostLine.RunWithCheck(JobJnlLine);

                        ProcessedCount += 1;
                        TotalQuantity += JobJnlLine.Quantity;

                        LineNo += 10000;
                    end else
                        Error('Error al crear línea de diario para Entry %1', EntryNo);
                end else
                    Error('No se encontró el Item Ledger Entry %1', EntryNo);
            end;
        end;

        if ProcessedCount = 0 then
            Error('No se procesó ningún material');

        exit(StrSubstNo('✓ Se consumieron %1 materiales (Cantidad total: %2) en la tarea %3 del proyecto %4',
            ProcessedCount, TotalQuantity, JobTaskNo, JobNo));
    end;

    local procedure ValidateJobTask(JobNo: Code[20]; JobTaskNo: Code[20]): Boolean
    var
        JobTask: Record "Job Task";
    begin
        exit(JobTask.Get(JobNo, JobTaskNo));
    end;
}
