import nme.display.*;
import nme.text.*;
import nme.events.*;

class RenderTest extends Sprite
{
   var current:TestBase;
   var currentIdx = -1;
   var factories = new Array< Void->TestBase >();
   var nextButton:TextField;

   public function new()
   {
      super();
      factories.push( BitmapBlend.new );
      factories.push( ColourTransform.new );
      nextScreen();

      nextButton = new TextField();
      nextButton.textColor = 0xffffffff;
      nextButton.text = "Next";
      nextButton.border = true;
      nextButton.borderColor = 0xffffffff;
      nextButton.background = true;
      nextButton.backgroundColor = 0xff101030;
      nextButton.autoSize = TextFieldAutoSize.LEFT;
      nextButton.selectable = false;
      var dpiScale = nme.system.Capabilities.screenDPI/96;
      if (dpiScale>1.5)
         dpiScale = 1.0;
      nextButton.scaleX = nextButton.scaleY = dpiScale * 2.0;
      nextButton.addEventListener(MouseEvent.CLICK, function(_) nextScreen() );
      addChild(nextButton);

      addEventListener(Event.RESIZE, function(_) resize() );
      resize();
   }


   public function nextScreen()
   {
      if (current!=null)
         removeChild(current);

      currentIdx = (currentIdx+1) % factories.length;
      current = factories[currentIdx]();
      addChildAt(current,0);
      current.resize();
   }

   function resize()
   {
      current.resize();
      nextButton.x = Std.int(stage.stageWidth - nextButton.width*1.5);
      nextButton.y = Std.int(stage.stageHeight - nextButton.height*1.5);
   }
}
