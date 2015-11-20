import nme.display.Bitmap;
import nme.display.Sprite;
import nme.Assets;
import nme.Lib;


class Main extends Sprite {

	public function new () {
		super ();
        if(Assets.getText('someTextFile.txt') == 'someTextFile.txt')
		    Sys.exit(0);
        Sys.exit(1);
	}
	
	
}