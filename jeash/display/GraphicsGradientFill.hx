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

import jeash.display.IGraphicsData;
import jeash.display.IGraphicsFill;
import jeash.Html5Dom;

class GraphicsGradientFill implements IGraphicsData, implements IGraphicsFill
{
	public var alphas : Array<Float>;
	public var colors : Array<UInt>;
	public var focalPointRatio : Float;
	public var interpolationMethod : InterpolationMethod;
	public var matrix : jeash.geom.Matrix;
	public var ratios : Array<Float>;
	public var spreadMethod : SpreadMethod;
	public var type : GradientType;
	public var jeashGraphicsDataType(default,null):GraphicsDataType;
	public var jeashGraphicsFillType(default,null):GraphicsFillType;
	public function new(?type : GradientType, ?colors : Array<UInt>, ?alphas : Array<Float>, ?ratios : Array<Float>, ?matrix : jeash.geom.Matrix, ?spreadMethod : SpreadMethod, ?interpolationMethod : InterpolationMethod, focalPointRatio : Float = 0) {
		this.type = type;
		this.colors = colors;
		this.alphas = alphas;
		this.ratios = ratios;
		this.matrix = matrix;
		this.spreadMethod = spreadMethod;
		this.interpolationMethod = interpolationMethod;
		this.focalPointRatio = focalPointRatio;
		this.jeashGraphicsDataType = GRADIENT;
		this.jeashGraphicsFillType = GRADIENT_FILL;
	}
}

