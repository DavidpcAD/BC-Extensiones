page 50196 "GJW Disassembly Comp API"
{
    PageType = API;
    Caption = 'Disassembly Components API';
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'disassemblyComponent';
    EntitySetName = 'disassemblyComponents';
    SourceTable = "GJW Disassembly Components";
    SourceTableTemporary = true;
    DelayedInsert = true;
    ODataKeyFields = "Entry No.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(entryNo; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Entry No.';
                }
                field(parentEntryNo; Rec."Parent Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Parent Entry No.';
                }
                field(itemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                }
                field(variantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    Caption = 'Variant Code';
                }
            }
        }
    }
}
