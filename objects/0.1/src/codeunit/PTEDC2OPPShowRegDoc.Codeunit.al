codeunit 61155 "PTE DC2OPP Show. Reg. Doc."
{
    TableNo = 6085590;

    trigger OnRun()
    begin
        ShowPmtImpJnlLines(Rec);
    end;

    procedure ShowPmtImpJnlLines(Document: Record "CDC Document")
    var
        PmtImportRegister: Record "OPP Pmt. Import Register";
    begin
        if Document."Created Doc. Table No." = Database::"OPP Pmt. Import Register" then begin
            PmtImportRegister.SetRange("No.", Document."Created Doc. No.");
            if not PmtImportRegister.IsEmpty then
                page.Run(5157818, PmtImportRegister);
        end;
    end;
}
