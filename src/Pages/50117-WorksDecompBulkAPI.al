page 50117 "GJW WorksDecomp Bulk API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'workDecompBulk';
    EntitySetName = 'workDecompBulks';
    SourceTable = "GomJob Works Decomposed Lines";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            field(id; Rec.SystemId)
            {
                Caption = 'Id';
                Editable = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportJSON)
            {
                Caption = 'Import JSON Lines';
                ApplicationArea = All;

                trigger OnAction()
                var
                    BulkCU: Codeunit "GJW WorksDecomp Bulk";
                    Response: Text;
                    InputNuevos: Text;
                    InputEditados: Text;
                    InputEliminados: Text;
                begin
                    // ⚙️ Simulación: esto se usa solo desde API, no manualmente
                    InputNuevos := '[]';
                    InputEditados := '[]';
                    InputEliminados := '[]';

                    Response := BulkCU.Import(InputNuevos, InputEditados, InputEliminados);
                    Message(Response);
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        BulkCU: Codeunit "GJW WorksDecomp Bulk";
        Response: Text;
    begin
        // ⚠️ Este trigger se usa solo para llamadas vía POST manuales
        if Rec.Description <> '' then
            Response := BulkCU.Import(Rec.Description, '[]', '[]')
        else
            Response := 'No se recibió JSON válido.';

        Message(Response);
        exit(false);
    end;
}
