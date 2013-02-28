package nme;


class AssetData {

	
	public static var library = new Map <String, String> ();
	public static var path = new Map <String, String> ();
	public static var type = new Map <String, String> ();
	
	private static var initialized:Bool = false;
	
	
	public static function initialize ():Void {
		
		if (!initialized) {
			
			::if (assets != null)::::foreach assets::path.set ("::id::", "::resourceName::");
			type.set ("::id::", "::type::");
			::end::::end::
			::if (libraries != null)::::foreach libraries::library.set ("::name::", "::type::");
			::end::::end::
			initialized = true;
			
		}
		
	}
	
	
}