package neko.tls;

import haxe.io.Error;
import haxe.io.Eof;
import neko.tls.Socket;

class SocketOutput extends haxe.io.Output {

	public var ssl : TLS;

	var __s : SocketHandle;

	public function new( s ) {
		__s = s;
	}

	public function writeChar( c : Int ) {
		try {
			socket_send_char( ssl, c );
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Error.Blocked;
			else
				throw Error.Custom(e);
		}
	}

	public override function close() {
		super.close();
		if( __s != null ) socket_close( __s );
	}

	static var socket_close = neko.Lib.load( "std", "socket_close", 1 );
	static var socket_send_char = Loader.load( "SSL_send_char", 2 );
	static var socket_send = Loader.load( "SSL_send", 4 );

}