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
import jeash.events.Event;
import jeash.events.DataEvent;

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
