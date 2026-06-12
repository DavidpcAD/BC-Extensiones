// ════════════════════════════════════════════════════════════════════════════════
// PermissionSet 50102 "GJW Purch API"
// Propósito: Permisos necesarios para usar las APIs de Pedidos de Compra
// ════════════════════════════════════════════════════════════════════════════════
permissionset 50102 "GJW Purch API"
{
    Assignable = true;
    Caption = 'Adelante Purchase API';

    Permissions =
        // Acceso a las páginas API
        page "GJW Purchase Orders API" = X,
        page "GJW Purchase Lines API" = X,
        page "GJW Purchase Quotes API" = X,
        page "GJW Purchase Quote Lines API" = X,
        page "GJW Post Purchase Order API" = X,

        // Acceso al codeunit de posting
        codeunit "GJW Purchase Post Processor" = X,

        // Acceso a tablas base necesarias
        tabledata "Purchase Header" = RIMD,
        tabledata "Purchase Line" = RIMD,
        tabledata "Purch. Rcpt. Header" = R,
        tabledata "Purch. Inv. Header" = R,

        // Codeunit estándar de posting
        codeunit "Purch.-Post" = X;
}
