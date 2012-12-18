package browser.system;


class LoaderContext {
	
	
	public var checkPolicyFile:Bool;
	
	private var applicationDomain:Dynamic;
	private var securityDomain:Dynamic;
	
	
	public function new (checkPolicyFile:Bool = false, ?applicationDomain, ?securityDomain) {
		
		this.checkPolicyFile = checkPolicyFile;
		
	}
	
	
}