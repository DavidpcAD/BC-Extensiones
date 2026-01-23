page 50171 "GJW Assembly Bulk API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'production';
    APIVersion = 'v1.0';
    EntityName = 'assemblyBulkOperation';
    EntitySetName = 'assemblyBulkOperations';
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
                field(productsJson; ProductsJson)
                {
                    Caption = 'Products JSON';
                }
                field(componentsJson; ComponentsJson)
                {
                    Caption = 'Components JSON';
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
        ProductsJson: Text;
        ComponentsJson: Text;
        Ejecutar: Boolean;
        Resultado: Text;

    trigger OnOpenPage()
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.ID := 1;
        Rec.Name := 'AssemblyBulkOperation';
        Rec.Insert();
    end;

    local procedure ProcesarBulk()
    var
        AssemblyBulkProcessor: Codeunit "GJW Assembly Bulk Processor";
    begin
        Ejecutar := false;

        if ProductsJson = '' then begin
            Resultado := 'Error: Products JSON es obligatorio';
            exit;
        end;

        if ComponentsJson = '' then begin
            Resultado := 'Error: Components JSON es obligatorio';
            exit;
        end;

        // Procesar bulk assembly
        Resultado := AssemblyBulkProcessor.ProcessBulkAssembly(ProductsJson, ComponentsJson);
    end;
}
