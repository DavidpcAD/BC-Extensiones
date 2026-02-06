page 50194 "GJW Material Consump Singleton"
{
    PageType = API;
    Caption = 'Material Consumption Singleton';
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'materialConsumptionOperation';
    EntitySetName = 'materialConsumptionOperations';
    DelayedInsert = true;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    ODataKeyFields = ID;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID';
                }
                field(itemLedgerEntryNos; ItemLedgerEntryNos)
                {
                    ApplicationArea = All;
                    Caption = 'Item Ledger Entry Nos (comma separated)';
                    ToolTip = 'Lista de Entry Nos separados por comas. Ejemplo: 62386,62394,62396';
                }
                field(jobNo; JobNo)
                {
                    ApplicationArea = All;
                    Caption = 'Job No.';
                    ToolTip = 'Número del proyecto donde se consumirán los materiales';
                }
                field(jobTaskNo; JobTaskNo)
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.';
                    ToolTip = 'Número de la tarea del proyecto';
                }
                field(documentNo; DocumentNo)
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                    ToolTip = 'Número de documento de la boleta de entrega (ej: BE000123)';
                }
                field(executeConsumption; ExecuteConsumption)
                {
                    ApplicationArea = All;
                    Caption = 'Execute Consumption';
                    ToolTip = 'Establecer en true para ejecutar el consumo de materiales';

                    trigger OnValidate()
                    begin
                        if ExecuteConsumption then
                            ProcessMaterialConsumption();
                    end;
                }
                field(result; ResultMessage)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    Editable = false;
                }
                field(success; Success)
                {
                    ApplicationArea = All;
                    Caption = 'Success';
                    Editable = false;
                }
            }
        }
    }

    var
        ItemLedgerEntryNos: Text;
        JobNo: Code[20];
        JobTaskNo: Code[20];
        DocumentNo: Code[20];
        ExecuteConsumption: Boolean;
        ResultMessage: Text;
        Success: Boolean;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.ID := 1;
            Rec.Insert();
        end;
    end;

    local procedure ProcessMaterialConsumption()
    var
        MaterialConsumption: Codeunit "GJW Material Consumption";
    begin
        Success := false;
        ResultMessage := '';

        // Validaciones básicas
        if ItemLedgerEntryNos = '' then begin
            ResultMessage := 'Error: No se especificaron materiales para consumir';
            exit;
        end;

        if JobNo = '' then begin
            ResultMessage := 'Error: Debe especificar el número de proyecto';
            exit;
        end;

        if DocumentNo = '' then begin
            ResultMessage := 'Error: Debe especificar el número de documento';
            exit;
        end;

        // Ejecutar el consumo
        if not TryConsumeWarehouseMaterials(MaterialConsumption) then begin
            ResultMessage := 'Error: ' + GetLastErrorText();
            Success := false;
        end else begin
            Success := true;
        end;

        // Resetear el trigger
        ExecuteConsumption := false;
    end;

    [TryFunction]
    local procedure TryConsumeWarehouseMaterials(var MaterialConsumption: Codeunit "GJW Material Consumption")
    begin
        ResultMessage := MaterialConsumption.ConsumeWarehouseMaterials(ItemLedgerEntryNos, JobNo, JobTaskNo, DocumentNo);
    end;
}
