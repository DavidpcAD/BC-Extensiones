// ════════════════════════════════════════════════════════════════════════════════
// Table 50270 "GJW Usuario App Nombre"
// Traduce el usuario del login de las apps (p. ej. «jessieCor» de Digitación) al nombre
// completo de la persona («Jessie Cordero Mena»). La usa el codeunit 50270 para llenar
// "Digitado por" en los Movs. producto con el nombre y no con el username.
// Se carga desde AdelantePRO (dbo.V_Colaborador) por la API usuarioAppNombres, o a mano
// en la página «Nombres de usuarios de apps». Si un usuario no está, se muestra el username.
// ════════════════════════════════════════════════════════════════════════════════
table 50270 "GJW Usuario App Nombre"
{
    Caption = 'Nombre de usuario de app';
    DataClassification = CustomerContent;
    LookupPageId = "GJW Usuarios App Nombres";
    DrillDownPageId = "GJW Usuarios App Nombres";

    fields
    {
        field(1; Usuario; Code[50])
        {
            Caption = 'Usuario';
        }
        field(2; Nombre; Text[100])
        {
            Caption = 'Nombre';
        }
    }

    keys
    {
        key(PK; Usuario)
        {
            Clustered = true;
        }
    }
}
