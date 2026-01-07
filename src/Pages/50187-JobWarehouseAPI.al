page 50187 "GJW Job Warehouse API"
{
    PageType = API;
    Caption = 'Job Warehouse Quantity API';
    APIPublisher = 'adelante';
    APIGroup = 'returns';
    APIVersion = 'v1.0';
    EntityName = 'jobWarehouseQuantity';
    EntitySetName = 'jobWarehouseQuantities';
    SourceTable = "GomJob Warehouse Quantity";
    DelayedInsert = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(systemId; Rec.SystemId)
                {
                    ApplicationArea = All;
                    Caption = 'System Id';
                }
                field(itemLedgerEntryNo; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = All;
                    Caption = 'Item Ledger Entry No.';
                }
                field(jobNo; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job No.';
                }
                field(jobTaskNo; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task No.';
                }
                field(jobTaskDescription; Rec."Job Task Description")
                {
                    ApplicationArea = All;
                    Caption = 'Job Task Description';
                }
                field(quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Quantity';
                }
                field(itemNo; ItemNo)
                {
                    ApplicationArea = All;
                    Caption = 'Item No.';
                    Editable = false;
                }
                field(description; ItemDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                }
                field(locationCode; LocationCode)
                {
                    ApplicationArea = All;
                    Caption = 'Location Code';
                    Editable = false;
                }
            }
        }
    }

    var
        ItemNo: Code[20];
        ItemDescription: Text[100];
        LocationCode: Code[10];

    trigger OnAfterGetRecord()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        JobTask: Record "Job Task";
    begin
        Clear(ItemNo);
        Clear(ItemDescription);
        Clear(LocationCode);

        // Obtener Item No. y Description desde Item Ledger Entry
        if ItemLedgerEntry.Get(Rec."Item Ledger Entry No.") then begin
            ItemNo := ItemLedgerEntry."Item No.";
            ItemDescription := ItemLedgerEntry.Description;
        end;

        // Obtener Location Code desde Job Task
        if JobTask.Get(Rec."Job No.", Rec."Job Task No.") then
            LocationCode := JobTask."Location Code";
    end;
}
