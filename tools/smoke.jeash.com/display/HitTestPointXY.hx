
import flash.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.Lib;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.display.Loader;
import flash.display.LoaderInfo;

/**
 * @author pauLE
 */
class HitTestPointXY extends Sprite {
	private var back:Bitmap;
	private var back1:Sprite;
	private var bitmap1:Bitmap;

	private function construct () { 
	
		back1 = new Sprite();
	
		bitmap1 = new Bitmap(back.bitmapData);
		
		//bitmap1.x = -back.width / 2;
		//bitmap1.y = -back.height / 2;
		back1.addChild(bitmap1);
		back1.x = 40;
		back1.y = 40;
		stage.addEventListener(MouseEvent.MOUSE_DOWN, clicked);
		

		addChild(back1);

		
		

	}
	private function clicked(e:MouseEvent)
		{	
			if (back1.hitTestPoint(mouseX, mouseY))
				trace("hitTestPoint(mouseX, mouseY):hit");
			else
				trace("hitTestPoint(mouseX, mouseY):not hit");
			if ((mouseX >=	back1.x) && (mouseX <= (back1.x  +back1.width )))
				if ((mouseY >= back1.y) && (mouseY <= (back1.y + back1.height)))
					trace("my hitTest: hit");
				else
					trace("my hitTest: not hit");
			else
					trace("my hitTest: not hit");
			
			trace("bitmap1 hitTestPoint w/ shapeFlag: " + bitmap1.hitTestPoint(mouseX, mouseY, true));
			trace("back1 hitTestPoint w/ shapeFlag: " + back1.hitTestPoint(mouseX, mouseY, true));
			#if js 
			untyped window.phantomTestResult = bitmap1.hitTestPoint(mouseX, mouseY, true) && back1.hitTestPoint(mouseX, mouseY, true);
			#end
		}
	private function onLoadedBack(e:Event) {
		var loader:LoaderInfo = cast(e.target, LoaderInfo ); 
		back= cast(loader.content, Bitmap); 
		construct();
	}
	
	private function this_onAddedToStage (event:Event):Void {

		var loader:Loader = new Loader();
		var file:String = "back.png";
		loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onLoadedBack );
		loader.load(new URLRequest(file));
	}
	private function initialize ():Void {
		
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		
	}
	
	
	
	
	// Entry point

	
	public function new () {
		
		super ();
		addEventListener (Event.ADDED_TO_STAGE, this_onAddedToStage);
		
		initialize ();
		
		
		
	}
	
	public static function main () {
		
		Lib.current.addChild (new HitTestPointXY ());
		
	}
	
	
}
