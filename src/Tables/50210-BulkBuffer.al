table 50199 "GJW Bulk Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        // Mantener compatibilidad: campos originales (no usados), necesarios para upgrade
        field(10; jsonNuevos; Text[2048]) { Caption = 'jsonNuevos'; ObsoleteState = Pending; ObsoleteReason = 'Use payload1..payload20'; }
        field(11; jsonEditados; Text[2048]) { Caption = 'jsonEditados'; ObsoleteState = Pending; ObsoleteReason = 'Use payload1..payload20'; }
        field(12; jsonEliminados; Text[2048]) { Caption = 'jsonEliminados'; ObsoleteState = Pending; ObsoleteReason = 'Use payload1..payload20'; }

        // Nuevos chunks para payload grande
        field(100; payload1; Text[2048]) { Caption = 'payload1'; }
        field(101; payload2; Text[2048]) { Caption = 'payload2'; }
        field(102; payload3; Text[2048]) { Caption = 'payload3'; }
        field(103; payload4; Text[2048]) { Caption = 'payload4'; }
        field(104; payload5; Text[2048]) { Caption = 'payload5'; }
        field(105; payload6; Text[2048]) { Caption = 'payload6'; }
        field(106; payload7; Text[2048]) { Caption = 'payload7'; }
        field(107; payload8; Text[2048]) { Caption = 'payload8'; }
        field(108; payload9; Text[2048]) { Caption = 'payload9'; }
        field(109; payload10; Text[2048]) { Caption = 'payload10'; }
        field(110; payload11; Text[2048]) { Caption = 'payload11'; }
        field(111; payload12; Text[2048]) { Caption = 'payload12'; }
        field(112; payload13; Text[2048]) { Caption = 'payload13'; }
        field(113; payload14; Text[2048]) { Caption = 'payload14'; }
        field(114; payload15; Text[2048]) { Caption = 'payload15'; }
        field(115; payload16; Text[2048]) { Caption = 'payload16'; }
        field(116; payload17; Text[2048]) { Caption = 'payload17'; }
        field(117; payload18; Text[2048]) { Caption = 'payload18'; }
        field(118; payload19; Text[2048]) { Caption = 'payload19'; }
        field(119; payload20; Text[2048]) { Caption = 'payload20'; }
        field(120; payload21; Text[2048]) { Caption = 'payload21'; }
        field(121; payload22; Text[2048]) { Caption = 'payload22'; }
        field(122; payload23; Text[2048]) { Caption = 'payload23'; }
        field(123; payload24; Text[2048]) { Caption = 'payload24'; }
        field(124; payload25; Text[2048]) { Caption = 'payload25'; }
        field(125; payload26; Text[2048]) { Caption = 'payload26'; }
        field(126; payload27; Text[2048]) { Caption = 'payload27'; }
        field(127; payload28; Text[2048]) { Caption = 'payload28'; }
        field(128; payload29; Text[2048]) { Caption = 'payload29'; }
        field(129; payload30; Text[2048]) { Caption = 'payload30'; }
        field(130; payload31; Text[2048]) { Caption = 'payload31'; }
        field(131; payload32; Text[2048]) { Caption = 'payload32'; }
        field(132; payload33; Text[2048]) { Caption = 'payload33'; }
        field(133; payload34; Text[2048]) { Caption = 'payload34'; }
        field(134; payload35; Text[2048]) { Caption = 'payload35'; }
        field(135; payload36; Text[2048]) { Caption = 'payload36'; }
        field(136; payload37; Text[2048]) { Caption = 'payload37'; }
        field(137; payload38; Text[2048]) { Caption = 'payload38'; }
        field(138; payload39; Text[2048]) { Caption = 'payload39'; }
        field(139; payload40; Text[2048]) { Caption = 'payload40'; }
        field(40; ejecutar; Boolean)
        {
            Caption = 'ejecutar';
        }
        field(41; resultado; Text[2048])
        {
            Caption = 'resultado';
        }
    }

    keys
    {
        key(PK; ID)
        {
            Clustered = true;
        }
    }
}
