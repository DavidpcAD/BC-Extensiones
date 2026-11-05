// Page 50270: lista editable de usuario de app → nombre completo (ver tabla 50270).
page 50270 "GJW Usuarios App Nombres"
{
    PageType = List;
    Caption = 'Nombres de usuarios de apps';
    SourceTable = "GJW Usuario App Nombre";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Usuario; Rec.Usuario)
                {
                    ApplicationArea = All;
                    ToolTip = 'Usuario con el que la persona entra a la app (Digitación, Boletas).';
                }
                field(Nombre; Rec.Nombre)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre completo que se muestra en "Digitado por" de los Movs. producto.';
                }
            }
        }
    }
}
