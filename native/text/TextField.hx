package native.text;


import native.display.InteractiveObject;
import native.Loader;


class TextField extends InteractiveObject {
	
	
	public var antiAliasType:AntiAliasType;
	public var autoSize (get_autoSize, set_autoSize):TextFieldAutoSize;
	public var background (get_background, set_background):Bool;
	public var backgroundColor (get_backgroundColor, set_backgroundColor):Int;
	public var border (get_border, set_border):Bool;
	public var borderColor (get_borderColor, set_borderColor):Int;
	public var bottomScrollV (get_bottomScrollV, null):Int;
	public var defaultTextFormat (get_defaultTextFormat, set_defaultTextFormat):TextFormat;
	public var displayAsPassword (get_displayAsPassword, set_displayAsPassword):Bool;
	public var embedFonts (get_embedFonts, set_embedFonts):Bool;
	public var htmlText (get_htmlText, set_htmlText):String;
	public var maxChars (get_maxChars, set_maxChars):Int;
	public var maxScrollH (get_maxScrollH, null):Int;
	public var maxScrollV (get_maxScrollV, null):Int;
	public var multiline (get_multiline, set_multiline):Bool;
	public var numLines (get_numLines, null):Int;
	public var scrollH (get_scrollH, set_scrollH):Int;
	public var scrollV (get_scrollV, set_scrollV):Int;
	public var selectable (get_selectable, set_selectable):Bool;
	public var text (get_text, set_text):String;
	public var textColor (get_textColor, set_textColor):Int;
	public var textHeight (get_textHeight, null):Float;
	public var textWidth (get_textWidth, null):Float;
	public var type (get_type, set_type):TextFieldType;
	public var wordWrap (get_wordWrap, set_wordWrap):Bool;
	
	
	public function new () {
		
		var handle = nme_text_field_create ();
		super (handle, "TextField");
		
	}
	
	
	public function appendText (newText:String):Void {
		
		nme_text_field_set_text (nmeHandle, nme_text_field_get_text (nmeHandle) + newText);
		
	}
	
	
	public function getLineOffset (lineIndex:Int):Int {
		
		return nme_text_field_get_line_offset(nmeHandle, lineIndex);
		
	}
	
	
	public function getLineText (lineIndex:Int):String {
		
		return nme_text_field_get_line_text (nmeHandle, lineIndex);
		
	}
	
	
	public function setSelection (beginIndex:Int, endIndex:Int):Void {
		
		// ignored right now
		
	}
	
	
	public function setTextFormat (format:TextFormat, beginIndex:Int = -1, endIndex:Int = -1):Void {
		
		nme_text_field_set_text_format (nmeHandle, format, beginIndex, endIndex);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_autoSize ():TextFieldAutoSize { return Type.createEnumIndex (TextFieldAutoSize, nme_text_field_get_auto_size (nmeHandle)); }
	private function set_autoSize (inVal:TextFieldAutoSize):TextFieldAutoSize { nme_text_field_set_auto_size (nmeHandle, Type.enumIndex (inVal)); return inVal; }
	private function get_background ():Bool { return nme_text_field_get_background (nmeHandle); }
	private function set_background (inVal:Bool):Bool { nme_text_field_set_background (nmeHandle, inVal); return inVal; }
	private function get_backgroundColor ():Int { return nme_text_field_get_background_color (nmeHandle); }
	private function set_backgroundColor (inVal:Int):Int { nme_text_field_set_background_color (nmeHandle, inVal); return inVal; }
	private function get_border ():Bool { return nme_text_field_get_border (nmeHandle); }
	private function set_border (inVal:Bool):Bool { nme_text_field_set_border (nmeHandle, inVal); return inVal; }
	private function get_borderColor ():Int { return nme_text_field_get_border_color (nmeHandle); }
	private function set_borderColor (inVal:Int):Int { nme_text_field_set_border_color (nmeHandle, inVal); return inVal; }
	private function get_bottomScrollV ():Int { return nme_text_field_get_bottom_scroll_v (nmeHandle); }
	private function get_defaultTextFormat ():TextFormat { var result = new TextFormat (); nme_text_field_get_def_text_format (nmeHandle, result); return result; }
	private function set_defaultTextFormat (inFormat:TextFormat):TextFormat { nme_text_field_set_def_text_format (nmeHandle, inFormat); return inFormat; }
	private function get_displayAsPassword ():Bool { return nme_text_field_get_display_as_password (nmeHandle); }
	private function set_displayAsPassword (inVal:Bool):Bool { nme_text_field_set_display_as_password (nmeHandle, inVal); return inVal; }
	private function get_embedFonts ():Bool { return true; }
	private function set_embedFonts (value:Bool):Bool { return true; }
	private function get_htmlText ():String { return StringTools.replace (nme_text_field_get_html_text (nmeHandle), "\n", "<br/>"); }
	private function set_htmlText (inText:String):String	{ nme_text_field_set_html_text (nmeHandle, inText); return inText; }
	private function get_maxChars ():Int { return nme_text_field_get_max_chars (nmeHandle); }
	private function set_maxChars (inVal:Int):Int { nme_text_field_set_max_chars (nmeHandle, inVal); return inVal; }
	private function get_maxScrollH ():Int { return nme_text_field_get_max_scroll_h (nmeHandle); }
	private function get_maxScrollV ():Int { return nme_text_field_get_max_scroll_v (nmeHandle); }
	private function get_multiline ():Bool { return nme_text_field_get_multiline (nmeHandle); }
	private function set_multiline (inVal:Bool):Bool { nme_text_field_set_multiline (nmeHandle, inVal); return inVal; }
	private function get_numLines ():Int { return nme_text_field_get_num_lines (nmeHandle); }
	private function get_scrollH ():Int { return nme_text_field_get_scroll_h(nmeHandle); }
	private function set_scrollH (inVal:Int):Int { nme_text_field_set_scroll_h (nmeHandle, inVal); return inVal; }
	private function get_scrollV ():Int { return nme_text_field_get_scroll_v (nmeHandle); }
	private function set_scrollV (inVal:Int):Int { nme_text_field_set_scroll_v (nmeHandle, inVal); return inVal; }
	private function get_selectable ():Bool { return nme_text_field_get_selectable (nmeHandle); }
	private function set_selectable (inSel:Bool):Bool { nme_text_field_set_selectable (nmeHandle, inSel); return inSel; }
	private function get_text ():String { return nme_text_field_get_text (nmeHandle); }
	private function set_text (inText:String):String { nme_text_field_set_text (nmeHandle, inText); return inText; }
	private function get_textColor ():Int { return nme_text_field_get_text_color (nmeHandle); }
	private function set_textColor (inCol:Int):Int { nme_text_field_set_text_color (nmeHandle, inCol); return inCol; }
	private function get_textWidth ():Float { return nme_text_field_get_text_width (nmeHandle); }
	private function get_textHeight ():Float { return nme_text_field_get_text_height (nmeHandle); }
	private function get_type ():TextFieldType { return nme_text_field_get_type (nmeHandle) ? TextFieldType.INPUT : TextFieldType.DYNAMIC; }
	private function set_type (inType:TextFieldType):TextFieldType { nme_text_field_set_type (nmeHandle, inType == TextFieldType.INPUT); return inType; }
	private function get_wordWrap ():Bool { return nme_text_field_get_word_wrap (nmeHandle); }
	private function set_wordWrap (inVal:Bool):Bool { nme_text_field_set_word_wrap (nmeHandle, inVal); return inVal; }
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_text_field_create = Loader.load ("nme_text_field_create", 0);
	private static var nme_text_field_get_text = Loader.load ("nme_text_field_get_text", 1);
	private static var nme_text_field_set_text = Loader.load ("nme_text_field_set_text", 2);
	private static var nme_text_field_get_html_text = Loader.load ("nme_text_field_get_html_text", 1);
	private static var nme_text_field_set_html_text = Loader.load ("nme_text_field_set_html_text", 2);
	private static var nme_text_field_get_text_color = Loader.load ("nme_text_field_get_text_color", 1);
	private static var nme_text_field_set_text_color = Loader.load ("nme_text_field_set_text_color", 2);
	private static var nme_text_field_get_selectable = Loader.load ("nme_text_field_get_selectable", 1);
	private static var nme_text_field_set_selectable = Loader.load ("nme_text_field_set_selectable", 2);
	private static var nme_text_field_get_display_as_password = Loader.load ("nme_text_field_get_display_as_password", 1);
	private static var nme_text_field_set_display_as_password = Loader.load ("nme_text_field_set_display_as_password", 2);
	private static var nme_text_field_get_def_text_format = Loader.load ("nme_text_field_get_def_text_format", 2);
	private static var nme_text_field_set_def_text_format = Loader.load ("nme_text_field_set_def_text_format", 2);
	private static var nme_text_field_get_auto_size = Loader.load ("nme_text_field_get_auto_size", 1);
	private static var nme_text_field_set_auto_size = Loader.load ("nme_text_field_set_auto_size", 2);
	private static var nme_text_field_get_type = Loader.load ("nme_text_field_get_type", 1);
	private static var nme_text_field_set_type = Loader.load ("nme_text_field_set_type", 2);
	private static var nme_text_field_get_multiline = Loader.load ("nme_text_field_get_multiline", 1);
	private static var nme_text_field_set_multiline = Loader.load ("nme_text_field_set_multiline", 2);
	private static var nme_text_field_get_word_wrap = Loader.load ("nme_text_field_get_word_wrap", 1);
	private static var nme_text_field_set_word_wrap = Loader.load ("nme_text_field_set_word_wrap", 2);
	private static var nme_text_field_get_border = Loader.load ("nme_text_field_get_border", 1);
	private static var nme_text_field_set_border = Loader.load ("nme_text_field_set_border", 2);
	private static var nme_text_field_get_border_color = Loader.load ("nme_text_field_get_border_color", 1);
	private static var nme_text_field_set_border_color = Loader.load ("nme_text_field_set_border_color", 2);
	private static var nme_text_field_get_background = Loader.load ("nme_text_field_get_background", 1);
	private static var nme_text_field_set_background = Loader.load ("nme_text_field_set_background", 2);
	private static var nme_text_field_get_background_color = Loader.load ("nme_text_field_get_background_color", 1);
	private static var nme_text_field_set_background_color = Loader.load ("nme_text_field_set_background_color", 2);
	private static var nme_text_field_get_text_width = Loader.load ("nme_text_field_get_text_width", 1);
	private static var nme_text_field_get_text_height = Loader.load ("nme_text_field_get_text_height", 1);
	private static var nme_text_field_set_text_format = Loader.load ("nme_text_field_set_text_format", 4);
	private static var nme_text_field_get_max_scroll_v = Loader.load ("nme_text_field_get_max_scroll_v", 1);
	private static var nme_text_field_get_max_scroll_h = Loader.load ("nme_text_field_get_max_scroll_h", 1);
	private static var nme_text_field_get_bottom_scroll_v = Loader.load ("nme_text_field_get_bottom_scroll_v", 1);
	private static var nme_text_field_get_scroll_h = Loader.load ("nme_text_field_get_scroll_h", 1);
	private static var nme_text_field_set_scroll_h = Loader.load ("nme_text_field_set_scroll_h", 2);
	private static var nme_text_field_get_scroll_v = Loader.load ("nme_text_field_get_scroll_v", 1);
	private static var nme_text_field_set_scroll_v = Loader.load ("nme_text_field_set_scroll_v", 2);
	private static var nme_text_field_get_num_lines = Loader.load ("nme_text_field_get_num_lines", 1);
	private static var nme_text_field_get_max_chars = Loader.load ("nme_text_field_get_max_chars", 1);
	private static var nme_text_field_set_max_chars = Loader.load ("nme_text_field_set_max_chars", 2);
	private static var nme_text_field_get_line_text = Loader.load ("nme_text_field_get_line_text", 2);
	private static var nme_text_field_get_line_offset = Loader.load ("nme_text_field_get_line_offset", 2);
	
	
}