
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
class DragSpriteLockCenter extends Sprite {
	private var back:Bitmap;
	
	private function construct () { 
	
		var backS:Sprite = new Sprite();
		back.x = -back.width / 2;
		back.y = -back.height / 2;
		backS.addChild(back);
		//backS.x = stage.stageWidth / 2;
		//backS.y = stage.stageHeight / 2;
		backS.x = 180;
		backS.y = 180;

		//	trace("Back.x="+back.x);
			//trace("Back.y=" + back.y);
			//trace("Back.scaleX=" + back.scaleX);
		backS.addEventListener(MouseEvent.MOUSE_DOWN, clicked);
		backS.buttonMode = true;
		backS.useHandCursor = true;

		addChild(backS);
		
		

	}
	private function clicked(e:MouseEvent)
		{	
			// show release areas
			// start dragging clicked object
			var object:Sprite = new Sprite();
			var object:Sprite = cast(e.currentTarget, Sprite);
			object.buttonMode = false;
			object.useHandCursor = false;
			object.removeEventListener(MouseEvent.MOUSE_DOWN, clicked);
			object.mouseEnabled = false;
			object.startDrag(true);
			
			e.stopImmediatePropagation();
			//stage.addEventListener(MouseEvent.CLICK, drop);
	
			}	
	

	private function onLoadedBack(e:Event) {
		var loader:LoaderInfo = cast(e.target, LoaderInfo ); 
		back= cast(loader.content, Bitmap); 
		construct();
	}
	
	private function this_onAddedToStage (event:Event):Void {

		var loader:Loader = new Loader();
		var file:String = "enemy.png";
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
		
		Lib.current.addChild (new DragSpriteLockCenter ());
		
	}
	
	
}
