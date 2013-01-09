import nme.display.Bitmap;
import nme.display.Sprite;
import nme.Assets;
import nme.Lib;


class Main extends Sprite {
	
	
	public function new () {
		
		super ();
		
		var bitmap = new Bitmap (Assets.getBitmapData ("assets/nme.png"));
		addChild (bitmap);
		
		bitmap.x = (Lib.current.stage.stageWidth - bitmap.width) / 2;
		bitmap.y = (Lib.current.stage.stageHeight - bitmap.height) / 2;
		
	}
	
	
}