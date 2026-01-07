page 50127 "GJW WorkLines Bulk API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'workLineBulkOperation';
    EntitySetName = 'workLineBulkOperations';
    SourceTable = "GomJob Works Line";
    DelayedInsert = true;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

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

    [ServiceEnabled]
    procedure BulkImport(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        BulkCU: Codeunit "GJW WorkLines Bulk";
    begin
        exit(BulkCU.Import(jsonNuevos, jsonEditados, jsonEliminados));
    end;
}
