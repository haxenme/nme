package native.text;
#if (cpp || neko)

class TextFormat 
{
   public var align:String;
   public var blockIndent:Dynamic;
   public var bold:Dynamic;
   public var bullet:Dynamic;
   public var color:Dynamic;
   public var display:String;
   public var font:String;
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

#end