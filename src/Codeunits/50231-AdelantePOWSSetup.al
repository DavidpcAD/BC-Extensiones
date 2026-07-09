// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50231 "Adelante PO WS Setup"
// Registra el codeunit "Adelante PO Actions" como Web Service publicado ("AdelantePO")
// para que quede expuesto por OData V4 sin tener que registrarlo a mano en la página
// Web Services. Idempotente: si ya existe, no hace nada.
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50231 "Adelante PO WS Setup"
{
    Access = Internal;

    procedure Register()
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        if TenantWebService.Get(TenantWebService."Object Type"::Codeunit, 'AdelantePO') then begin
            if not TenantWebService.Published then begin
                TenantWebService.Published := true;
                TenantWebService.Modify(true);
            end;
            exit;
        end;
        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Codeunit;
        TenantWebService."Object ID" := Codeunit::"Adelante PO Actions";
        TenantWebService."Service Name" := 'AdelantePO';
        TenantWebService.Published := true;
        TenantWebService.Insert(true);
    end;
}
