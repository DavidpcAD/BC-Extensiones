// ════════════════════════════════════════════════════════════════════════════════
// Codeunit 50259 "GJW Vendor Ident Sync"
// Puente entre la identificación propia del proveedor y los campos donde ese mismo
// dato ya vivía:
//
//   "GJW No. Identificacion"  <->  "VAT Registration No." (86, base) = el CIF/NIF
//   "GJW Tipo Identificacion"  ->  "LLB VAT registration Type" (70830810), de la
//                                  localización de Costa Rica
//
// El campo de la localización se toca por NÚMERO, con FieldRef, y no por dependencia
// a propósito: la localización está instalada en Sandbox pero NO en Production, y una
// dependencia dejaría a AdelanteAPI sin poder instalarse allá. Donde el campo no
// existe, el puente no hace nada y la identificación vive solo en los campos propios;
// el día que instalen la localización en Production, empieza a copiar solo.
//
// El CIF/NIF sí es campo base, así que ese lado del puente funciona en los dos
// entornos y en las dos direcciones.
// ════════════════════════════════════════════════════════════════════════════════
codeunit 50259 "GJW Vendor Ident Sync"
{
    // ── Tipo de identificación: propio -> localización ──────────────────────────
    procedure TipoHaciaLocalizacion(var Proveedor: Record Vendor)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        OrdinalLLB: Integer;
        OrdinalActual: Integer;
    begin
        if not OrdinalLocalizacion(Proveedor."GJW Tipo Identificacion", OrdinalLLB) then
            exit;   // sin definir: LLB no tiene vacío, así que no hay qué copiar

        RecRef.GetTable(Proveedor);
        if not RecRef.FieldExist(CampoTipoLocalizacion()) then
            exit;   // entorno sin la localización instalada (hoy, Production)

        FldRef := RecRef.Field(CampoTipoLocalizacion());
        OrdinalActual := FldRef.Value();
        if OrdinalActual = OrdinalLLB then
            exit;

        FldRef.Validate(OrdinalLLB);
        RecRef.SetTable(Proveedor);
    end;

    // ── Número de identificación: propio -> CIF/NIF ─────────────────────────────
    procedure NumeroHaciaCIFNIF(var Proveedor: Record Vendor)
    begin
        if Proveedor."GJW No. Identificacion" = '' then
            exit;
        if Proveedor."VAT Registration No." = Proveedor."GJW No. Identificacion" then
            exit;

        // Con Validate, para que apliquen las reglas de formato y el registro de IVA
        // igual que si lo hubieran digitado en el campo CIF/NIF.
        Proveedor.Validate("VAT Registration No.", Proveedor."GJW No. Identificacion");
    end;

    // ── Número de identificación: CIF/NIF -> propio ─────────────────────────────
    // Quien digite en Facturación no tiene por qué saber que existe el campo de
    // arriba: se lo llenamos nosotros. La comparación previa corta el rebote, porque
    // el otro lado del puente también llama a Validate.
    [EventSubscriber(ObjectType::Table, Database::Vendor, 'OnAfterValidateEvent', 'VAT Registration No.', false, false)]
    local procedure CIFNIFHaciaNumero(var Rec: Record Vendor)
    var
        Nuevo: Code[20];
    begin
        if Rec.IsTemporary() then
            exit;

        Nuevo := CopyStr(Rec."VAT Registration No.", 1, MaxStrLen(Rec."GJW No. Identificacion"));
        if Rec."GJW No. Identificacion" = Nuevo then
            exit;

        Rec."GJW No. Identificacion" := Nuevo;
    end;

    // ── Arrastre inicial ────────────────────────────────────────────────────────
    // Los proveedores que ya tienen CIF/NIF arrancan con el número propio igual, para
    // no salir a redigitar cientos de cédulas. El TIPO no se adivina: el de LLB dice
    // "Cédula Física" en todos por defecto, así que copiarlo sería inventar el dato
    // —y ese dato termina en la factura electrónica—. Queda en blanco, que es lo
    // honesto y lo que deja ver en la lista a quién le falta.
    procedure RellenarDesdeCIFNIF(): Integer
    var
        Proveedor: Record Vendor;
        Tocados: Integer;
    begin
        Proveedor.SetRange("GJW No. Identificacion", '');
        Proveedor.SetFilter("VAT Registration No.", '<>%1', '');
        if Proveedor.FindSet(true) then
            repeat
                Proveedor."GJW No. Identificacion" :=
                    CopyStr(Proveedor."VAT Registration No.", 1, MaxStrLen(Proveedor."GJW No. Identificacion"));
                Proveedor.Modify(false);
                Tocados += 1;
            until Proveedor.Next() = 0;
        exit(Tocados);
    end;

    // El orden de la lista Option de LLB, que no tiene valor en blanco:
    //   0 Cédula Física · 1 Cédula Jurídica · 2 DIMEX · 3 NITE o Pasaporte Extranjero
    //   4 Extranjero no domiciliado · 5 No contribuyente
    local procedure OrdinalLocalizacion(Tipo: Enum "GJW Tipo Identificacion"; var Ordinal: Integer): Boolean
    begin
        case Tipo of
            Tipo::Fisica:
                Ordinal := 0;
            Tipo::Juridica:
                Ordinal := 1;
            Tipo::DIMEX:
                Ordinal := 2;
            Tipo::NITE:
                Ordinal := 3;
            Tipo::"Extranjero No Domiciliado":
                Ordinal := 4;
            Tipo::"No Contribuyente":
                Ordinal := 5;
            else
                exit(false);
        end;
        exit(true);
    end;

    local procedure CampoTipoLocalizacion(): Integer
    begin
        exit(70830810);   // Vendor."LLB VAT registration Type"
    end;
}
