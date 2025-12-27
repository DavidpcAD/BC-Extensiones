page 50165 "GJW Return Command API"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'returnCommand';
    EntitySetName = 'returnCommands';

    SourceTable = "GJW Return Command";
    SourceTableTemporary = true;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                // CAMPOS INPUT (sin validación)
                field(inputJobNo; Rec."Input Job No.")
                {
                    ApplicationArea = All;
                }
                field(inputTaskNo; Rec."Input Task No.")
                {
                    ApplicationArea = All;
                }
                field(inputItemNo; Rec."Input Item No.")
                {
                    ApplicationArea = All;
                }
                field(inputDestinationJobNo; Rec."Input Destination Job No.")
                {
                    ApplicationArea = All;
                }
                field(inputDestinationTaskNo; Rec."Input Destination Task No.")
                {
                    ApplicationArea = All;
                }
                // CAMPOS NORMALES (ocultos, no se envían desde PowerApps)
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(returnType; Rec."Return Type")
                {
                    ApplicationArea = All;
                }
                // CAMPOS COMENTADOS - Causan validación en BC
                // field(destinationJobNo; Rec."Destination Job No.")
                // {
                //     ApplicationArea = All;
                // }
                // field(destinationTaskNo; Rec."Destination Task No.")
                // {
                //     ApplicationArea = All;
                // }
                // field(sourceLocationCode; Rec."Source Location Code")
                // {
                //     ApplicationArea = All;
                // }
                // field(destinationLocationCode; Rec."Destination Location Code")
                // {
                //     ApplicationArea = All;
                // }
                field(postingDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                }
                field(itemLedgerEntryNo; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = All;
                }
                field(linesPosted; Rec."Lines Posted")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(successMessage; Rec."Success Message")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        ProcessReturn: Codeunit "GJW Process Material Return";
        TempRec: Record "GJW Return Command" temporary;
    begin
        // SOLUCIÓN: Crear un registro temporal completamente nuevo
        // para evitar la validación automática de Business Central
        TempRec.Init();
        TempRec."Entry No." := Rec."Entry No.";

        // Copiar campos Input a campos internos - SIN VALIDACIÓN
        TempRec."Job No." := Rec."Input Job No.";
        TempRec."Task No." := Rec."Input Task No.";
        TempRec."Item No." := Rec."Input Item No.";
        TempRec."Variant Code" := Rec."Variant Code";
        TempRec.Quantity := Rec.Quantity;
        TempRec."Return Type" := Rec."Return Type";
        TempRec."Posting Date" := Rec."Posting Date";
        TempRec."Item Ledger Entry No." := Rec."Item Ledger Entry No.";

        // Locations
        TempRec."Source Location Code" := Rec."Input Job No.";

        // Destination
        if Rec."Input Destination Job No." <> '' then begin
            TempRec."Destination Job No." := Rec."Input Destination Job No.";
            TempRec."Destination Location Code" := Rec."Input Destination Job No.";
        end else begin
            TempRec."Destination Location Code" := 'CENTRAL';
        end;

        if Rec."Input Destination Task No." <> '' then
            TempRec."Destination Task No." := Rec."Input Destination Task No.";

        TempRec.Insert();

        // Validar datos obligatorios
        if TempRec."Job No." = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Job No. es requerido';
            exit(true);
        end;

        if TempRec."Task No." = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Task No. es requerido';
            exit(true);
        end;

        if TempRec."Item No." = '' then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Item No. es requerido';
            exit(true);
        end;

        if TempRec.Quantity <= 0 then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := 'ERROR: Quantity debe ser mayor a cero';
            exit(true);
        end;

        if TempRec."Posting Date" = 0D then
            TempRec."Posting Date" := Today();

        // Procesar la devolución con el registro temporal
        if not ProcessReturn.ProcessReturn(TempRec) then begin
            Rec."Lines Posted" := 0;
            Rec."Success Message" := TempRec."Success Message";
        end else begin
            Rec."Lines Posted" := TempRec."Lines Posted";
            Rec."Success Message" := TempRec."Success Message";
        end;

        exit(true);
    end;
}
