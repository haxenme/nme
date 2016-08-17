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
     
      var data = new Array<Int>();
      for(i in 0...80*80)
         data[i] = 0xff00ffff;

      var provider:CGDataProvider = CGDataProvider.createWithArray(data);
      trace("Create image...");
      cg = CGImage.create(80,80,8,32,4*80,ColorSpace.DEVICE_RGB, CGBitmapInfo.ByteOrder32Little, provider, null, true, CGColorRenderingIntent.Default);

      //var bytes = haxe.io.Bytes.alloc(100);
      //var uiimage = ios.uikit.UIImage.imageWithData( bytes );
      trace("Set image...");
      InterfaceController.instance.image0.setImage(ios.uikit.UIImage.imageWithCGImage( cg ));
   }
}

