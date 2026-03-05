pageextension 50131 "GJW Works Line Page Ext" extends "GomJob Works Sub"
{
    layout
    {
        addafter(Description)
        {
            field("IDVisibles"; Rec."IDVisibles")
            {
                ApplicationArea = All;
                Caption = 'IDVisibles';
                ToolTip = 'Identificador visible asociado a esta línea';
                Visible = true;
                Editable = _isEditable;
            }
        }
        modify(Description)
        {
            Editable = _isEditable;
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Works: Record "GomJob Works";
    begin
        if Works.Get(Rec."Works No.") then
            _isEditable := not Works."Budget Locked"
        else
            _isEditable := true;
    end;

    trigger OnModifyRecord(): Boolean
    var
        Works: Record "GomJob Works";
    begin
        if Works.Get(Rec."Works No.") then
            if Works."Budget Locked" then
                Error('🔒 El presupuesto de esta obra está bloqueado. Modifícalo desde Power Apps.');
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Works: Record "GomJob Works";
    begin
        if Works.Get(Rec."Works No.") then
            if Works."Budget Locked" then
                Error('🔒 El presupuesto de esta obra está bloqueado. Modifícalo desde Power Apps.');
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        Works: Record "GomJob Works";
    begin
        if Works.Get(Rec."Works No.") then
            if Works."Budget Locked" then
                Error('🔒 El presupuesto de esta obra está bloqueado. Modifícalo desde Power Apps.');
        exit(true);
    end;

    var
        _isEditable: Boolean;
}
