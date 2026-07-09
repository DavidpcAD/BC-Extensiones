// Registra el web service "AdelantePO" cuando la extensión ya estaba instalada y
// se publica una versión nueva (upgrade). Como AdelanteAPI ya está instalada en BC,
// este es el trigger que efectivamente correrá al subir esta versión.
codeunit 50233 "Adelante PO Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    var
        Setup: Codeunit "Adelante PO WS Setup";
    begin
        Setup.Register();
    end;
}
