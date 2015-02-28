package nme.system;
#if (cpp || neko)

@:nativeProperty
class SecurityDomain
{		
	public static var currentDomain(default, null) = new SecurityDomain();
	
	private function new()
	{	
	}
}

#else
typedef SecurityDomain = flash.system.SecurityDomain;
#end
