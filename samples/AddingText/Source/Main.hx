import nme.display.Sprite;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.Assets;


class Main extends Sprite {
	
	
	public function new () {
		
		super ();
		
		var format = new TextFormat (Assets.getFont ("assets/KatamotzIkasi.ttf").fontName, 30, 0x7A0026);
		var textField = new TextField ();
		
		textField.defaultTextFormat = format;
		textField.embedFonts = true;
		textField.selectable = false;
		
		textField.x = 50;
		textField.y = 50;
		textField.width = 200;
		
		textField.text = "Hello World";
		
		addChild (textField);
		
	}
	
	
}