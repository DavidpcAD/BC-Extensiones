// ════════════════════════════════════════════════════════════════════════════════
// PageExtension 50257 "GJW Vendor Card Ext" extends "Vendor Card" (26)
// Los dos campos de identificación quedan en General, debajo del Nombre, marcados
// como obligatorios (ShowMandatory) y exigidos de verdad al cerrar la ficha: BC
// inserta el proveedor en cuanto se le asigna el N.º, así que el único momento en
// que se le puede reclamar el dato sin trabar la digitación es la salida.
//
// La exigencia es SOLO para el proveedor que se acaba de crear en esta ficha. A los
// que ya existían se les muestra el campo vacío pero no se les cierra la puerta: si
// no, cualquiera que abra un proveedor viejo a consultar queda atrapado en la página
// hasta conseguir la cédula.
// ════════════════════════════════════════════════════════════════════════════════
pageextension 50257 "GJW Vendor Card Ext" extends "Vendor Card"
{
    layout
    {
        addafter(Name)
        {
            field("GJW Tipo Identificacion"; Rec."GJW Tipo Identificacion")
            {
                ApplicationArea = All;
                Caption = 'Tipo de identificación';
                ShowMandatory = true;
                ToolTip = 'Indica si el proveedor es persona física o persona jurídica.';
            }
            field("GJW No. Identificacion"; Rec."GJW No. Identificacion")
            {
                ApplicationArea = All;
                Caption = 'Número de identificación';
                ShowMandatory = true;
                ToolTip = 'Especifica el número de cédula del proveedor, física o jurídica según el tipo de identificación.';
            }
        }
    }

    var
        ProveedorNuevo: Boolean;
        NoProveedorNuevo: Code[20];

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ProveedorNuevo := true;
        NoProveedorNuevo := '';
    end;

    trigger OnAfterGetCurrRecord()
    begin
        // El N.º no se conoce en el OnNewRecord (lo pone la serie o el usuario); el
        // primero que aparece después es el del proveedor recién creado.
        if ProveedorNuevo and (NoProveedorNuevo = '') then
            NoProveedorNuevo := Rec."No.";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Proveedor: Record Vendor;
    begin
        if not ProveedorNuevo then
            exit(true);
        // Se creó uno y luego se navegó con las flechas a otro: el de al lado es
        // ajeno a esta creación.
        if (NoProveedorNuevo <> '') and (Rec."No." <> NoProveedorNuevo) then
            exit(true);
        // Ficha en blanco (Nuevo y nada digitado) o proveedor eliminado desde la
        // misma ficha: no hay nada que reclamar.
        if Rec."No." = '' then
            exit(true);
        if not Proveedor.Get(Rec."No.") then
            exit(true);

        Proveedor.GJWTestIdentificacion();
        exit(true);
    end;
}
