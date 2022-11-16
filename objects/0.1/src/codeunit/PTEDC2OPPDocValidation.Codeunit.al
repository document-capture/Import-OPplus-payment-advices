codeunit 61151 "PTE DC2OPP Doc Validation"
{
    // C/SIDE
    // revision:63
    // This codeunit validates the full sales document

    TableNo = 6085590;

    trigger OnRun()
    var
        DocumentLine: Record "CDC Temp. Document Line" temporary;
        Template: Record "CDC Template";
        "Field": Record "CDC Template Field";
        DocumentComment: Record "CDC Document Comment";
        Cust: Record Customer;
        IsValid: Boolean;
        IsHandled: Boolean;
    begin
        CODEUNIT.RUN(CODEUNIT::"CDC Doc. - Field Validation", Rec);

        Template.GET(Rec."Template No.");

        IsValid := Rec.OK;

        Cust.GET(Rec.GetSourceID);
        IF Cust.Blocked = Cust.Blocked::All THEN BEGIN
            DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error,
              STRSUBSTNO(Text006, Cust.FIELDCAPTION(Blocked), Cust.Blocked, Cust.TABLECAPTION, Cust."No."));
            IsValid := FALSE;
        END;
        /*
        AmountExclVAT := SalesDocMgt.GetAllAmountsExclVAT(Rec);
        VATAmount := SalesDocMgt.GetVATAmount(Rec);
        SubtractedAmountExclVAT := SalesDocMgt.GetSubtractedAmountExclVAT(Rec);
        AmountInclVAT := SalesDocMgt.GetAmountInclVAT(Rec);

        // *********************************************************************************************************************************
        // CHECK EXTERNAL DOCUMENT NO.
        // *********************************************************************************************************************************
        CustDocNo := COPYSTR(SalesDocMgt.GetDocumentNo(Rec), 1, MAXSTRLEN(CustDocNo));
        IF CustDocNo <> '' THEN BEGIN
            CustLedgEntry.RESET;
            CustLedgEntry.SETCURRENTKEY("External Document No.");
            IF SalesDocMgt.GetDocType(Rec) = SalesHeader."Document Type"::Order THEN
                CustLedgEntry.SETRANGE("Document Type", CustLedgEntry."Document Type"::Invoice)
            ELSE
                CustLedgEntry.SETRANGE("Document Type", CustLedgEntry."Document Type"::"Credit Memo");
            CustLedgEntry.SETRANGE("External Document No.", COPYSTR(CustDocNo, 1, MAXSTRLEN(CustLedgEntry."External Document No.")));
            CustLedgEntry.SETRANGE("Customer No.", Cust."No.");
            IF CustLedgEntry.FINDFIRST THEN BEGIN
                DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error,
                  STRSUBSTNO(DocNoExistOnEntryMsg, CustDocNo, CustLedgEntry.TABLECAPTION,
                  CustLedgEntry.FIELDCAPTION("Entry No."), CustLedgEntry."Entry No."));
                IsValid := FALSE;
            END ELSE BEGIN
                SalesHeader.SETCURRENTKEY("Document Type", "Sell-to Customer No.", "No.");
                IF SalesDocMgt.GetDocType(Rec) = SalesHeader."Document Type"::Order THEN
                    SalesHeader.SETFILTER("Document Type", '%1|%2', SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice)
                ELSE
                    SalesHeader.SETFILTER("Document Type", '%1|%2',
                      SalesHeader."Document Type"::"Credit Memo", SalesHeader."Document Type"::"Return Order");
                SalesHeader.SETRANGE("External Document No.", COPYSTR(CustDocNo, 1, MAXSTRLEN(SalesHeader."External Document No.")));
                SalesHeader.SETRANGE("Sell-to Customer No.", Cust."No.");
                IF SalesHeader.FINDFIRST THEN BEGIN
                    DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error,
                      STRSUBSTNO(DocNoExistOnEntryMsg, CustDocNo, SalesHeader.TABLECAPTION, SalesHeader."Document Type", SalesHeader."No."));
                    IsValid := FALSE;
                END;
            END;
        END;
*/
        // *********************************************************************************************************************************
        // WARN IF DIFFERENT DATE FORMATS ARE USED ON FIELDS
        // *********************************************************************************************************************************
        IsHandled := FALSE;
        OnBeforeCheckDifferentDateFormatsUsed(Rec, Template, IsHandled);
        IF NOT IsHandled THEN BEGIN
            Field.SETRANGE("Template No.", Rec."Template No.");
            Field.SETRANGE("Data Type", Field."Data Type"::Date);
            IF Field.FINDFIRST THEN BEGIN
                Field.SETFILTER("Date Format", '<>%1', Field."Date Format");
                IF NOT Field.ISEMPTY THEN
                    DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Warning, Text011);
            END;
        END;
        Field.RESET;
        /*
                DocCurrCode := SalesDocMgt.GetCurrencyCode(Rec);
                GLSetup.GET;
                DCSetup.GET;

                // *********************************************************************************************************************************
                // CHECK CURRENCY CODE
                // *********************************************************************************************************************************
                IF (DocCurrCode = '') AND DCSetup."Fill-out LCY" THEN
                    DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error, Text019);

                // *********************************************************************************************************************************
                // WARN IF CURRENCY CODE <> CUSTOMER CARD CURRENCY CODE
                // *********************************************************************************************************************************
                IF (NOT ((Cust."Currency Code" IN ['', GLSetup."LCY Code"]) AND (DocCurrCode IN ['', GLSetup."LCY Code"])) AND
                  (Cust."Currency Code" <> DocCurrCode))
                THEN
                    DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Warning,
                      STRSUBSTNO(Text008, DocCurrCode, Cust.TABLECAPTION, Cust."Currency Code"));

                // *********************************************************************************************************************************
                // CHECK HEADER AMOUNTS
                // *********************************************************************************************************************************
                IF ((AmountExclVAT + VATAmount) - AmountInclVAT) <> 0 THEN BEGIN
                    DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error, Text001);
                    IsValid := FALSE;
                END;

                // *********************************************************************************************************************************
                // CHECK NOSERIES
                // *********************************************************************************************************************************
                IF Field.GET("Template No.", Field.Type::Header, 'NOSERIES') THEN BEGIN
                    DocNoSeriesCode := SalesDocMgt.GetDocumentNoSeriesCode(Rec);
                    IF DocNoSeriesCode <> '' THEN BEGIN
                        // Check NoSeries exist
                        IF NOT NoSeries.GET(DocNoSeriesCode) THEN
                            DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Warning,
                              STRSUBSTNO(NoSeriesNotFoundMsg, NoSeries.TABLECAPTION, DocNoSeriesCode))
                        ELSE BEGIN
                            MainNoSeriesCode := DocNoSeriesMgt.GetMainNoseriesCode(Rec);
                            IF MainNoSeriesCode <> '' THEN //Check that NoSeries is linked to main NoSeries
                                IF NoSeries.Code <> MainNoSeriesCode THEN
                                    IF NOT NoSeriesRelationship.GET(MainNoSeriesCode, NoSeries.Code) THEN
                                        DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Warning,
                                          STRSUBSTNO(NoSerNotLinkToMainNoSerMsg, NoSeries.TABLECAPTION, NoSeries.Code, MainNoSeriesCode));
                        END;
                    END;
                END;
        */
        // *********************************************************************************************************************************
        // BUILD LINES TABLE AND CHECK THE LINES
        // *********************************************************************************************************************************
        Rec.BuildTempLinesTable(DocumentLine);
        IF DocumentLine.ISEMPTY THEN BEGIN
            IF Template."Recognize Lines" = Template."Recognize Lines"::Yes THEN
                DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Warning, Text012);
        END ELSE
            IF NOT DocumentLine.ISEMPTY THEN BEGIN
                DocumentLine.SETRANGE(OK, FALSE);
                IF NOT DocumentLine.ISEMPTY THEN BEGIN
                    DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error, Text002);
                    IsValid := FALSE;
                END;
            END;
        /*                
                        // Sum all the lines and compare it to the headerfield, Amount Excl. VAT
                        IF Template."Validate Line Totals" THEN BEGIN
                            DocumentLine.SETRANGE(OK);
                            IF DocumentLine.FINDSET(FALSE, FALSE) THEN
                                REPEAT
                                    TotalLineAmount := TotalLineAmount + SalesDocMgt.GetLineAmount(Rec, DocumentLine."Line No.");
                                UNTIL DocumentLine.NEXT = 0;

                            IF ((TotalLineAmount <> 0) OR (SubtractedAmountExclVAT <> 0)) AND (TotalLineAmount <> SubtractedAmountExclVAT) THEN BEGIN
                                DocumentComment.Add(Rec, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error,
                                  STRSUBSTNO(Text003, DCAppMgt.FormatAmount(TotalLineAmount, DocCurrCode),
                                  DCAppMgt.FormatAmount(SubtractedAmountExclVAT, DocCurrCode)));
                                IsValid := FALSE;
                            END;
                        END;
                    END;
                */
        IsValid := IsValid AND ValidateLines(Template, Rec, DocumentLine);
        IsValid := IsValid AND ValidateAmtAccounts(Rec, Template);
        OnAfterValidateDocument(Rec, Template, IsValid);

        IF IsValid <> Rec.OK THEN BEGIN
            Rec.OK := IsValid;
            Rec.MODIFY;
        END;
    end;

    var
        Text002: Label 'One or more lines have errors.';
        Text006: Label '%1 cannot be ''%2'' on %3 %4';
        Text009: Label 'No lines have been matched and no amounts has been configured to be transfered.';
        Text010: Label 'No Account has been configured for %1.';
        Text011: Label 'WARNING: Different date formats used on fields.';
        Text012: Label 'WARNING: No lines recognized.';

    internal procedure ValidateLines(Template: Record "CDC Template"; var Document: Record "CDC Document"; var DocumentLine: Record "CDC Temp. Document Line" temporary): Boolean
    var
        IsValid: Boolean;
    begin
        IsValid := TRUE;
        /*
        Field.GET(Template."No.", Field.Type::Line, 'NO');
        IF DocumentLine.FINDSET THEN
            REPEAT
                No := SalesDocMgt.GetLineAccountNo(Document, DocumentLine."Line No.");
                Quantity := SalesDocMgt.GetLineQuantity(Document, DocumentLine."Line No.");
                UnitCost := SalesDocMgt.GetLineUnitCost(Document, DocumentLine."Line No.");
                LineAmount := SalesDocMgt.GetLineAmount(Document, DocumentLine."Line No.");

                MatchRequired := (Quantity <> 0) OR (UnitCost <> 0) OR (LineAmount <> 0);

                IF MatchRequired THEN
                    IF NOT SalesDocMgt.GetLineTranslation2(Document, DocumentLine."Line No.",
                      LineTransl)
                    THEN BEGIN
                        DocumentComment.Add(Document, Field, DocumentLine."Line No.", DocumentComment.Area::Validation,
                          DocumentComment."Comment Type"::Error, STRSUBSTNO(Text005, Field."Field Name", No, DocumentLine."Line No."));
                        IsValid := FALSE;
                    END;
            UNTIL DocumentLine.NEXT = 0;
        */
        EXIT(IsValid);
    end;

    internal procedure ValidateAmtAccounts(var Document: Record "CDC Document"; Template: Record "CDC Template"): Boolean
    var
        DataTransl: Record "CDC Data Translation";
        "Field": Record "CDC Template Field";
        TemplField: Record "CDC Template Field";
        DocumentComment: Record "CDC Document Comment";
        Value: Record "CDC Document Value";
        CaptureMgnt: Codeunit "CDC Capture Management";
        Amount: Decimal;
        IsInvalid: Boolean;
        AccountNo: Code[20];
        LinesCaptured: Boolean;
    begin
        Value.SETCURRENTKEY("Document No.", "Is Value", Type, "Line No.");
        Value.SETRANGE("Document No.", Document."No.");
        Value.SETRANGE("Is Value", TRUE);
        Value.SETRANGE(Type, Value.Type::Line);
        LinesCaptured := NOT Value.ISEMPTY;

        Field.SETRANGE("Template No.", Document."Template No.");
        Field.SETRANGE(Type, Field.Type::Header);
        Field.SETRANGE("Data Type", Field."Data Type"::Number);
        IF NOT LinesCaptured THEN
            Field.SETFILTER("Transfer Amount to Document", '<>%1', Field."Transfer Amount to Document"::" ")
        ELSE
            Field.SETRANGE("Transfer Amount to Document", Field."Transfer Amount to Document"::Always);
        Field.SETRANGE("Subtract from Amount Field", '');

        IF NOT Template."Allow Register without Amounts" THEN BEGIN
            IF (NOT Field.FINDSET) AND (NOT LinesCaptured) THEN BEGIN
                DocumentComment.Add(Document, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error, Text009);
                IsInvalid := TRUE;
            END;
        END;

        REPEAT
            Amount := CaptureMgnt.GetDecimal(Document, Field.Type, Field.Code, 0);
            IF Amount <> 0 THEN BEGIN
                AccountNo := '';

                IF Field."G/L Account Field Code" <> '' THEN
                    IF (TemplField.GET(Field."Template No.", Field.Type, Field."G/L Account Field Code")) THEN
                        AccountNo := CaptureMgnt.GetValueAsText(Document."No.", 0, TemplField);

                IF AccountNo = '' THEN
                    IF DataTransl.GET(Document."Template No.", Field.Type, Field.Code) THEN
                        AccountNo := DataTransl."Translate to No.";

                IF (AccountNo = '') AND (NOT Template."Allow Register without Amounts") THEN BEGIN
                    DocumentComment.Add(Document, Field, 0, DocumentComment.Area::Validation, DocumentComment."Comment Type"::Error,
                      STRSUBSTNO(Text010, Field."Field Name"));
                    IsInvalid := TRUE;
                END;
            END;

        UNTIL Field.NEXT = 0;

        EXIT(NOT IsInvalid);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDifferentDateFormatsUsed(Document: Record "CDC Document"; Template: Record "CDC Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateDocument(var Document: Record "CDC Document"; Template: Record "CDC Template"; var IsValid: Boolean)
    begin
    end;
}