package nme;


import nme.Assets;
import nme.AssetType;



class AssetData
{
	public static var className = new Map<String,Dynamic>();
	public static var type = new Map<String,AssetType>();
	public static var useResources = false;
	private static var initialized:Bool = false;
	
	public static function initialize ():Void
   {
		
		if (!initialized)
      {
			::if (assets != null)::::foreach assets::className.set ("::id::", nme.NME_::flatName::);
			type.set ("::id::", Reflect.field (AssetType, "::type::".toUpperCase ()));
			::end::::end::
			::if (libraries != null)::::foreach libraries::library.set ("::name::", Reflect.field (LibraryType, "::type::".toUpperCase ()));
			::end::::end::
			initialized = true;
		}
	}
}


::foreach assets::::if (type == "image")::class NME_::flatName:: extends flash.display.BitmapData { public function new () { super (0, 0); } }::else::class NME_::flatName:: extends ::flashClass:: { }::end::
::end::
