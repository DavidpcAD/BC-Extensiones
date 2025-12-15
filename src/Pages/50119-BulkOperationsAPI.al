page 50119 "GJW Bulk Operations API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'bulkOperation';
    EntitySetName = 'bulkOperations';

    SourceTable = Integer;
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            field(number; Rec.Number)
            {
                Caption = 'Number';
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get(0) then begin
            Rec.Number := 0;
            Rec.Insert();
        end;
    end;

    [ServiceEnabled]
    [Scope('Cloud')]
    procedure importBulk(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text) resultado: Text
    var
        BulkCU: Codeunit "GJW WorksDecomp Bulk";
    begin
        resultado := BulkCU.Import(jsonNuevos, jsonEditados, jsonEliminados);
    end;
}
