/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

class Reflect {

	public static function hasField( o : Dynamic, field : String ) : Bool untyped {
		if( o.hasOwnProperty != null )
			return o.hasOwnProperty(field);
		var arr = fields(o);
		for( t in arr.iterator() )
			if( t == field ) return true;
		return false;
	}

	public inline static function field( o : Dynamic, field : String ) : Dynamic untyped {
		
		/*var v = null;
		try {
			v = o[field];
		} catch( e : Dynamic ) {
		}
		return v;*/
		
		var methodName = "jeashGet" + field.substr (0, 1).toUpperCase () + field.substr (1);
		
		if (o[methodName] != null) {
			
			return o[methodName] ();
			
		} else {
			
			var v = null;
			try {
				v = o[field];
			} catch( e : Dynamic ) {
			}
			return v;
			
		}
		
	}

	public inline static function setField( o : Dynamic, field : String, value : Dynamic ) : Void untyped {
		//o[field] = value;
		
		var methodName = "jeashSet" + field.substr (0, 1).toUpperCase () + field.substr (1);
		
		if (o[methodName] != null) {
			
			o[methodName] (value);
			
		} else {
			
			o[field] = value;
			
		}
		
	}

	public inline static function callMethod( o : Dynamic, func : Dynamic, args : Array<Dynamic> ) : Dynamic untyped {
		return func.apply(o,args);
	}

	public static function fields( o : Dynamic ) : Array<String> untyped {
		if( o == null ) return new Array();
		var a = new Array();
		if( o.hasOwnProperty ) {
			__js__("
				for(var i in o)
					if( o.hasOwnProperty(i) )
						a.push(i);
			");
		} else {
			var t;
			try{ t = o.__proto__; } catch( e : Dynamic ) { t = null; }
			if( t != null )
				o.__proto__ = null;
			__js__("
				for(var i in o)
					if( i != \"__proto__\" )
						a.push(i);
			");
			if( t != null )
				o.__proto__ = t;
		}
		return a;
	}

	public static function isFunction( f : Dynamic ) : Bool untyped {
		return __js__("typeof(f)") == "function" && f.__name__ == null;
	}

	public static function compare<T>( a : T, b : T ) : Int {
		return ( a == b ) ? 0 : (((cast a) > (cast b)) ? 1 : -1);
	}

	public static function compareMethods( f1 : Dynamic, f2 : Dynamic ) : Bool {
		if( f1 == f2 )
			return true;
		if( !isFunction(f1) || !isFunction(f2) )
			return false;
		return f1.scope == f2.scope && f1.method == f2.method && f1.method != null;
	}

	public static function isObject( v : Dynamic ) : Bool untyped {
		if( v == null )
			return false;
		var t = __js__("typeof(v)");
		return (t == "string" || (t == "object" && !v.__enum__) || (t == "function" && v.__name__ != null));
	}

	public static function deleteField( o : Dynamic, f : String ) : Bool untyped {
		if( !hasField(o,f) ) return false;
		__js__("delete")(o[f]);
		return true;
	}

	public static function copy<T>( o : T ) : T {
		var o2 : Dynamic = {};
		for( f in Reflect.fields(o) )
			Reflect.setField(o2,f,Reflect.field(o,f));
		return o2;
	}

	public static function makeVarArgs( f : Array<Dynamic> -> Dynamic ) : Dynamic {
		return function() untyped {
			var a = new Array();
			for( i in 0...arguments.length )
				a.push(arguments[i]);
			return f(a);
		};
	}

}