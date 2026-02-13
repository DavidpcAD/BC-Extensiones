tableextension 50140 "GJW Job Ext" extends Job
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
                JobTask: Record "Job Task";
                GomJobWorks: Record "GomJob Works";
            begin
                // Sincronizar con todas las Job Tasks de este proyecto
                JobTask.Reset();
                JobTask.SetRange("Job No.", Rec."No.");
                if JobTask.FindSet(true) then
                    repeat
                        JobTask."ID Encargado" := Rec."ID Encargado";
                        JobTask.Modify(true);
                    until JobTask.Next() = 0;

                // Sincronizar con GomJob Works
                GomJobWorks.Reset();
                GomJobWorks.SetRange("No.", Rec."No.");
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

            trigger OnValidate()
            var
                JobTask: Record "Job Task";
                GomJobWorks: Record "GomJob Works";
            begin
                // Sincronizar con todas las Job Tasks de este proyecto
                JobTask.Reset();
                JobTask.SetRange("Job No.", Rec."No.");
                if JobTask.FindSet(true) then
                    repeat
                        JobTask."ID Encargado Text" := Rec."ID Encargado Text";
                        JobTask.Modify(true);
                    until JobTask.Next() = 0;

                // Sincronizar con GomJob Works
                GomJobWorks.Reset();
                GomJobWorks.SetRange("No.", Rec."No.");
                if GomJobWorks.FindSet(true) then
                    repeat
                        GomJobWorks."ID Encargado Text" := Rec."ID Encargado Text";
                        GomJobWorks.Modify(true);
                    until GomJobWorks.Next() = 0;
            end;
        }

        field(50300; "Area Prorrateada"; Decimal)
        {
            Caption = 'Area Prorrateada';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
        }
    }
}
