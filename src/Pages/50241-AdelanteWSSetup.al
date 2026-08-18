// ════════════════════════════════════════════════════════════════════════════════
// Page 50241 "Adelante WS Setup"
// Red de seguridad para PUBLICAR los Web Services de codeunit (AdelantePO / AdelanteObra)
// cuando el despliegue es por RAP desde VS Code, que NO ejecuta el trigger de Upgrade.
//
// El registro real, idempotente, lo hace el codeunit 50231 "Adelante PO WS Setup".
//   · Install  (50232 OnInstallAppPerDatabase) ya llama Register() en instalación nueva.
//   · Upgrade  (50233 OnUpgradePerDatabase)     ya llama Register() en upgrade gestionado.
//   · Esta página  = el botón manual para el caso RAP (VS Code), donde no corre ninguno.
//
// Buscar en BC como: "Publicar Web Services Adelante".
// ════════════════════════════════════════════════════════════════════════════════
page 50241 "Adelante WS Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Publicar Web Services Adelante';

    layout
    {
        area(content)
        {
            group(Estado)
            {
                Caption = 'Estado actual en este entorno';
                field(EstadoPO; EstadoPOTxt)
                {
                    ApplicationArea = All;
                    Caption = 'AdelantePO (codeunit 50230)';
                    Editable = false;
                }
                field(EstadoObra; EstadoObraTxt)
                {
                    ApplicationArea = All;
                    Caption = 'AdelanteObra (codeunit 50240)';
                    Editable = false;
                }
            }
            group(Ayuda)
            {
                Caption = 'Qué hace';
                InstructionalText = 'Publica (o republica) los Web Services de codeunit AdelantePO y AdelanteObra para exponerlos por OData V4. Úsalo después de publicar desde VS Code (RAP), que no ejecuta el upgrade. Es idempotente: si ya están publicados, no cambia nada.';
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Publicar)
            {
                ApplicationArea = All;
                Caption = 'Publicar / Republicar Web Services';
                ToolTip = 'Registra y publica los Web Services AdelantePO y AdelanteObra en este entorno.';
                Image = Web;

                trigger OnAction()
                var
                    Setup: Codeunit "Adelante PO WS Setup";
                begin
                    Setup.Register();
                    CargarEstado();
                    CurrPage.Update(false);
                    Message('Web Services publicados en este entorno:\- AdelantePO (codeunit 50230)\- AdelanteObra (codeunit 50240)\\Ya puedes invocar AdelantePO_ReopenOrder y las demás acciones por OData V4.');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';
                actionref(Publicar_Promoted; Publicar) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CargarEstado();
    end;

    var
        EstadoPOTxt: Text;
        EstadoObraTxt: Text;

    local procedure CargarEstado()
    begin
        EstadoPOTxt := EstadoServicio('AdelantePO');
        EstadoObraTxt := EstadoServicio('AdelanteObra');
    end;

    local procedure EstadoServicio(serviceName: Text[240]): Text
    var
        TenantWebService: Record "Tenant Web Service";
    begin
        if not TenantWebService.Get(TenantWebService."Object Type"::Codeunit, serviceName) then
            exit('No registrado');
        if TenantWebService.Published then
            exit('Publicado')
        else
            exit('Registrado pero NO publicado');
    end;
}
