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

package jeash.display;

import jeash.events.EventDispatcher;

/**
* @author	Niel Drummond
* @author	Russell Weir
* @todo init, open, progress, unload (?) events
**/
class LoaderInfo extends EventDispatcher {

	public var bytes(default,null) : jeash.utils.ByteArray;
	public var bytesLoaded(default,null) : Int;
	public var bytesTotal(default,null) : Int;
	public var childAllowsParent(default,null) : Bool;
	public var content(default,null) : DisplayObject;
	public var contentType(default,null) : String;
	public var frameRate(default,null) : Float;
	public var height(default,null) : Int;
	public var loader(default,null) : Loader;
	public var loaderURL(default,null) : String;
	public var parameters(default,null) : Dynamic<String>;
	public var parentAllowsChild(default,null) : Bool;
	public var sameDomain(default,null) : Bool;
	public var sharedEvents(default,null) : jeash.events.EventDispatcher;
	public var url(default,null) : String;
	public var width(default,null) : Int;
	//static function getLoaderInfoByDefinition(object : Dynamic) : jeash.display.LoaderInfo;

	private function new() {
		super();
		bytesLoaded = 0;
		bytesTotal = 0;
		childAllowsParent = true;
		parameters = {};

	}

	public static function create(ldr : Loader) {
		var li = new LoaderInfo();
		if (ldr != null)
			li.loader = ldr;

		return li;
	}
}
