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
        // Cachés por registro para minimizar llamadas (ligero en red y DB)
        QtyGastado: Decimal;
        VariantDesc: Text;
        EsConsumido: Boolean;

        JL: Record "Job Ledger Entry";
        ItemVariant: Record "Item Variant";

    trigger OnAfterGetRecord()
    begin
        // Precalcular una vez por registro para que los campos calculados no re-ejecuten consultas
        QtyGastado := CalcQtyGastado();
        VariantDesc := CalcVariantDesc();
        EsConsumido := QtyGastado > 0;
    end;

    local procedure GetParentTaskTemp(): Text
    var
        t: Text;
        dotPos: Integer;
    begin
        t := Format(Rec."Task No.");
        dotPos := StrPos(t, '.');
        if dotPos > 0 then
            exit(CopyStr(t, 1, dotPos - 1));
        exit(t);
    end;

    local procedure CalcVariantDesc(): Text
    begin
        if (Rec."No." = '') or (Rec."Variant Code" = '') then
            exit('');
        if ItemVariant.Get(Rec."No.", Rec."Variant Code") then
            exit(ItemVariant.Description);
        exit('');
    end;

    local procedure CalcQtyGastado(): Decimal
    var
        total: Decimal;
    begin
        // Filtros solicitados:
        // Item No. = No.
        // Location Code = Works No.   (ajusta si en tu modelo "Works No." no es ubicación)
        // Job Task No. = Task No.
        // Solo positivas (interpretado como Quantity > 0 en Job Ledger Entry)
        JL.Reset();
        if Rec."No." <> '' then
            JL.SetRange("No.", Rec."No."); // Filtro por Item No.

        if Rec."Works No." <> '' then
            JL.SetRange("Location Code", Rec."Works No."); // Filtro por Works No. en Location Code (ajusta si tu modelo es diferente)

        if Rec."Task No." <> '' then
            JL.SetRange("Job Task No.", Rec."Task No."); // Filtro por Task No. en Job Task No.

        // Si también quieres acotar por proyecto: (descomenta si corresponde a tu modelo)
        if Rec."Job No." <> '' then
            JL.SetRange("Job No.", Rec."Job No.");

        //        JL.SetFilter(Quantity, '>%1', 0); // Solo cantidades positivas (ajusta si tu definición de "gastado" es diferente)

        JL.CalcSums(Quantity);
        total := JL.Quantity;
        exit(total);
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

        exit(0); // fallback improbable, pero evita warnings del compilador
    end;

}