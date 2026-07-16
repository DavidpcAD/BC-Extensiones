// ════════════════════════════════════════════════════════════════════════════════
// Table 50250 "Adelante Postventa Setup"
// Mapeo editable prefijo del N° de obra -> obra Postventa del desarrollo.
// Ej: VN -> PV-NOVARUM, VI -> PV-ILIOS. Se mantiene desde la página homónima, sin
// recompilar para agregar desarrollos nuevos.
// ════════════════════════════════════════════════════════════════════════════════
table 50250 "Adelante Postventa Setup"
{
    Caption = 'Adelante Postventa Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Prefijo"; Code[20])
        {
            Caption = 'Prefijo N° Obra';
            NotBlank = true;
        }
        field(2; "Obra Postventa No."; Code[20])
        {
            Caption = 'Obra Postventa';
            TableRelation = "GomJob Works"."No.";
        }
        field(3; "Descripcion"; Text[100])
        {
            Caption = 'Descripción';
        }
    }

    keys
    {
        key(PK; "Prefijo") { Clustered = true; }
    }
}
