enum 50100 "GJW Posting Status"
{
    Extensible = true;

    value(0; Pending)
    {
        Caption = 'Pending';
    }
    value(1; Processing)
    {
        Caption = 'Processing';
    }
    value(2; Success)
    {
        Caption = 'Success';
    }
    value(3; Failed)
    {
        Caption = 'Failed';
    }
    value(4; PartialSuccess)
    {
        Caption = 'Partial Success';
    }
}
