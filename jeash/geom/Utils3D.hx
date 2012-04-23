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

class Utils3D
{
	//static function pointTowards(percent : Float, mat : Matrix3D, pos : Vector3D, ?at : Vector3D, ?up : Vector3D) : Matrix3D;
	public static function projectVector(m : Matrix3D, v : Vector3D) : Vector3D
	{
		var n = m.rawData;
		var l_oProj:Vector3D = new Vector3D();
		l_oProj.x = v.x * n[0] + v.y * n[4] + v.z * n[8] + n[12];
		l_oProj.y = v.x * n[1] + v.y * n[5] + v.z * n[9] + n[13];
		l_oProj.z = v.x * n[2] + v.y * n[6] + v.z * n[10] + n[14];
		var w:Float = v.x * n[3] + v.y * n[7] + v.z * n[11] + n[15];
		// --
		l_oProj.z /= w;
		l_oProj.x /= w;
		l_oProj.y /= w;
		// --
		return l_oProj;
	}
	//static function projectVectors(m : Matrix3D, verts : jeash.Vector<Float>, projectedVerts : jeash.Vector<Float>, uvts : jeash.Vector<Float>) : Void;
}
