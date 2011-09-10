package nme.system;


#if flash
@:native ("flash.system.ApplicationDomain")
@:final extern class ApplicationDomain {
	@:require(flash10) var domainMemory : nme.utils.ByteArray;
	var parentDomain(default,null) : ApplicationDomain;
	function new(?parentDomain : ApplicationDomain) : Void;
	function getDefinition(name : String) : Dynamic;
	function hasDefinition(name : String) : Bool;
	@:require(flash10) static var MIN_DOMAIN_MEMORY_LENGTH(default,null) : UInt;
	static var currentDomain(default,null) : ApplicationDomain;
}
#end