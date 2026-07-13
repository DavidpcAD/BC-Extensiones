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
    begin
        RegisterService(Codeunit::"Adelante PO Actions", 'AdelantePO');
        RegisterService(Codeunit::"Adelante Obra Actions", 'AdelanteObra');
    end;

    local procedure RegisterService(objectId: Integer; serviceName: Text[240])
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        if TenantWebService.Get(TenantWebService."Object Type"::Codeunit, serviceName) then begin
            if not TenantWebService.Published then begin
                TenantWebService.Published := true;
                TenantWebService.Modify(true);
            end;
            exit;
        end;
        TenantWebService.Init();
        TenantWebService."Object Type" := TenantWebService."Object Type"::Codeunit;
        TenantWebService."Object ID" := objectId;
        TenantWebService."Service Name" := CopyStr(serviceName, 1, MaxStrLen(TenantWebService."Service Name"));
        TenantWebService.Published := true;
        TenantWebService.Insert(true);
    end;
}
