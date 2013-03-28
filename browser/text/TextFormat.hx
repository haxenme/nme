package browser.text;
#if js

import browser.utils.UInt;

class TextFormat {
	
	
	public var align:TextFormatAlign;
	public var blockIndent:Float;
	public var bold:Bool;
	public var bullet:Bool;
	public var color:UInt;
	public var display:String;
	public var font:String;
	public var indent:Float;
	public var italic:Bool;
	public var kerning:Bool;
	public var leading:Float;
	public var leftMargin:Float;
	public var letterSpacing:Float;
	public var rightMargin:Float;
	public var size:Float;
	public var tabStops:UInt;
	public var target:String;
	public var underline:Bool;
	public var url:String;
	
	
	public function new(?in_font:String, ?in_size:Float, ?in_color:UInt, ?in_bold:Bool, ?in_italic:Bool, ?in_underline:Bool, ?in_url:String, ?in_target:String, ?in_align:TextFormatAlign, ?in_leftMargin:Int, ?in_rightMargin:Int, ?in_indent:Int, ?in_leading:Int) {
		
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
	
	
	public function clone():TextFormat {
		
		var newFormat = new TextFormat(font, size, color, bold, italic, underline, url, target);
		
		newFormat.align = align;
		newFormat.leftMargin = leftMargin;
		newFormat.rightMargin = rightMargin;
		newFormat.indent = indent;
		newFormat.leading = leading;
		
		newFormat.blockIndent = blockIndent;
		newFormat.bullet = bullet;
		newFormat.display = display;
		newFormat.kerning = kerning;
		newFormat.letterSpacing = letterSpacing;
		newFormat.tabStops = tabStops;
		
		return newFormat;
		
	}
	
	
}


#end