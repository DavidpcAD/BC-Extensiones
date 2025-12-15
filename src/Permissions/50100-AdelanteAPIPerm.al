permissionset 50100 "Adelante API RIMD"
{
    Assignable = true;
    IncludedPermissionSets = SUPER;  // ⚠️ TEMPORAL para depurar
    Permissions =
        // TABLAS (CRUD completo)
        tabledata "GomJob Works" = RIMD,
        tabledata "GomJob Works Line" = RIMD,
        tabledata "GomJob Works Production Line" = RIMD,
        tabledata "GomJob Works Certif. Line" = RIMD,
        tabledata "GomJob Works Additional Line" = RIMD,
        tabledata "GomJob Works Version" = RIMD,
        tabledata "GomJob Posted Prod. Buffer" = RIMD,
        tabledata "GomJob Posted Works Prod. Line" = RIMD,
        tabledata "GomJob Works Decomposed Lines" = RIMD,
        tabledata "Item Journal Template" = RIMD,   //
        tabledata "Item Journal Batch" = RIMD,
        tabledata "Item Journal Line" = RIMD,
        tabledata "Job Ledger Entry" = R,
        tabledata "Item Variant" = R,
        tabledata "Item Ledger Entry" = RIMD,
        tabledata "GomJob Warehouse Quantity" = RIMD,
        tabledata "GJW Item Availability Buffer" = RIMD,
        tabledata "Job Journal Line" = RIMD,
        tabledata Item = R,
        tabledata Location = R,
        tabledata "Job Task" = RIMD,
        tabledata "Job" = R,
        tabledata "Job Journal Batch" = RIMD,
        tabledata "Job Journal Template" = RIMD,
        tabledata "GJW Warehouse Quantity Buffer" = RIMD,




        // PÁGINAS API (Execute)
        page "GJW Works API" = X,
        page "GJWWorkLines" = X,
        page "GJW Production Lines API" = X,
        page "GJW Posted Prod Buffer" = X,
        page "GJW Posted Work Prod Lines" = X,
        page "GJW Works Decomposed Line API" = X,
        page "GJW Decomposed Lines API" = X,
        page "GJW Item Journal Templates API" = X,
        page "GJW Item Journal Batches API" = X,
        page "GJW Item Journal Lines API" = X,
        page "GJW Works Decomp OnSite" = X,
        page "GJW Works Version" = X,
        page "GJW WorksDecompImportV2 API" = X,
        page "GJW ItemAvailBuffer API" = X,
        page "GJW Init ItemAvailBuffer Page" = X,
        page "GJW WorksDecomp Bulk API" = X,
        page "GJW WorksDecomp Bulk Single" = X,
        page "GJW Bulk Operations API" = X,
        page "Job Task API" = X,
        page "Job Journal Batch API" = X,
        page "Job Journal Template API" = X,
        page "Adelante Item API" = X,
        page "Adelante Job Journal Line API" = X,


        // CODEUNITS (Execute)
        codeunit "GJW WorksDecomp Bulk" = X,
        codeunit "GJW WorksDecomp Bulk Unbound" = X,
        codeunit "GJW Init ItemAvailBuffer API" = X,
        codeunit JobJnlManagement = X,
        codeunit "GJW Job Journal Line ValPre" = X,
        codeunit "GJW Job Journal Line ValPost" = X,
        codeunit "GJW Warehouse Quantity Handler" = X,
        codeunit "GJW Warehouse Quantity POST" = X,
        codeunit "Job Journal Line AutoNo" = X,
        codeunit "Item Journal Line AutoNo" = X,
        codeunit "GJW Item Journal Post Handler" = X; // ⭐ Automatización Warehouse Quantity

}
