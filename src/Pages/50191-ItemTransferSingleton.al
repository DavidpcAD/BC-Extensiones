page 50191 "GJW Item Transfer Singleton"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'itemTransferBulk';
    EntitySetName = 'itemTransferBulks';
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
                field(resultado; Resultado)
                {
                    Caption = 'Resultado';
                    Editable = false;
                }
            }
        }
    }

    var
        TransfersJSON: Text;
        Ejecutar: Boolean;
        Resultado: Text;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Name := 'ItemTransferBulk';
        Rec.Insert();
    end;

    local procedure ProcesarTransferencias()
    var
        TransferCU: Codeunit "GJW Item Transfer Bulk";
    begin
        Ejecutar := false;

        if TransfersJSON = '' then begin
            Resultado := 'ERROR: No se recibió JSON de transferencias';
            exit;
        end;

        // 🚀 Ejecutar transferencias bulk (crea líneas y registra automáticamente)
        Resultado := TransferCU.ProcessTransfers(TransfersJSON);
    end;
}
