#if flash


package nme.ui;


@:native ("flash.ui.ContextMenuItem")
@:final extern class ContextMenuItem extends nme.display.NativeMenuItem {
	var caption : String;
	var separatorBefore : Bool;
	var visible : Bool;
	function new(caption : String, separatorBefore : Bool = false, enabled : Bool = true, visible : Bool = true) : Void;
	function clone() : ContextMenuItem;
}


#end