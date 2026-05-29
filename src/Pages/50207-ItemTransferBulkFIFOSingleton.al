page 50207 "GJW Item Transfer FIFO API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';

    EntityName = 'itemTransferBulkFifoOperation';
    EntitySetName = 'itemTransferBulkFifoOperations';

    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;

    ODataKeyFields = ID;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    Caption = 'Id';
                }

                field(transfersJSON; TransfersJSON)
                {
                    Caption = 'Transfers JSON';
                    ToolTip = 'Arreglo JSON con multiples lineas FIFO. Cada linea debe traer sourceEntryNo/appliesFromEntry.';
                }

                field(ejecutar; Ejecutar)
                {
                    Caption = 'Ejecutar';

                    trigger OnValidate()
                    begin
                        if Ejecutar then
                            ProcesarTransferencias();
                    end;
                }

                field(success; Success)
                {
                    Caption = 'Success';
                    Editable = false;
                }

                field(resultado; Resultado)
                {
                    Caption = 'Resultado';
                    Editable = false;
                }

                field(jsonResults; JsonResults)
                {
                    Caption = 'JSON Results';
                    Editable = false;
                }
            }
        }
    }

    var
        TransfersJSON: Text;
        Ejecutar: Boolean;
        Success: Boolean;
        Resultado: Text;
        JsonResults: Text;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Name := 'ItemTransferBulkFIFO';
        Rec.Insert();
    end;

    local procedure ProcesarTransferencias()
    var
        TransferCU: Codeunit "GJW Item Transfer Bulk FIFO";
    begin
        Ejecutar := false;
        Success := false;
        Resultado := '';
        JsonResults := '[]';

        if TransfersJSON = '' then begin
            Resultado := 'ERROR: No se recibio JSON de transferencias';
            exit;
        end;

        Resultado := TransferCU.ProcessTransfersWithTrace(TransfersJSON, JsonResults);
        Success := CopyStr(Resultado, 1, 3) = 'OK:';
    end;
}
