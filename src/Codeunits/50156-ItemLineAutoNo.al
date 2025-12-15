codeunit 50156 "Item Journal Line AutoNo"
{
    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure AssignLineNo(var Rec: Record "Item Journal Line"; RunTrigger: Boolean)
    var
        IL: Record "Item Journal Line";
        MaxLineNo: Integer;
        ProposedLineNo: Integer;
    begin
        // Solo generar si viene vacío (API / integraciones)
        if Rec."Line No." = 0 then begin
            IL.SetRange("Journal Template Name", Rec."Journal Template Name");
            IL.SetRange("Journal Batch Name", Rec."Journal Batch Name");

            // Buscar el máximo Line No. actual
            if IL.FindLast() then
                MaxLineNo := IL."Line No."
            else
                MaxLineNo := 0;

            // Proponer nuevo Line No.
            ProposedLineNo := MaxLineNo + 10000;

            // Verificar que NO exista (por si hay gaps o concurrencia)
            IL.Reset();
            IL.SetRange("Journal Template Name", Rec."Journal Template Name");
            IL.SetRange("Journal Batch Name", Rec."Journal Batch Name");
            IL.SetRange("Line No.", ProposedLineNo);

            // Si ya existe, seguir buscando un número libre
            while IL.FindFirst() do begin
                ProposedLineNo += 10000;
                IL.SetRange("Line No.", ProposedLineNo);
            end;

            Rec."Line No." := ProposedLineNo;
        end;
    end;
}
