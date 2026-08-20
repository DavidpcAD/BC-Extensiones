// ════════════════════════════════════════════════════════════════════════════════
// Enum 50101 "GJW Tipo Almacen"
// Clasifica los almacenes (tabla Location 14) entre físicos (Real) y lógicos
// (Virtual: casas, comisiones, centros de costo, etc. que no tienen bodega física).
// El valor 0 (en blanco) significa "sin clasificar" para no asumir un tipo en los
// almacenes ya existentes.
// ════════════════════════════════════════════════════════════════════════════════
enum 50101 "GJW Tipo Almacen"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Real")
    {
        Caption = 'Real';
    }
    value(2; "Virtual")
    {
        Caption = 'Virtual';
    }
}
