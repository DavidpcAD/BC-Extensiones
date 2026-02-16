tableextension 50129 "GJW Works Line Ext" extends "GomJob Works Line"
{
    fields
    {
        field(50100; "ID Encargado"; Integer)
        {
            Caption = 'ID Encargado (Obsoleto)';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by field 50200 ID Encargado Text';
        }

        field(50200; "ID Encargado Text"; Text[100])
        {
            Caption = 'ID Encargado';
            DataClassification = CustomerContent;
        }

        // Nuevo par de campos: ID Visibles (igual patrón que Encargado)
        field(50300; "ID Visibles"; Integer)
        {
            Caption = 'ID Visibles (Obsoleto)';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by field 50350 ID Visibles Text';
        }

        field(50350; "ID Visibles Text"; Text[100])
        {
            Caption = 'ID Visibles';
            DataClassification = CustomerContent;
        }
    }
}
