page 50110 "GJW Works API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'work';
    EntitySetName = 'works';

    SourceTable = "GomJob Works";
    ODataKeyFields = SystemId;
    DelayedInsert = true;

    // CRUD (los FlowFields seguirán sin ser editables)
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // Identificación
                field(id; Rec.SystemId) { Caption = 'Id'; }
                field(no; Rec."No.") { Caption = 'No.'; }
                field(description; Rec.Description) { Caption = 'Description'; }
                field(idEncargado; Rec."ID Encargado") { Caption = 'ID Encargado'; ObsoleteState = Pending; }
                field(idEncargadoText; Rec."ID Encargado Text") { Caption = 'ID Encargado'; }
                field(filterVersionCode; Rec."Filter Version Code") { Caption = 'Filter Version Code'; }

                // Importes (los mismos que ves en el Factbox)
                field(salesLineAmount; Rec."Sales Line Amount") { Caption = 'Sales Line Amount'; Editable = false; }
                field(costLineAmount; Rec."Cost Line Amount") { Caption = 'Cost Line Amount'; Editable = false; }
                field(indirectCostLineAmount; Rec."Indirect Cost Line Amount") { Caption = 'Indirect Cost Line Amount'; Editable = false; }

                // Resultado calculado igual que el Factbox
                field(result; ResultCalc) { Caption = 'Result'; Editable = false; }

                // Producción / certificación (opcional pero útil)
                field(prodLineAmount; Rec."Prod. Line Amount") { Caption = 'Prod. Line Amount'; Editable = false; }
                field(prodPosted; Rec."Prod. Posted Line Amount") { Caption = 'Prod. Posted Amount'; Editable = false; }
                field(prodPending; Rec."Prod. Pending Line Amount") { Caption = 'Prod. Pending Amount'; Editable = false; }
                field(certLineAmount; Rec."Cert. Line Amount") { Caption = 'Cert. Line Amount'; Editable = false; }
                field(certPosted; Rec."Cert. Posted Line Amount") { Caption = 'Cert. Posted Amount'; Editable = false; }
                field(certPending; Rec."Cert. Pending Line Amount") { Caption = 'Cert. Pending Amount'; Editable = false; }

                // Control de edición
                field(budgetLocked; Rec."Budget Locked") { Caption = 'Budget Locked'; }
                field(enEjecucion; Rec."En Ejecucion") { Caption = 'En Ejecucion'; }

                // Auditoría
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ver: Code[20];
    begin
        // 1) Fijar automáticamente la última versión de la obra
        ver := GetLatestVersion(Rec."No.");
        if ver <> '' then
            Rec.SetRange("Filter Version Code", ver);

        // 2) Asegurar valores de FlowFields antes de usarlos
        Rec.CalcFields(
            "Sales Line Amount",
            "Cost Line Amount",
            "Indirect Cost Line Amount",
            "Prod. Line Amount",
            "Prod. Posted Line Amount",
            "Prod. Pending Line Amount",
            "Cert. Line Amount",
            "Cert. Posted Line Amount",
            "Cert. Pending Line Amount"
        );

        // 3) Calcular el resultado igual que el Factbox
        ResultCalc := Rec."Sales Line Amount"
                    - Rec."Cost Line Amount"
                    - Rec."Indirect Cost Line Amount";
    end;

    local procedure GetLatestVersion(WorkNo: Code[20]): Code[20]
    var
        WorkVer: Record "GomJob Works Version";
    begin
        // Busca la última versión por fecha de creación para esa obra
        WorkVer.SetRange("Works No.", WorkNo);
        WorkVer.SetCurrentKey("Create Date Time");
        if WorkVer.FindLast() then
            exit(WorkVer."Version Code");
        exit('');
    end;

    var
        ResultCalc: Decimal;
}
