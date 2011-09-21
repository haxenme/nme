import ::APP_MAIN_PACKAGE::::APP_MAIN_CLASS::;


class ApplicationMain {
	
	
	public static function main () {
		
		::APP_MAIN_CLASS::.main ();
		
	}
	

   public static function getAsset(inName:String):Dynamic
   {
      ::foreach assets::
      if (inName=="::id::")
      {
         ::if (type=="image")::
            return nme.display.BitmapData.load(inName);
         ::elseif (type=="sound")::
            return new nme.media.Sound(new nme.net.URLRequest(inName),null,false);
         ::elseif (type=="music")::
            return new nme.media.Sound(new nme.net.URLRequest(inName),null,true);
         ::else::
            return nme.utils.ByteArray.readFile(inName);
         ::end::
      }
      ::end::
      return null;
   }
   
}