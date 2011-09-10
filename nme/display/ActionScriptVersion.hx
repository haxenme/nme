package nme.display;


#if flash
@:native ("flash.display.ActionScriptVersion")
@:fakeEnum(UInt) extern enum ActionScriptVersion {
	ACTIONSCRIPT2;
	ACTIONSCRIPT3;
}
#end