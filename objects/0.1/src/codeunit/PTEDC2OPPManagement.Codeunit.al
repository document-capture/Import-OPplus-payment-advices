codeunit 61153 "PTE DC2OPP Management"
{
    // SRA: We need this code at them moment if we do not want to create a DOCTYPE header field which is queried by DC code
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDC Purch. Doc. - Management", 'OnBeforeIsDocMatched', '', true, true)]
    local procedure DC_OnBeforeIsDocMatched(Document: Record "CDC Document"; var IsDocMatched: Boolean; var Handled: Boolean)
    var
        DocumentCategory: Record "CDC Document Category";
    begin
        if not DocumentCategory.Get(Document."Document Category Code") then
            exit;

        if (DocumentCategory."Source Table No." = 18) and
           (DocumentCategory."Destination Header Table No." = 5157808) and
           (DocumentCategory."Destination Line Table No." = 5157809) then begin
            IsDocMatched := true;
            Handled := true;
            exit;
        end;
    end;

}
