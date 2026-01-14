page 50192 "GJW ProdLines Bulk Singleton"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'productionLineBulk';
    EntitySetName = 'productionLineBulks';
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
                field(worksNo; WorksNo)
                {
                    Caption = 'Works No.';
                }
                field(lineasJSON; LineasJSON)
                {
                    Caption = 'Lineas JSON';
                }
                field(ejecutar; Ejecutar)
                {
                    Caption = 'Ejecutar';

                    trigger OnValidate()
                    begin
                        if Ejecutar then
                            ProcesarBulk();
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
        WorksNo: Code[20];
        LineasJSON: Text;
        Ejecutar: Boolean;
        Resultado: Text;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Name := 'ProdLinesBulk';
        Rec.Insert();
    end;

    local procedure ProcesarBulk()
    var
        BulkCU: Codeunit "GJW ProdLines Bulk";
    begin
        Ejecutar := false;

        if WorksNo = '' then begin
            Resultado := 'Error: Works No. es obligatorio';
            exit;
        end;

        if LineasJSON = '' then
            LineasJSON := '[]';

        // Llamar al codeunit de procesamiento masivo
        Resultado := BulkCU.Import(LineasJSON);
    end;
}
