package nme.text;
#if display


import nme.display.BitmapData;


typedef NMEFontDef =
{
  name:String,
  height:Int,
  bold:Bool,
  italic:Bool,
};

typedef NMEFontFactory = NMEFontDef->NMEFont;


typedef NMEGlyphInfo =
{
  width:Int,
  height:Int,
  advance:Int,
  offsetX:Int,
  offsetY:Int,
};


extern class NMEFont
{
	function new(inHeight:Int, inAscent:Int, inDescent:Int, inIsRGB:Bool):Void;
	function getGlyphInfo(inChar:Int) : NMEGlyphInfo;
	function renderGlyph(inChar:Int) : BitmapData;
	static function registerFont(inName:String, inFactory:NMEFontFactory):Void;
}


#elseif (cpp || neko)
typedef NMEFont = native.text.NMEFont;
#end
