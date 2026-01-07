codeunit 50125 "GJW WorkLines Bulk Unbound"
{
    [ServiceEnabled]
    procedure BulkImport(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        BulkCU: Codeunit "GJW WorkLines Bulk";
    begin
        exit(BulkCU.Import(jsonNuevos, jsonEditados, jsonEliminados));
    end;
}
