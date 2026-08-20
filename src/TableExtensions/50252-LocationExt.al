// ════════════════════════════════════════════════════════════════════════════════
// TableExtension 50252 "GJW Location Ext" extends Location (14)
// Agrega la clasificación Real / Virtual del almacén.
// ════════════════════════════════════════════════════════════════════════════════
tableextension 50252 "GJW Location Ext" extends Location
{
    fields
    {
        field(50100; "GJW Tipo Almacen"; Enum "GJW Tipo Almacen")
        {
            Caption = 'Tipo de almacén';
            DataClassification = CustomerContent;
            ToolTip = 'Indica si el almacén es físico (Real) o lógico (Virtual).';
        }
    }
}
