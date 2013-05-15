package nme.system;
#if display


extern class SecurityDomain {
	//@:require(flash11_3) var domainID(default,null) : String;
	static var currentDomain(default,null) : SecurityDomain;
}


#elseif (cpp || neko)
typedef SecurityDomain = native.system.SecurityDomain;
#elseif flash
typedef SecurityDomain = flash.system.SecurityDomain;
#end
