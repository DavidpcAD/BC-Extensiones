// ════════════════════════════════════════════════════════════════════════════════
// Enum 50102 "GJW Tipo Identificacion"
// Cómo se identifica un proveedor ante Hacienda. La lista es la MISMA que la del
// campo "Tipo de identificación" de la localización de Costa Rica (LLB VAT
// registration Type, 70830810) y en el mismo orden, porque los dos campos guardan
// el mismo dato y se copian entre sí (codeunit 50259).
//
// La diferencia: aquí sí hay un valor en blanco. El de LLB arranca en "Cédula
// Física" para todo el mundo, así que con él no se puede saber a quién le falta el
// dato; con este sí, y es lo que permite exigirlo al crear el proveedor.
// ════════════════════════════════════════════════════════════════════════════════
enum 50102 "GJW Tipo Identificacion"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Fisica")
    {
        Caption = 'Cédula Física';
    }
    value(2; "Juridica")
    {
        Caption = 'Cédula Jurídica';
    }
    value(3; "DIMEX")
    {
        Caption = 'Documento de Identificación de Migración y Extranjería - DIMEX';
    }
    value(4; "NITE")
    {
        Caption = 'NITE o Pasaporte Extranjero';
    }
    value(5; "Extranjero No Domiciliado")
    {
        Caption = 'Extranjero no domiciliado';
    }
    value(6; "No Contribuyente")
    {
        Caption = 'No contribuyente';
    }
}
