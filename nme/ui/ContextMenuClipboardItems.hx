package nme.ui;


#if flash
@:native ("flash.ui.ContextMenuClipboardItems")
@:final extern class ContextMenuClipboardItems {
	var clear : Bool;
	var copy : Bool;
	var cut : Bool;
	var paste : Bool;
	var selectAll : Bool;
	function new() : Void;
	function clone() : ContextMenuClipboardItems;
}
#end