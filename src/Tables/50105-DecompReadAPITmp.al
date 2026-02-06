table 50105 "DecompReadAPITmp"

{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; SystemId; Guid) { DataClassification = SystemMetadata; }
        field(2; category; Text[20]) { DataClassification = ToBeClassified; }
        field(3; "Works No."; Code[20]) { DataClassification = ToBeClassified; }
        field(4; "Task No."; Code[20]) { DataClassification = ToBeClassified; }
        field(5; "Description"; Text[100]) { DataClassification = ToBeClassified; }
        field(6; "Quantity"; Decimal) { DataClassification = ToBeClassified; }
        field(7; "Job No."; Code[20]) { DataClassification = ToBeClassified; }
        field(8; "Unit of Measure"; Code[20]) { DataClassification = ToBeClassified; }
        field(9; "Task Type"; Code[20]) { DataClassification = ToBeClassified; }
        field(10; "Type"; Code[20]) { DataClassification = ToBeClassified; }
        field(11; "No."; Code[20]) { DataClassification = ToBeClassified; }
        field(12; "Performance"; Decimal) { DataClassification = ToBeClassified; }
        field(13; "Variant Code"; Code[20]) { DataClassification = ToBeClassified; }
        field(14; qtyGastado; Decimal) { DataClassification = ToBeClassified; }
        field(15; cantidadDisponible; Decimal) { DataClassification = ToBeClassified; }
        field(16; estadoConsumo; Integer) { DataClassification = ToBeClassified; }
        field(17; VariantDesc; Text[100]) { DataClassification = ToBeClassified; }
        field(18; parentTaskTemp; Text[20]) { DataClassification = ToBeClassified; }
    }

    keys
    {
        key(PK; SystemId) { Clustered = true; }
    }
}