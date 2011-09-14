/*
 These classes are in the "gen" directory, and have been auto-generated
  fron the .class files found in android.jar, and GameActivity.class
  that found in the compiled bin directory.
*/
import android.widget.Toast;
import org.haxe.nme.GameActivity;

class AndroidJNI
{
   public static function main()
   {
      var context = GameActivity.getContext();
      // Haxe normally runs in the "render" thread - and this thread can't
      //  update the GUI (ie, 'Toast') directly.
      // In order to access the UI, we post a callback that will get
      //  run asynchronously in the UI thread at some time in the (near) future.
      nme.Lib.postUICallback( function()
        {
         var toast = Toast.makeText(context,"Hello JNI!",Toast.LENGTH_LONG);
         toast.show();
        } );
   }
}
