page 50149 "GJW ItemAvailBuffer API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'itemAvailabilityBuffer';
    EntitySetName = 'itemAvailabilityBuffers';
    SourceTable = "GJW Item Availability Buffer";
    SourceTableTemporary = true;
    DelayedInsert = true;

    Caption = 'Item Availability by Location (Buffer)';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(itemNo; Rec."Item No.")
                {
                    Caption = 'Item No.';
                    ApplicationArea = All;
                }
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                    ApplicationArea = All;
                }
                field(locationName; Rec."Location Name")
                {
                    Caption = 'Location Name';
                    ApplicationArea = All;
                }
                field(expectedInventory; Rec."Expected Inventory")
                {
                    Caption = 'Expected Inventory';
                    ApplicationArea = All;
                }
                field(grossRequirement; Rec."Gross Requirement")
                {
                    Caption = 'Gross Requirement';
                    ApplicationArea = All;
                }
                field(plannedOrderReceipt; Rec."Planned Order Receipt")
                {
                    Caption = 'Planned Order Receipt';
                    ApplicationArea = All;
                }
                field(scheduledReceipt; Rec."Scheduled Receipt")
                {
                    Caption = 'Scheduled Receipt';
                    ApplicationArea = All;
                }
                field(projectedAvailable; Rec."Projected Available")
                {
                    Caption = 'Projected Available';
                    ApplicationArea = All;
                }
                field(availableInventory; Rec."Available Inventory")
                {
                    Caption = 'Available Inventory';
                    ApplicationArea = All;
                }
            }
        }
    }

    var
        Item: Record Item;
        Loc: Record Location;
        ItemAvailMgt: Codeunit "Item Availability Forms Mgt";

    trigger OnOpenPage()
    var
        itemNoFilter: Text;
        itemNo: Code[20];
        gross: Decimal;
        planned: Decimal;
        scheduled: Decimal;
        plannedRel: Decimal;
        proj: Decimal;
        exp: Decimal;
        avail: Decimal;
        dummy: Decimal;
        locFilter: Text;
    begin
        // 1️⃣ Leer filtros OData de la URL
        itemNoFilter := Rec.GetFilter("Item No.");
        locFilter := Rec.GetFilter("Location Code"); // opcional

        // 2️⃣ Si no hay filtro de ítem, no devolvemos nada (seguridad + rendimiento)
        if itemNoFilter = '' then
            exit;

        itemNo := CopyStr(itemNoFilter, 1, MaxStrLen(itemNo));

        if not Item.Get(itemNo) then
            exit;

        // 3️⃣ Evitar error de "Specify a filter for the Date Filter field"
        if Item.GetFilter("Date Filter") = '' then
            Item.SetRange("Date Filter", 0D, DMY2Date(31, 12, 9999));

        // 4️⃣ Si se filtra por ubicación, aplicar el filtro
        if locFilter <> '' then
            Loc.SetFilter(Code, locFilter);

        Loc.GetLocationsIncludingUnspecifiedLocation(false, false);

        if Loc.FindSet() then
            repeat
                Item.SetRange("Location Filter", Loc.Code);

                // 5️⃣ Calcular cantidades disponibles
                ItemAvailMgt.CalcAvailQuantities(
                    Item, false,
                    gross, planned, scheduled, plannedRel,
                    proj, exp, dummy, avail);

                // 6️⃣ Insertar en buffer temporal
                Rec.Init();
                Rec."Item No." := itemNo;
                Rec."Location Code" := Loc.Code;
                Rec."Location Name" := Loc.Name;
                Rec."Expected Inventory" := exp;
                Rec."Gross Requirement" := gross;
                Rec."Planned Order Receipt" := planned;
                Rec."Scheduled Receipt" := scheduled;
                Rec."Projected Available" := proj;
                Rec."Available Inventory" := avail;
                Rec.Insert();
            until Loc.Next() = 0;
    end;
}
