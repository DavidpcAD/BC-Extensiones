// ════════════════════════════════════════════════════════════════════════════════
// TableExtension 50256 "GJW Vendor Ext" extends Vendor (23)
// Identificación del proveedor: tipo (cédula física, jurídica, DIMEX...) y número.
// Son obligatorios al crear un proveedor; quien hace valer esa obligación es la
// ficha (PageExtension 50257), que no deja salir sin ellos. El chequeo vive aquí,
// en GJWTestIdentificacion, para poder exigirlo también desde otro lado el día que
// haga falta (p. ej. antes de registrar un documento de compra).
//
// Los dos campos NO son un dato aparte: se copian a los que ya existían para lo
// mismo —el CIF/NIF de la base y el "Tipo de identificación" de la localización de
// Costa Rica— a través del codeunit 50259, que es donde está explicado el puente.
// ════════════════════════════════════════════════════════════════════════════════
tableextension 50256 "GJW Vendor Ext" extends Vendor
{
    fields
    {
        field(50100; "GJW Tipo Identificacion"; Enum "GJW Tipo Identificacion")
        {
            Caption = 'Tipo de identificación';
            DataClassification = CustomerContent;
            ToolTip = 'Especifica con qué documento se identifica el proveedor ante Hacienda. Es el mismo dato que el Tipo de identificación de la sección Facturación.';

            trigger OnValidate()
            var
                Puente: Codeunit "GJW Vendor Ident Sync";
            begin
                Puente.TipoHaciaLocalizacion(Rec);
            end;
        }
        field(50101; "GJW No. Identificacion"; Code[20])
        {
            Caption = 'Número de identificación';
            DataClassification = CustomerContent;
            ToolTip = 'Especifica el número de cédula del proveedor. Es el mismo dato que el CIF/NIF de la sección Facturación: lo que se digite aquí se copia allá y al revés.';

            trigger OnValidate()
            var
                Puente: Codeunit "GJW Vendor Ident Sync";
            begin
                Puente.NumeroHaciaCIFNIF(Rec);
            end;
        }
    }

    var
        FaltaTipoErr: Label 'Indique el tipo de identificación del proveedor %1.\Si lo creó por error, elimine la ficha.', Comment = '%1 = N.º del proveedor';
        FaltaNumeroErr: Label 'Indique el número de identificación del proveedor %1.\Si lo creó por error, elimine la ficha.', Comment = '%1 = N.º del proveedor';

    // Reclama los dos datos. Nombra al proveedor en el mensaje porque el error sale
    // al cerrar la ficha, cuando el usuario ya puede no tener la pantalla enfrente.
    procedure GJWTestIdentificacion()
    begin
        if Rec."GJW Tipo Identificacion" = Rec."GJW Tipo Identificacion"::" " then
            Error(FaltaTipoErr, Rec."No.");
        if Rec."GJW No. Identificacion" = '' then
            Error(FaltaNumeroErr, Rec."No.");
    end;
}
