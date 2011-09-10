#if flash


package nme.system;


@:native ("flash.system.SecurityDomain")
extern class SecurityDomain {
	static var currentDomain(default,null) : SecurityDomain;
}



#end