codeunit 50261 "Produccion Pendiente Guard"
{
    // Pared contra el sobreavance de producción (incidente 2026-10-01).
    //
    // «Traer tareas de proyecto» inserta las líneas con "Maximum Quantity" = 1 y
    // Quantity = 0, y deja "Outstanding Amount" calculado contra la Maximum
    // Quantity: la línea nace con el 100 % del presupuesto como pendiente. El
    // report 70720583 «GomJob Register Production» postea ese pendiente, así que
    // registrar la obra genera el asiento del presupuesto entero con las
    // cantidades en cero (VC-F.12 línea 1.1: 725.399,30 = (1 - 0,8875) x 6.447.993,81).
    //
    // La base del cálculo es "Outstanding Quantity" (110), no (Quantity -
    // "Registered Quantity"). Las dos dan lo mismo en las líneas de tipo Posting
    // —Goom mantiene ahí la resta— pero NO en las de tipo Total: los capítulos
    // llevan Quantity = 1 y "Unit Amount" = el total del capítulo, y Goom les deja
    // a propósito las dos columnas de pendiente en cero porque no se registran.
    // Calcular contra la resta les metería el capítulo entero como pendiente y
    // duplicaría el presupuesto por el otro lado. Medido en Sandbox el 02/10/2026:
    // la resta tocaba 285 de 2.732 líneas (284 de ellas capítulos, 5.330 millones
    // de colones de más); el "Outstanding Quantity" toca 1, que es el bug real.
    //
    // Acá se fuerza esa identidad antes de que la fila se escriba. En una línea
    // sana ya se cumple, así que no cambia nada; si Goom corrige el bug sigue sin
    // cambiar nada y se puede retirar sin prisa.

    [EventSubscriber(ObjectType::Table, Database::"GomJob Works Production Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CuadrarAlInsertar(var Rec: Record "GomJob Works Production Line"; RunTrigger: Boolean)
    begin
        CuadrarPendiente(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"GomJob Works Production Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CuadrarAlModificar(var Rec: Record "GomJob Works Production Line"; RunTrigger: Boolean)
    begin
        CuadrarPendiente(Rec);
    end;

    local procedure CuadrarPendiente(var Linea: Record "GomJob Works Production Line")
    var
        Correcto: Decimal;
    begin
        Correcto := Linea."Outstanding Quantity" * Linea."Unit Amount";
        if Linea."Outstanding Amount" <> Correcto then
            Linea."Outstanding Amount" := Correcto;
    end;
}
