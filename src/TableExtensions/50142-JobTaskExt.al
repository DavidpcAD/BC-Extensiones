tableextension 50142 "GJW Job Task Ext" extends "Job Task"
{
    fields
    {
        field(50100; "ID Encargado"; Integer)
        {
            Caption = 'ID Encargado';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by field 50200 ID Encargado Text';

            trigger OnValidate()
            var
                Job: Record Job;
                GomJobWorks: Record "GomJob Works";
            begin
                // Sincronizar hacia el Job (proyecto padre)
                if Job.Get(Rec."Job No.") then begin
                    Job."ID Encargado" := Rec."ID Encargado";
                    Job.Modify(true);
                end;

                // Sincronizar con GomJob Works del mismo proyecto
                GomJobWorks.Reset();
                GomJobWorks.SetRange("No.", Rec."Job No.");
                if GomJobWorks.FindSet(true) then
                    repeat
                        GomJobWorks."ID Encargado" := Rec."ID Encargado";
                        GomJobWorks.Modify(true);
                    until GomJobWorks.Next() = 0;
            end;
        }

        field(50200; "ID Encargado Text"; Text[100])
        {
            Caption = 'ID Encargado';
            DataClassification = CustomerContent;
        }
    }
}
