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

import jeash.display.DisplayObject;

class Transform
{
  public static inline var DEG_TO_RAD:Float = Math.PI / 180.0;

  private var _matrix:Matrix;
  private var _fullMatrix:Matrix;
  public var matrix(getMatrix, setMatrix):Matrix;
  public var colorTransform(default, setColorTransform):ColorTransform;
  public var pixelBounds(getPixelBounds, never):Rectangle;

  private var _displayObject:DisplayObject;

  public function new(displayObject:DisplayObject) {
    if (displayObject == null) throw "Cannot create Transform with no DisplayObject.";
    _displayObject = displayObject;

    _matrix = new Matrix();
    _fullMatrix = new Matrix();
    this.colorTransform = new ColorTransform();
  }

  private function getMatrix():Matrix {
    return _matrix.clone();
  }
  
  private function setMatrix(inValue:Matrix):Matrix {
    jeashSetMatrix(inValue);
    _displayObject.jeashInvalidateMatrix(true);
    return _matrix;
  }
  
  public inline function jeashSetMatrix(inValue:Matrix):Void {
    _matrix.copy(inValue);
  }

  public inline function jeashGetFullMatrix(?localMatrix:Matrix):Matrix {
    var m;
    if (localMatrix != null)
      m = localMatrix.mult(_fullMatrix);
    else
      m = _fullMatrix.clone();
    return m;
  }

  public inline function jeashSetFullMatrix(inValue:Matrix):Matrix {
    _fullMatrix.copy(inValue);
    return _fullMatrix;
  }

  private function setColorTransform(inValue:ColorTransform):ColorTransform {
    this.colorTransform = inValue;
    return inValue;
  }

  private function getPixelBounds():Rectangle {
    return _displayObject.getBounds(null);
  }
}
