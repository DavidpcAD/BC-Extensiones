// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50260 "GJW Vendor Ident Upgrade"
// Al subir la versión, copia el CIF/NIF que ya tenían los proveedores al campo
// propio de número de identificación. Es idempotente: solo toca a los que tienen el
// campo propio vacío, así que correrlo de nuevo no hace nada.
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50260 "GJW Vendor Ident Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
        Puente: Codeunit "GJW Vendor Ident Sync";
    begin
        Puente.RellenarDesdeCIFNIF();
    end;
}
