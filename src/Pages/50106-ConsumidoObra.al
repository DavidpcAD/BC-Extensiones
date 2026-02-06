page 50106 "ConsumidoObra"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'consumidoObra';
    EntitySetName = 'consumidoObraSet';
    SourceTable = "DecompReadAPITmp";
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
            }
        }
    }

    var
        tmpRec: Record "DecompReadAPITmp" temporary;
        decompLine: Record "GomJob Works Decomposed Lines";
        jl: Record "Job Ledger Entry";
        ItemVariant: Record "Item Variant";

    trigger OnOpenPage()
    begin
        BuildDecompReadAPITmp();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if tmpRec.Count = 0 then
            BuildDecompReadAPITmp();
        exit(false);
    end;

    trigger OnAfterGetRecord()
    begin
        if tmpRec.Count = 0 then
            BuildDecompReadAPITmp();
    end;

    local procedure BuildDecompReadAPITmp()
    var
        exists: Boolean;
        parentTask: Text;
        dotPos: Integer;
    begin
        tmpRec.DeleteAll();
        // Presupuestadas
        decompLine.SetRange(Type, decompLine.Type::Item);
        if decompLine.FindSet() then
            repeat
                tmpRec.Init();
                tmpRec.SystemId := decompLine.SystemId;
                tmpRec.category := 'Presupuestado';
                tmpRec."Works No." := decompLine."Works No.";
                tmpRec."Task No." := decompLine."Task No.";
                tmpRec."Description" := decompLine."Description";
                tmpRec."Quantity" := decompLine."Quantity";
                tmpRec."Job No." := decompLine."Job No.";
                tmpRec."Unit of Measure" := decompLine."Unit of Measure";
                tmpRec."Task Type" := Format(decompLine."Task Type");
                tmpRec."Type" := Format(decompLine."Type");
                tmpRec."No." := decompLine."No.";
                tmpRec."Performance" := decompLine."Performance";
                tmpRec."Variant Code" := decompLine."Variant Code";
                // Parent Task
                parentTask := Format(decompLine."Task No.");
                dotPos := StrPos(parentTask, '.');
                if dotPos > 0 then
                    tmpRec.parentTaskTemp := CopyStr(parentTask, 1, dotPos - 1)
                else
                    tmpRec.parentTaskTemp := parentTask;
                // VariantDesc
                if (decompLine."No." <> '') and (decompLine."Variant Code" <> '') then
                    if ItemVariant.Get(decompLine."No.", decompLine."Variant Code") then
                        tmpRec.VariantDesc := ItemVariant.Description;
                // Calcular QtyGastado
                jl.Reset();
                jl.SetRange("No.", decompLine."No.");
                jl.SetRange("Location Code", decompLine."Works No.");
                jl.SetRange("Job Task No.", decompLine."Task No.");
                jl.SetRange("Job No.", decompLine."Job No.");
                jl.CalcSums(Quantity);
                tmpRec.qtyGastado := jl.Quantity;
                tmpRec.cantidadDisponible := decompLine."Quantity" - tmpRec.qtyGastado;
                tmpRec.estadoConsumo := GetEstadoConsumo(decompLine."Performance", tmpRec.qtyGastado);
                tmpRec.Insert();
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
                    tmpRec.Init();
                    tmpRec.SystemId := CreateGuid();
                    tmpRec.category := 'Extra';
                    tmpRec."Works No." := jl."Location Code";
                    tmpRec."Task No." := jl."Job Task No.";
                    tmpRec."Description" := jl."Description";
                    tmpRec."Quantity" := 0;
                    tmpRec."Job No." := jl."Job No.";
                    tmpRec."Unit of Measure" := jl."Unit of Measure Code";
                    tmpRec."Task Type" := '';
                    tmpRec."Type" := 'Item';
                    tmpRec."No." := jl."No.";
                    tmpRec."Performance" := 0;
                    tmpRec."Variant Code" := jl."Variant Code";
                    tmpRec.parentTaskTemp := '';
                    tmpRec.VariantDesc := '';
                    tmpRec.qtyGastado := jl.Quantity;
                    tmpRec.cantidadDisponible := -jl.Quantity;
                    tmpRec.estadoConsumo := GetEstadoConsumo(0, jl.Quantity);
                    tmpRec.Insert();
                end;
            until jl.Next() = 0;
    end;

    local procedure GetEstadoConsumo(performance: Decimal; qtyGastado: Decimal): Integer
    begin
        if performance > qtyGastado then
            exit(0);
        if performance = qtyGastado then
            exit(1);
        if performance < qtyGastado then
            exit(2);
        exit(0);
    end;
}