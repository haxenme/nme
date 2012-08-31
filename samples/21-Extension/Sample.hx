import flash.text.TextFieldAutoSize;
import flash.display.Sprite;
import flash.text.TextField;
import nme.JNI;

class Sample extends Sprite
{
	public static function main()
	{
		new Sample();
	}

	static inline var DEFAULT_BROWSER_URL = "http://www.google.com";

	var urlText:TextField;
	var launchBrowserButton:TextField;

	function new()
	{
		super();

		flash.Lib.current.addChild(this);
		createGUI();
	}

	function createGUI()
	{
		urlText = new TextField();
		urlText.text = DEFAULT_BROWSER_URL;
		urlText.type = flash.text.TextFieldType.INPUT;
		urlText.height = 18;
		urlText.width = 200;
		urlText.x = 20;
		urlText.y = 20;
		urlText.border = true;
		urlText.borderColor =  0x000000;
		addChild(urlText);

		launchBrowserButton = new TextField();
		launchBrowserButton.htmlText = "<font size='24'>Launch Browser</font>";
		launchBrowserButton.width = 180;
		launchBrowserButton.height = 40;
		launchBrowserButton.y = 100;
		launchBrowserButton.border = true;
		launchBrowserButton.borderColor =  0xff0000;
		launchBrowserButton.selectable = false;

		//		launchBrowserButton.addEventListener(flash.events.MouseEvent.CLICK, function(_) { launchChromeBrowser(); });
		launchBrowserButton.addEventListener(flash.events.MouseEvent.CLICK, function(_) { launchEmbeddedBrowser(); });

		addChild(launchBrowserButton);
	}

	function launchChromeBrowser()
	{
		launchBrowser("launchChrome", urlText.text);
	}

	function launchEmbeddedBrowser()
	{
		launchBrowser("launchEmbedded", urlText.text);
	}

	function launchBrowser(methodName:String, url:String)
	{
		var launchBrowser:Dynamic = JNI.createStaticMethod("nme/BrowserLauncher", methodName, "(Ljava/lang/String;)V");
		if (launchBrowser != null)
			nme.Lib.postUICallback( function() { launchBrowser(url); } );
	}
}
