package browser.net;


import browser.events.EventDispatcher;
import browser.events.NetStatusEvent;


class NetConnection extends EventDispatcher {
	
	
	public static inline var CONNECT_SUCCESS:String = "connectSuccess";
	
	public var connect:Dynamic;
	
	
	public function new ():Void {
		
		super ();
		
		connect = Reflect.makeVarArgs (js_connect);
		//should set up bidirection connection with Flash Media Server or Flash Remoting
		//currently does nothing
		
	}
	
	
	private function js_connect (val:Array<Dynamic>):Void {
		
		if (val.length > 1 || val[0] != null)
			throw "nme can only connect in 'http streaming' mode";
		
		var info:Dynamic = { code:NetConnection.CONNECT_SUCCESS };
		var ev:NetStatusEvent = new NetStatusEvent (NetStatusEvent.NET_STATUS, false, true, info);
		this.dispatchEvent (ev);
		
		//connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		
	}
	
	
}