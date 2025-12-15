codeunit 50155 "Job Journal Line AutoNo"
{
    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure AssignLineNo(var Rec: Record "Job Journal Line"; RunTrigger: Boolean)
    var
        JL: Record "Job Journal Line";
        MaxLineNo: Integer;
        ProposedLineNo: Integer;
    begin
        // Solo generar si viene vacío (API / integraciones)
        if Rec."Line No." = 0 then begin
            JL.SetRange("Journal Template Name", Rec."Journal Template Name");
            JL.SetRange("Journal Batch Name", Rec."Journal Batch Name");

            // Buscar el máximo Line No. actual
            if JL.FindLast() then
                MaxLineNo := JL."Line No."
            else
                MaxLineNo := 0;


            // Proponer nuevo Line No.
            ProposedLineNo := MaxLineNo + 10000;


            // Verificar que NO exista (por si hay gaps o concurrencia)
            JL.Reset();
            JL.SetRange("Journal Template Name", Rec."Journal Template Name");
            JL.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            JL.SetRange("Line No.", ProposedLineNo);

            // Si ya existe, seguir buscando un número libre
            while JL.FindFirst() do begin
                ProposedLineNo += 10000;
                JL.SetRange("Line No.", ProposedLineNo);
            end;

            Rec."Line No." := ProposedLineNo;
        end;
    end;
}
