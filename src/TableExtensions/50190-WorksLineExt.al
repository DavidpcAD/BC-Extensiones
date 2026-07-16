// ════════════════════════════════════════════════════════════════════════════════
// TableExtension 50190 "Adelante Works Line Ext" extends "GomJob Works Line"
// Campos para marcar (no borrar) la actividad de Postventa al desbloquear una obra.
// ════════════════════════════════════════════════════════════════════════════════
tableextension 50190 "Adelante Works Line Ext" extends "GomJob Works Line"
{
    fields
    {
        field(50210; "Adelante Revertida"; Boolean)
        {
            Caption = 'Revertida';
            DataClassification = CustomerContent;
        }
        field(50211; "Adelante Fecha Reversa"; Date)
        {
            Caption = 'Fecha Reversa';
            DataClassification = CustomerContent;
        }
    }
}
