import nme.Lib;
import nme.display.Sprite;
import nme.events.Event;
import nme.net.URLLoader;
import nme.net.URLRequest;
import nme.text.TextField;
import nme.text.TextFieldAutoSize;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.errors.SecurityError;
import nme.errors.TypeError;

  
class Sample extends Sprite {
    private var xmlTextField:TextField;
    private var externalXML:Xml;    
    private var loader:URLLoader;

    public function new()
	 {
	     super();
		  nme.Lib.current.addChild(this);
        xmlTextField = new TextField();
        var request:URLRequest = new URLRequest("http://www.w3schools.com/xml/cd_catalog.xml");

        loader = new URLLoader();

        try {
            loader.load(request);
        }
        catch (error:SecurityError)
        {
            trace("A SecurityError has occurred.");
        }

        loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
        loader.addEventListener(ProgressEvent.PROGRESS, onProgress);

        xmlTextField.x = 10;
        xmlTextField.y = 10;
        xmlTextField.background = true;
        xmlTextField.autoSize = TextFieldAutoSize.LEFT;

        addChild(xmlTextField);
    }

	 function onProgress(event:ProgressEvent)
	 {
	    trace("Loaded " + event.bytesLoaded + "/" + event.bytesTotal );
	 }

    private function loaderCompleteHandler(event:Event):Void {

            try {
                xmlTextField.text = loader.data;
            } catch (e:TypeError) {
                trace("Could not load the XML file.");
            }
    }


    private function errorHandler(e:IOErrorEvent):Void {
        xmlTextField.text = "Error:" + e.text;
    }

	 public static function main()
	 {
      new Sample();
	 }
}

