package;


import sys.io.Process;


class PlatformHelper {
	
	
	public static var hostArchitecture (getHostArchitecture, null):Architecture;
	public static var hostPlatform (getHostPlatform, null):Platform;
	
	private static var _hostArchitecture:Architecture;
	private static var _hostPlatform:Platform;
	
	
	private static function getHostArchitecture ():Architecture {
		
		if (_hostArchitecture == null) {
			
			switch (hostPlatform) {
				
				case Platform.WINDOWS:
					
					var architecture = Sys.getEnv ("PROCESSOR_ARCHITEW6432");
					
					if (architecture != null && architecture.indexOf ("64") > -1) {
						
						_hostArchitecture = Architecture.X86_64;
						
					} else {
						
						_hostArchitecture = Architecture.X86;
						
					}
					
				case Platform.LINUX:
					
					var process = new Process ("uname", [ "-m" ]);
					var output = process.stdout.readAll ().toString ();
					var error = process.stderr.readAll ().toString ();
					process.exitCode ();
					process.close ();
					
					if (output.indexOf ("64") > -1) {
					
						_hostArchitecture = Architecture.X86_64;
					
					} else {
						
						_hostArchitecture = Architecture.X86;
						
					}
					
				case Platform.MAC:
					
					_hostArchitecture = Architecture.X86;
					
				default:
					
					_hostArchitecture = Architecture.ARMV6;
				
			}
			
			LogHelper.info ("", " - Detected host architecture: " + StringHelper.formatEnum (_hostArchitecture));
			
		}
		
		return _hostArchitecture;
		
	}
	
	
	private static function getHostPlatform ():Platform {
		
		if (_hostPlatform == null) {
			
			if (new EReg ("window", "i").match (Sys.systemName ())) {
				
				_hostPlatform = Platform.WINDOWS;
				
			} else if (new EReg ("linux", "i").match (Sys.systemName ())) {
				
				_hostPlatform = Platform.LINUX;
				
			} else if (new EReg ("mac", "i").match (Sys.systemName ())) {
				
				_hostPlatform = Platform.MAC;
				
			}
			
			LogHelper.info ("", " - Detected host platform: " + StringHelper.formatEnum (_hostPlatform));
			
		}
		
		return _hostPlatform;
		
	}
		

}
