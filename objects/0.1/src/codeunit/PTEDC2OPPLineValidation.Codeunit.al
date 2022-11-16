codeunit 61152 "PTE DC2OPP Line Validation"
{
    // C/SIDE
    // revision:23
    // This codeunit validates lines on DC 2 OPP Advices documents

    TableNo = 6085596;

    trigger OnRun()
    var
        Document: Record "CDC Document";
        "Field": Record "CDC Template Field";
        Currency: Record Currency;
        SalesDocMgt: Codeunit "CDC Sales - Management";
        CaptureMgt: Codeunit "CDC Capture Management";
        Quantity: Decimal;
        UnitCost: Decimal;
        LineAmount: Decimal;
        DiscAmount: Decimal;
        DiscPct: Decimal;
        LineAmount2: Decimal;
        AmountRoundingPrecision: Decimal;
        LineDescription: Text[250];
        LineAccountNo: Code[250];
        CurrencyCode: Code[10];
    begin
        IF NOT Document.GET(Rec."Document No.") THEN
            EXIT;
        //TODO: Add line validation here
        /*LineAccountNo := SalesDocMgt.GetLineAccountNo(Document, "Line No.");
        LineDescription := SalesDocMgt.GetLineDescription(Document, "Line No.");
        Quantity := SalesDocMgt.GetLineQuantity(Document, Rec."Line No.");
        UnitCost := SalesDocMgt.GetLineUnitCost(Document, Rec."Line No.");
        DiscPct := SalesDocMgt.GetLineDiscPct(Document, Rec."Line No.");
        DiscAmount := SalesDocMgt.GetLineDiscAmount(Document, Rec."Line No.");
        LineAmount := SalesDocMgt.GetLineAmount(Document, Rec."Line No.");
        CurrencyCode := SalesDocMgt.GetCurrencyCode(Document);

        IF (LineAccountNo = '') AND (Quantity = 0) AND (UnitCost = 0) AND (LineAmount = 0) AND (DiscPct = 0) AND
          (DiscAmount = 0) AND (LineDescription = '')
        THEN BEGIN
            Skip := TRUE;
            EXIT;
        END;
        */
        Field.SETRANGE("Template No.", Rec."Template No.");
        Field.SETRANGE(Type, Field.Type::Line);
        IF Field.FINDSET THEN
            REPEAT
                IF NOT CaptureMgt.IsValidValue(Field, Rec."Document No.", Rec."Line No.") THEN BEGIN
                    Rec.OK := FALSE;
                    EXIT;
                END;
            UNTIL Field.NEXT = 0;

        /*
        IF CurrencyCode = '' THEN BEGIN
            Currency.InitRoundingPrecision;
            AmountRoundingPrecision := Currency."Amount Rounding Precision"
        END ELSE BEGIN
            IF NOT Currency.GET(CurrencyCode) THEN BEGIN
                OK := FALSE;
                EXIT;
            END;

            IF Currency."Amount Rounding Precision" <> 0 THEN
                AmountRoundingPrecision := Currency."Amount Rounding Precision"
            ELSE
                AmountRoundingPrecision := 0.01;
        END;

        LineAmount2 := ROUND(Quantity * UnitCost, AmountRoundingPrecision);

        IF DiscAmount <> 0 THEN
            LineAmount2 := LineAmount2 - ROUND(DiscAmount, AmountRoundingPrecision)
        ELSE
            IF DiscPct <> 0 THEN BEGIN
                DiscAmount := ROUND(LineAmount2 * DiscPct / 100, AmountRoundingPrecision);
                LineAmount2 := LineAmount2 - DiscAmount;
            END;

        OK := LineAmount = LineAmount2;
        */

        Rec.OK := TRUE;

        OnAfterRun(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var TempDocumentLine: Record "CDC Temp. Document Line")
    begin
    end;
}
