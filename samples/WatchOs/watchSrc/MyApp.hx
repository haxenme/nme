import InterfaceController;
import ios.coregraphics.*;
import ios.spritekit.*;
import ios.uikit.UIColor;
import ios.watchconnectivity.WCSession;
import cpp.objc.NSDictionary;

class MyApp extends nme.watchos.SpriteKitApp
{
   var textNode: SKLabelNode;
   var haxeNode:SKSpriteNode;
   var nmeNode:SKSpriteNode;
   var tBase:Float;
   var mode = "";
   var rotation:Float = 0;

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

   public function setContext(context:Dynamic):Void
   {
      if (context!=null)
      {
         mode = context.mode;
      }
   }

   override public function onContext(session:WCSession, context:NSDictionary):Void
   {
      var ctx:Dynamic = context;
      trace("got message from app: " + ctx);
      setContext(ctx);
   }



   override public function onAwake(context:Dynamic)
   {
      setupGame(context);
      super.onAwake(context);
   }

   override public function crownDidRotate(delta:Float, rotationsPerSecond:Float)
   {
      rotation += delta * 3;
   }

   override public function crownDidBecomeIdle()
   {
   }


   // SKSceneDelegate
   override public function onUpdate(time:Float)
   {
      if (tBase==0.0)
        tBase=time;

      var t = time-tBase;
      var phase = Math.sin(t*3);
      var node:SKSpriteNode = null;
      var showNme = mode=="Nme" || (mode!="Haxe" && phase<0);
      if (showNme)
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
      node.zRotation = rotation;
   }

   public function setupGame(context:Dynamic)
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
      skScene.delegate = asSKSceneDelegate();
         
      
      ic.skScene.presentScene(skScene);

      trace(skScene.delegate);

      setContext(context);
      // Load and set the background image.
      //let backgroundImage = UIImage(named:"art.scnassets/background.png")

   }
}

