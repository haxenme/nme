package jeash.system;

class LoaderContext {
	var applicationDomain : Dynamic;
	public var checkPolicyFile : Bool;
	var securityDomain : Dynamic;
	public function new(checkPolicyFile : Bool = false, ?applicationDomain, ?securityDomain) 
	{
		this.checkPolicyFile = checkPolicyFile;
	}
}

