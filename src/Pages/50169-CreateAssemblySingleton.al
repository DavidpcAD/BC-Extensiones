page 50169 "GJW Create Assembly Singleton"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'production';
    APIVersion = 'v1.0';
    EntityName = 'createAssemblyOperation';
    EntitySetName = 'createAssemblyOperations';
    SourceTable = Integer;
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = Number;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(number; Rec.Number)
                {
                    Caption = 'Number';
                }
                field(itemNo; ItemNo)
                {
                    Caption = 'Item No.';
                }
                field(quantity; Quantity)
                {
                    Caption = 'Quantity';
                }
                field(locationCode; LocationCode)
                {
                    Caption = 'Location Code';
                }
                field(componentsJson; ComponentsJson)
                {
                    Caption = 'Components JSON';
                }
                field(assemblyOrderNo; AssemblyOrderNo)
                {
                    Caption = 'Assembly Order No.';
                }
                field(resultMessage; ResultMessage)
                {
                    Caption = 'Result Message';
                }
            }
        }
    }

    var
        ItemNo: Code[20];
        Quantity: Decimal;
        LocationCode: Code[10];
        ComponentsJson: Text;
        AssemblyOrderNo: Code[20];
        ResultMessage: Text[250];

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        CreateAssemblyHandler: Codeunit "GJW Create Assembly Handler";
    begin
        if ItemNo = '' then
            Error('Item No. is required');

        if Quantity <= 0 then
            Error('Quantity must be greater than 0');

        if LocationCode = '' then
            Error('Location Code is required');

        // Crear Assembly Order con componentes y lotes
        AssemblyOrderNo := CreateAssemblyHandler.CreateAssemblyWithLots(
            ItemNo,
            Quantity,
            LocationCode,
            ComponentsJson
        );

        ResultMessage := 'Assembly Order ' + AssemblyOrderNo + ' created successfully';

        exit(true);
    end;
}
