tableextension 50130 "GJW Works Decomp Line Ext" extends "GomJob Works Decomposed Lines"
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
    }
}
