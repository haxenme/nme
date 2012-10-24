package ;
import flash.net.URLRequest;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
class DisplayHierarchy{
	public static function main():Void{
		var m:MovieClip = Lib.current;

		// This is where the green square and png image will be displayed
		var bottomContainer:Sprite = new Sprite();
		bottomContainer.name = "bottomContainer";
		m.addChild(bottomContainer);

		// The red box should be displayed above the bottomContainer
		var topContainer:Sprite = new Sprite();
		topContainer.name = "topContainer";
		topContainer.graphics.beginFill(0xff0000);
		topContainer.graphics.drawRect(0,0,100,100);
		m.addChild(topContainer);

		// Add the green square which has to be displayed below the red box
		var bottomChild:Sprite = new Sprite();
		bottomChild.name = "bottomChild";
		bottomChild.graphics.beginFill(0x00ff00);
		bottomChild.graphics.drawRect(0,0,200,200);
		bottomContainer.addChild(bottomChild);

		bottomContainer.x = bottomContainer.y = 50;

		// Load our image
		var l:Loader = new Loader();
		l.contentLoaderInfo.addEventListener("complete", function(e:Event):Void{
			// Add the image to our bottom container. If you add the loader - and not the content - directly to the container it works
			bottomContainer.addChild(l.content);
		});
		l.load(new URLRequest("test.png"));
	}
}
