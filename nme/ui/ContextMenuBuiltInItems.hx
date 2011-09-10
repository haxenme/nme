package nme.ui;


#if flash
@:native ("flash.ui.ContextMenuBuiltInItems")
@:final extern class ContextMenuBuiltInItems {
	var forwardAndBack : Bool;
	var loop : Bool;
	var play : Bool;
	var print : Bool;
	var quality : Bool;
	var rewind : Bool;
	var save : Bool;
	var zoom : Bool;
	function new() : Void;
	function clone() : ContextMenuBuiltInItems;
}
#end