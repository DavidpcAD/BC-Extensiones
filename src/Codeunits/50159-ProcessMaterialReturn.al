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
        if not FindOriginalPrice(ReturnCommand, UnitPrice, EntryNo) then begin
            ReturnCommand."Success Message" := 'ERROR: No se encontró el movimiento original para obtener el precio';
            exit(false);
        end;

        // Paso 2: Crear línea de Job Journal (ajuste negativo)
        if not CreateJobJournalLine(ReturnCommand, UnitPrice) then begin
            ReturnCommand."Success Message" := 'ERROR: No se pudo crear la línea de Job Journal';
            exit(false);
        end;

        // Paso 3: Crear línea de Item Reclassification Journal
        if not CreateReclassificationLine(ReturnCommand, UnitPrice, EntryNo) then begin
            ReturnCommand."Success Message" := 'ERROR: No se pudo crear la línea de reclasificación';
            exit(false);
        end;

        // Paso 4: Postear Job Journal
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'JOB');
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
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
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
    begin
        // Buscar el último movimiento del producto en la obra/tarea
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
        JobJnlLine.SetRange("Journal Template Name", 'JOB');
        JobJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if JobJnlLine.FindLast() then
            LineNo := JobJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        // Crear nueva línea
        JobJnlLine.Init();
        JobJnlLine."Journal Template Name" := 'JOB';
        JobJnlLine."Journal Batch Name" := 'DEFAULT';
        JobJnlLine."Line No." := LineNo;
        JobJnlLine."Posting Date" := ReturnCommand."Posting Date";
        JobJnlLine."Document No." := 'RETURN-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');
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
        LineNo: Integer;
    begin
        // Obtener el último número de línea
        ItemJnlLine.SetRange("Journal Template Name", 'TRANSFEREN');
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');
        if ItemJnlLine.FindLast() then
            LineNo := ItemJnlLine."Line No." + 10000
        else
            LineNo := 10000;

        // Crear nueva línea
        ItemJnlLine.Init();
        ItemJnlLine."Journal Template Name" := 'TRANSFEREN';
        ItemJnlLine."Journal Batch Name" := 'DEFAULT';
        ItemJnlLine."Line No." := LineNo;
        ItemJnlLine."Posting Date" := ReturnCommand."Posting Date";
        ItemJnlLine."Document No." := 'RETURN-' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');
        ItemJnlLine."Item No." := ReturnCommand."Item No.";
        ItemJnlLine."Variant Code" := ReturnCommand."Variant Code";
        ItemJnlLine."Location Code" := ReturnCommand."Source Location Code";
        ItemJnlLine."New Location Code" := ReturnCommand."Destination Location Code";
        ItemJnlLine.Quantity := ReturnCommand.Quantity; // POSITIVO
        ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
        ItemJnlLine."Value Entry Type" := ItemJnlLine."Value Entry Type"::"Direct Cost";

        // Aplicar al movimiento original para mantener precio
        ItemJnlLine."Applies-to Entry" := ApplyToEntryNo;

        exit(ItemJnlLine.Insert(true));
    end;

    local procedure PostJobJournal(var JobJnlLine: Record "Job Journal Line"): Boolean
    var
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
    begin
        JobJnlLine.Reset();
        JobJnlLine.SetRange("Journal Template Name", 'JOB');
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
        ItemJnlLine.SetRange("Journal Batch Name", 'DEFAULT');

        if ItemJnlLine.FindFirst() then begin
            Commit();
            ItemJnlPostBatch.Run(ItemJnlLine);
        end;

        exit(true);
    end;
}
