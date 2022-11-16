codeunit 61154 "PTE DC2OPP Reopen"
{
    TableNo = 6085590;

    trigger OnRun()
    var
        PmtImportRegister: Record "OPP Pmt. Import Register";
    begin
        CASE Rec.Status OF
            Rec.Status::Open:
                ERROR(AlreadyOpenErr, Rec.TABLECAPTION);
            Rec.Status::Registered, Rec.Status::Rejected:
                IF NOT CONFIRM(STRSUBSTNO(DoYouWantToReopenQst), TRUE) THEN
                    ERROR('');
        END;

        Rec."Force Register" := FALSE;
        //Prüfen, ob noch Datensätze existieren und ggf. löschen
        PmtImportRegister.SetRange("No.", Rec."Created Doc. No.");

        if not PmtImportRegister.IsEmpty then
            PmtImportRegister.DeleteAll(true);
        Rec.VALIDATE(Status, Rec.Status::Open);
        Rec.VALIDATE(OK, FALSE);
        Rec.MODIFY(TRUE);
    end;

    var
        DoYouWantToReopenQst: Label 'Do you want to reopen the document?';
        AlreadyOpenErr: Label '%1 is already open.';
}
