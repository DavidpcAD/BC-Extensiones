page 50200 "GJW G/L Account API"
{
    PageType = API;
    APIPublisher = 'adelante';
    APIGroup = 'finance';
    APIVersion = 'v1.0';
    EntityName = 'glAccount';
    EntitySetName = 'glAccounts';

    SourceTable = "G/L Account";
    ODataKeyFields = "No.";
    DelayedInsert = true;

    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Main)
            {
                field(no; Rec."No.") { Caption = 'No.'; ApplicationArea = All; }
                field(name; Rec.Name) { Caption = 'Name'; ApplicationArea = All; }
                field(searchName; Rec."Search Name") { Caption = 'Search Name'; ApplicationArea = All; }
                field(accountType; Rec."Account Type") { Caption = 'Account Type'; ApplicationArea = All; }
                field(incomeBalance; Rec."Income/Balance") { Caption = 'Income/Balance'; ApplicationArea = All; }
                field(accountCategory; Rec."Account Category") { Caption = 'Account Category'; ApplicationArea = All; }
                field(debitCreditType; Rec."Debit/Credit") { Caption = 'Debit/Credit'; ApplicationArea = All; }
                field(genPostingType; Rec."Gen. Posting Type") { Caption = 'Gen. Posting Type'; ApplicationArea = All; }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group") { Caption = 'Gen. Bus. Posting Group'; ApplicationArea = All; }
                field(genProdPostingGroup; Rec."Gen. Prod. Posting Group") { Caption = 'Gen. Prod. Posting Group'; ApplicationArea = All; }
                field(blocked; Rec.Blocked) { Caption = 'Blocked'; ApplicationArea = All; }
                field(directPosting; Rec."Direct Posting") { Caption = 'Direct Posting'; ApplicationArea = All; }
                field(netChange; Rec."Net Change") { Caption = 'Net Change'; ApplicationArea = All; }
                field(balance; Rec.Balance) { Caption = 'Balance'; ApplicationArea = All; }
                field(balanceAtDate; Rec."Balance at Date") { Caption = 'Balance at Date'; ApplicationArea = All; }
                field(indentation; Rec.Indentation) { Caption = 'Indentation'; ApplicationArea = All; }
            }
        }
    }
}
