uses
  StrUtils, Dialogs, SchLib, Sch;

procedure ListComponentValues;

const
  cFontName = 'GOST type B';
  cFontSize = 24;
  cFontBold = False;
  cFontUnderline = False;
  cFontItalic = True;
  cFontColor = $0000FF; // Синій колір
  cOffset = 1000000; // Зміщення для тексту

var
  Document: ISch_Document;
  Iterator: ISch_Iterator;
  Component: ISch_Component;
  ParamIterator: ISch_Iterator;
  Parameter: ISch_Parameter;
  LabelObject: ISch_Label;
  ComponentValues: string;
  X, Y: Double;
  FontManager: ISch_FontManager;
  FontID: TFont;
  OriginalValue: string;
  FixedValue: string;
begin
  Document := SchServer.GetCurrentSchDocument;
  if Document = nil then
  begin
    ShowMessage('No schematic document is currently open.');
    Exit;
  end;

  FontManager := SchServer.FontManager;
  if FontManager = nil then
  begin
    ShowMessage('FontManager is not available.');
    Exit;
  end;

  ComponentValues := 'Components with specific parameters:' + #13#10;
  Iterator := Document.SchIterator_Create;
  try
    Iterator.AddFilter_ObjectSet(MkSet(eSchComponent));
    Component := Iterator.FirstSchObject;
    while Component <> nil do
    begin
      X := Component.Location.X;
      Y := Component.Location.Y;

      ParamIterator := Component.SchIterator_Create;
      try
        ParamIterator.AddFilter_ObjectSet(MkSet(eParameter));
        Parameter := ParamIterator.FirstSchObject;
        while Parameter <> nil do
        begin
          // Перевірка наявності параметра та його типу
          if Assigned(Parameter) and (VarType(Parameter.Text) = varOleStr) then
          begin
            // Перевірка для параметрів "VALUE" або "PART NUMBER" зі значенням "NC"
            if ((UpperCase(Parameter.Name) = 'VALUE') or (UpperCase(Parameter.Name) = 'PART NUMBER')) and (UpperCase(Parameter.Text) = 'NC') then
            begin
              ComponentValues := ComponentValues + Component.Designator.Text + ': ' + Component.Comment.Text + ' (Type: ' + Parameter.Text + ')' + #13#10;

              // Додавання мітки "NP" для компонентів зі значенням "NC"
              LabelObject := SchServer.SchObjectFactory(eLabel, eCreate_Default);
              if LabelObject <> nil then
              begin
                FontID := FontManager.GetFontID(cFontSize, 0, cFontUnderline, cFontItalic, cFontBold, False, cFontName);
                LabelObject.Location := Point(X + (Component.BoundingRectangle.Right - Component.BoundingRectangle.Left) div 2, Y + (Component.BoundingRectangle.Top - Component.BoundingRectangle.Bottom) div 2 - 900000);
                LabelObject.Text := 'NP';
                LabelObject.Color := cFontColor;
                LabelObject.FontId := FontID;
                Document.AddSchObject(LabelObject);
                Document.GraphicallyInvalidate;
              end;
            end;

            // Перевірка на наявність десяткової крапки в полі "Value"
            if (UpperCase(Parameter.Name) = 'VALUE') then
            begin
             OriginalValue := Parameter.Text;
              if Pos('K', OriginalValue) > 0 then
              begin
                // Заміна крапки на кому
                OriginalValue := Parameter.Text;
                Parameter.Text := ReplaceStr(OriginalValue, 'K', 'k');
              end;
              OriginalValue := Parameter.Text;
              if Pos('.', OriginalValue) > 0 then
              begin
                // Заміна крапки на кому
                OriginalValue := Parameter.Text;
                Parameter.Text := ReplaceStr(OriginalValue, '.', ',');
                ComponentValues := ComponentValues + Component.Designator.Text + ': ' + Parameter.Text + ' -> ' + Parameter.Text + ' (Decimal point replaced)' + #13#10;
              end;
            end;
          end;

          Parameter := ParamIterator.NextSchObject;
        end;
      finally
        Component.SchIterator_Destroy(ParamIterator);
      end;
      Component := Iterator.NextSchObject;
    end;
  finally
    Document.SchIterator_Destroy(Iterator);
  end;

  ShowMessage(ComponentValues);
end;

begin
  ListComponentValues;
end.

