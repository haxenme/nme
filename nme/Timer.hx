/*
 * Copyright (c) 2006, Lee McColl Sylvester - www.designrealm.co.uk
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
 
package nme;

import nme.Time;

// TODO: Sort out API - check samples/1-Collision-Detect
//                    - compare to flash9

class Timer extends Time
{
	private static var arr : Array<Timer> = new Array();
	
	public function new( time : Int )
	{
		super( time );
		arr.push( this );
	}

	public function stop()
	{
		arr.remove( this );
	}

	dynamic public function run() {	}
	
	public static function check()
	{
		for ( timer in arr )
			if ( timer.isTime() ) timer.run();
	}
	
	override public function isTime() : Bool
	{
		var cur = Time.getCurrent();
		if ( cur - previous >= rate )
		{
			previous = cur;
			return true;
		}
		return false;
	}

	public static function delayed( f : Void -> Void, time : Int ) : Void -> Void
	{
		return function()
		{
			var t = new nme.Timer( time );
			t.run = function()
			{
				t.stop();
				f();
			};
		};
	}

	private static var fqueue = new Array<Void -> Void>();
	public static function queue( f : Void -> Void, ?time : Int ) : Void
	{
		fqueue.push( f );
		nme.Timer.delayed( function()
		{
			fqueue.shift()();
		}, if( time == null ) 0 else time)();
	}

	/**
		Returns a timestamp, in seconds
	**/
	public static function stamp() : Float
	{
		return Time.getCurrent();
	}

	/**
		Returns a timestamp, in milli-seconds
	**/
	public static function getCurrent() : Float
	{
		return Time.getCurrent() * 1000.0;
	}

}
