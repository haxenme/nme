package nme.text;
#if (cpp || neko)


class TextFormat
{
	
	public var align:Null<String>;
	public var blockIndent:Dynamic;
	public var bold:Dynamic;
	public var bullet:Dynamic;
	public var color:Dynamic;
	public var display:Null<String>;
	public var font:Null<String>;
	public var indent:Dynamic;
	public var italic:Dynamic;
	public var kerning:Dynamic;
	public var leading:Dynamic;
	public var leftMargin:Dynamic;
	public var letterSpacing:Dynamic;
	public var rightMargin:Dynamic;
	public var size:Dynamic;
	public var tabStops:Array<Int>;
	public var target:String;
	public var underline:Dynamic;
	public var url:String;
	
	
	public function new(?in_font:String, ?in_size:Dynamic, ?in_color:Dynamic, ?in_bold:Dynamic, ?in_italic:Dynamic, ?in_underline:Dynamic, ?in_url:String, ?in_target:String, ?in_align:String, ?in_leftMargin:Dynamic, ?in_rightMargin:Dynamic, ?in_indent:Dynamic, ?in_leading:Dynamic)
	{
		font = in_font;
		size = in_size;
		color = in_color;
		bold = in_bold;
		italic = in_italic;
		underline = in_underline;
		url = in_url;
		target = in_target;
		align = in_align;
		leftMargin = in_leftMargin;
		rightMargin = in_rightMargin;
		indent = in_indent;
		leading = in_leading;
	}
	
}


#elseif js

import Html5Dom;

class TextFormat
{
   public var align : TextFormatAlign;
   public var blockIndent : Int;
   public var bold : Bool;
   public var bullet : Bool;
   public var color : UInt;
   public var display : String;
   public var font : String;
   public var indent : Int;
   public var italic : Bool;
   public var kerning : Bool;
   public var leading : Int;
   public var leftMargin : Int;
   public var letterSpacing : Int;
   public var rightMargin : Int;
   public var size : Float;
   public var tabStops : Int;
   public var target : String;
   public var underline : Bool;
   public var url : String;

  public function new(?in_font : String,
                      ?in_size : Float,
                      ?in_color : UInt,
                      ?in_bold : Bool,
                      ?in_italic : Bool,
                      ?in_underline : Bool,
                      ?in_url : String,
                      ?in_target : String,
                      ?in_align : TextFormatAlign,
                      ?in_leftMargin : Int,
                      ?in_rightMargin : Int,
                      ?in_indent : Int,
                      ?in_leading : Int)
   {
      font = in_font;
      size = in_size;
      color = in_color;
      bold = in_bold;
      italic = in_italic;
      underline = in_underline;
      url = in_url;
      target = in_target;
      align = in_align;
      leftMargin = in_leftMargin;
      rightMargin = in_rightMargin;
      indent = in_indent;
      leading = in_leading;
   }

}

#else
typedef TextFormat = flash.text.TextFormat;
#end