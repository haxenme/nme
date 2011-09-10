package nme.system;


#if flash
@:native ("flash.system.SecurityDomain")
extern class SecurityDomain {
	static var currentDomain(default,null) : SecurityDomain;
}
#end