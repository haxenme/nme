package nme.text;
#if (cpp || neko)


import nme.display.InteractiveObject;
import nme.Loader;


class TextField extends InteractiveObject
{
	
	public var autoSize(nmeGetAutoSize, nmeSetAutoSize):TextFieldAutoSize;
	public var background(nmeGetBackground, nmeSetBackground):Bool;
	public var backgroundColor(nmeGetBackgroundColor, nmeSetBackgroundColor):Int;
	public var border(nmeGetBorder, nmeSetBorder):Bool;
	public var borderColor(nmeGetBorderColor, nmeSetBorderColor):Int;
	public var bottomScrollV(nmeGetBottomScrollV, null):Int;
	public var defaultTextFormat (nmeGetDefaultTextFormat, nmeSetDefaultTextFormat):TextFormat;
	public var displayAsPassword(nmeGetDisplayAsPassword, nmeSetDisplayAsPassword):Bool;
	public var embedFonts(nmeGetEmbedFonts, nmeSetEmbedFonts):Bool;
	public var htmlText(nmeGetHTMLText, nmeSetHTMLText):String;
	public var maxChars(nmeGetMaxChars, nmeSetMaxChars):Int;
	public var maxScrollH(nmeGetMaxScrollH, null):Int;
	public var maxScrollV(nmeGetMaxScrollV, null):Int;
	public var multiline(nmeGetMultiline, nmeSetMultiline):Bool;
	public var numLines(nmeGetNumLines, null):Int;
	public var scrollH(nmeGetScrollH, nmeSetScrollH):Int;
	public var scrollV(nmeGetScrollV, nmeSetScrollV):Int;
	public var selectable(nmeGetSelectable, nmeSetSelectable):Bool;
	public var text(nmeGetText, nmeSetText):String;
	public var textColor(nmeGetTextColor, nmeSetTextColor):Int;
	public var textHeight(nmeGetTextHeight, null):Float;
	public var textWidth(nmeGetTextWidth, null):Float;
	public var type(nmeGetType, nmeSetType):TextFieldType;
	public var wordWrap(nmeGetWordWrap, nmeSetWordWrap):Bool;
	
	
	public function new()
	{
		var handle = nme_text_field_create();
		super(handle, "TextField");
	}
	
	
	public function appendText (newText:String):Void
	{
		nme_text_field_set_text (nmeHandle, nme_text_field_get_text(nmeHandle) + newText);
	}
	
	
	public function setTextFormat(format:TextFormat, beginIndex:Int = -1, endIndex:Int = -1):Void
	{
		nme_text_field_set_text_format(nmeHandle, format, beginIndex, endIndex);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetAutoSize():TextFieldAutoSize { return Type.createEnumIndex(TextFieldAutoSize, nme_text_field_get_auto_size(nmeHandle)); }
	private function nmeSetAutoSize(inVal:TextFieldAutoSize):TextFieldAutoSize { nme_text_field_set_auto_size(nmeHandle, Type.enumIndex(inVal)); return inVal; }
	private function nmeGetBackground():Bool { return nme_text_field_get_background(nmeHandle); }
	private function nmeSetBackground(inVal:Bool):Bool { nme_text_field_set_background(nmeHandle, inVal); return inVal; }
	private function nmeGetBackgroundColor():Int { return nme_text_field_get_background_color(nmeHandle); }
	private function nmeSetBackgroundColor(inVal:Int):Int { nme_text_field_set_background_color(nmeHandle, inVal); return inVal; }
	private function nmeGetBorder():Bool { return nme_text_field_get_border(nmeHandle); }
	private function nmeSetBorder(inVal:Bool):Bool { nme_text_field_set_border(nmeHandle, inVal); return inVal; }
	private function nmeGetBorderColor():Int { return nme_text_field_get_border_color(nmeHandle); }
	private function nmeSetBorderColor(inVal:Int):Int { nme_text_field_set_border_color(nmeHandle, inVal); return inVal; }
	private function nmeGetBottomScrollV():Int { return nme_text_field_get_bottom_scroll_v(nmeHandle); }
	private function nmeGetDefaultTextFormat():TextFormat { var result = new TextFormat(); nme_text_field_get_def_text_format(nmeHandle, result); return result; }
	private function nmeSetDefaultTextFormat(inFormat:TextFormat):TextFormat { nme_text_field_set_def_text_format(nmeHandle, inFormat); return inFormat; }
	private function nmeGetDisplayAsPassword():Bool { return nme_text_field_get_display_as_password(nmeHandle); }
	private function nmeSetDisplayAsPassword(inVal:Bool):Bool { nme_text_field_set_display_as_password(nmeHandle, inVal); return inVal; }
	private function nmeGetEmbedFonts():Bool { return true; }
	private function nmeSetEmbedFonts(value:Bool):Bool { return true; }
	private function nmeGetHTMLText():String { return nme_text_field_get_html_text(nmeHandle); }
	private function nmeSetHTMLText(inText:String):String	{ nme_text_field_set_html_text(nmeHandle, inText); return inText; }
	private function nmeGetMaxChars():Int { return nme_text_field_get_max_chars(nmeHandle); }
	private function nmeSetMaxChars(inVal:Int):Int { nme_text_field_set_max_chars(nmeHandle, inVal); return inVal; }
	private function nmeGetMaxScrollH():Int { return nme_text_field_get_max_scroll_h(nmeHandle); }
	private function nmeGetMaxScrollV():Int { return nme_text_field_get_max_scroll_v(nmeHandle); }
	private function nmeGetMultiline():Bool { return nme_text_field_get_multiline(nmeHandle); }
	private function nmeSetMultiline(inVal:Bool):Bool { nme_text_field_set_multiline(nmeHandle, inVal); return inVal; }
	private function nmeGetNumLines():Int { return nme_text_field_get_num_lines(nmeHandle); }
	private function nmeGetScrollH():Int { return nme_text_field_get_scroll_h(nmeHandle); }
	private function nmeSetScrollH(inVal:Int):Int { nme_text_field_set_scroll_h(nmeHandle, inVal); return inVal; }
	private function nmeGetScrollV():Int { return nme_text_field_get_scroll_v(nmeHandle); }
	private function nmeSetScrollV(inVal:Int):Int { nme_text_field_set_scroll_v(nmeHandle, inVal); return inVal; }
	private function nmeGetSelectable():Bool { return nme_text_field_get_selectable(nmeHandle); }
	private function nmeSetSelectable(inSel:Bool):Bool { nme_text_field_set_selectable(nmeHandle, inSel); return inSel; }
	private function nmeGetText():String { return nme_text_field_get_text(nmeHandle); }
	private function nmeSetText(inText:String):String { nme_text_field_set_text(nmeHandle, inText);	return inText; }
	private function nmeGetTextColor():Int { return nme_text_field_get_text_color(nmeHandle); }
	private function nmeSetTextColor(inCol:Int):Int { nme_text_field_set_text_color(nmeHandle, inCol); return inCol; }
	private function nmeGetTextWidth():Float { return nme_text_field_get_text_width(nmeHandle); }
	private function nmeGetTextHeight():Float { return nme_text_field_get_text_height(nmeHandle); }
	private function nmeGetType():TextFieldType { return nme_text_field_get_type(nmeHandle) ? TextFieldType.INPUT : TextFieldType.DYNAMIC; }
	private function nmeSetType(inType:TextFieldType):TextFieldType { nme_text_field_set_type(nmeHandle, inType == TextFieldType.INPUT);	return inType; }
	private function nmeGetWordWrap():Bool { return nme_text_field_get_word_wrap(nmeHandle); }
	private function nmeSetWordWrap(inVal:Bool):Bool { nme_text_field_set_word_wrap(nmeHandle, inVal); return inVal; }
	
	
	
	// Native Methods
	
	
	
	private static var nme_text_field_create = Loader.load("nme_text_field_create", 0);
	private static var nme_text_field_get_text = Loader.load("nme_text_field_get_text", 1);
	private static var nme_text_field_set_text = Loader.load("nme_text_field_set_text", 2);
	private static var nme_text_field_get_html_text = Loader.load("nme_text_field_get_html_text", 1);
	private static var nme_text_field_set_html_text = Loader.load("nme_text_field_set_html_text", 2);
	private static var nme_text_field_get_text_color = Loader.load("nme_text_field_get_text_color", 1);
	private static var nme_text_field_set_text_color = Loader.load("nme_text_field_set_text_color", 2);
	private static var nme_text_field_get_selectable = Loader.load("nme_text_field_get_selectable", 1);
	private static var nme_text_field_set_selectable = Loader.load("nme_text_field_set_selectable", 2);
	private static var nme_text_field_get_display_as_password = Loader.load("nme_text_field_get_display_as_password", 1);
	private static var nme_text_field_set_display_as_password = Loader.load("nme_text_field_set_display_as_password", 2);
	private static var nme_text_field_get_def_text_format = Loader.load("nme_text_field_get_def_text_format", 2);
	private static var nme_text_field_set_def_text_format = Loader.load("nme_text_field_set_def_text_format", 2);
	private static var nme_text_field_get_auto_size = Loader.load("nme_text_field_get_auto_size", 1);
	private static var nme_text_field_set_auto_size = Loader.load("nme_text_field_set_auto_size", 2);
	private static var nme_text_field_get_type = Loader.load("nme_text_field_get_type", 1);
	private static var nme_text_field_set_type = Loader.load("nme_text_field_set_type", 2);
	private static var nme_text_field_get_multiline = Loader.load("nme_text_field_get_multiline", 1);
	private static var nme_text_field_set_multiline = Loader.load("nme_text_field_set_multiline", 2);
	private static var nme_text_field_get_word_wrap = Loader.load("nme_text_field_get_word_wrap", 1);
	private static var nme_text_field_set_word_wrap = Loader.load("nme_text_field_set_word_wrap", 2);
	private static var nme_text_field_get_border = Loader.load("nme_text_field_get_border", 1);
	private static var nme_text_field_set_border = Loader.load("nme_text_field_set_border", 2);
	private static var nme_text_field_get_border_color = Loader.load("nme_text_field_get_border_color", 1);
	private static var nme_text_field_set_border_color = Loader.load("nme_text_field_set_border_color", 2);
	private static var nme_text_field_get_background = Loader.load("nme_text_field_get_background", 1);
	private static var nme_text_field_set_background = Loader.load("nme_text_field_set_background", 2);
	private static var nme_text_field_get_background_color = Loader.load("nme_text_field_get_background_color", 1);
	private static var nme_text_field_set_background_color = Loader.load("nme_text_field_set_background_color", 2);
	private static var nme_text_field_get_text_width = Loader.load("nme_text_field_get_text_width", 1);
	private static var nme_text_field_get_text_height = Loader.load("nme_text_field_get_text_height", 1);
	private static var nme_text_field_set_text_format = Loader.load("nme_text_field_set_text_format", 4);
	private static var nme_text_field_get_max_scroll_v = Loader.load("nme_text_field_get_max_scroll_v", 1);
	private static var nme_text_field_get_max_scroll_h = Loader.load("nme_text_field_get_max_scroll_h", 1);
	private static var nme_text_field_get_bottom_scroll_v = Loader.load("nme_text_field_get_bottom_scroll_v", 1);
	private static var nme_text_field_get_scroll_h = Loader.load("nme_text_field_get_scroll_h", 1);
	private static var nme_text_field_set_scroll_h = Loader.load("nme_text_field_set_scroll_h", 2);
	private static var nme_text_field_get_scroll_v = Loader.load("nme_text_field_get_scroll_v", 1);
	private static var nme_text_field_set_scroll_v = Loader.load("nme_text_field_set_scroll_v", 2);
	private static var nme_text_field_get_num_lines = Loader.load("nme_text_field_get_num_lines", 1);
	private static var nme_text_field_get_max_chars = Loader.load("nme_text_field_get_max_chars", 1);
	private static var nme_text_field_set_max_chars = Loader.load("nme_text_field_set_max_chars", 2);
	
}


#else
typedef TextField = flash.text.TextField;
#end