package nme.text;
#if (cpp || neko)


class TextField extends nme.display.InteractiveObject
{
   public var text(nmeGetText,nmeSetText):String;
   public var htmlText(nmeGetHTMLText,nmeSetHTMLText):String;
   public var textColor(nmeGetTextColor,nmeSetTextColor):Int;
   public var selectable(nmeGetSelectable,nmeSetSelectable):Bool;
   public var displayAsPassword(nmeGetDisplayAsPassword,nmeSetDisplayAsPassword):Bool;
   public var defaultTextFormat (nmeGetDefTextFormat, nmeSetDefTextFormat):TextFormat;
   public var type(nmeGetType,nmeSetType):TextFieldType;
   public var multiline(nmeGetMultiline,nmeSetMultiline):Bool;
   public var wordWrap(nmeGetWordWrap,nmeSetWordWrap):Bool;
   public var border(nmeGetBorder,nmeSetBorder):Bool;
   public var borderColor(nmeGetBorderColor,nmeSetBorderColor):Int;
   public var background(nmeGetBackground,nmeSetBackground):Bool;
   public var backgroundColor(nmeGetBackgroundColor,nmeSetBackgroundColor):Int;
   public var autoSize(nmeGetAutoSize,nmeSetAutoSize):TextFieldAutoSize;
   public var textWidth(nmeGetTextWidth,null):Float;
   public var textHeight(nmeGetTextHeight,null):Float;
   public var maxScrollV(nmeGetMaxScrollV,null):Int;
   public var maxScrollH(nmeGetMaxScrollH,null):Int;
   public var bottomScrollV(nmeGetBottomScrollV,null):Int;
   public var scrollH(nmeGetScrollH,nmeSetScrollH):Int;
   public var scrollV(nmeGetScrollV,nmeSetScrollV):Int;
   public var numLines(nmeGetNumLines,null):Int;
   public var maxChars(nmeGetMaxChars, nmeSetMaxChars):Int;
   public var embedFonts(nmeGetEmbedFonts, nmeSetEmbedFonts):Bool;

   public function new( )
   {
      var handle = nme_text_field_create( );
      super(handle,"TextField");
   }

	public function setTextFormat(format:TextFormat, beginIndex:Int = -1, endIndex:Int = -1):Void
	{
		nme_text_field_set_text_format(nmeHandle,format,beginIndex,endIndex);
	}
   
	function nmeGetEmbedFonts ():Bool { return true; }
	function nmeSetEmbedFonts (value:Bool):Bool { return true; }
	
   function nmeGetText() : String { return nme_text_field_get_text(nmeHandle); }
   function nmeSetText(inText:String ) : String
   {
      nme_text_field_set_text(nmeHandle,inText);
      return inText;
   }

	function nmeGetHTMLText() : String { return nme_text_field_get_html_text(nmeHandle); }
   function nmeSetHTMLText(inText:String ) : String
   {
      nme_text_field_set_html_text(nmeHandle,inText);
      return inText;
   }


   function nmeGetTextColor() : Int { return nme_text_field_get_text_color(nmeHandle); }
   function nmeSetTextColor(inCol:Int ) : Int
   {
      nme_text_field_set_text_color(nmeHandle,inCol);
      return inCol;
   }

   function nmeGetSelectable() : Bool { return nme_text_field_get_selectable(nmeHandle); }
   function nmeSetSelectable(inSel:Bool ) : Bool
   {
      nme_text_field_set_selectable(nmeHandle,inSel);
      return inSel;
   }

   function nmeGetDisplayAsPassword() : Bool { return nme_text_field_get_display_as_password(nmeHandle); }
   function nmeSetDisplayAsPassword(inVal:Bool ) : Bool
   {
      nme_text_field_set_display_as_password(nmeHandle,inVal);
      return inVal;
   }



   function nmeGetType() : TextFieldType
   {
      return nme_text_field_get_type(nmeHandle) ? TextFieldType.INPUT : TextFieldType.DYNAMIC;
   }
   function nmeSetType(inType:TextFieldType ) : TextFieldType
   {
      nme_text_field_set_type(nmeHandle,inType==TextFieldType.INPUT);
      return inType;
   }

   function nmeGetMultiline() : Bool { return nme_text_field_get_multiline(nmeHandle); }
   function nmeSetMultiline(inVal:Bool ) : Bool
   {
      nme_text_field_set_multiline(nmeHandle,inVal);
      return inVal;
   }

	function nmeGetWordWrap() : Bool { return nme_text_field_get_word_wrap(nmeHandle); }
   function nmeSetWordWrap(inVal:Bool ) : Bool
   {
      nme_text_field_set_word_wrap(nmeHandle,inVal);
      return inVal;
   }

	function nmeGetAutoSize() : TextFieldAutoSize
	{
		return Type.createEnumIndex(TextFieldAutoSize,nme_text_field_get_auto_size(nmeHandle));
	}
   function nmeSetAutoSize(inVal:TextFieldAutoSize ) : TextFieldAutoSize
   {
      nme_text_field_set_auto_size(nmeHandle,Type.enumIndex(inVal));
      return inVal;
   }

 
   function nmeGetBorder() : Bool { return nme_text_field_get_border(nmeHandle); }
   function nmeSetBorder(inVal:Bool ) : Bool
   {
      nme_text_field_set_border(nmeHandle,inVal);
      return inVal;
   }

	function nmeGetBorderColor() : Int { return nme_text_field_get_border_color(nmeHandle); }
   function nmeSetBorderColor(inVal:Int ) : Int
   {
      nme_text_field_set_border_color(nmeHandle,inVal);
      return inVal;
   }

   function nmeGetBackground() : Bool { return nme_text_field_get_background(nmeHandle); }
   function nmeSetBackground(inVal:Bool ) : Bool
   {
      nme_text_field_set_background(nmeHandle,inVal);
      return inVal;
   }

	function nmeGetBackgroundColor() : Int { return nme_text_field_get_background_color(nmeHandle); }
   function nmeSetBackgroundColor(inVal:Int ) : Int
   {
      nme_text_field_set_background_color(nmeHandle,inVal);
      return inVal;
   }

	function nmeGetTextWidth() : Float { return nme_text_field_get_text_width(nmeHandle); }
	function nmeGetTextHeight() : Float { return nme_text_field_get_text_height(nmeHandle); }

   
   function nmeGetDefTextFormat() : TextFormat
   {
      var result = new TextFormat();
      nme_text_field_get_def_text_format(nmeHandle,result);
      return result;
   }
   function nmeSetDefTextFormat(inFormat:TextFormat) : TextFormat
   {
      nme_text_field_set_def_text_format(nmeHandle,inFormat);
      return inFormat;
   }

   function nmeGetMaxScrollV() : Int { return nme_text_field_get_max_scroll_v(nmeHandle); }
   function nmeGetMaxScrollH() : Int { return nme_text_field_get_max_scroll_h(nmeHandle); }
   function nmeGetBottomScrollV() : Int { return nme_text_field_get_bottom_scroll_v(nmeHandle); }
   function nmeGetScrollH() : Int { return nme_text_field_get_scroll_h(nmeHandle); }
	function nmeSetScrollH(inVal:Int) : Int
	{
	   nme_text_field_set_scroll_h(nmeHandle,inVal);
		return inVal;
	}
   function nmeGetScrollV() : Int { return nme_text_field_get_scroll_v(nmeHandle); }
	function nmeSetScrollV(inVal:Int) : Int
	{
	   nme_text_field_set_scroll_v(nmeHandle,inVal);
		return inVal;
   }

   function nmeGetNumLines() : Int { return nme_text_field_get_num_lines(nmeHandle); }

   function nmeGetMaxChars() : Int { return nme_text_field_get_max_chars(nmeHandle); }
	function nmeSetMaxChars(inVal:Int) : Int
	{
	   nme_text_field_set_max_chars(nmeHandle,inVal);
		return inVal;
   }


   static var nme_text_field_create = nme.Loader.load("nme_text_field_create",0);
   static var nme_text_field_get_text = nme.Loader.load("nme_text_field_get_text",1);
   static var nme_text_field_set_text = nme.Loader.load("nme_text_field_set_text",2);
   static var nme_text_field_get_html_text = nme.Loader.load("nme_text_field_get_html_text",1);
   static var nme_text_field_set_html_text = nme.Loader.load("nme_text_field_set_html_text",2);
   static var nme_text_field_get_text_color = nme.Loader.load("nme_text_field_get_text_color",1);
   static var nme_text_field_set_text_color = nme.Loader.load("nme_text_field_set_text_color",2);
   static var nme_text_field_get_selectable = nme.Loader.load("nme_text_field_get_selectable",1);
   static var nme_text_field_set_selectable = nme.Loader.load("nme_text_field_set_selectable",2);
   static var nme_text_field_get_display_as_password = nme.Loader.load("nme_text_field_get_display_as_password",1);
   static var nme_text_field_set_display_as_password = nme.Loader.load("nme_text_field_set_display_as_password",2);
   static var nme_text_field_get_def_text_format = nme.Loader.load("nme_text_field_get_def_text_format",2);
   static var nme_text_field_set_def_text_format = nme.Loader.load("nme_text_field_set_def_text_format",2);
   static var nme_text_field_get_auto_size = nme.Loader.load("nme_text_field_get_auto_size",1);
   static var nme_text_field_set_auto_size = nme.Loader.load("nme_text_field_set_auto_size",2);
   static var nme_text_field_get_type = nme.Loader.load("nme_text_field_get_type",1);
   static var nme_text_field_set_type = nme.Loader.load("nme_text_field_set_type",2);
   static var nme_text_field_get_multiline = nme.Loader.load("nme_text_field_get_multiline",1);
   static var nme_text_field_set_multiline = nme.Loader.load("nme_text_field_set_multiline",2);
   static var nme_text_field_get_word_wrap = nme.Loader.load("nme_text_field_get_word_wrap",1);
   static var nme_text_field_set_word_wrap = nme.Loader.load("nme_text_field_set_word_wrap",2);
   static var nme_text_field_get_border = nme.Loader.load("nme_text_field_get_border",1);
   static var nme_text_field_set_border = nme.Loader.load("nme_text_field_set_border",2);
   static var nme_text_field_get_border_color = nme.Loader.load("nme_text_field_get_border_color",1);
   static var nme_text_field_set_border_color = nme.Loader.load("nme_text_field_set_border_color",2);
   static var nme_text_field_get_background = nme.Loader.load("nme_text_field_get_background",1);
   static var nme_text_field_set_background = nme.Loader.load("nme_text_field_set_background",2);
   static var nme_text_field_get_background_color = nme.Loader.load("nme_text_field_get_background_color",1);
   static var nme_text_field_set_background_color = nme.Loader.load("nme_text_field_set_background_color",2);
   static var nme_text_field_get_text_width = nme.Loader.load("nme_text_field_get_text_width",1);
   static var nme_text_field_get_text_height = nme.Loader.load("nme_text_field_get_text_height",1);
   static var nme_text_field_set_text_format = nme.Loader.load("nme_text_field_set_text_format",4);

   static var nme_text_field_get_max_scroll_v = nme.Loader.load("nme_text_field_get_max_scroll_v",1);
   static var nme_text_field_get_max_scroll_h = nme.Loader.load("nme_text_field_get_max_scroll_h",1);
   static var nme_text_field_get_bottom_scroll_v = nme.Loader.load("nme_text_field_get_bottom_scroll_v",1);
   static var nme_text_field_get_scroll_h = nme.Loader.load("nme_text_field_get_scroll_h",1);
   static var nme_text_field_set_scroll_h = nme.Loader.load("nme_text_field_set_scroll_h",2);
   static var nme_text_field_get_scroll_v = nme.Loader.load("nme_text_field_get_scroll_v",1);
   static var nme_text_field_set_scroll_v = nme.Loader.load("nme_text_field_set_scroll_v",2);
   static var nme_text_field_get_num_lines = nme.Loader.load("nme_text_field_get_num_lines",1);
   static var nme_text_field_get_max_chars = nme.Loader.load("nme_text_field_get_max_chars",1);
   static var nme_text_field_set_max_chars = nme.Loader.load("nme_text_field_set_max_chars",2);
}


#else
typedef TextField = flash.text.TextField;
#end