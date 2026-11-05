// ════════════════════════════════════════════════════════════════════════════════
// Page 50271 "GJW Usuario App Nombre API"
// GET/POST/PATCH .../construction/v1.0/companies(..)/usuarioAppNombres
//   { "usuario": "jessieCor", "nombre": "Jessie Cordero Mena" }
// La sincroniza el script de Boletas desde AdelantePRO (dbo.V_Colaborador).
// ════════════════════════════════════════════════════════════════════════════════
page 50271 "GJW Usuario App Nombre API"
{
    PageType = API;
    Caption = 'Usuario App Nombre';
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'usuarioAppNombre';
    EntitySetName = 'usuarioAppNombres';
    SourceTable = "GJW Usuario App Nombre";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(usuario; Rec.Usuario)
                {
                    Caption = 'Usuario';
                }
                field(nombre; Rec.Nombre)
                {
                    Caption = 'Nombre';
                }
            }
        }
    }
}
