import InterfaceController;
import ios.coreGraphics.*;

class MyApp extends nme.watchos.App
{
   var cg:CGImage = null;

   public function new()
   {
      super();
      trace("MyApp");
      trace(cg);
   }

   override public function onAwake()
   {
      trace(InterfaceController.instance);
      InterfaceController.instance.label0.setText("My Text!");

      //var bytes = haxe.io.Bytes.alloc(100);
      //var uiimage = ios.uikit.UIImage.imageWithData( bytes );
      cg = CGImage.create(80,80,8,32,4*80,ColorSpace.DEVICE_RGB, CGBitmapInfo.ByteOrder32Little, null, null, true, CGColorRenderingIntent.Default);
      var bytes = haxe.io.Bytes.alloc(100);
      var uiimage = ios.uikit.UIImage.imageWithData( bytes );
   }
}

