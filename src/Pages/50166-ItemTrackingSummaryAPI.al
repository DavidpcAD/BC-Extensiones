page 50166 "GJW Item Tracking Summary API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'inventory';
    APIVersion = 'v1.0';
    EntityName = 'itemTrackingSummary';
    EntitySetName = 'itemTrackingSummaries';
    SourceTable = "Entry Summary";
    DelayedInsert = true;
    ODataKeyFields = "Entry No.";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(entryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(tableId; Rec."Table ID")
                {
                    Caption = 'Table ID';
                }
                field(summaryType; Rec."Summary Type")
                {
                    Caption = 'Summary Type';
                }
                field(lotNo; Rec."Lot No.")
                {
                    Caption = 'Lot No.';
                }
                field(serialNo; Rec."Serial No.")
                {
                    Caption = 'Serial No.';
                }
                field(packageNo; Rec."Package No.")
                {
                    Caption = 'Package No.';
                }
                field(totalQuantity; Rec."Total Quantity")
                {
                    Caption = 'Total Quantity';
                }
                field(totalRequestedQuantity; Rec."Total Requested Quantity")
                {
                    Caption = 'Total Requested Quantity';
                }
                field(currentPendingQuantity; Rec."Current Pending Quantity")
                {
                    Caption = 'Current Pending Quantity';
                }
                field(totalAvailableQuantity; Rec."Total Available Quantity")
                {
                    Caption = 'Total Available Quantity';
                }
                field(expirationDate; Rec."Expiration Date")
                {
                    Caption = 'Expiration Date';
                }
                field(warrantyDate; Rec."Warranty Date")
                {
                    Caption = 'Warranty Date';
                }
            }
        }
    }
}
