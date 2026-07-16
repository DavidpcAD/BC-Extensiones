// ════════════════════════════════════════════════════════════════════════════════
// Page 50251 "Adelante Postventa Setup"
// Mantenimiento del mapeo prefijo -> obra Postventa (tabla 50250). Editable en BC.
// ════════════════════════════════════════════════════════════════════════════════
page 50251 "Adelante Postventa Setup"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Adelante Postventa Setup';
    SourceTable = "Adelante Postventa Setup";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(prefijo; Rec.Prefijo)
                {
                    ToolTip = 'Prefijo del N° de obra (texto antes del primer guión). Ej: VN, VI.';
                }
                field(obraPostventa; Rec."Obra Postventa No.")
                {
                    ToolTip = 'Obra Postventa del desarrollo. Ej: PV-NOVARUM, PV-ILIOS.';
                }
                field(descripcion; Rec.Descripcion)
                {
                    ToolTip = 'Descripción del desarrollo (opcional).';
                }
            }
        }
    }
}
