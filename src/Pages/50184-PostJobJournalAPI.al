page 50184 "GJW Post Job Journal API"
{
    PageType = API;
    Caption = 'Post Job Journal API';
    APIPublisher = 'adelante';
    APIGroup = 'project';
    APIVersion = 'v1.0';
    EntityName = 'postJobJournal';
    EntitySetName = 'postJobJournals';



    SourceTable = "GJW Post Job Journal Cmd";
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    Permissions =
        tabledata "Job Journal Line" = RIMD,
        tabledata "Job Journal Batch" = RIMD;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(commandId; Rec."Command ID")
                {
                    ApplicationArea = All;
                    Caption = 'Command ID';
                }
                field(batchName; Rec."Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Batch Name';
                }
                field(templateName; Rec."Template Name")
                {
                    ApplicationArea = All;
                    Caption = 'Template Name';
                }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Posting Date';
                }
                field(documentNo; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Document No.';
                }
                field(projectNo; Rec."Project No.")
                {
                    ApplicationArea = All;
                    Caption = 'Project No.';
                }
                field(projectTaskNo; Rec."Project Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Project Task No.';
                }
                field(type; Rec.Type)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                }
                field(unitCost; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Cost';
                }
                field(unitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Unit Price';
                }
                field(locationCode; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                }
                field(shortcutDimension1Code; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 1 Code';
                }
                field(shortcutDimension2Code; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = All;
                    Caption = 'Shortcut Dimension 2 Code';
                }
                field(linesPosted; Rec."Lines Posted")
                {
                    ApplicationArea = All;
                    Caption = 'Lines Posted';
                    Editable = false;
                }
                field(successMessage; Rec."Success Message")
                {
                    ApplicationArea = All;
                    Caption = 'Success Message';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        LineCount: Integer;
        BatchName: Code[20];
        TemplateName: Code[20];
        TempBatchName: Code[20];
    begin
        // Configuración inicial
        if Rec."Template Name" <> '' then
            TemplateName := Rec."Template Name"
        else
            TemplateName := 'PROJECT';

        BatchName := Rec."Batch Name";
        if BatchName = '' then
            BatchName := 'DEFAULT';

        // DECISIÓN: ¿Modo crear línea individual o registrar batch completo?
        if Rec."No." <> '' then begin
            // MODO 1: Crear línea individual en batch temporal aislado
            // Generar nombre corto único (max 10 caracteres): TMP + 7 dígitos aleatorios
            TempBatchName := 'TMP' + CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, 7);

            // Crear batch temporal
            if not JobJnlBatch.Get(TemplateName, TempBatchName) then begin
                JobJnlBatch.Init();
                JobJnlBatch."Journal Template Name" := TemplateName;
                JobJnlBatch.Name := TempBatchName;
                JobJnlBatch.Description := 'Temp batch for API posting';
                JobJnlBatch.Insert();
            end;

            // Crear línea en batch temporal
            JobJnlLine.Init();
            JobJnlLine."Journal Template Name" := TemplateName;
            JobJnlLine."Journal Batch Name" := TempBatchName;
            JobJnlLine."Line No." := 10000;

            // Fecha de registro
            if Rec."Posting Date" <> 0D then
                JobJnlLine."Posting Date" := Rec."Posting Date"
            else
                JobJnlLine."Posting Date" := WorkDate();

            // Type y No.
            JobJnlLine.Type := JobJnlLine.Type::Item;
            JobJnlLine."No." := Rec."No.";

            // Campos opcionales básicos
            if Rec."Variant Code" <> '' then
                JobJnlLine."Variant Code" := Rec."Variant Code";
            JobJnlLine.Quantity := Rec.Quantity;
            if Rec."Document No." <> '' then
                JobJnlLine."Document No." := Rec."Document No.";
            if Rec.Description <> '' then
                JobJnlLine.Description := Rec.Description;

            // Proyecto
            JobJnlLine."Job No." := Rec."Project No.";
            JobJnlLine."Job Task No." := Rec."Project Task No.";

            // Costos y precios
            if Rec."Unit Cost" <> 0 then
                JobJnlLine."Unit Cost" := Rec."Unit Cost";
            if Rec."Unit Price" <> 0 then
                JobJnlLine."Unit Price" := Rec."Unit Price";

            // Ubicación
            if Rec."Location Code" <> '' then
                JobJnlLine."Location Code" := Rec."Location Code";

            // Dimensiones
            if Rec."Shortcut Dimension 1 Code" <> '' then
                JobJnlLine."Shortcut Dimension 1 Code" := Rec."Shortcut Dimension 1 Code";
            if Rec."Shortcut Dimension 2 Code" <> '' then
                JobJnlLine."Shortcut Dimension 2 Code" := Rec."Shortcut Dimension 2 Code";

            JobJnlLine.Insert(false);  // false = no validar
            LineCount := 1;

            // Registrar sin validar fecha
            Commit();
            JobJnlPostLine.Run(JobJnlLine);

            // Limpiar batch temporal
            if JobJnlBatch.Get(TemplateName, TempBatchName) then
                JobJnlBatch.Delete(true);

        end else begin
            // MODO 2: Registrar batch completo línea por línea
            JobJnlLine.Reset();
            JobJnlLine.SetRange("Journal Template Name", TemplateName);
            JobJnlLine.SetRange("Journal Batch Name", BatchName);

            if not JobJnlLine.FindSet() then begin
                Rec."Success Message" := 'ERROR: No hay líneas en ' + TemplateName + '/' + BatchName;
                exit(true);
            end;

            // PASO 1: Actualizar todas las fechas primero SIN validar
            repeat
                if JobJnlLine."Posting Date" <> WorkDate() then begin
                    JobJnlLine."Posting Date" := WorkDate();
                    JobJnlLine.Modify(false);  // false = no validar
                end;
            until JobJnlLine.Next() = 0;

            // PASO 2: Commit para guardar los cambios de fecha
            Commit();

            // PASO 3: Registrar y eliminar cada línea
            JobJnlLine.Reset();
            JobJnlLine.SetRange("Journal Template Name", TemplateName);
            JobJnlLine.SetRange("Journal Batch Name", BatchName);
            if JobJnlLine.FindSet() then begin
                repeat
                    // Usar Run() en lugar de RunWithCheck() para evitar validación de fecha
                    JobJnlPostLine.Run(JobJnlLine);
                    LineCount += 1;
                until JobJnlLine.Next() = 0;
            end;

            // PASO 4: Eliminar las líneas ya registradas
            JobJnlLine.Reset();
            JobJnlLine.SetRange("Journal Template Name", TemplateName);
            JobJnlLine.SetRange("Journal Batch Name", BatchName);
            JobJnlLine.DeleteAll();
        end;

        Rec."Lines Posted" := LineCount;
        Rec."Success Message" := '✅ ' + Format(LineCount) + ' registradas';
        exit(true);
    end;
}
