package nme.system;


#if flash
@:native ("flash.system.IME")
extern class IME extends nme.events.EventDispatcher {
	static var constructOK(null,default) : Bool;
	static var conversionMode : IMEConversionMode;
	static var enabled : Bool;
	@:require(flash10_1) static var isSupported(default,null) : Bool;
	@:require(flash10_1) static function compositionAbandoned() : Void;
	@:require(flash10_1) static function compositionSelectionChanged(start : Int, end : Int) : Void;
	static function doConversion() : Void;
	static function setCompositionString(composition : String) : Void;
}
#end