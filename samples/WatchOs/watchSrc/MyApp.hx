import InterfaceController;
import ios.coregraphics.*;
import ios.spritekit.*;
import ios.uikit.UIColor;

class MyApp extends nme.watchos.App
{
   public function new()
   {
      super();
   }

   var textNode: SKLabelNode;

   override public function onAwake()
   {
      trace(InterfaceController.instance);
      trace(InterfaceController.instance.skScene);
      setupGame();
   }

   public function setupGame()
   {
      var ic = InterfaceController.instance;
      /*
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
      */

      textNode =  SKLabelNode.withFontNamed("Headline");
      textNode.fontColor = UIColor.withRed(1,0,1,1);
      textNode.text = "Hi!";
      textNode.fontSize = 45;
      textNode.position = CGPoint.make(50,100);


      var skScene = SKScene.withSize(ic.contentFrame.size);
      skScene.scaleMode = SKSceneScaleMode.resizeFill;
      skScene.addChild(textNode);
         
      ic.skScene.presentScene(skScene);

      // Load and set the background image.
      //let backgroundImage = UIImage(named:"art.scnassets/background.png")

   }
}

