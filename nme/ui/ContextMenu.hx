#if flash


package nme.ui;

@:native ("flash.ui.ContextMenu")
@:final extern class ContextMenu extends nme.display.NativeMenu {
	var builtInItems : ContextMenuBuiltInItems;
	@:require(flash10) var clipboardItems : ContextMenuClipboardItems;
	@:require(flash10) var clipboardMenu : Bool;
	var customItems : Array<Dynamic>;
	@:require(flash10) var link : nme.net.URLRequest;
	function new() : Void;
	function clone() : ContextMenu;
	function hideBuiltInItems() : Void;
	@:require(flash10_1) static var isSupported(default,null) : Bool;
}


#end