package browser.net;
#if js


import browser.events.DataEvent;
import browser.events.Event;
import browser.events.EventDispatcher;


class XMLSocket extends EventDispatcher {
	
	
	public var connected(default, null):Bool;
	public var timeout:Int;
	
	private var _socket:Dynamic;
	
	
	public function new(host:String = null, port:Int = 80):Void {
		
		super();
		
		if (host != null) {
			
			connect(host, port);
			
		}
		
	}
	
	
	public function close():Void {
		
		_socket.close();
		
	}
	
	
	public function connect(host: String, port:Int):Void {
		
		_socket = untyped __js__("new WebSocket(\"ws://\" + host + \":\" + port)");
		_socket.onopen = onOpenHandler;
		_socket.onmessage = onMessageHandler;
		
	}
	
	
	public function send(object:Dynamic):Void {
		
		_socket.send(object);
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function onMessageHandler(msg:Dynamic):Void {
		
		dispatchEvent(new DataEvent(DataEvent.DATA, false, false, msg.data));
		
	}
	
	
	private function onOpenHandler(_):Void {
		
		dispatchEvent(new Event(Event.CONNECT));
		
	}
	
	
}


#end