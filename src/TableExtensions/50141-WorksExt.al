tableextension 50141 "GJW Works Ext" extends "GomJob Works"
{
    fields
    {
        field(50101; "ID Encargado"; Integer)
        {
            Caption = 'ID Encargado';
            DataClassification = CustomerContent;
            ObsoleteState = Pending;
            ObsoleteReason = 'Replaced by field 50200 ID Encargado Text';

            trigger OnValidate()
            var
                Job: Record Job;
                JobTask: Record "Job Task";
            begin
                // Sincronizar hacia Job
                if Job.Get(Rec."No.") then begin
                    Job."ID Encargado" := Rec."ID Encargado";
                    Job.Modify(true);
                end;

                // Sincronizar hacia todas las Job Tasks
                JobTask.Reset();
                JobTask.SetRange("Job No.", Rec."No.");
                if JobTask.FindSet(true) then
                    repeat
                        JobTask."ID Encargado" := Rec."ID Encargado";
                        JobTask.Modify(true);
                    until JobTask.Next() = 0;
            end;
        }

        field(50200; "ID Encargado Text"; Text[100])
        {
            Caption = 'ID Encargado';
            DataClassification = CustomerContent;
        }

        field(50201; "Budget Locked"; Boolean)
        {
            Caption = 'Presupuesto Bloqueado';
            DataClassification = CustomerContent;
        }

        field(50202; "En Ejecucion"; Boolean)
        {
            Caption = 'En Ejecución';
            DataClassification = CustomerContent;
        }
    }
}
