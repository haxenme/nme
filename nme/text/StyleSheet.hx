package nme.text;


#if flash
@:native ("flash.text.StyleSheet")
extern class StyleSheet extends nme.events.EventDispatcher, implements Dynamic {
	var styleNames(default,null) : Array<Dynamic>;
	function new() : Void;
	function clear() : Void;
	function getStyle(styleName : String) : Dynamic;
	function parseCSS(CSSText : String) : Void;
	function setStyle(styleName : String, styleObject : Dynamic) : Void;
	function transform(formatObject : Dynamic) : TextFormat;
}
#end