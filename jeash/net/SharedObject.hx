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
import jeash.net.SharedObjectFlushedStatus;

import haxe.Serializer;
import haxe.Unserializer;

import js.Storage;

class SharedObject extends EventDispatcher {
	var jeashKey:String;
	public var data(default, null):Dynamic;
	public var size(get_size, never):Int;

	function get_size()
	{
		var d = Serializer.run(data);
		return haxe.io.Bytes.ofString(d).length;
	}

	function new() super()

	public function clear() {
		data = {};
		jeashGetLocalStorage().removeItem(jeashKey);
		flush();
	}

	public function flush() {
		var data = Serializer.run(data);

		jeashGetLocalStorage().setItem(jeashKey, data);
		
		return SharedObjectFlushedStatus.FLUSHED;
	}

	static function jeashGetLocalStorage ():Storage {
		var res = Storage.getLocal();
		if (res == null) throw new jeash.errors.Error("SharedObject not supported");
		return res;
	}

	static public function getLocal(name : String, ?localPath : String, secure : Bool = false /* note: unsupported */) {

		if (localPath == null) localPath = js.Lib.window.location.href;

		var so = new SharedObject();
		so.jeashKey = localPath + ":" + name;
		var rawData = jeashGetLocalStorage().getItem(so.jeashKey);

		so.data = if (rawData == "" || rawData == null) {}
		else Unserializer.run(rawData);

		return so;
	}
}
