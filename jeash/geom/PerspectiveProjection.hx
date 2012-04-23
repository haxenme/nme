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

package jeash.geom;

class PerspectiveProjection
{
	public var fieldOfView (default,jeashSetFieldOfView): Float;
	public var focalLength : Float;
	// FIXME: does this do anything at all?
	public var projectionCenter : Point;

	var matrix3D : Matrix3D;
	public static inline var TO_RADIAN : Float = 0.01745329251994329577; // Math.PI / 180

	public function new() { 
		matrix3D = new Matrix3D();
		projectionCenter = new Point(Lib.current.stage.stageWidth/2, Lib.current.stage.stageHeight/2);
	}

	function jeashSetFieldOfView(fieldOfView:Float)
	{
		var p_nFovY = fieldOfView * TO_RADIAN;
		this.fieldOfView = p_nFovY;
		var cotan = 1/Math.tan(p_nFovY / 2);
		this.focalLength = Lib.current.stage.stageWidth * (Lib.current.stage.stageWidth/Lib.current.stage.stageHeight) / 2 * cotan;
		return fieldOfView;
	}

	public function toMatrix3D() : Matrix3D
	{
		if (fieldOfView == null || projectionCenter == null) return null;

		var _mp = matrix3D.rawData;
		_mp[0] = focalLength;
		_mp[5] = focalLength;
		_mp[11] = 1.0;
		_mp[15] = 0;
	
		//matrix3D.rawData = [357.0370178222656,0,0,0,0,357.0370178222656,0,0,0,0,1,1,0,0,0,0];
		return matrix3D;
	}
}
