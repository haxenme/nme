package browser.accessibility;
#if js


class AccessibilityProperties {
	
	
	public var description:String;
	public var forceSimple:Bool;
	public var name:String;
	public var noAutoLabeling:Bool;
	public var shortcut:String;
	public var silent:Bool;
	
	
	public function new() {
		
		description = "";
		forceSimple = false;
		name = "";
		noAutoLabeling = false;
		shortcut = "";
		silent = false;
		
	}
	
}


#end