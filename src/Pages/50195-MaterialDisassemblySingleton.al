page 50195 "GJW Mat Disassembly Single"
{
    PageType = API;
    Caption = 'Material Disassembly Singleton';
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'materialDisassemblyOperation';
    EntitySetName = 'materialDisassemblyOperations';
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
                field(itemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    ToolTip = 'Número del producto a desensamblar';
                }
                field(locationCode; LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                    ToolTip = 'Código del almacén donde está el material';
                }
                field(itemLedgerEntryNo; ItemLedgerEntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item Ledger Entry No.';
                    ToolTip = 'Número del movimiento de almacén del material a desensamblar';
                }
                field(quantity; Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                    ToolTip = 'Cantidad de unidades a desensamblar';
                }
                field(componentsJson; ComponentsJson)
                {
                    ApplicationArea = All;
                    Caption = 'Components JSON';
                    ToolTip = 'JSON con los componentes resultantes del desensamblado';
                }
                field(destinationLocation; DestinationLocation)
                {
                    ApplicationArea = All;
                    Caption = 'Destination Location';
                    ToolTip = 'Almacén destino donde se registrarán los componentes';
                }
                field(executeDisassembly; ExecuteDisassembly)
                {
                    ApplicationArea = All;
                    Caption = 'Execute Disassembly';
                    ToolTip = 'Establecer en true para ejecutar el desensamblado';

                    trigger OnValidate()
                    begin
                        if ExecuteDisassembly then
                            ProcessDisassembly();
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
        ItemNo: Code[20];
        LocationCode: Code[10];
        DestinationLocation: Code[10];
        ItemLedgerEntryNo: Integer;
        Quantity: Decimal;
        ComponentsJson: Text;
        ExecuteDisassembly: Boolean;
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

    local procedure ProcessDisassembly()
    var
        MaterialDisassembly: Codeunit "GJW Material Disassembly";
    begin
        Success := false;
        ResultMessage := '';

        // Validaciones básicas
        if (ItemNo = '') and (ItemLedgerEntryNo = 0) then begin
            ResultMessage := 'Error: Debe especificar un material para desensamblar';
            exit;
        end;

        if Quantity <= 0 then begin
            ResultMessage := 'Error: La cantidad debe ser mayor a cero';
            exit;
        end;
        if ComponentsJson = '' then begin
            ResultMessage := 'Error: Debe especificar los componentes del desensamblado';
            exit;
        end;


        // Ejecutar el desensamblado
        if not TryDisassemble(MaterialDisassembly) then begin
            ResultMessage := 'Error: ' + GetLastErrorText();
            Success := false;
        end else begin
            Success := true;
        end;

        // Resetear el trigger
        ExecuteDisassembly := false;
    end;

    [TryFunction]
    local procedure TryDisassemble(var MaterialDisassembly: Codeunit "GJW Material Disassembly")
    begin
        // Si se especificó destinationLocation, usar la variante hacia destino
        if DestinationLocation <> '' then begin
            if ItemNo <> '' then
                ResultMessage := MaterialDisassembly.DisassembleByItemNoToDestination(ItemNo, LocationCode, Quantity, ComponentsJson, DestinationLocation)
            else
                ResultMessage := MaterialDisassembly.DisassembleToDestination(ItemLedgerEntryNo, Quantity, ComponentsJson, DestinationLocation);
        end else begin
            if ItemNo <> '' then
                ResultMessage := MaterialDisassembly.DisassembleByItemNo(ItemNo, LocationCode, Quantity, ComponentsJson)
            else
                ResultMessage := MaterialDisassembly.DisassembleWithComponents(ItemLedgerEntryNo, Quantity, ComponentsJson);
        end;
    end;
}
