page 50118 "GJW WorksDecomp Bulk Single"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'workDecompBulkOperation';
    EntitySetName = 'workDecompBulkOperations';
    SourceTable = "GomJob Works Decomposed Lines";
    DelayedInsert = true;

    // ⚡ Configuración para permitir llamadas directas
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

    // ✅ Procedimiento UNBOUND - se llama directamente sin ID de registro
    [ServiceEnabled]
    procedure BulkImport(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        BulkCU: Codeunit "GJW WorksDecomp Bulk";
    begin
        exit(BulkCU.Import(jsonNuevos, jsonEditados, jsonEliminados));
    end;
}
