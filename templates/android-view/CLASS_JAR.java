package ::CLASS_PACKAGE::;

import android.util.Log;
import org.haxe.nme.HaxeObject;
import org.haxe.nme.Value;

public class ::CLASS_NAME::Base extends org.haxe.nme.GameActivity
{
   static HaxeObject haxeCallbackObject;

   public static void setHaxeCallbackObject(HaxeObject inHaxeCallbackObject)
   {
      haxeCallbackObject = inHaxeCallbackObject;
   }

   public void setProperty(final String name, final String value)
   {
      final HaxeObject haxeObj = haxeCallbackObject;
      // Log.v("::CLASS_NAME::Base", "setProperty " + haxeObj);
      if (haxeObj!=null)
      {
         sendToView( new Runnable() { @Override public void run() {
            haxeObj.call2("setProperty", name, value );
         } });
      }
   }

}

