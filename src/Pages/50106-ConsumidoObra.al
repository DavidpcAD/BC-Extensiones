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
        iv: Record "Item Variant";
        JLSums: Dictionary of [Text, Decimal];
        VariantDescs: Dictionary of [Text, Text];
        PresupKeys: Dictionary of [Text, Boolean];
        tmpKey: Text;
        tmpQty: Decimal;
        tmpText: Text;
        tmpParentTask: Text;
        tmpDotPos: Integer;

    trigger OnOpenPage()
    begin
        BuildDecompReadAPITmp();
    end;

    // Pre-agregacion: 1 sola query a Job Ledger Entry
    local procedure BuildJLSums()
    begin
        Clear(JLSums);
        jl.Reset();
        if jl.FindSet() then
            repeat
                tmpKey := jl."No." + '|' + jl."Location Code" + '|' + jl."Job Task No.";
                if JLSums.ContainsKey(tmpKey) then begin
                    JLSums.Get(tmpKey, tmpQty);
                    JLSums.Set(tmpKey, tmpQty + jl.Quantity);
                end else
                    JLSums.Add(tmpKey, jl.Quantity);
            until jl.Next() = 0;
    end;

    // Pre-carga: 1 sola query a Item Variant
    local procedure BuildVariantDescs()
    begin
        Clear(VariantDescs);
        if iv.FindSet() then
            repeat
                tmpKey := iv."Item No." + '|' + iv.Code;
                if not VariantDescs.ContainsKey(tmpKey) then
                    VariantDescs.Add(tmpKey, iv.Description);
            until iv.Next() = 0;
    end;

    local procedure GetJLQty(itemNo: Code[20]; worksNo: Code[20]; taskNo: Code[20]): Decimal
    begin
        tmpKey := itemNo + '|' + worksNo + '|' + taskNo;
        if JLSums.Get(tmpKey, tmpQty) then
            exit(tmpQty);
        exit(0);
    end;

    local procedure GetVariantDescFromDict(itemNo: Code[20]; variantCode: Code[10]): Text
    begin
        if (itemNo = '') or (variantCode = '') then
            exit('');
        tmpKey := itemNo + '|' + variantCode;
        if VariantDescs.Get(tmpKey, tmpText) then
            exit(tmpText);
        exit('');
    end;

    local procedure BuildDecompReadAPITmp()
    begin
        Rec.DeleteAll();
        Clear(PresupKeys);

        // 2 queries totales para pre-cargar todo
        BuildJLSums();       // 1 query: todos los Job Ledger Entries
        BuildVariantDescs(); // 1 query: todas las Item Variants

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

                // Parent Task (sin query)
                tmpParentTask := Format(decompLine."Task No.");
                tmpDotPos := StrPos(tmpParentTask, '.');
                if tmpDotPos > 0 then
                    Rec.parentTaskTemp := CopyStr(tmpParentTask, 1, tmpDotPos - 1)
                else
                    Rec.parentTaskTemp := tmpParentTask;

                // VariantDesc - Dictionary lookup O(1), sin query
                Rec.VariantDesc := GetVariantDescFromDict(decompLine."No.", decompLine."Variant Code");

                // qtyGastado - Dictionary lookup O(1), sin query
                Rec.qtyGastado := GetJLQty(decompLine."No.", decompLine."Works No.", decompLine."Task No.");
                Rec.cantidadDisponible := decompLine."Quantity" - Rec.qtyGastado;
                Rec.estadoConsumo := GetestadoConsumo(decompLine."Performance", Rec.qtyGastado);
                Rec.EsConsumido := Rec.qtyGastado > 0;

                // Registrar clave para el check de Extras (sin query)
                tmpKey := decompLine."No." + '|' + decompLine."Works No." + '|' + Format(decompLine."Task No.");
                if not PresupKeys.ContainsKey(tmpKey) then
                    PresupKeys.Add(tmpKey, true);

                Rec.Insert();
            until decompLine.Next() = 0;

        // Extras: JL sin linea presupuestada - Dictionary check, sin query a decompLine
        jl.Reset();
        jl.SetFilter(Quantity, '>%1', 0);
        if jl.FindSet() then
            repeat
                tmpKey := jl."No." + '|' + jl."Location Code" + '|' + jl."Job Task No.";
                if not PresupKeys.ContainsKey(tmpKey) then begin
                    Rec.Init();
                    Rec.SystemId := CreateGuid();
                    Rec.category := 'Extra';
                    Rec."Works No." := jl."Location Code";
                    Rec."Task No." := jl."Job Task No.";
                    Rec."Description" := jl."Description";
                    Rec."Quantity" := 0;
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
                    Rec.estadoConsumo := GetestadoConsumo(0, jl.Quantity);
                    Rec.EsConsumido := Rec.qtyGastado > 0;
                    Rec.Insert();
                end;
            until jl.Next() = 0;
    end;

    local procedure GetestadoConsumo(performance: Decimal; qtyGastado: Decimal): Integer
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