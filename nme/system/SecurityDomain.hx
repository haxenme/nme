package nme.system;
#if (cpp || neko)

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