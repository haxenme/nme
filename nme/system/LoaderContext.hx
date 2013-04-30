package nme.system;
#if display


extern class LoaderContext {
	@:require(flash10_1) var allowCodeImport : Bool;
	@:require(flash10_1) var allowLoadBytesCodeExecution : Bool;
	var applicationDomain : ApplicationDomain;
	var checkPolicyFile : Bool;
	@:require(flash11) var imageDecodingPolicy : ImageDecodingPolicy;
	@:require(flash11) var parameters : Dynamic;
	@:require(flash11) var requestedContentParent : flash.display.DisplayObjectContainer;
	var securityDomain : SecurityDomain;
	function new(checkPolicyFile : Bool = false, ?applicationDomain : ApplicationDomain, ?securityDomain : SecurityDomain) : Void;
}


#elseif (cpp || neko)
typedef LoaderContext = native.system.LoaderContext;
#elseif flash
typedef LoaderContext = flash.system.LoaderContext;
#end
