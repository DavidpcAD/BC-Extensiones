codeunit 50190 "GJW Create Job Journal Line"
{
    procedure CreateLine(JobNo: Code[20]; JobTaskNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; Desc: Text[100]): Boolean
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        LineNo: Integer;
    begin
        // Validar que existan Template y Batch
        if not JobJnlTemplate.Get('PROJECT') then
            Error('Template PROJECT no existe');

        if not JobJnlBatch.Get('PROJECT', 'DEFAULT') then
            Error('Batch DEFAULT no existe en template PROJECT');

        // Obtener siguiente Line No.
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

        // Asignación directa SIN validar para evitar errores de relación
        JobJnlLine."Job No." := JobNo;
        JobJnlLine."Job Task No." := JobTaskNo;
        JobJnlLine."Line Type" := JobJnlLine."Line Type"::"Both Budget and Billable";  // CRÍTICO para devoluciones
        JobJnlLine.Type := JobJnlLine.Type::Item;
        JobJnlLine."No." := ItemNo;
        JobJnlLine.Quantity := Qty;
        JobJnlLine."Unit Cost" := UnitPrice;  // CRÍTICO: Usar Unit Cost en vez de Unit Price
        JobJnlLine."Unit Price" := UnitPrice;
        JobJnlLine.Description := Desc;
        JobJnlLine."Posting Date" := WorkDate();
        JobJnlLine."Document No." := JobNo; // Usar Job No. como Doc No.
        JobJnlLine."Shortcut Dimension 1 Code" := JobNo; // CRÍTICO: Global Dimension 1

        JobJnlLine.Insert(false); // false = sin validaciones

        exit(true);
    end;
}