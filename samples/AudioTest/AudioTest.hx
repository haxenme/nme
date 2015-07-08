import nme.display.Sprite;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;

class AudioTest extends Sprite
{
   static var pageNames = [ "Ogg", "Midi", "Wav", "Mp3", "Sync", "Async" ];
   var currentPage = "Ogg";
   var titles:Array<TextField> = [];
   var tabs:Array<Sprite> = [];
   var textFormatBg:TextFormat;
   var textFormatFg:TextFormat;
   var textFormatDisabled:TextFormat;

   public function new()
   {
      super();

      textFormatFg = createTextFormat(0x3030ff);
      textFormatBg = createTextFormat(0x000000);
      textFormatDisabled = createTextFormat(0xa0a0a0);

      for(page in pageNames)
      {
         var tab = new Sprite();
         addChild(tab);
         tabs.push(tab);
         if (canPlay(page))
            tab.addEventListener(MouseEvent.CLICK, function(_) setTab(page) );

         var tf = new TextField();
         tf.text = page;
         tab.addChild(tf);
         titles.push(tf);
         tf.mouseEnabled = false;
      }

      stage.addEventListener( Event.RESIZE, function(_) layout() );
      layout();
   }

   function getScale()
      return nme.ui.Scale.getFontScale();

   function createTextFormat(inColour:Int)
   {
      var result = new TextFormat();
      result.color = inColour;
      result.font = "_sans";
      result.size = 24 * getScale();
      result.align = TextFormatAlign.RIGHT;
      return result;
   }

   function setTab(inName:String)
   {
      if (inName!=currentPage)
      {
         currentPage = inName;
         layout();
      }
   }

   function canPlay(inFormat:String)
   {
      return inFormat!="Mp3";
   }

   function layout()
   {
      var w = stage.stageWidth;
      var h = stage.stageHeight;
      var scale = getScale();

      var fieldH = Std.int( 40*scale );
      var fieldW = Std.int( 120*scale );

      var gfx = graphics;
      gfx.clear();
      gfx.beginFill(0x606060);
      gfx.drawRect(0,0,fieldW,h);

      var y = 0;
      for(i in 0...tabs.length)
      {
         var page = pageNames[i];
         var tab = tabs[i];
         var tf = titles[i];
         tf.width = fieldW;
         tf.height = fieldH;

         tf.setTextFormat( !canPlay(page) ? textFormatDisabled :
                        page==currentPage ? textFormatFg : textFormatBg );

         var gfx = tab.graphics;
         gfx.clear();
         gfx.beginFill( 0xffffff, page==currentPage ? 1 : 0 );
         gfx.drawRect(0,0,fieldW, fieldH);
         tab.y = y;
         y+=fieldH;
      }
   }
}

