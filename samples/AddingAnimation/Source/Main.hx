import com.eclecticdesignstudio.motion.easing.Elastic;
import com.eclecticdesignstudio.motion.Actuate;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.Assets;
import nme.Lib;


class Main extends Sprite {
	
	
	public function new () {
		
		super ();
		
		var bitmap = new Bitmap (Assets.getBitmapData ("assets/nme.png"));
		bitmap.x = - bitmap.width / 2;
		bitmap.y = - bitmap.height / 2;
		bitmap.smoothing = true;
		
		var container = new Sprite ();
		container.addChild (bitmap);
		container.alpha = 0;
		container.scaleX = 0;
		container.scaleY = 0;
		container.x = Lib.current.stage.stageWidth / 2;
		container.y = Lib.current.stage.stageHeight / 2;
		
		addChild (container);
		
		Actuate.tween (container, 3, { alpha: 1 } );
		Actuate.tween (container, 4, { scaleX: 1, scaleY: 1 } ).delay (0.4).ease (Elastic.easeOut);
		
	}
	
	
}