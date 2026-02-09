page 50106 "ConsumidoObra"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'consumidoObra';
    EntitySetName = 'consumidoObraSet';
    SourceTable = "DecompReadAPITmp";
    SourceTableTemporary = true;
    ODataKeyFields = SystemId;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(systemId; Rec.SystemId) { Caption = 'System ID'; ApplicationArea = All; }
                field(category; Rec.category) { Caption = 'Category'; ApplicationArea = All; }
                field(worksNo; Rec."Works No.") { ApplicationArea = All; }
                field(taskNo; Rec."Task No.") { ApplicationArea = All; }
                field(description; Rec."Description") { ApplicationArea = All; }
                field(quantity; Rec."Quantity") { ApplicationArea = All; }
                field(jobNo; Rec."Job No.") { ApplicationArea = All; }
                field(unitOfMeasure; Rec."Unit of Measure") { ApplicationArea = All; }
                field(taskType; Rec."Task Type") { ApplicationArea = All; }
                field(type; Rec."Type") { ApplicationArea = All; }
                field(no; Rec."No.") { ApplicationArea = All; }
                field(performance; Rec."Performance") { ApplicationArea = All; }
                field(variantCode; Rec."Variant Code") { ApplicationArea = All; }
                field(parentTaskTemp; Rec.parentTaskTemp) { Caption = 'Parent Task'; ApplicationArea = All; Editable = false; }
                field(nomVariante; Rec.VariantDesc) { Caption = 'Variant Description'; ApplicationArea = All; Editable = false; }
                field(cantidadGastado; Rec.qtyGastado) { Caption = 'Cantidad Gastada'; ApplicationArea = All; Editable = false; }
                field(cantidadDisponible; Rec.cantidadDisponible) { Caption = 'Cantidad Disponible'; ApplicationArea = All; Editable = false; }
                field(estadoConsumo; Rec.estadoConsumo) { Caption = 'Estado Consumo'; ApplicationArea = All; Editable = false; }
                field(esConsumido; Rec.EsConsumido) { Caption = 'Es Consumido'; ApplicationArea = All; Editable = false; }
            }
        }
    }

    var
        decompLine: Record "GomJob Works Decomposed Lines";
        jl: Record "Job Ledger Entry";
        ItemVariant: Record "Item Variant";

    trigger OnOpenPage()
    begin
        BuildDecompReadAPITmp();
    end;

    local procedure BuildDecompReadAPITmp()
    var
        exists: Boolean;
        parentTask: Text;
        dotPos: Integer;
    begin
        Rec.DeleteAll();
        // Presupuestadas
        decompLine.SetRange(Type, decompLine.Type::Item);
        if decompLine.FindSet() then
            repeat
                Rec.Init();
                Rec.SystemId := decompLine.SystemId;
                Rec.category := 'Presupuestado';
                Rec."Works No." := decompLine."Works No.";
                Rec."Task No." := decompLine."Task No.";
                Rec."Description" := decompLine."Description";
                Rec."Quantity" := decompLine."Quantity";
                Rec."Job No." := decompLine."Job No.";
                Rec."Unit of Measure" := decompLine."Unit of Measure";
                Rec."Task Type" := Format(decompLine."Task Type");
                Rec."Type" := Format(decompLine."Type");
                Rec."No." := decompLine."No.";
                Rec."Performance" := decompLine."Performance";
                Rec."Variant Code" := decompLine."Variant Code";
                // Parent Task
                parentTask := Format(decompLine."Task No.");
                dotPos := StrPos(parentTask, '.');
                if dotPos > 0 then
                    Rec.parentTaskTemp := CopyStr(parentTask, 1, dotPos - 1)
                else
                    Rec.parentTaskTemp := parentTask;
                // VariantDesc
                if (decompLine."No." <> '') and (decompLine."Variant Code" <> '') then
                    if ItemVariant.Get(decompLine."No.", decompLine."Variant Code") then
                        Rec.VariantDesc := ItemVariant.Description;
                // Calcular QtyGastado
                jl.Reset();
                jl.SetRange("No.", decompLine."No.");
                jl.SetRange("Location Code", decompLine."Works No.");
                jl.SetRange("Job Task No.", decompLine."Task No.");
                jl.SetRange("Job No.", decompLine."Job No.");
                jl.CalcSums(Quantity);
                Rec.qtyGastado := jl.Quantity;
                Rec.cantidadDisponible := decompLine."Quantity" - Rec.qtyGastado;
                Rec.estadoConsumo := GetEstadoConsumo(decompLine."Performance", Rec.qtyGastado);
                Rec.EsConsumido := Rec.qtyGastado > 0;
                Rec.Insert();
            until decompLine.Next() = 0;

        // Extras (consumidos sin presupuestar)
        jl.Reset();
        jl.SetFilter(Quantity, '>%1', 0);
        if jl.FindSet() then
            repeat
                // Buscar si existe en presupuestadas
                decompLine.Reset();
                decompLine.SetRange(Type, decompLine.Type::Item);
                decompLine.SetRange("No.", jl."No.");
                decompLine.SetRange("Works No.", jl."Location Code");
                decompLine.SetRange("Task No.", jl."Job Task No.");
                decompLine.SetRange("Job No.", jl."Job No.");
                exists := decompLine.FindFirst();
                if not exists then begin
                    Rec.Init();
                    Rec.SystemId := CreateGuid();
                    Rec.category := 'Extra';
                    Rec."Works No." := jl."Location Code";
                    Rec."Task No." := jl."Job Task No.";
                    Rec."Description" := jl."Description";
                    Rec."Quantity" := 0;
                    Rec."Job No." := jl."Job No.";
                    Rec."Unit of Measure" := jl."Unit of Measure Code";
                    Rec."Task Type" := '';
                    Rec."Type" := 'Item';
                    Rec."No." := jl."No.";
                    Rec."Performance" := 0;
                    Rec."Variant Code" := jl."Variant Code";
                    Rec.parentTaskTemp := '';
                    Rec.VariantDesc := '';
                    Rec.qtyGastado := jl.Quantity;
                    Rec.cantidadDisponible := -jl.Quantity;
                    Rec.estadoConsumo := GetEstadoConsumo(0, jl.Quantity);
                    Rec.EsConsumido := Rec.qtyGastado > 0;
                    Rec.Insert();
                end;
            until jl.Next() = 0;
    end;

    local procedure GetEstadoConsumo(performance: Decimal; qtyGastado: Decimal): Integer
    begin
        if (performance = 0) and (qtyGastado = 0) then
            exit(3);
        if performance > qtyGastado then
            exit(0);
        if performance = qtyGastado then
            exit(1);
        if performance < qtyGastado then
            exit(2);
        exit(0);
    end;
}