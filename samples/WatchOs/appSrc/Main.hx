import nme.display.Sprite;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;
import nme.text.TextFieldAutoSize;
import nme.events.MouseEvent;
import nme.ui.Scale;
import cpp.Pointer;
#if objc
import cpp.objc.*;
import ios.watchconnectivity.*;
#end


class Button extends Sprite
{
   var textField:TextField;
   var active:Bool;

   public function getScale() return Scale.getFontScale()*2;

   public function new(inName:String, inOnClick:String->Void)
   {
      super();
      name = inName;
      textField = new TextField();
      textField.text = inName;
      textField.mouseEnabled = false;
      textField.text = inName;
      var s = getScale();
      textField.width = Std.int( s*100 );
      textField.height = Std.int( s*25 );
      active = false;

      addChild(textField);

      addEventListener( MouseEvent.CLICK, function(_) if (!active) inOnClick(inName) );
   }

   public function setCurrent(inName:String)
   {
      var s = getScale();
      var fmt = new TextFormat();
      fmt.align = TextFormatAlign.CENTER;
      fmt.font = "_sans";
      fmt.size = 16 * s;

      var bg = graphics;
      bg.clear();
 
      if (inName.substr(0,name.length)==name)
      {
         active = true;
         bg.beginFill(0xa0a0ff);
         fmt.color = 0xffffff;
      }
      else
      {
         active = false;
         textField.background = false;
         textField.borderColor = 0x0000ff;
         bg.lineStyle( Scale.getFontScale(),0x0000ff);
         fmt.color = 0xa0a0a0;
      }
      textField.setTextFormat(fmt);
      textField.y = (textField.height-textField.textHeight)/2;
      bg.drawRect(-1.5, -1.5, textField.width+2, textField.height+2);

      // Runing at 0fps needs explicit invalidate
      if (stage!=null)
         stage.invalidate();
   }
}


class Main extends Sprite #if objc implements WCSessionDelegate #end
{
   var asSessionDelegate:cpp.objc.Protocol<WCSessionDelegate>;
   var buttons:Array<Button> = [];
   public function new()
   {
      super();
      trace("Main app!");
      var y = 20.0;
      for(choice in ["Haxe","Nme", "Swap"])
      {
         var button = new Button(choice, setCurrent);
         addChild(button);
         buttons.push(button);
         button.x = 20;
         button.y = y;
         y+= Std.int(button.height * 1.5);
      }
      #if objc
      trace("Main app1!");
      activateWCSession();
      #end
      setCurrent("Swap");
   }


   function setCurrent(value:String)
   {
      for(but in buttons)
         but.setCurrent(value);

      #if objc
      if (WCSession.isSupported())
      {
         var error:NSError = null;
         WCSession.defaultSession().updateApplicationContext({mode:value}, cpp.RawPointer.addressOf(error) );
      }
      #end
   }


   #if objc
   public function activateWCSession()
   {
      trace("Main - activateWCSession!");
      if (WCSession.isSupported())
      {
          trace("Setting default");
          var session = WCSession.defaultSession();
          trace("Setting delegate");
          asSessionDelegate = this;
          session.delegate = asSessionDelegate;
          session.activateSession();
      }
      else
         trace("WCSession not supported");
   }

   // WCSessionDelegate
   public function activationCompleted(s:WCSession, state:WCSessionActivationState, error:NSError)
   {
      trace("iphone - activationCompleted " + state);
   }

   public function onContext(session:WCSession, context:NSDictionary):Void
   {
      var ctx:Dynamic = context;
      trace("iphone - didReceiveApplicationContext " + ctx);
   }

   public function sessionDidBecomeInactive(session:WCSession) : Void
   {
      trace("iphone - sessionDidBecomeInactive!\n");
   }

   public function sessionDidDeactivate(session:WCSession) : Void
   {
      trace("iphone - sessionDidDeactivate!\n");
   }


   public function sessionWatchStateDidChange(session:WCSession):Void
   {
      trace("iphone - sessionWatchStateDidChange");
   }

   public function sessionReachabilityDidChange(session:WCSession):Void
   {
      trace("iphone - sessionWatchStateDidChange");
   }
   #end

}
