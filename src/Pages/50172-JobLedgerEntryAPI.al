page 50172 "JobLedgerEntryAPI"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'construction';
    APIVersion = 'v1.0';
    EntityName = 'jobLedgerEntry';
    EntitySetName = 'jobLedgerEntries';

    SourceTable = "Job Ledger Entry";
    ODataKeyFields = SystemId;

    DelayedInsert = true;

    InsertAllowed = true;   // o false si lo quieres solo lectura
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(SystemId; Rec.SystemId) { Caption = 'System Id'; }
                field(EntryNo; Rec."Entry No.") { Caption = 'Entry No.'; }
                field(JobNo; Rec."Job No.") { Caption = 'Job No.'; }
                field(PostingDate; Rec."Posting Date") { Caption = 'Posting Date'; }
                field(DocumentNo; Rec."Document No.") { Caption = 'Document No.'; }
                field(Type; Rec."Type") { Caption = 'Type'; }
                field(No; Rec."No.") { Caption = 'No.'; }
                field(Description; Rec."Description") { Caption = 'Description'; }
                field(Quantity; Rec."Quantity") { Caption = 'Quantity'; }
                field(DirectUnitCostLCY; Rec."Direct Unit Cost (LCY)") { Caption = 'Direct Unit Cost (LCY)'; }
                field(UnitCostLCY; Rec."Unit Cost (LCY)") { Caption = 'Unit Cost (LCY)'; }
                field(TotalCostLCY; Rec."Total Cost (LCY)") { Caption = 'Total Cost (LCY)'; }
                field(UnitPriceLCY; Rec."Unit Price (LCY)") { Caption = 'Unit Price (LCY)'; }
                field(TotalPriceLCY; Rec."Total Price (LCY)") { Caption = 'Total Price (LCY)'; }
                field(UnitOfMeasureCode; Rec."Unit of Measure Code") { Caption = 'Unit of Measure Code'; }
                field(LocationCode; Rec."Location Code") { Caption = 'Location Code'; }
                field(JobPostingGroup; Rec."Job Posting Group") { Caption = 'Job Posting Group'; }
                field(GlobalDimension1Code; Rec."Global Dimension 1 Code") { Caption = 'Global Dimension 1 Code'; }
                field(GlobalDimension2Code; Rec."Global Dimension 2 Code") { Caption = 'Global Dimension 2 Code'; }
                field(UserID; Rec."User ID") { Caption = 'User ID'; }
                field(EntryType; Rec."Entry Type") { Caption = 'Entry Type'; }
                field(JournalBatchName; Rec."Journal Batch Name") { Caption = 'Journal Batch Name'; }
                field(ReasonCode; Rec."Reason Code") { Caption = 'Reason Code'; }
                field(GenProdPostingGroup; Rec."Gen. Prod. Posting Group") { Caption = 'Gen. Prod. Posting Group'; }
                field(DocumentDate; Rec."Document Date") { Caption = 'Document Date'; }
                field(IDBoletaEntrega; Rec."ID Boleta Entrega") { Caption = 'ID Boleta Entrega'; }
                field(JobTaskNo; Rec."Job Task No.") { Caption = 'Job Task No.'; }
                field(LineAmountLCY; Rec."Line Amount (LCY)") { Caption = 'Line Amount (LCY)'; }
                field(UnitCost; Rec."Unit Cost") { Caption = 'Unit Cost'; }
                field(TotalCost; Rec."Total Cost") { Caption = 'Total Cost'; }
                field(UnitPrice; Rec."Unit Price") { Caption = 'Unit Price'; }
                field(TotalPrice; Rec."Total Price") { Caption = 'Total Price'; }
                field(LineAmount; Rec."Line Amount") { Caption = 'Line Amount'; }
                field(LedgerEntryType; Rec."Ledger Entry Type") { Caption = 'Ledger Entry Type'; }
                field(LedgerEntryNo; Rec."Ledger Entry No.") { Caption = 'Ledger Entry No.'; }
                field(VariantCode; Rec."Variant Code") { Caption = 'Variant Code'; }
                field(QtyPerUnitOfMeasure; Rec."Qty. per Unit of Measure") { Caption = 'Qty. per Unit of Measure'; }
                field(QuantityBase; Rec."Quantity (Base)") { Caption = 'Quantity (Base)'; }
                field(GomJobPrestoTaskNo; Rec."GomJob Presto Task No.") { Caption = 'GomJob Presto Task No.'; }
                field(GomJobVendorNo; Rec."GomJob Vendor No.") { Caption = 'GomJob Vendor No.'; }
                field(GomJobVendorName; Rec."GomJob Vendor Name") { Caption = 'GomJob Vendor Name'; }
            }
        }
    }
}
