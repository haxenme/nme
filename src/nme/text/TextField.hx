package nme.text;
#if (!flash)

import nme.display.InteractiveObject;
import nme.PrimeLoader;
import nme.geom.Rectangle;

@:nativeProperty
class TextField extends InteractiveObject 
{
   public var antiAliasType:AntiAliasType;
   public var autoSize(get, set):TextFieldAutoSize;
   public var background(get, set):Bool;
   public var backgroundColor(get, set):Int;
   public var border(get, set):Bool;
   public var borderColor(get, set):Int;
   public var bottomScrollV(get, null):Int;
   public var defaultTextFormat(get, set):TextFormat;
   public var displayAsPassword(get, set):Bool;
   public var embedFonts(get, set):Bool;
   public var forceFreeType(get, set):Bool;
   public var gridFitType:GridFitType;
   public var htmlText(get, set):String;
   public var maxChars(get, set):Int;
   public var maxScrollH(get, null):Int;
   public var maxScrollV(get, null):Int;
   public var selectionBeginIndex(get, null):Int;
   public var selectionEndIndex(get, null):Int;
   public var multiline(get, set):Bool;
   public var numLines(get, null):Int;
   public var scrollH(get, set):Int;
   public var scrollV(get, set):Int;
   public var selectable(get, set):Bool;
   public var sharpness:Float;
   public var text(get, set):String;
   public var textColor(get, set):Int;
   public var textHeight(get, null):Float;
   public var textWidth(get, null):Float;
   public var type(get, set):TextFieldType;
   public var wordWrap(get, set):Bool;

   public function new() 
   {
      var handle = nme_text_field_create();
      super(handle, "TextField");
     gridFitType = GridFitType.PIXEL;
     sharpness = 0;
   }

   public function appendText(newText:String):Void 
   {
      nme_text_field_set_text(nmeHandle, nme_text_field_get_text(nmeHandle) + newText);
   }

   public function getLineOffset(lineIndex:Int):Int 
   {
      return nme_text_field_get_line_offset(nmeHandle, lineIndex);
   }

   public function getLineIndexOfChar(charIndex:Int):Int 
   {
      return nme_text_field_get_line_for_char(nmeHandle, charIndex);
   }


   public function getLinePositions(startLine:Int, endLine:Int):Array<Float>
   {
      var count = endLine-startLine;
      var buffer = new Array<Float>();
      if (count>0)
      {
         buffer[count-1] = 0.0;
         nme_text_field_get_line_positions(nmeHandle, startLine, buffer);
      }
      return buffer;
   }

   public function getLineText(lineIndex:Int):String 
   {
      return nme_text_field_get_line_text(nmeHandle, lineIndex);
   }

   public function getLineMetrics(lineIndex:Int):TextLineMetrics 
   {
      var result: TextLineMetrics = new TextLineMetrics();
      nme_text_field_get_line_metrics(nmeHandle, lineIndex, result);
      return result;
   }
   
   public function getTextFormat(beginIndex:Int = -1, endIndex:Int = -1):TextFormat 
   {
      var result = new TextFormat();
      nme_text_field_get_text_format(nmeHandle, result, beginIndex, endIndex);
      return result;
   } 

   public function getCharBoundaries(charIndex:Int):Rectangle
   {
      var result = new Rectangle();
      nme_text_field_get_char_boundaries(nmeHandle, charIndex, result);
      return result;
   }

   public function setSelection(beginIndex:Int, endIndex:Int):Void 
   {
      nme_text_field_set_selection(nmeHandle, beginIndex, endIndex);
   }

   public function setTextFormat(format:TextFormat, beginIndex:Int = -1, endIndex:Int = -1):Void 
   {
      nme_text_field_set_text_format(nmeHandle, format, beginIndex, endIndex);
   }

   public function replaceSelectedText(inNewText:String) : Void
   {
      nme_text_field_replace_selected_text(nmeHandle, inNewText);
   }

   public function replaceText(c0:Int, c1:Int,inNewText:String) : Void
   {
      nme_text_field_replace_text(nmeHandle, c0, c1, inNewText);
   }

   public function sendKey(charCode:Int, keyId:Int, shift:Bool, ctrl:Bool, alt:Bool) : Void
   {
      var flags = 0;
      if (shift) flags |= 0x02;
      if (ctrl) flags |= 0x14;
      if (alt) flags |= 0x08;
      nme_text_field_send_key(nmeHandle, charCode, keyId, flags);
   }

   public function sendCopy() { sendKey(0, nme.ui.Keyboard.C, false, true, false ); }
   public function sendPaste() { sendKey(0, nme.ui.Keyboard.V, false, true, false ); }



   // Getters & Setters
   private function get_autoSize():TextFieldAutoSize { return Type.createEnumIndex(TextFieldAutoSize, nme_text_field_get_auto_size(nmeHandle)); }
   private function set_autoSize(inVal:TextFieldAutoSize):TextFieldAutoSize { nme_text_field_set_auto_size(nmeHandle, Type.enumIndex(inVal)); return inVal; }
   private function get_background():Bool { return nme_text_field_get_background(nmeHandle); }
   private function set_background(inVal:Bool):Bool { nme_text_field_set_background(nmeHandle, inVal); return inVal; }
   private function get_backgroundColor():Int { return nme_text_field_get_background_color(nmeHandle); }
   private function set_backgroundColor(inVal:Int):Int { nme_text_field_set_background_color(nmeHandle, inVal); return inVal; }
   private function get_border():Bool { return nme_text_field_get_border(nmeHandle); }
   private function set_border(inVal:Bool):Bool { nme_text_field_set_border(nmeHandle, inVal); return inVal; }
   private function get_borderColor():Int { return nme_text_field_get_border_color(nmeHandle); }
   private function set_borderColor(inVal:Int):Int { nme_text_field_set_border_color(nmeHandle, inVal); return inVal; }
   private function get_bottomScrollV():Int { return nme_text_field_get_bottom_scroll_v(nmeHandle); }
   private function get_defaultTextFormat():TextFormat { var result = new TextFormat(); nme_text_field_get_def_text_format(nmeHandle, result); return result; }
   private function set_defaultTextFormat(inFormat:TextFormat):TextFormat { nme_text_field_set_def_text_format(nmeHandle, inFormat); return inFormat; }
   private function get_displayAsPassword():Bool { return nme_text_field_get_display_as_password(nmeHandle); }
   private function set_displayAsPassword(inVal:Bool):Bool { nme_text_field_set_display_as_password(nmeHandle, inVal); return inVal; }
   private function get_embedFonts():Bool { return nme_text_field_get_embed_fonts(nmeHandle); }
   private function set_embedFonts(inVal:Bool):Bool { nme_text_field_set_embed_fonts(nmeHandle,inVal); return inVal; }
   private function get_forceFreeType():Bool { return nme_text_field_get_embed_fonts(nmeHandle); }
   private function set_forceFreeType(inVal:Bool):Bool { nme_text_field_set_embed_fonts(nmeHandle,inVal); return inVal; }

   private function get_htmlText():String { return StringTools.replace(nme_text_field_get_html_text(nmeHandle), "\n", "<br/>"); }
   private function set_htmlText(inText:String):String   { nme_text_field_set_html_text(nmeHandle, inText); return inText; }
   private function get_maxChars():Int { return nme_text_field_get_max_chars(nmeHandle); }
   private function set_maxChars(inVal:Int):Int { nme_text_field_set_max_chars(nmeHandle, inVal); return inVal; }
   private function get_maxScrollH():Int { return nme_text_field_get_max_scroll_h(nmeHandle); }
   private function get_maxScrollV():Int { return nme_text_field_get_max_scroll_v(nmeHandle); }
   private function get_multiline():Bool { return nme_text_field_get_multiline(nmeHandle); }
   private function set_multiline(inVal:Bool):Bool { nme_text_field_set_multiline(nmeHandle, inVal); return inVal; }
   private function get_numLines():Int { return nme_text_field_get_num_lines(nmeHandle); }
   private function get_scrollH():Int { return nme_text_field_get_scroll_h(nmeHandle); }
   private function set_scrollH(inVal:Int):Int { nme_text_field_set_scroll_h(nmeHandle, inVal); return inVal; }
   private function get_scrollV():Int { return nme_text_field_get_scroll_v(nmeHandle); }
   private function set_scrollV(inVal:Int):Int { nme_text_field_set_scroll_v(nmeHandle, inVal); return inVal; }
   private function get_selectable():Bool { return nme_text_field_get_selectable(nmeHandle); }
   private function set_selectable(inSel:Bool):Bool { nme_text_field_set_selectable(nmeHandle, inSel); return inSel; }
   private function get_selectionBeginIndex():Int { return nme_text_field_get_selection_begin_index(nmeHandle); }
   private function get_selectionEndIndex():Int { return nme_text_field_get_selection_end_index(nmeHandle); }
   private function get_text():String { return nme_text_field_get_text(nmeHandle); }
   private function set_text(inText:String):String { nme_text_field_set_text(nmeHandle, inText); return inText; }
   private function get_textColor():Int { return nme_text_field_get_text_color(nmeHandle); }
   private function set_textColor(inCol:Int):Int { nme_text_field_set_text_color(nmeHandle, inCol); return inCol; }
   private function get_textWidth():Float { return nme_text_field_get_text_width(nmeHandle); }
   private function get_textHeight():Float { return nme_text_field_get_text_height(nmeHandle); }
   private function get_type():TextFieldType { return nme_text_field_get_type(nmeHandle) ? TextFieldType.INPUT : TextFieldType.DYNAMIC; }
   private function set_type(inType:TextFieldType):TextFieldType { nme_text_field_set_type(nmeHandle, inType == TextFieldType.INPUT); return inType; }
   private function get_wordWrap():Bool { return nme_text_field_get_word_wrap(nmeHandle); }
   private function set_wordWrap(inVal:Bool):Bool { nme_text_field_set_word_wrap(nmeHandle, inVal); return inVal; }

   // Native Methods
   private static var nme_text_field_create = PrimeLoader.load("nme_text_field_create", "o");
   private static var nme_text_field_get_text = nme.Loader.load("nme_text_field_get_text", 1);
   private static var nme_text_field_set_text = nme.Loader.load("nme_text_field_set_text", 2);
   private static var nme_text_field_get_html_text = nme.Loader.load("nme_text_field_get_html_text", 1);
   private static var nme_text_field_set_html_text = nme.Loader.load("nme_text_field_set_html_text", 2);
   private static var nme_text_field_get_text_color = PrimeLoader.load("nme_text_field_get_text_color", "oi");
   private static var nme_text_field_set_text_color = PrimeLoader.load("nme_text_field_set_text_color", "oiv");
   private static var nme_text_field_get_selectable = PrimeLoader.load("nme_text_field_get_selectable", "ob");
   private static var nme_text_field_set_selectable = PrimeLoader.load("nme_text_field_set_selectable", "obv");
   private static var nme_text_field_get_display_as_password = PrimeLoader.load("nme_text_field_get_display_as_password", "ob");
   private static var nme_text_field_set_display_as_password = PrimeLoader.load("nme_text_field_set_display_as_password", "obv");
   private static var nme_text_field_get_def_text_format = PrimeLoader.load("nme_text_field_get_def_text_format", "oov");
   private static var nme_text_field_set_def_text_format = PrimeLoader.load("nme_text_field_set_def_text_format", "oov");
   private static var nme_text_field_get_auto_size = PrimeLoader.load("nme_text_field_get_auto_size", "oi");
   private static var nme_text_field_set_auto_size = PrimeLoader.load("nme_text_field_set_auto_size", "oiv");
   private static var nme_text_field_get_type = PrimeLoader.load("nme_text_field_get_type", "ob");
   private static var nme_text_field_set_type = PrimeLoader.load("nme_text_field_set_type", "obv");
   private static var nme_text_field_get_multiline = PrimeLoader.load("nme_text_field_get_multiline", "ob");
   private static var nme_text_field_set_multiline = PrimeLoader.load("nme_text_field_set_multiline", "obv");
   private static var nme_text_field_get_word_wrap = PrimeLoader.load("nme_text_field_get_word_wrap", "ob");
   private static var nme_text_field_set_word_wrap = PrimeLoader.load("nme_text_field_set_word_wrap", "obv");
   private static var nme_text_field_get_border = PrimeLoader.load("nme_text_field_get_border", "ob");
   private static var nme_text_field_set_border = PrimeLoader.load("nme_text_field_set_border", "obv");
   private static var nme_text_field_get_border_color = PrimeLoader.load("nme_text_field_get_border_color", "oi");
   private static var nme_text_field_set_border_color = PrimeLoader.load("nme_text_field_set_border_color", "oiv");
   private static var nme_text_field_get_background = PrimeLoader.load("nme_text_field_get_background", "ob");
   private static var nme_text_field_set_background = PrimeLoader.load("nme_text_field_set_background", "obv");
   private static var nme_text_field_get_background_color = PrimeLoader.load("nme_text_field_get_background_color", "oi");
   private static var nme_text_field_set_background_color = PrimeLoader.load("nme_text_field_set_background_color", "oiv");
   private static var nme_text_field_get_text_width = PrimeLoader.load("nme_text_field_get_text_width", "od");
   private static var nme_text_field_get_text_height = PrimeLoader.load("nme_text_field_get_text_height", "od");
   private static var nme_text_field_get_text_format = PrimeLoader.load("nme_text_field_get_text_format", "ooiiv");
   private static var nme_text_field_set_text_format = PrimeLoader.load("nme_text_field_set_text_format", "ooiiv");
   private static var nme_text_field_get_max_scroll_v = PrimeLoader.load("nme_text_field_get_max_scroll_v", "oi");
   private static var nme_text_field_get_max_scroll_h = PrimeLoader.load("nme_text_field_get_max_scroll_h", "oi");
   private static var nme_text_field_get_bottom_scroll_v = PrimeLoader.load("nme_text_field_get_bottom_scroll_v", "oi");
   private static var nme_text_field_get_scroll_h = PrimeLoader.load("nme_text_field_get_scroll_h", "oi");
   private static var nme_text_field_set_scroll_h = PrimeLoader.load("nme_text_field_set_scroll_h", "oiv");
   private static var nme_text_field_get_scroll_v = PrimeLoader.load("nme_text_field_get_scroll_v", "oi");
   private static var nme_text_field_set_scroll_v = PrimeLoader.load("nme_text_field_set_scroll_v", "oiv");
   private static var nme_text_field_get_num_lines = PrimeLoader.load("nme_text_field_get_num_lines", "oi");
   private static var nme_text_field_get_max_chars = PrimeLoader.load("nme_text_field_get_max_chars", "oi");
   private static var nme_text_field_set_max_chars = PrimeLoader.load("nme_text_field_set_max_chars", "oiv");
   private static var nme_text_field_get_line_text = nme.Loader.load("nme_text_field_get_line_text", 2);
   private static var nme_text_field_get_line_metrics = PrimeLoader.load("nme_text_field_get_line_metrics", "oiov");
   private static var nme_text_field_get_line_offset = PrimeLoader.load("nme_text_field_get_line_offset", "oii");
   private static var nme_text_field_get_embed_fonts = PrimeLoader.load("nme_text_field_get_embed_fonts", "ob");
   private static var nme_text_field_set_embed_fonts = PrimeLoader.load("nme_text_field_set_embed_fonts", "obv");
   private static var nme_text_field_get_char_boundaries = PrimeLoader.load("nme_text_field_get_char_boundaries", "oiov");
   private static var nme_text_field_get_selection_begin_index = PrimeLoader.load("nme_text_field_get_selection_begin_index", "oi");
   private static var nme_text_field_get_selection_end_index = PrimeLoader.load("nme_text_field_get_selection_end_index", "oi");
   private static var nme_text_field_set_selection = PrimeLoader.load("nme_text_field_set_selection", "oiiv");

   private static var nme_text_field_get_line_positions = PrimeLoader.load("nme_text_field_get_line_positions", "oiov");
   private static var nme_text_field_get_line_for_char = PrimeLoader.load("nme_text_field_get_line_for_char", "oii");
   private static var nme_text_field_replace_selected_text = PrimeLoader.load("nme_text_field_replace_selected_text", "oov");
   private static var nme_text_field_replace_text = PrimeLoader.load("nme_text_field_replace_text", "oiiov");
   private static var nme_text_field_send_key = PrimeLoader.load("nme_text_field_send_key", "oiiiv");
}

#else
typedef TextField = flash.text.TextField;
#end
