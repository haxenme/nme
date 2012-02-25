package nme.net;
#if js


import nme.events.EventDispatcher;
import nme.events.Event;
import nme.events.DataEvent;

class XMLSocket extends EventDispatcher {

	private var _socket: Dynamic;

	public var connected(default, null): Bool;
	public var timeout: Int;

	public function new(?host: String, port: Int = 80): Void {
		super();
		if (host != null)
			connect(host, port);
	}

	public function close(): Void {
		_socket.close();
	}

	public function connect(host: String, port: Int): Void {
		_socket = untyped __js__("new WebSocket(\"ws://\" + host + \":\" + port)");
		_socket.onopen = onOpenHandler;
		_socket.onmessage = onMessageHandler;
	}

	private function onOpenHandler(_): Void {
		dispatchEvent(new Event(Event.CONNECT));
	}

	private function onMessageHandler(msg: Dynamic): Void {
		dispatchEvent(new DataEvent(DataEvent.DATA, false, false, msg.data));
	}

	public function send(object: Dynamic): Void {
		_socket.send(object);
	}

}


#else
typedef XMLSocket = flash.net.XMLSocket;
#end