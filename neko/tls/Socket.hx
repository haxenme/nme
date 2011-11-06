package neko.tls;

import neko.net.Host;

enum SocketHandle {}
enum CTX {}
enum TLS {}


class Socket {

	static function __init__() {
		neko.Lib.load( "std", "socket_init", 0 )();
	}

	static var certFolder = "/etc/ssl/certs"; //TODO

	public var input(default,null) : SocketInput;
	public var output(default,null) : SocketOutput;

	var __s : SocketHandle;
	var ctx : CTX;
	var ssl: TLS;

	public function new( ?s ) {
		initializeOpenSSL();
		__s = if( s == null ) socket_new(false) else s;
		input = new SocketInput(__s);
		output = new SocketOutput(__s);
	}
	
	/*
	public function setSecure() {
		trace("TODO not implemented");
	}
	*/
	
	public function connect( host : Host, port : Int ) {
		try {
			socket_connect(__s, host.ip, port);
			ssl = SSL_new( ctx );
			input.ssl = ssl;
			output.ssl = ssl;
			var sbio = BIO_new_socket( __s, BIO_NOCLOSE() );
			SSL_set_bio( ssl, sbio, sbio );
			var rsc : Int = SSL_connect(ssl);
		} catch( e : String ) {
			if( e == "std@socket_connect" )
				throw "Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString() ) +":" + port;
			else
				neko.Lib.rethrow( e );
		}
	}

	public function close() {
		socket_close( __s );
		untyped {
			input.__s = null;
			output.__s = null;
		}
		input.close();
		output.close();
	}

	public function read() : String {
		return socket_read( ssl );
	}

	public function write( content : String ) {
		socket_write( ssl, neko.Lib.haxeToNeko( content ) );
	}

	public function listen( connections : Int ) {
		socket_listen( __s, connections );
	}

	public function shutdown( read : Bool, write : Bool ) {
		SSL_shutdown( ssl );
		socket_shutdown( __s, read, write );
	}

	public function bind( host : Host, port : Int ) {
		socket_bind( __s, host, port );
	}

	public function accept() : Socket {
		return new Socket( socket_accept( __s ) );
	}

	public function peer() : { host : Host, port : Int } {
		var a : Dynamic = socket_peer( __s );
		return { host : a[0], port : a[1] };
	}

	public function host() : { host : Host, port : Int } {
		var a : Dynamic = socket_host( __s );
		return { host : a[0], port : a[1] };
	}

	public function setTimeout( timeout : Float ) {
		socket_set_timeout( __s, timeout );
	}

	public function waitForRead() {
		select( [this], null, null, null );
	}

	public function setBlocking( b : Bool ) {
		socket_set_blocking( __s, b );
	}

	function initializeOpenSSL() {
		SSL_library_init();
		SSL_load_error_strings();
		ctx = SSL_CTX_new( SSLv23_client_method() );
		var rsclvl : Int = SSL_CTX_load_verify_locations( ctx, neko.Lib.haxeToNeko( certFolder ) );
	}

	public static function select( read : Array<Socket>, write : Array<Socket>, others : Array<Socket>, timeout : Float )
	: {read: Array<Socket>, write: Array<Socket>, others: Array<Socket> } {
		var c = untyped __dollar__hnew( 1 );
		var f = function( a : Array<Socket> ){
			if( a == null ) return null;
			untyped {
				var r = __dollar__amake( a.length );
				var i = 0;
				while( i < a.length ){
					r[i] = a[i].__s;
					__dollar__hadd( c, a[i].__s, a[i] );
					i += 1;
				}
				return r;
			}
		}
		var neko_array = socket_select( f(read), f(write), f(others), timeout);
		var g = function( a ) : Array<Socket> {
			if( a == null ) return null;
			var r = new Array();
			var i = 0;
			while( i < untyped __dollar__asize(a) ){
				var t = untyped __dollar__hget(c,a[i],null);
				if( t == null ) throw "Socket object not found.";
				r[i] = t;
				i += 1;
			}
			return r;
		}

		return {
			read: g(neko_array[0]),
			write: g(neko_array[1]),
			others: g(neko_array[2])
		};
	}

	static var socket_new = neko.Lib.load( "std", "socket_new", 1 );
	static var socket_close = neko.Lib.load( "std", "socket_close", 1 );
	static var socket_write = Loader.load( "__SSL_write", 2 );
	static var socket_read = Loader.load( "__SSL_read", 1 );
	static var socket_connect = neko.Lib.load( "std", "socket_connect", 3 );
	static var socket_listen = neko.Lib.load( "std", "socket_listen", 2 );
	static var socket_select = neko.Lib.load( "std", "socket_select", 4 );
	static var socket_bind = neko.Lib.load( "std", "socket_bind", 3 );
	static var socket_accept = neko.Lib.load( "std", "socket_accept", 1 );
	static var socket_peer = neko.Lib.load( "std", "socket_peer", 1 );
	static var socket_host = neko.Lib.load( "std", "socket_host", 1 );
	static var socket_set_timeout = neko.Lib.load( "std", "socket_set_timeout", 2 );
	static var socket_shutdown = neko.Lib.load( "std", "socket_shutdown", 3 );
	static var socket_set_blocking = neko.Lib.load( "std", "socket_set_blocking", 2 );

	static var SSL_shutdown = Loader.load( "_SSL_shutdown", 1 );
	static var SSL_load_error_strings = Loader.load( "_SSL_load_error_strings", 0 );
	static var SSL_library_init = Loader.load( "_SSL_library_init", 0 );
	static var SSL_CTX_new = Loader.load( "_SSL_CTX_new", 1 );
	static var SSL_CTX_load_verify_locations = Loader.load( "_SSL_CTX_load_verify_locations", 2 );
	static var SSLv23_client_method = Loader.load( "_SSLv23_client_method", 0 );
	static var SSL_new = Loader.load( "_SSL_new", 1 );
	static var BIO_new_socket = Loader.load( "_BIO_new_socket", 2 );
	static var SSL_set_bio = Loader.load( "_SSL_set_bio", 3 );
	static var BIO_NOCLOSE = Loader.load( "_BIO_NOCLOSE", 0 );
	static var SSL_connect = Loader.load( "_SSL_connect", 1 );
	static var SSL_set_fd = Loader.load ( "_SSL_set_fd", 2 );
	static var SSL_CTX_set_verify_depth = Loader.load(  "_SSL_CTX_set_verify_depth", 2 );

	static var BIO_new = Loader.load( "_BIO_new", 1 );
	static var BIO_set_fd = Loader.load( "_BIO_set_fd", 3 );
	static var BIO_s_socket = Loader.load( "_BIO_s_socket", 0 );

}
