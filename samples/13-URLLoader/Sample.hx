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
import nme.net.URLVariables;
import nme.net.URLRequestMethod;

  
class Sample extends Sprite {
    private var postTextField:TextField;
    private var xmlTextField:TextField;
    private var externalXML:Xml;    
    private var loader:URLLoader;

    public function new()
	 {
	     super();
		  flash.Lib.current.addChild(this);

        //var request:URLRequest = new URLRequest("http://www.w3schools.com/xml/cd_catalog.xml");
        var request:URLRequest = new URLRequest("https://twitter.com/");
        #if !flash
        request.basicAuth("basic","basic");
        request.cookieString = "name=value";
        //request.verbose = true;
        #end
        loader = new URLLoader();
        loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
        loader.addEventListener(ProgressEvent.PROGRESS, onProgress);

        try {
            loader.load(request);
        }
        catch (error:SecurityError)
        {
            trace("A SecurityError has occurred.");
        }

        postTextField = new TextField();
        postTextField.x = 10;
        postTextField.y = 10;
        postTextField.background = true;
        postTextField.autoSize = TextFieldAutoSize.LEFT;

        addChild(postTextField);


        xmlTextField = new TextField();
        xmlTextField.x = 10;
        xmlTextField.y = 100;
        xmlTextField.background = true;
        xmlTextField.autoSize = TextFieldAutoSize.LEFT;

        addChild(xmlTextField);

        //var t0 = haxe.Timer.stamp();
        //addEventListener( Event.ENTER_FRAME, function(_) trace( haxe.Timer.stamp()-t0 ) );

        var image_loader = new flash.display.Loader();
        image_loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
            var bmp:flash.display.Bitmap = cast image_loader.content;
            trace("Loaded image " + bmp.bitmapData.width + "x" + bmp.bitmapData.height);
        });

        var request:URLRequest = new URLRequest("http://upload.wikimedia.org/wikipedia/en/7/72/Example-serious.jpg");
        image_loader.load(request);
        image_loader.x = 10;
        image_loader.y = 180;
        image_loader.scaleX = 0.5;
        image_loader.scaleY = 0.5;
        addChild(image_loader);

        var post = new URLRequest("http://www.snee.com/xml/crud/posttest.cgi");
        var vars = new URLVariables();
        vars.fname = "Milla";
        vars.lname = "Jovovich";
        vars.submit = "1";
        post.method = URLRequestMethod.POST;
        post.data = vars;
        //post.verbose = true;
        var postLoad = new URLLoader();
        postLoad.addEventListener(Event.COMPLETE, function(_) {
           postTextField.htmlText = postLoad.data.toString();
        } );

        try {
            postLoad.load(post);
        }
        catch (error:SecurityError)
        {
            trace("A SecurityError has occurred.");
        }

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

