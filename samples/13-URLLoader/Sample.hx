import flash.Lib;
import flash.display.Sprite;
import flash.events.Event;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.errors.SecurityError;
import flash.errors.TypeError;

  
class Sample extends Sprite {
    private var xmlTextField:TextField;
    private var externalXML:Xml;    
    private var loader:URLLoader;

    public function new()
	 {
	     super();
		  flash.Lib.current.addChild(this);
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

        var image_loader = new flash.display.Loader();
        image_loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
            var bmp:flash.display.Bitmap = cast image_loader.content;
            trace("Loaded image " + bmp.bitmapData.width + "x" + bmp.bitmapData.height);
        });

        var request:URLRequest = new URLRequest("http://upload.wikimedia.org/wikipedia/en/7/72/Example-serious.jpg");
        image_loader.load(request);
        image_loader.x = 180;
        image_loader.y = 180;
        addChild(image_loader);
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

