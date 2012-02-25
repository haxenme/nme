package nme.system;
#if js


class LoaderContext {
	var applicationDomain : Dynamic;
	public var checkPolicyFile : Bool;
	var securityDomain : Dynamic;
	public function new(checkPolicyFile : Bool = false, ?applicationDomain, ?securityDomain) 
	{
		this.checkPolicyFile = checkPolicyFile;
	}
}


#else
typedef LoaderContext = flash.system.LoaderContext;
#end