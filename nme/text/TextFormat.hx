package nme.text;


#if flash
@:native ("flash.text.TextFormat")
extern class TextFormat {
	//var align : TextFormatAlign;
	var align : String;
	var blockIndent : Null<Float>;
	var bold : Null<Bool>;
	var bullet : Null<Bool>;
	var color : Null<UInt>;
	//var display : TextFormatDisplay;
	var font : String;
	var indent : Null<Float>;
	var italic : Null<Bool>;
	var kerning : Null<Bool>;
	var leading : Null<Float>;
	var leftMargin : Null<Float>;
	var letterSpacing : Null<Float>;
	var rightMargin : Null<Float>;
	var size : Null<Float>;
	var tabStops : Array<UInt>;
	var target : String;
	var underline : Null<Bool>;
	var url : String;
	//function new(?font : String, ?size : Float, ?color : UInt, ?bold : Bool, ?italic : Bool, ?underline : Bool, ?url : String, ?target : String, ?align : TextFormatAlign, ?leftMargin : Float, ?rightMargin : Float, ?indent : Float, ?leading : Float) : Void;
	function new(?font : String, ?size : Float, ?color : UInt, ?bold : Bool, ?italic : Bool, ?underline : Bool, ?url : String, ?target : String, ?align : String, ?leftMargin : Float, ?rightMargin : Float, ?indent : Float, ?leading : Float) : Void;
}
#else



class TextFormat
{
   public var align : Null<String>;
   public var blockIndent : Dynamic;
   public var bold : Dynamic;
   public var bullet : Dynamic;
   public var color : Dynamic;
   public var display : Null<String>;
   public var font : Null<String>;
   public var indent : Dynamic;
   public var italic : Dynamic;
   public var kerning : Dynamic;
   public var leading : Dynamic;
   public var leftMargin : Dynamic;
   public var letterSpacing : Dynamic;
   public var rightMargin : Dynamic;
   public var size : Dynamic;
   public var tabStops : Array<Int>;
   public var target : String;
   public var underline : Dynamic;
   public var url : String;

  public function new(?in_font : String,
                      ?in_size : Dynamic,
                      ?in_color : Dynamic,
                      ?in_bold : Dynamic,
                      ?in_italic : Dynamic,
                      ?in_underline : Dynamic,
                      ?in_url : String,
                      ?in_target : String,
                      ?in_align : String,
                      ?in_leftMargin : Dynamic,
                      ?in_rightMargin : Dynamic,
                      ?in_indent : Dynamic,
                      ?in_leading : Dynamic)
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
#end