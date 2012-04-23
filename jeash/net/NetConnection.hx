/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash.net;

import jeash.events.EventDispatcher;
import jeash.events.NetStatusEvent;


class NetConnection extends EventDispatcher
{
	public var connect:Dynamic;
	
	public static inline var CONNECT_SUCCESS:String 	= "NetConnection.Connect.Success";
	
	public function new() : Void
	{
		super();
		connect = Reflect.makeVarArgs(js_connect);
		//should set up bidirection connection with Flash Media Server or Flash Remoting
		//currently does nothing
	}

	private function js_connect (val:Array<Dynamic>) : Void
	{
		if (val.length > 1 || val[0] != null)
		throw "jeash can only connect in 'http streaming' mode";
		
		//dispatch events:
		var info:Dynamic = { code:NetConnection.CONNECT_SUCCESS } ;
		var ev:NetStatusEvent = new NetStatusEvent(NetStatusEvent.NET_STATUS, false, true, info );
		this.dispatchEvent(ev);
		
		//connection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
	}

}