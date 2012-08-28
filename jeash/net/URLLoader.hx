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

import jeash.events.Event;
import jeash.events.EventDispatcher;
import jeash.events.IOErrorEvent;
import jeash.events.HTTPStatusEvent;
import jeash.events.ProgressEvent;
import jeash.errors.IOError;
import jeash.utils.ByteArray;

import jeash.Html5Dom;
import js.Dom;
import js.Lib;
import js.XMLHttpRequest;

typedef XMLHttpRequestProgressEvent = Dynamic;

class URLLoader extends EventDispatcher
{
	public var bytesLoaded:Int;
	public var bytesTotal:Int;
	public var data:Dynamic;
	public var dataFormat:URLLoaderDataFormat;

	public function new(?request:URLRequest) {
		super();
		bytesLoaded = 0;
		bytesTotal = 0;
		dataFormat = URLLoaderDataFormat.TEXT;
		if(request != null)
			load(request);
	}

	public function close() { }

	public function load(request:URLRequest) {
		if( request.contentType == null )
			switch (dataFormat) {
				case BINARY:
					request.requestHeaders.push(new URLRequestHeader("Content-Type","application/octet-stream"));
				default:
					request.requestHeaders.push(new URLRequestHeader("Content-Type","application/x-www-form-urlencoded"));
			}
		else
			request.requestHeaders.push(new URLRequestHeader("Content-Type", request.contentType));

		requestUrl(
			request.url,
			request.method,
			request.data,
			request.requestHeaders
		);
	}

	function onData (_) {
		var content:Dynamic = getData();

		if (Std.is(content, String)) {
			this.data = Std.string(content);
		} else if (Std.is(content, ByteArray)) {
			this.data = ByteArray.jeashOfBuffer(content);
		} else {
			switch (dataFormat) {
				case BINARY:
					this.data = ByteArray.jeashOfBuffer(content);
				default:
					var bytes:nme.utils.ByteArray = ByteArray.jeashOfBuffer(content);
					if (bytes != null && bytes.length > 0) {
						this.data = Std.string(bytes.readUTFBytes(bytes.length));
					} else {
						this.data = Std.string(content);
					}
			}
		}

		var evt = new Event(Event.COMPLETE);
		evt.currentTarget = this;
		dispatchEvent(evt);
	}

	function onError (msg:String) {
		var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		evt.text = msg;
		evt.currentTarget = this;
		dispatchEvent(evt);
	}

	function onOpen () {
		var evt = new Event(Event.OPEN);
		evt.currentTarget = this;
		dispatchEvent(evt);
	}

	function onStatus (status:Int) {
		var evt = new HTTPStatusEvent(HTTPStatusEvent.HTTP_STATUS, false, false, status);
		evt.currentTarget = this;
		dispatchEvent(evt);
	}

	function onProgress (event:XMLHttpRequestProgressEvent) {
		var evt = new ProgressEvent(ProgressEvent.PROGRESS);
		evt.currentTarget = this;
		evt.bytesLoaded = event.loaded;
		evt.bytesTotal = event.total;
		dispatchEvent(evt);
	}

	function registerEvents( subject:EventTarget ) {
		var self = this;

		if (untyped __js__("typeof XMLHttpRequestProgressEvent") != __js__('"undefined"'))
			subject.addEventListener("progress", onProgress, false);

		untyped subject.onreadystatechange = function() {
			if( subject.readyState != 4 )
				return;
			var s = try subject.status catch( e : Dynamic ) null;
			if( s == untyped __js__("undefined") )
				s = null;
			if( s != null )
				self.onStatus(s);
			if( s != null && s >= 200 && s < 400 )
				self.onData(subject.response);
			else switch( s ) {
			case null:
				self.onError("Failed to connect or resolve host");
			case 12029:
				self.onError("Failed to connect to host");
			case 12007:
				self.onError("Unknown host");
			default:
				self.onError("Http Error #"+subject.status);
			}
		};
	}

	function requestUrl( url:String, method:String, data:Dynamic, requestHeaders:Array<URLRequestHeader> ) : Void {
		var xmlHttpRequest : XMLHttpRequest = untyped __new__("XMLHttpRequest");

		registerEvents(cast xmlHttpRequest);

		var uri:Dynamic = "";
		switch (true) {
			case (data == null):
			case Std.is(data, ByteArray):
				var data:ByteArray = cast data;
				switch (dataFormat) {
					case BINARY: 
						uri = data.jeashGetBuffer();
					default:
						uri = data.readUTFBytes(data.length);
				}
			case Std.is(data, URLVariables):
				var data:URLVariables = cast data;
				for (p in Reflect.fields(data)) {
					if (uri.length != 0) uri += "&";
					uri += StringTools.urlEncode(p)+"="+StringTools.urlEncode(Reflect.field(data, p));
				}
			default:
				if (data != null)
					uri = data.toString();
		}

		try {
			if (method == "GET" && uri != null && uri != "") {
				var question = url.split("?").length <= 1;
				xmlHttpRequest.open(method, url+(if( question ) "?" else "&")+uri,true);
				uri = "";
			} else 
				xmlHttpRequest.open(method, url, true);
		} catch( e : Dynamic ) {
			onError(e.toString());
			return;
		}

		switch (dataFormat) {
			case BINARY: 
				untyped xmlHttpRequest.responseType = 'arraybuffer';
			default:
		}

		for( header in requestHeaders ) {
			xmlHttpRequest.setRequestHeader(header.name, header.value);
		}
		
		untyped __js__ ("// If you receive \"DOMException: NETWORK_ERR\", you most likely are testing");
		untyped __js__ ("// locally, and AJAX calls are not allowed in your browser for security");
		
		xmlHttpRequest.send(uri);
		onOpen();
		getData = function () { return xmlHttpRequest.response; };

	}

	dynamic function getData():Dynamic {}
}

