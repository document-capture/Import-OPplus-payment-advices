codeunit 61150 "OPP DC Avis - Register"
{
    TableNo = "CDC Document";

    trigger OnRun()
    var
        CDCTemplate: Record "CDC Template";
        CDCTemplateField: Record "CDC Template Field";
        ImpInterfaceTemplField: Record "CDC Template Field";
        //Setup: Record "CDC Document Capture Setup";
        OPPPmtImpSetup: Record "OPP Pmt. Import Setup";
        OPPImportLines: Record "OPP Pmt. Import Line";
        PmtImportRegister: Record "OPP Pmt. Import Register";
        TempDocumentLine: Record "CDC Temp. Document Line" temporary;

        NoSeriesMgmt: Codeunit NoSeriesManagement;
        ShowDocument: Boolean;
        PmtLineEntryNo: Integer;
    begin
        CDCTemplate.GET(Rec."Template No.");

        if CDCTemplate."Codeunit ID: Doc. Validation" <> 0 then begin
            Codeunit.Run(CDCTemplate."Codeunit ID: Doc. Validation", Rec);
            Commit();
        end;
        Rec.TestField(Rec.OK);

        // Set Journal description
        /*IF Rec.Description = '' THEN
            Rec.Description := CopyStr(CaptureMgnt.GetText(Rec, CDCTemplateField.Type::Header, 'DESC', 0), 1, MaxStrLen(Rec.Description));
        IF Rec.Description = '' THEN
            Rec.Description := CopyStr(CDCTemplate.Description, 1, MaxStrLen(Rec.Description));
        */
        if not ImpInterfaceTemplField.Get(Rec."Template No.", ImpInterfaceTemplField.Type::Header, 'IMPINTERFACE') then
            exit;

        PmtImportInterface.GET(CaptureMgnt.GetText(Rec, CDCTemplateField.Type::Header, 'IMPINTERFACE', 0));
        PmtImportInterface."Last Statement" += 1;
        PmtImportInterface.Modify();

        OPPPmtImpSetup.GET();

        PmtImportRegister.ChangeCompany(PmtImportInterface."Import to Company");
        PmtImportRegister.INIT();
        PmtImportRegister.Validate("No.", NoSeriesMgmt.GetNextNo(OPPPmtImpSetup."Pmt. Import Journal Nos.", TODAY, TRUE));
        PmtImportRegister.Validate("Pmt. Import Interface", PmtImportInterface.Code);
        PmtImportRegister.Validate("No. Series", OPPPmtImpSetup."Pmt. Import Journal Nos.");
        PmtImportRegister.Validate("Port Code", 'AVIS');
        PmtImportRegister.Validate("Filename", CopyStr(CaptureMgnt.GetText(Rec, CDCTemplateField.Type::Header, 'DESC', 0), 1, MaxStrLen(PmtImportRegister.Filename)));
        IF PmtImportRegister.Filename = '' THEN
            PmtImportRegister.Validate("Filename", StrSubstNo('Import via Document Capture %1', Rec."No."));

        PmtImportRegister."Statement No." := Rec."No.";
        PmtImportRegister.Validate("Import Date", TODAY());
        PmtImportRegister.Validate("Import Time", Time);
        PmtImportRegister.Validate("User ID", CopyStr(USERID(), 1, MaxStrLen(PmtImportRegister."User ID")));
        PmtImportRegister.Validate("In Progress", TRUE);
        //PmtImportRegister.Validate("Statement No.", FORMAT(PmtImportInterface."Last Statement"));

        RecRef.GETTABLE(PmtImportRegister);

        //Transfer header fields
        CaptureMgnt.TransferTableFields(RecRef, Rec, 0, TRUE);
        RecRef.SETTABLE(PmtImportRegister);
        IF PmtImportRegister."Statement Date" = 0D THEN
            PmtImportRegister.Validate("Statement Date", TODAY);

        PmtImportRegister.INSERT(true);

        Rec.BuildTempLinesTable(TempDocumentLine);

        IF TempDocumentLine.FINDSET(FALSE, FALSE) THEN begin
            REPEAT
                InsertLine(Rec, TempDocumentLine, PmtImportRegister, PmtLineEntryNo);
            UNTIL TempDocumentLine.NEXT() = 0;
        end;

        Rec.Status := Rec.Status::Registered;
        Rec.MODIFY();

        IF CDCTemplate."Codeunit ID: After Step 1" <> 0 THEN
            CODEUNIT.RUN(CDCTemplate."Codeunit ID: After Step 1", Rec);

        IF CDCTemplate."Codeunit ID: After Step 2" <> 0 THEN
            CODEUNIT.RUN(CDCTemplate."Codeunit ID: After Step 2", Rec);

        Rec."Created Doc. Table No." := Database::"OPP Pmt. Import Register";
        //Document."Created Doc. Subtype" := PurchHeader."Document Type";
        Rec."Created Doc. No." := PmtImportRegister."No.";
        Rec.Modify();
        case CDCTemplate."Show Document After Register" of
            CDCTemplate."Show Document After Register"::Always:
                ShowDocument := true;
            CDCTemplate."Show Document After Register"::Ask:
                ShowDocument := Confirm('Sollen die erzeugten Importzeilen angezeigt werden?', false);
        end;

        if ShowDocument then begin
            OPPImportLines.SetRange("Pmt. Import Interface Code", PmtImportInterface.Code);
            OPPImportLines.SetRange("Statement No.", Rec."No.");
            if OPPImportLines.IsEmpty then
                error('Es wurden keine Importzeilen an das OPP Import Journal übergeben');
            page.Run(5157819, OPPImportLines);
        end;

    end;



    /*
    local procedure GetNextPmtImportLineEntryNo(): Integer
    begin
        if PmtImportLine.FindLast() then
            exit(PmtImportLine."Entry No." + 1)
        else
            exit(1);
    end;
*/
    procedure InsertLine(CDCDoc: Record "CDC Document"; CDCTempDocLine: Record "CDC Temp. Document Line"; var PmtImportRegister: Record "OPP Pmt. Import Register"; var CurrEntryNo: Integer);
    var
        PmtImportLine: Record "OPP Pmt. Import Line";
    BEGIN
        PmtImportLine.CHANGECOMPANY(PmtImportRegister.CurrentCompany);

        if CurrEntryNo = 0 then
            if PmtImportLine.FindLast() then
                CurrEntryNo := PmtImportLine."Entry No.";

        CurrEntryNo += 1;


        PmtImportLine.INIT();
        PmtImportLine.Validate("Entry No.", CurrEntryNo);
        PmtImportLine.Validate("Import Register No.", PmtImportRegister."No.");
        PmtImportLine.Validate("Pmt. Import Interface Code", PmtImportInterface.Code);
        PmtImportLine.Validate("Statement No.", PmtImportRegister."Statement No.");

        PmtImportLine.Validate("Statement Line No.", CDCTempDocLine."Line No.");
        PmtImportLine.Validate("Import Date", PmtImportRegister."Import Date");
        PmtImportLine.Validate("Import Time", PmtImportRegister."Import Time");
        PmtImportLine.Validate("User ID", CopyStr(USERID(), 1, MaxStrLen(PmtImportLine."User ID")));
        PmtImportLine.Validate("Import in Acc. Type", PmtImportInterface."Import to Account Type");
        PmtImportLine.Validate("Import in Acc. No.", PmtImportInterface."Import to Account No.");

        RecRef.GETTABLE(PmtImportLine);
        CaptureMgnt.TransferTableFields(RecRef, CDCDoc, CDCTempDocLine."Line No.", FALSE);
        RecRef.SETTABLE(PmtImportLine);

        IF PmtImportLine."Posting Date" = 0D THEN
            PmtImportLine.Validate("Posting Date", PmtImportRegister."Statement Date");

        PmtImportLine.Insert(true);
        //;
    END;

    VAR


        PmtImportInterface: Record "OPP Pmt. Import Interface";
        CaptureMgnt: Codeunit "CDC Capture Management";
        RecRef: RecordRef;
}
