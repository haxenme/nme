package nme;


class AssetData {

	
	public static var className = new Map <String, Dynamic> ();
	public static var library = new Map <String, String> ();
	public static var path = new Map <String, String> ();
	public static var type = new Map <String, String> ();
	
	private static var initialized:Bool = false;
	
	
	public static function initialize ():Void {
		
		if (!initialized) {
			
			::if (assets != null)::::foreach assets::::if (type == "font")::className.set ("::id::", nme.NME_::flatName::);::else::path.set ("::id::", "::resourceName::");::end::
			type.set ("::id::", "::type::");
			::end::::end::
			::if (libraries != null)::::foreach libraries::library.set ("::name::", "::type::");
			::end::::end::
			initialized = true;
			
		}
		
	}
	
	
}


::foreach assets::::if (type == "font")::class NME_::flatName:: extends nme.text.Font { }::end::
::end::