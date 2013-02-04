package ;
import flash.net.URLLoaderDataFormat;
import flash.events.Event;
import flash.net.URLLoader;
import haxe.Log;
import haxe.unit.TestCase;
import haxe.unit.TestRunner;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;
import flash.utils.ByteArray;

/**
 * ...
 * @author deep <system.grand@gmail.com>
 */
@:keep class URLRequestTest
{

	public function new() 
	{
		
	}
	
	static function main()
	{
		#if js
		TestRunner.print = function (a) untyped js.Boot["__trace"](a, null);
		#end
		var t = new TestRunner();
		t.add(new BaseTests());
		var res = t.run();
		#if js untyped window.phantomTestResult = res; #end
	}
	
}

@:keep class BaseTests extends TestCase
{
	function testURLRequest()
	{
		var r = new URLRequest();
		
		assertEquals(r.requestHeaders.length, 0);
		assertEquals(r.contentType, null);
		assertEquals(r.method, URLRequestMethod.GET);
		assertEquals(r.data, null);
		assertEquals(r.url, null);
	}
}
