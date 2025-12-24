codeunit 50159 "GJW Process Material Return"
{
    procedure ProcessReturn(var ReturnCommand: Record "GJW Return Command"): Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobJnlLine: Record "Job Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        UnitPrice: Decimal;
        EntryNo: Integer;
    begin
        // Paso 1: Buscar el precio del movimiento original
        ReturnCommand."Success Message" := 'DEBUG: Paso 1 - Buscando precio original';
        if not FindOriginalPrice(ReturnCommand, UnitPrice, EntryNo) then begin
            ReturnCommand."Success Message" := 'ERROR PASO 1: No se encontró el movimiento original - Entry No: ' + Format(ReturnCommand."Item Ledger Entry No.");
            ReturnCommand."Lines Posted" := 0;
            exit(false);
        end;

        // Paso 2: Crear línea de Job Journal (ajuste negativo)
        ReturnCommand."Success Message" := 'DEBUG: Paso 2 - Creando Job Journal Line';
        if not CreateJobJournalLine(ReturnCommand, UnitPrice) then begin
            ReturnCommand."Success Message" := 'ERROR PASO 2: No se pudo crear la línea de Job Journal';
            ReturnCommand."Lines Posted" := 0;
            exit(false);
        end;

        // Paso 3: Crear línea de Item Reclassification Journal
        if not CreateReclassificationLine(ReturnCommand, UnitPrice, EntryNo) then begin
            // El mensaje ya está en Success Message desde CreateReclassificationLine
            ReturnCommand."Lines Posted" := 0;
            exit(false);
        end;

        // Paso 4: Postear Job Journal
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'PROJECT');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if JobJnlLine.FindFirst() then begin
            Commit();
            if not PostJobJournal(JobJnlLine) then begin
                ReturnCommand."Success Message" := 'ERROR: Falló el posteo del Job Journal';
                exit(false);
            end;
        end;

        // Paso 5: Postear Item Reclassification Journal
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEVOLUCION');
        if ItemJnlLine.FindFirst() then begin
            Commit();
            if not PostReclassificationJournal(ItemJnlLine) then begin
                ReturnCommand."Success Message" := 'ERROR: Falló el posteo de la reclasificación';
                exit(false);
            end;
        end;

        // Establecer resultado exitoso
        ReturnCommand."Lines Posted" := 2;
        ReturnCommand."Success Message" := StrSubstNo('✅ Devolución procesada: %1 unidades de %2',
            ReturnCommand.Quantity, ReturnCommand."Item No.");

        exit(true);
    end;

    local procedure FindOriginalPrice(ReturnCommand: Record "GJW Return Command"; var UnitPrice: Decimal; var EntryNo: Integer): Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Si viene el Item Ledger Entry No. específico, usarlo directamente
        if ReturnCommand."Item Ledger Entry No." <> 0 then begin
            if ItemLedgerEntry.Get(ReturnCommand."Item Ledger Entry No.") then begin
                // Usar directamente el precio del Item Ledger Entry
                if ItemLedgerEntry.Quantity <> 0 then
                    UnitPrice := Abs(ItemLedgerEntry."Cost Amount (Actual)" / ItemLedgerEntry.Quantity)
                else
                    UnitPrice := Abs(ItemLedgerEntry."Cost Amount (Actual)");
                EntryNo := ItemLedgerEntry."Entry No.";
                exit(true);
            end else begin
                // Si no se encuentra el Item Ledger Entry, usar precio 0
                UnitPrice := 0;
                EntryNo := ReturnCommand."Item Ledger Entry No.";
                exit(true);
            end;
        end;

        // Si no viene Entry No., buscar el último movimiento del producto en la obra/tarea
        JobLedgerEntry.SetRange("Job No.", ReturnCommand."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", ReturnCommand."Task No.");
        JobLedgerEntry.SetRange("No.", ReturnCommand."Item No.");
        JobLedgerEntry.SetRange("Variant Code", ReturnCommand."Variant Code");
        JobLedgerEntry.SetRange("Location Code", ReturnCommand."Source Location Code");
        JobLedgerEntry.SetFilter("Entry Type", '%1', JobLedgerEntry."Entry Type"::Usage);

        if JobLedgerEntry.FindLast() then begin
            UnitPrice := JobLedgerEntry."Unit Price";
            EntryNo := JobLedgerEntry."Entry No.";
            exit(true);
        end;

        exit(false);
    end;

    local procedure CreateJobJournalLine(ReturnCommand: Record "GJW Return Command"; UnitPrice: Decimal): Boolean
    var
        JobJnlLine: Record "Job Journal Line";
        LineNo: Integer;
    begin
        // Obtener el último número de línea
        JobJnlLine.SetRange("Journal Template Name", 'PROJECT');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if JobJnlLine.FindLast() then
            LineNo := JobJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        // Crear nueva línea
        JobJnlLine.Init();
        JobJnlLine."Journal Template Name" := 'PROJECT';
        JobJnlLine."Journal Batch Name" := 'DEFAULT';
        JobJnlLine."Line No." := LineNo;
        JobJnlLine."Posting Date" := ReturnCommand."Posting Date";
        JobJnlLine."Document No." := 'RETURN-' + Format(CurrentDateTime, 0, '<Year,2><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');
        JobJnlLine."Job No." := ReturnCommand."Job No.";
        JobJnlLine."Job Task No." := ReturnCommand."Task No.";
        JobJnlLine.Type := JobJnlLine.Type::Item;
        JobJnlLine."No." := ReturnCommand."Item No.";
        JobJnlLine."Variant Code" := ReturnCommand."Variant Code";
        JobJnlLine."Location Code" := ReturnCommand."Source Location Code";
        JobJnlLine.Quantity := -ReturnCommand.Quantity; // NEGATIVO
        JobJnlLine."Unit Price" := UnitPrice;
        JobJnlLine."Entry Type" := JobJnlLine."Entry Type"::Usage;

        exit(JobJnlLine.Insert(true));
    end;

    local procedure CreateReclassificationLine(ReturnCommand: Record "GJW Return Command"; UnitPrice: Decimal; ApplyToEntryNo: Integer): Boolean
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlBatch: Record "Item Journal Batch";
        LineNo: Integer;
    begin
        ReturnCommand."Success Message" := 'DEBUG 3.1: Verificando batch DEVOLUCION';

        // Verificar que el batch existe
        if not ItemJnlBatch.Get('TRANSFEREN', 'DEVOLUCION') then begin
            ReturnCommand."Success Message" := 'ERROR 3.1: Batch DEVOLUCION no existe en plantilla TRANSFEREN';
            exit(false);
        end;

        ReturnCommand."Success Message" := 'DEBUG 3.2: Obteniendo último LineNo';

        // Obtener el último número de línea
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEVOLUCION');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        ReturnCommand."Success Message" := 'DEBUG 3.3: Creando línea con LineNo ' + Format(LineNo);

        // Crear nueva línea
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'TRANSFEREN';
        ItemJnlLine."Journal Batch Name" := 'DEVOLUCION';
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine."Posting Date" := ReturnCommand."Posting Date";
        ItemJnlLine."Document No." := 'RETURN-' + Format(CurrentDateTime, 0, '<Year,2><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');
        ItemJnlLine."Item No." := ReturnCommand."Item No.";
        ItemJnlLine."Variant Code" := ReturnCommand."Variant Code";
        ItemJnlLine."Location Code" := ReturnCommand."Source Location Code";
        ItemJnlLine."New Location Code" := ReturnCommand."Destination Location Code";
        ItemJnlLine.Quantity := ReturnCommand.Quantity; // POSITIVO
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";

        // Aplicar al movimiento original para mantener precio
        ItemJnlLine."Applies-to Entry" := ApplyToEntryNo;

        // Intentar insertar con manejo de errores
        ClearLastError();
        if not ItemJnlLine.Insert(true) then begin
            if GetLastErrorText() <> '' then
                ReturnCommand."Success Message" := 'ERROR Insert: ' + GetLastErrorText()
            else
                ReturnCommand."Success Message" := 'ERROR Insert: Falló sin mensaje de error';
            exit(false);
        end;

        ReturnCommand."Success Message" := 'DEBUG: Reclassification line creada exitosamente';
        exit(true);
    end;

    local procedure PostJobJournal(var JobJnlLine: Record "Job Journal Line"): Boolean
    var
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'PROJECT');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');

        if JobJnlLine.FindSet() then
            repeat
                JobJnlPostLine.RunWithCheck(JobJnlLine);
            until JobJnlLine.Next() = 0;

        exit(true);
    end;

    local procedure PostReclassificationJournal(var ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEVOLUCION');

        if ItemJnlLine.FindFirst() then begin
            Commit();
            ItemJnlPostBatch.Run(ItemJnlLine);
        end;

        exit(true);
    end;
}
