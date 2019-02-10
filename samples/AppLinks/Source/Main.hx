import nme.events.AppLinkEvent;
import nme.text.TextField;
import nme.text.TextFormat;
import nme.display.Bitmap;
import nme.display.Sprite;
import nme.Assets;
import nme.Lib;

class Main extends Sprite {

    public function new () {
        
        super ();

        var textField = new TextField ();

        textField.embedFonts = true;
        textField.selectable = false;

        textField.x = 50;
        textField.y = 50;
        textField.width = 400;
        textField.text = "Please view the README for instructions.";

        addChild (textField);
        
        stage.addEventListener(AppLinkEvent.APP_LINK, onAppLink);
    }
    
    private function onAppLink(event:AppLinkEvent):Void {
        trace("Received App Link: " + event.url);
    }
}