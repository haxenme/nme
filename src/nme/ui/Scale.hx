package nme.ui;

class Scale
{
   static var scale = 0.0;

   public static function getFontScale()
   {
      if (scale==0.0)
      {
         #if android
         var getDensity = JNI.createStaticMethod("org.haxe.nme.GameActivity", "CapabilitiesScaledDensity", "()D");
         if (getDensity!=null)
         {
            scale = getDensity();
            return scale;
         }
         #end
         scale = nme.system.Capabilities.screenDPI;
         if (scale>120)
            scale /= 120;
         else
            scale = 1.0;
      }
      return scale;
   }
}
