codeunit 50115 "GJW WorksDecomp Bulk Unbound"
{
    // ✅ Este procedimiento es UNBOUND - se puede llamar directamente desde API
    [ServiceEnabled]
    procedure BulkImport(jsonNuevos: Text; jsonEditados: Text; jsonEliminados: Text): Text;
    var
        BulkCU: Codeunit "GJW WorksDecomp Bulk";
    begin
        exit(BulkCU.Import(jsonNuevos, jsonEditados, jsonEliminados));
    end;
}
