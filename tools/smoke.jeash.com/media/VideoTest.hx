package ;

import flash.Lib;
import flash.display.Sprite;
import flash.media.Video;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.events.NetStatusEvent;
import flash.events.Event;


/**
 * ...
 * @author Valentin Smirnov (smival)
 */

class VideoTest extends Sprite 
{
	private var URL:String = "haxe.webm";
	private var _ns:NetStream;
	private var _nc:NetConnection;
	private var _v:Video;
	
	public function new() 
	{
		super();
		addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(e) 
	{
		// note: this is really only a compile check + a manual
		// test, video codecs are not supported in phantomjs.

		#if js untyped window.phantomTestResult = true; #end
		
		// entry point

		_nc = new NetConnection();
			_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
			_nc.connect(null);

	}
	
	private function createStream():Void
	{
		_ns = new NetStream(_nc);
			_ns.play(URL);
		
		_v = new Video(200, 200);
			_v.attachNetStream(_ns);
			addChild(_v);
	}
	
	private function onNetStatusEvent(e:NetStatusEvent):Void
	{
		switch (e.info.code) 
		{
			case "NetConnection.Connect.Success":
				createStream();
			case "NetStream.Play.StreamNotFound":
				Lib.trace("Stream not found: " + URL);
			
			case "NetStream.Play.Stop":
				Lib.trace("stream stopped");
				_ns.play(URL);
		}
	}
	
	static public function main() 
	{
		var stage = Lib.current.stage;
			stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
			stage.align = flash.display.StageAlign.TOP_LEFT;
		
		Lib.current.addChild(new VideoTest());
	}
	
}
