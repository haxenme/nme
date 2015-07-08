import nme.display.Sprite;
import nme.display.Shape;
import nme.display.SimpleButton;
import nme.display.Stage;
import nme.geom.Point;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.text.TextFormatAlign;
import nme.media.Sound;
import nme.media.SoundChannel;
import nme.Assets;

class Slider extends Sprite
{
   var boxWidth:Int;
   var boxHeight:Int;
   public var max:Float;
   public var active(default,set):Bool;
   public var position(default,set):Float;
   public var onPosition:Float->Void;
   var captureStage:Stage;

   public function new()
   {
      super();
      boxWidth = boxHeight = 0;
      max = 100.0;
      position = 0.0;
      active = false;
      captureStage = null;
      addEventListener(MouseEvent.MOUSE_DOWN, onDown);
   }

   public function onDown(event:MouseEvent)
   {
      //if (!active) return;
      if (onPosition!=null && captureStage==null)
      {
         captureStage = stage;
         captureStage.addEventListener( MouseEvent.MOUSE_MOVE, onMove );
         captureStage.addEventListener( MouseEvent.MOUSE_UP, onUp );
      }
      if (onPosition!=null)
         onPosition(mouseToPos(event));
   }

   public function onMove(event:MouseEvent)
   {
      if (captureStage!=null && onPosition!=null)
         onPosition(mouseToPos(event));
   }

   public function onUp(event:MouseEvent)
   {
      if (captureStage!=null)
      {
         captureStage.removeEventListener( MouseEvent.MOUSE_MOVE, onMove );
         captureStage.removeEventListener( MouseEvent.MOUSE_UP, onUp );
         captureStage = null;
      }
   }
 

   function mouseToPos(event:MouseEvent)
   {
      if (boxWidth==0)
         return 0.0;
      var lx = globalToLocal( new Point( event.stageX, event.stageY ) ).x;
      var pos = Math.min( Math.max(0,lx)*max/boxWidth, max );
      return pos;
   }

   public function layout(inWidth:Float, inHeight:Float)
   {
      boxWidth = Std.int(inWidth);
      boxHeight = Std.int(inHeight);
      render();
   }

   public function render()
   {
      var gfx = graphics;
      gfx.clear();
      if (position!=0.0 && max>0.0)
      {
         gfx.beginFill(active ? 0xa0ffa0 : 0xeeeeee);
         gfx.drawRect(0,0, boxWidth*position/max, boxHeight );
         gfx.endFill();
      }
      gfx.beginFill(0xffffff,0.0);
      gfx.lineStyle(1,0xa0a0a0);
      gfx.drawRect(0.5,0.5, boxWidth, boxHeight );
   }

   public function set_active(inActive:Bool) : Bool
   {
      active = inActive;
      if (boxWidth>0)
         render();
      return active;
   }

   public function set_position(inPos:Float) : Float
   {
      position = Math.min(inPos,max);
      if (boxWidth>0)
         render();
      return position;
   }
}


class AudioPage extends Sprite
{
   var asset:String;
   var play:SimpleButton;
   var slider:Slider;
   var durationText:TextField;
   var sound:Sound;
   var soundChannel:SoundChannel;
   var listening:Bool;

   public function new(inAsset:String)
   { 
      super();
      name = asset = inAsset;

      listening = false;

      sound = Assets.getSound(asset);

      play = new SimpleButton( createPlay("up"), createPlay("over"), createPlay("down"), createPlay("up") );
      addChild(play);
      play.addEventListener(MouseEvent.CLICK, function(_) onPlay() );
      var s = AudioTest.getScale();
      play.y = Std.int(20*s);
      play.x = Std.int(10*s);

      slider = new Slider();
      slider.onPosition = onPosition;
      addChild(slider);

      durationText = new TextField();
      var fmt = new TextFormat();
      fmt.color = 0xa0a0a0;
      fmt.font = "_sans";
      fmt.size = 10 * s;
      fmt.align = TextFormatAlign.RIGHT;
      durationText.defaultTextFormat = fmt;

      if (sound==null)
         durationText.text = "Error - no sound";
      else
      {
         durationText.text = Std.int(sound.length*0.1)*0.01 + "s";
         slider.max = sound.length*0.001;
      }
      durationText.mouseEnabled = false;
      addChild(durationText);
   }

   function onPosition(inPosition:Float)
   {
      if (soundChannel!=null)
      {
         soundChannel.stop();
         soundChannel = sound.play(inPosition*1000.0, 0, null);
      }
   }

   public function onPlay()
   {
      if (sound!=null)
      {
         soundChannel = sound.play(0.0, 0, null);
         if (soundChannel!=null)
         {
            var ch = soundChannel;
            soundChannel.addEventListener( Event.SOUND_COMPLETE, function(_) onComplete(ch) );
            if (!listening)
            {
               listening = true;
               slider.active = true;
               addEventListener( Event.ENTER_FRAME, onUpdate );
            }
         }
      }
   }

   public function onUpdate(_)
   {
      if (soundChannel!=null)
         slider.position = soundChannel.position*0.001;
   }

   public function onComplete(inChannel:SoundChannel)
   {
      if (inChannel==soundChannel)
      {
         removeEventListener( Event.ENTER_FRAME, onUpdate );
         slider.active = false;
         listening = false;
         soundChannel = null;
      }
   }


   function createPlay(state:String)
   {
      var shape = new Shape();

      var gfx = shape.graphics;
      gfx.lineStyle(3,0xa0a0a0);
      gfx.beginFill(state=="up" ? 0xffffff :
                    state=="down" ? 0xeeeeee :
                    0xeeeeff );
 
      var s = AudioTest.getScale();
      gfx.drawCircle( 40*s,   40*s, 40*s );
      gfx.beginFill( 0xffffff);
      gfx.moveTo( (40-10)*s, (40-20)*s );
      gfx.lineTo( (40-10)*s, (40+20)*s );
      gfx.lineTo( (40+20)*s, (40)*s );
      gfx.lineTo( (40-10)*s, (40-20)*s );
      return shape;
   }


   public function layout(inWidth:Float, inHeight:Float)
   {
      var s = AudioTest.getScale();
    
      slider.x = Std.int(10*s);
      slider.y = Std.int(120*s);
      slider.layout( inWidth - s*20, s*20 );

      durationText.x = slider.x;
      durationText.y = slider.y - durationText.textHeight - 5*s;
      durationText.width = inWidth-s*20;
      durationText.height = s*20;
   }
}

class AudioTest extends Sprite
{
   static var pageNames = [ "Ogg", "Midi", "Wav", "Mp3", "Sync", "Async" ];
   var currentName:String;
   var titles:Array<TextField> = [];
   var tabs:Array<Sprite> = [];
   var pages:Array<AudioPage> = [];
   var currentPage:AudioPage;
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

         if (Assets.exists(page))
            pages.push( new AudioPage(page) );
      }

      stage.addEventListener( Event.RESIZE, function(_) layout() );

      setTab(pages[0].name);
   }

   public static function getScale()
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
      if (inName!=currentName)
      {
         currentName = inName;
         layout();
         if (currentPage!=null)
            removeChild(currentPage);
         currentPage = null;
         for(page in pages)
            if (page.name == currentName)
            { 
               currentPage = page;
               addChild(currentPage);
               break;
            }
         layout();
      }
   }

   function canPlay(inFormat:String)
   {
      if (Assets.exists(inFormat))
         return true;
      if (inFormat=="Sync")
         return true;
      if (inFormat=="Async")
         return #if flash false #else true #end ;
      return false;
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
                        page==currentName ? textFormatFg : textFormatBg );

         var gfx = tab.graphics;
         gfx.clear();
         gfx.beginFill( 0xffffff, page==currentName ? 1 : 0 );
         gfx.drawRect(0,0,fieldW, fieldH);
         tab.y = y;
         y+=fieldH;
      }

      if (currentPage!=null)
      {
         currentPage.x = fieldW;
         currentPage.y = 0;
         currentPage.layout(w-fieldW, h);
      }
   }
}

