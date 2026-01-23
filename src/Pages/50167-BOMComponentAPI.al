page 50167 "GJW BOM Component API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'production';
    APIVersion = 'v1.0';
    EntityName = 'bomComponent';
    EntitySetName = 'bomComponents';
    SourceTable = "BOM Component";
    DelayedInsert = true;
    ODataKeyFields = "Parent Item No.", "Line No.";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(parentItemNo; Rec."Parent Item No.")
                {
                    Caption = 'Parent Item No.';
                }
                field(lineNo; Rec."Line No.")
                {
                    Caption = 'Line No.';
                }
                field(type; Rec.Type)
                {
                    Caption = 'Type';
                }
                field(no; Rec."No.")
                {
                    Caption = 'No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(quantityPer; Rec."Quantity per")
                {
                    Caption = 'Quantity per';
                }
                field(unitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                field(variantCode; Rec."Variant Code")
                {
                    Caption = 'Variant Code';
                }
                field(resourceUsageType; Rec."Resource Usage Type")
                {
                    Caption = 'Resource Usage Type';
                }
                field(position; Rec.Position)
                {
                    Caption = 'Position';
                }
                field(position2; Rec."Position 2")
                {
                    Caption = 'Position 2';
                }
                field(position3; Rec."Position 3")
                {
                    Caption = 'Position 3';
                }
                field(installedInLine; Rec."Installed in Line No.")
                {
                    Caption = 'Installed in Line No.';
                }
            }
        }
    }
}
