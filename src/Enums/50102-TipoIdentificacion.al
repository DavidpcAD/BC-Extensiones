// ════════════════════════════════════════════════════════════════════════════════
// Enum 50102 "GJW Tipo Identificacion"
// Cómo se identifica un proveedor ante Hacienda: como persona física (cédula de
// identidad) o como persona jurídica (cédula jurídica). El valor 0 (en blanco)
// significa "sin definir": es el que quedan arrastrando los proveedores que ya
// existían antes de este campo, y es justo lo que la ficha no deja guardar en uno
// nuevo.
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
        Caption = 'Persona física';
    }
    value(2; "Juridica")
    {
        Caption = 'Persona jurídica';
    }
}
