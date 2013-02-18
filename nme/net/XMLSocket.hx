
package nme.net;

#if display

/**
 * @see flash.net.XMLSocket in Adobe's public flash documentation
 **/

@:final extern class XMLSocket
{
	public var connected(default, null): Bool;

    public var timeout : Int;

    public function new(?host : String, port : Int = 80) : Void;

    public function close() : Void;

    public function connect(host : String, port : Int) : Void;
    
    public function send(object : Dynamic) : Void;
}

#elseif (cpp || neko)
typedef XMLSocket = neash.net.XMLSocket;
#elseif js
typedef XMLSocket = jeash.net.XMLSocket;
#else
typedef URLRequest = flash.net.XMLSocket;
#end
