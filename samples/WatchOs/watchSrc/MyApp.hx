import InterfaceController;
import ios.coregraphics.*;
import ios.spritekit.*;
import ios.uikit.UIColor;
import ios.watchconnectivity.WCSession;

class MyApp extends nme.watchos.SpriteKitApp
{
   var textNode: SKLabelNode;
   var haxeNode:SKSpriteNode;
   var nmeNode:SKSpriteNode;
   var tBase:Float;

   public function new()
   {
      super();
      tBase = 0;
      trace("New MyApp");
      // call finalize at end ...
      cpp.NativeGc.addFinalizable(this,false);

      activateWCSession();
   }

   public function finalize():Void
   {
      // Release references
      textNode = null;
      haxeNode = null;
      nmeNode = null;
   }


   override public function onAwake()
   {
      setupGame();
      super.onAwake();
   }

   // SKSceneDelegate
   override public function onUpdate(time:Float)
   {
      if (tBase==0.0)
        tBase=time;

      var t = time-tBase;
      var phase = Math.sin(t*3);
      var node:SKSpriteNode = null;
      if (phase<0)
      {
         node = nmeNode;
         haxeNode.hidden = true;
      }
      else
      {
         node = haxeNode;
         nmeNode.hidden = true;
      }
      node.hidden = false;
      node.setScale( Math.abs(phase) );
   }

   public function setupGame()
   {
      var ic = InterfaceController.instance;

      textNode =  SKLabelNode.withFontNamed("Headline");
      textNode.fontColor = UIColor.withRed(1,0,1,1);
      textNode.text = "Hi!";
      textNode.fontSize = 45;
      textNode.position = CGPoint.make(50,100);

      var size = ic.contentFrame.size;
      var d = size.width < size.height ? size.width : size.height;

      var texture = SKTexture.withImageNamed("haxe");
      haxeNode = SKSpriteNode.withTextureSize(texture, CGSize.make(d,d) );
      haxeNode.position = CGPoint.make(size.width/2,size.height/2);
      haxeNode.hidden = true;

      var texture = SKTexture.withImageNamed("nme");
      nmeNode = SKSpriteNode.withTextureSize(texture, CGSize.make(d,d) );
      nmeNode.position = CGPoint.make(size.width/2,size.height/2);


      var skScene = SKScene.withSize(size);
      skScene.scaleMode = SKSceneScaleMode.resizeFill;
      trace(skScene.delegate);
      //skScene.addChild(textNode);
      skScene.addChild(haxeNode);
      skScene.addChild(nmeNode);
      skScene.delegate = this;
         
      
      ic.skScene.presentScene(skScene);

      trace(skScene.delegate);

      // Load and set the background image.
      //let backgroundImage = UIImage(named:"art.scnassets/background.png")

   }
}

