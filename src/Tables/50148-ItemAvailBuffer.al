table 50148 "GJW Item Availability Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Location Code"; Code[10]) { DataClassification = CustomerContent; }
        field(3; "Location Name"; Text[50]) { DataClassification = CustomerContent; }
        field(4; "Expected Inventory"; Decimal) { }
        field(5; "Gross Requirement"; Decimal) { }
        field(6; "Planned Order Receipt"; Decimal) { }
        field(7; "Scheduled Receipt"; Decimal) { }
        field(8; "Projected Available"; Decimal) { }
        field(9; "Available Inventory"; Decimal) { }
    }

    keys
    {
        key(PK; "Item No.", "Location Code") { Clustered = true; }
    }
}
