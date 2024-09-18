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
import nme.display.*;

  
class Sample extends Sprite
{
    private var postTextField:TextField;
    private var xmlTextField:TextField;
    private var externalXML:Xml;
    private var loader:URLLoader;

    public function new()
    {
        super();
        //nme.Lib.current.addChild(this);

        var request:URLRequest = new URLRequest("http://help.websiteos.com/websiteos/example_of_a_simple_html_page.htm");
        request.userAgent = "haxe test";
        //request.basicAuth("basic","basic");
        //request.cookieString = "name=value";
        //request.verbose = true;

        loader = new URLLoader();
        loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
        loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
        loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
        trace('Request:$request');

        try {
            loader.load(request);
            trace('Loader:$loader');
        }
        catch (error:SecurityError)
        {
            trace("A SecurityError has occurred.");
        }

        postTextField = new TextField();
        postTextField.x = 10;
        postTextField.y = 10;
        postTextField.background = true;
        postTextField.border = true;
        postTextField.width = 400;
        postTextField.height = 240;
        //postTextField.autoSize = TextFieldAutoSize.LEFT;
        postTextField.text = "post ...";

        addChild(postTextField);


        xmlTextField = new TextField();
        xmlTextField.x = 10;
        xmlTextField.y = 260;
        xmlTextField.background = true;
        xmlTextField.border = true;
        xmlTextField.width = 400;
        xmlTextField.height = 240;
        //xmlTextField.autoSize = TextFieldAutoSize.LEFT;
        xmlTextField.text = "xml data...";

        addChild(xmlTextField);

        //var t0 = haxe.Timer.stamp();
        //addEventListener( Event.ENTER_FRAME, function(_) trace( haxe.Timer.stamp()-t0 ) );

        var image_loader = new nme.display.Loader();
        image_loader.contentLoaderInfo.addEventListener(nme.events.Event.COMPLETE, function(_) {
            var bmp:nme.display.Bitmap = cast image_loader.content;
            trace("Loaded image " + bmp.bitmapData);
        });
        image_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, e -> {
             var tf = new TextField();
             tf.text = "Error:" + e;
             image_loader.scaleX = image_loader.scaleY = 1.0;
             image_loader.addChild(tf);
          });

        var request:URLRequest = new URLRequest("https://avatars.githubusercontent.com/u/2187351",{s:200,v:4} );
        image_loader.load(request);
        image_loader.x = 10;
        image_loader.y = 510;
        image_loader.scaleX = 0.25;
        image_loader.scaleY = 0.25;
        addChild(image_loader);

        var post = new URLRequest("https://httpbin.org/anything");
        var vars = new URLVariables();
        vars.fname = "Milla";
        vars.lname = "Jovovich";
        vars.submit = "1";
        post.method = URLRequestMethod.POST;
        post.data = vars;
        //post.verbose = true;
        var postLoad = new URLLoader();
        postLoad.addEventListener(IOErrorEvent.IO_ERROR, e ->
           postTextField.htmlText = "Error in post:" + e + " " + post);
        postLoad.addEventListener(Event.COMPLETE, function(_) {
           postTextField.htmlText = postLoad.data.toString();
        } );

        try
        {
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

    private function loaderCompleteHandler(event:Event):Void
    {
       trace("loaderCompleteHandler!");
       try
       {
          xmlTextField.text = loader.data;
       }
       catch (e:TypeError)
       {
          trace("Could not load the XML file.");
       }
    }


    private function errorHandler(e:IOErrorEvent):Void
    {
       trace("error " + e);
       xmlTextField.text = "Error:" + e.text;
       #if wasm
       xmlTextField.text += " Perhaps CORS - check developer console";
       #end
    }
}

