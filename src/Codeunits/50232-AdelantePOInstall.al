// Registra el web service "AdelantePO" en una instalación NUEVA de la extensión.
codeunit 50232 "Adelante PO Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    var
        Setup: Codeunit "Adelante PO WS Setup";
    begin
        Setup.Register();
    end;
}
