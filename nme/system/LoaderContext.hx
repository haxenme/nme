package nme.system;
#if (!flash)

@:nativeProperty
class LoaderContext
{		
	public var allowCodeImport:Bool;
	public var allowLoadBytesCodeExecution:Bool;
	public var applicationDomain:ApplicationDomain;
	public var checkPolicyFile:Bool;
	public var securityDomain:SecurityDomain;
	
	public function new(checkPolicyFile:Bool = false, applicationDomain:ApplicationDomain = null, securityDomain:SecurityDomain = null)
	{	
		this.checkPolicyFile = checkPolicyFile;
		this.securityDomain = securityDomain;
		
		if (applicationDomain != null)
		{	
			this.applicationDomain = applicationDomain;	
		}
		else
		{	
			this.applicationDomain = ApplicationDomain.currentDomain;	
		}
	}
}

#else
typedef LoaderContext = flash.system.LoaderContext;
#end
