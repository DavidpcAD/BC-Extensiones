// ════════════════════════════════════════════════════════════════════════════════
// TableExtension 50256 "GJW Vendor Ext" extends Vendor (23)
// Identificación del proveedor: tipo (física / jurídica) y número de cédula.
// Son obligatorios al crear un proveedor; quien hace valer esa obligación es la
// ficha (PageExtension 50257), que no deja salir sin ellos. El chequeo vive aquí,
// en GJWTestIdentificacion, para poder exigirlo también desde otro lado el día que
// haga falta (p. ej. antes de registrar un documento de compra).
// ════════════════════════════════════════════════════════════════════════════════
tableextension 50256 "GJW Vendor Ext" extends Vendor
{
    fields
    {
        field(50100; "GJW Tipo Identificacion"; Enum "GJW Tipo Identificacion")
        {
            Caption = 'Tipo de identificación';
            DataClassification = CustomerContent;
            ToolTip = 'Indica si el proveedor es persona física o persona jurídica.';
        }
        field(50101; "GJW No. Identificacion"; Code[20])
        {
            Caption = 'Número de identificación';
            DataClassification = CustomerContent;
            ToolTip = 'Especifica el número de cédula del proveedor, física o jurídica según el tipo de identificación.';
        }
    }

    var
        FaltaTipoErr: Label 'Indique el tipo de identificación (persona física o jurídica) del proveedor %1.\Si lo creó por error, elimine la ficha.', Comment = '%1 = N.º del proveedor';
        FaltaNumeroErr: Label 'Indique el número de identificación del proveedor %1.\Si lo creó por error, elimine la ficha.', Comment = '%1 = N.º del proveedor';

    // Reclama los dos datos. Nombra al proveedor en el mensaje porque el error sale
    // al cerrar la ficha, cuando el usuario ya puede no tener la pantalla enfrente.
    procedure GJWTestIdentificacion()
    begin
        if "GJW Tipo Identificacion" = "GJW Tipo Identificacion"::" " then
            Error(FaltaTipoErr, "No.");
        if "GJW No. Identificacion" = '' then
            Error(FaltaNumeroErr, "No.");
    end;
}
