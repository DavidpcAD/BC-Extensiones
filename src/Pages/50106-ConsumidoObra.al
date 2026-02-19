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
        Rec.DeleteAll(); // Limpiar la tabla temporal antes de llenarla
        // Presupuestadas
        decompLine.SetRange(Type, decompLine.Type::Item); // Solo líneas de tipo Item
        if decompLine.FindSet() then // Recorremos todas las líneas de descomposición
            repeat // para cada línea, calculamos lo gastado y otros campos adicionales y luego insertamos un registro en la tabla temporal
                Rec.Init();       // Inicializamos el registro temporal
                Rec.SystemId := decompLine.SystemId;  // Usamos el mismo SystemId para trazabilidad
                Rec.category := 'Presupuestado'; // Marcamos la categoría para diferenciar luego en la consulta
                Rec."Works No." := decompLine."Works No."; // Copiamos los campos base de la línea de descomposición 
                Rec."Task No." := decompLine."Task No.";  // Copiamos los campos base de la línea de descomposición
                Rec."Description" := decompLine."Description";          // Copiamos los campos base de la línea de descomposición
                Rec."Quantity" := decompLine."Quantity"; // Copiamos los campos base de la línea de descomposición
                Rec."Job No." := decompLine."Job No."; // Copiamos los campos base de la línea de descomposición
                Rec."Unit of Measure" := decompLine."Unit of Measure"; // Copiamos los campos base de la línea de descomposición
                Rec."Task Type" := Format(decompLine."Task Type"); // Copiamos los campos base de la línea de descomposición
                Rec."Type" := Format(decompLine."Type"); // Copiamos los campos base de la línea de descomposición
                Rec."No." := decompLine."No."; // Copiamos los campos base de la línea de descomposición
                Rec."Performance" := decompLine."Performance"; // Copiamos los campos base de la línea de descomposición
                Rec."Variant Code" := decompLine."Variant Code"; // Copiamos los campos base de la línea de descomposición
                // Parent Task
                parentTask := Format(decompLine."Task No."); // El campo Task No. tiene el formato "ParentTask.SubTask", así que para obtener el ParentTask hacemos un copy hasta el punto
                dotPos := StrPos(parentTask, '.');      // Buscamos la posición del punto en el texto del ParentTask 
                if dotPos > 0 then
                    Rec.parentTaskTemp := CopyStr(parentTask, 1, dotPos - 1) // Si hay punto, copiamos solo la parte del ParentTask
                else
                    Rec.parentTaskTemp := parentTask; // Si no hay punto, copiamos todo el ParentTask
                // VariantDesc
                if (decompLine."No." <> '') and (decompLine."Variant Code" <> '') then
                    if ItemVariant.Get(decompLine."No.", decompLine."Variant Code") then
                        Rec.VariantDesc := ItemVariant.Description;
                // Calcular qtyGastado
                jl.Reset(); // Para calcular lo gastado, sumamos las cantidades de los Job Ledger Entry relacionados con esta línea de descomposición (mismo Item No., misma Works No. en Location Code, misma Task No. en Job Task No. y mismo Job No.)
                jl.SetRange("No.", decompLine."No.");
                jl.SetRange("Location Code", decompLine."Works No."); // En nuestro diseño, el campo "Location Code" del Job Ledger Entry se usa para guardar el número de obra, lo cual nos permite relacionar los consumos con la obra correspondiente
                jl.SetRange("Job Task No.", decompLine."Task No.");
                // jl.SetRange("Job No.", decompLine."Job No."); // También filtramos por Job No. para evitar mezclar consumos de diferentes trabajos que puedan tener tareas con el mismo número
                jl.CalcSums(Quantity);
                Rec.qtyGastado := jl.Quantity;
                Rec.cantidadDisponible := decompLine."Quantity" - Rec.qtyGastado; //presupuestado - gastado
                Rec.estadoConsumo := GetestadoConsumo(decompLine."Performance", Rec.qtyGastado); // estado de consumo  (disponible, 0 consumo parcial, 1 consumido, 2 sobreconsumo)
                Rec.EsConsumido := Rec.qtyGastado > 0;// si se ha consumido algo, aunque sea parcialmente
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
                //  decompLine.SetRange("Job No.", jl."Job No."); //
                exists := decompLine.FindFirst();
                if not exists then begin
                    Rec.Init();
                    Rec.SystemId := CreateGuid();
                    Rec.category := 'Extra';
                    Rec."Works No." := jl."Location Code";
                    Rec."Task No." := jl."Job Task No.";
                    Rec."Description" := jl."Description";
                    Rec."Quantity" := 0;
                    //  Rec."Job No." := jl."Job No."; // 
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