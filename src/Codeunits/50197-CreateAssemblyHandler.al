codeunit 50197 "GJW Create Assembly Handler"
{
    procedure CreateAssemblyWithLots(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ComponentsJson: Text): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        TrackingSpecification: Record "Tracking Specification";
        ComponentArray: JsonArray;
        ComponentToken: JsonToken;
        ComponentObject: JsonObject;
        ComponentItemNo: Code[20];
        ComponentLotNo: Code[50];
        ComponentQty: Decimal;
        LineNo: Integer;
    begin
        // Crear Assembly Header
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        AssemblyHeader."No." := '';
        AssemblyHeader.Insert(true);

        AssemblyHeader.Validate("Item No.", ItemNo);
        AssemblyHeader.Validate(Quantity, Quantity);
        AssemblyHeader.Validate("Location Code", LocationCode);
        AssemblyHeader.Modify(true);

        // Procesar componentes desde JSON
        if ComponentsJson <> '' then begin
            ComponentArray.ReadFrom(ComponentsJson);

            foreach ComponentToken in ComponentArray do begin
                ComponentObject := ComponentToken.AsObject();

                // Extraer datos del componente
                ComponentItemNo := GetJsonValue(ComponentObject, 'itemNo');
                ComponentLotNo := GetJsonValue(ComponentObject, 'lotNo');
                Evaluate(ComponentQty, GetJsonValue(ComponentObject, 'quantity'));

                // Buscar la línea de assembly correspondiente
                AssemblyLine.Reset();
                AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
                AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
                AssemblyLine.SetRange("No.", ComponentItemNo);
                if AssemblyLine.FindFirst() then begin
                    // Actualizar cantidad si es diferente
                    if AssemblyLine."Quantity to Consume" <> ComponentQty then begin
                        AssemblyLine.Validate("Quantity to Consume", ComponentQty);
                        AssemblyLine.Modify(true);
                    end;

                    // Crear Tracking Specification para el lote
                    if ComponentLotNo <> '' then begin
                        TrackingSpecification.Init();
                        TrackingSpecification."Source Type" := DATABASE::"Assembly Line";
                        TrackingSpecification."Source Subtype" := AssemblyLine."Document Type".AsInteger();
                        TrackingSpecification."Source ID" := AssemblyLine."Document No.";
                        TrackingSpecification."Source Ref. No." := AssemblyLine."Line No.";
                        TrackingSpecification."Item No." := ComponentItemNo;
                        TrackingSpecification."Location Code" := LocationCode;
                        TrackingSpecification."Lot No." := ComponentLotNo;
                        TrackingSpecification."Quantity (Base)" := ComponentQty;
                        TrackingSpecification."Qty. to Handle (Base)" := ComponentQty;
                        TrackingSpecification."Qty. to Invoice (Base)" := ComponentQty;
                        TrackingSpecification."Entry No." := GetNextTrackingEntryNo();
                        TrackingSpecification.Insert(true);
                    end;
                end;
            end;
        end;

        exit(AssemblyHeader."No.");
    end;

    local procedure GetJsonValue(JObject: JsonObject; KeyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(KeyName, JToken) then
            exit(JToken.AsValue().AsText());
        exit('');
    end;

    local procedure GetNextTrackingEntryNo(): Integer
    var
        TrackingSpec: Record "Tracking Specification";
    begin
        TrackingSpec.Reset();
        if TrackingSpec.FindLast() then
            exit(TrackingSpec."Entry No." + 1);
        exit(1);
    end;
}
