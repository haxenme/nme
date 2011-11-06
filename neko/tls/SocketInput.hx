package neko.tls;

import haxe.io.Eof;
import haxe.io.Error;
import neko.tls.Socket;

class SocketInput extends haxe.io.Input {

	public var ssl : TLS;

	var __s : SocketHandle;

	public function new( s ) {
		__s = s;
	}

	public function readChar() : Int {
		try {
			return socket_recv_char( ssl );
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Error.Blocked;
			else if( __s == null )
				throw Error.Custom(e);
			else
				throw new Eof();
				return -1;
		}
	}

	public override function readBytes( buf : haxe.io.Bytes, pos : Int, len : Int ) : Int {
		var r : Int;
		try {
			r = socket_recv(ssl,buf.getData(),pos,len);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else
				throw Custom(e);
		}
		if( r == 0 )
			throw new haxe.io.Eof();
		return r;
	}

	public override function close() {
		super.close();
		if( __s != null ) socket_close( __s );
	}

	static var socket_recv = Loader.load( "SSL_recv", 4 );
	static var socket_recv_char = Loader.load( "SSL_recv_char", 1 );
	static var socket_close = neko.Lib.load( "std", "socket_close", 1 );
	static var SSL_read = Loader.load( "_SSL_read", 3 );

}