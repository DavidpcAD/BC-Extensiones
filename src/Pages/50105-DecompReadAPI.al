page 50105 "GJW Works Decomp OnSite"
{
    PageType = API;

    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'gomJobWorkDecomposedRead';
    EntitySetName = 'gomJobWorksDecomposedRead';

    SourceTable = "GomJob Works Decomposed Lines"; // 70720580
    // Solo líneas de tipo Item para aligerar la consulta
    SourceTableView = where(Type = const(Item));

    // Solo lectura (ideal para Power Apps en campo)
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;

    ODataKeyFields = SystemId;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                // --- System fields (útiles para trazabilidad) ---
                field(systemId; Rec.SystemId) { Caption = 'System Id'; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Caption = 'System Created At'; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Caption = 'System Modified At'; }

                // --- Campos base (solo los que pediste) ---
                field(worksNo; Rec."Works No.") { ApplicationArea = All; }
                field(taskNo; Rec."Task No.") { ApplicationArea = All; }
                field(description; Rec."Description") { ApplicationArea = All; }
                field(quantity; Rec."Quantity") { ApplicationArea = All; }
                field(jobNo; Rec."Job No.") { ApplicationArea = All; }
                field(unitOfMeasure; Rec."Unit of Measure") { ApplicationArea = All; }
                field(taskType; Rec."Task Type") { ApplicationArea = All; }
                field(type; Rec."Type") { ApplicationArea = All; } // vendrá siempre "Item" por el filtro
                field(no; Rec."No.") { ApplicationArea = All; }
                field(performance; Rec."Performance") { ApplicationArea = All; }
                field(variantCode; Rec."Variant Code") { ApplicationArea = All; }

                // --- Calculadas (solo lectura) ---
                field(parentTaskTemp; GetParentTaskTemp())
                {
                    Caption = 'Parent Task';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(nomVariante; VariantDesc)
                {
                    Caption = 'Variant Description';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(cantidadGastado; QtyGastado)
                {
                    Caption = 'Cantidad Gastada';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(cantidadDisponible; GetCantidadDisponible())
                {
                    Caption = 'Cantidad Disponible';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(estadoConsumo; GetEstadoConsumo())
                {
                    Caption = 'Estado Consumo';
                    ApplicationArea = All;
                    Editable = false;
                }

                field(esConsumido; EsConsumido)
                {
                    Caption = 'Es Consumido';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    var
        QtyGastado: Decimal;
        VariantDesc: Text;
        EsConsumido: Boolean;
        JL: Record "Job Ledger Entry";
        ItemVariant: Record "Item Variant";
        JLSums: Dictionary of [Text, Decimal];
        VariantDescs: Dictionary of [Text, Text];
        tmpKey: Text;
        tmpQty: Decimal;
        tmpText: Text;
        tmpDotPos: Integer;

    trigger OnOpenPage()
    begin
        BuildJLSums();
        BuildVariantDescs();
    end;

    // Pre-agregacion: 1 sola query a Job Ledger Entry
    local procedure BuildJLSums()
    begin
        Clear(JLSums);
        JL.Reset();
        if JL.FindSet() then
            repeat
                tmpKey := JL."No." + '|' + JL."Location Code" + '|' + JL."Job Task No.";
                if JLSums.ContainsKey(tmpKey) then begin
                    JLSums.Get(tmpKey, tmpQty);
                    JLSums.Set(tmpKey, tmpQty + JL.Quantity);
                end else
                    JLSums.Add(tmpKey, JL.Quantity);
            until JL.Next() = 0;
    end;

    // Pre-carga: 1 sola query a Item Variant
    local procedure BuildVariantDescs()
    begin
        Clear(VariantDescs);
        if ItemVariant.FindSet() then
            repeat
                tmpKey := ItemVariant."Item No." + '|' + ItemVariant.Code;
                if not VariantDescs.ContainsKey(tmpKey) then
                    VariantDescs.Add(tmpKey, ItemVariant.Description);
            until ItemVariant.Next() = 0;
    end;

    trigger OnAfterGetRecord()
    begin
        // Dictionary lookups O(1) - sin queries a la DB
        tmpKey := Rec."No." + '|' + Rec."Works No." + '|' + Rec."Task No.";
        if JLSums.Get(tmpKey, tmpQty) then
            QtyGastado := tmpQty
        else
            QtyGastado := 0;

        if (Rec."No." <> '') and (Rec."Variant Code" <> '') then begin
            tmpKey := Rec."No." + '|' + Rec."Variant Code";
            if VariantDescs.Get(tmpKey, tmpText) then
                VariantDesc := tmpText
            else
                VariantDesc := '';
        end else
            VariantDesc := '';

        EsConsumido := QtyGastado > 0;
    end;

    local procedure GetParentTaskTemp(): Text
    begin
        tmpText := Format(Rec."Task No.");
        tmpDotPos := StrPos(tmpText, '.');
        if tmpDotPos > 0 then
            exit(CopyStr(tmpText, 1, tmpDotPos - 1));
        exit(tmpText);
    end;

    local procedure GetCantidadDisponible(): Decimal
    begin
        exit(Rec."Quantity" - QtyGastado);
    end;

    local procedure GetEstadoConsumo(): Integer
    begin
        if Rec."Performance" > QtyGastado then
            exit(0);
        if Rec."Performance" = QtyGastado then
            exit(1);
        if Rec."Performance" < QtyGastado then
            exit(2);
        exit(0);
    end;

}