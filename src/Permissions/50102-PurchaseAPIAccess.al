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
        page "Adelante Last Purch Price API" = X,

        // Acceso a los codeunits de posting / preview
        codeunit "GJW Purchase Post Processor" = X,
        codeunit "GJW Purch Posting Preview" = X,

        // Acceso a tablas base necesarias
        tabledata "Purchase Header" = RIMD,
        tabledata "Purchase Line" = RIMD,
        tabledata "Purch. Rcpt. Header" = R,
        tabledata "Purch. Inv. Header" = R,

        // Lectura de ledgers para la vista previa (Preview Posting)
        tabledata "G/L Entry" = R,
        tabledata "VAT Entry" = R,
        tabledata "Item Ledger Entry" = R,
        tabledata "Value Entry" = R,
        tabledata "Vendor Ledger Entry" = R,
        tabledata "Detailed Vendor Ledg. Entry" = R,

        // Codeunits estándar de posting / preview
        codeunit "Purch.-Post" = X,
        codeunit "Purch.-Post (Yes/No)" = X,
        codeunit "Gen. Jnl.-Post Preview" = X,
        codeunit "Posting Preview Event Handler" = X;
}
