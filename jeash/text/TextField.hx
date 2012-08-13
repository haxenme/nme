/** * Copyright (c) 2010, Jeash contributors.
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

package jeash.text;

import jeash.display.Graphics;
import jeash.geom.Matrix;
import jeash.geom.Rectangle;
import jeash.geom.Point;
import jeash.display.InteractiveObject;
import jeash.display.DisplayObject;
import jeash.text.TextFormatAlign;
import jeash.events.Event;
import jeash.events.KeyboardEvent;
import jeash.events.FocusEvent;
import jeash.ui.Keyboard;

import jeash.Html5Dom;

typedef SpanAttribs = {
	var face:String;
	var height:Int;
	var colour:Int;
	var align:TextFormatAlign;
}

typedef Span = {
	var font:FontInstance;
	var text:String;
}

typedef Paragraph = {
	var align:TextFormatAlign;
	var spans: Array<Span>;
}

typedef Paragraphs = Array<Paragraph>;

typedef LineInfo = {
	var mY0:Int;
	var mIndex:Int;
	var mX:Array<Int>;
}

typedef RowChar = {
	var x:Int;
	var fh:Int;
	var adv:Int;
	var chr:Int;
	var font:FontInstance;
	var sel:Bool;
}

typedef RowChars = Array<RowChar>;

class TextField extends jeash.display.InteractiveObject
{
	public var htmlText(GetHTMLText,SetHTMLText):String;
	public var text(GetText,SetText):String;
	public var textColor(GetTextColour,SetTextColour):Int;
	public var textWidth(GetTextWidth,null):Float;
	public var textHeight(GetTextHeight,null):Float;
	private var _defaultTextFormat : TextFormat;
	public var defaultTextFormat(jeashGetDefaultTextFormat,jeashSetDefaultTextFormat) : TextFormat;
	public static var mDefaultFont = Font.DEFAULT_FONT_NAME;

	private var mHTMLText:String;
	private var mText:String;
	private var mTextColour:Int;
	private var mType:String;

	public var autoSize(default,SetAutoSize) : String;
	public var selectable : Bool;
	public var multiline : Bool;
	public var embedFonts : Bool;
	public var borderColor(default,SetBorderColor) : Int;
	public var background(default,SetBackground) : Bool;
	public var backgroundColor(default,SetBackgroundColor) : Int;
	public var caretPos(GetCaret,null) : Int;
	public var displayAsPassword : Bool;
	public var border(default,SetBorder) : Bool;
	public var wordWrap(default,SetWordWrap) : Bool;
	public var maxChars : Int;
	public var restrict : String;
	public var type(GetType,SetType) : String;
	public var antiAliasType : String;
	public var sharpness : Float;
	public var gridFitType : String;
	public var length(default,null) : Int;
	public var mTextHeight:Int;
	public var mFace:String;
	public var mDownChar:Int;

	public var selectionBeginIndex : Int;
	public var selectionEndIndex : Int;
	public var caretIndex : Int;
	public var mParagraphs:Paragraphs;
	public var mTryFreeType:Bool;

	var mLineInfo:Array<LineInfo>;

	static var sSelectionOwner:TextField = null;

	var mAlign:TextFormatAlign;
	var mHTMLMode:Bool;
	var mSelStart:Int;
	var mSelEnd:Int;
	var mInsertPos:Int;
	var mSelectDrag:Int;
	var jeashInputEnabled:Bool;

	var mWidth:Float;
	var mHeight:Float;

	var mSelectionAnchored:Bool;
	var mSelectionAnchor:Int;

	var mScrollH:Int;
	var mScrollV:Int;

	var jeashGraphics:Graphics;

	public function new() {
		super();
		mWidth = 100;
		mHeight = 20;
		mHTMLMode = false;
		multiline = false;
		jeashGraphics = new Graphics();
		mFace = mDefaultFont;
		mAlign = jeash.text.TextFormatAlign.LEFT;
		mParagraphs = new Paragraphs();
		mSelStart = -1;
		mSelEnd = -1;
		mScrollH = 0;
		mScrollV = 1;

		mType = jeash.text.TextFieldType.DYNAMIC;
		autoSize = jeash.text.TextFieldAutoSize.NONE;
		mTextHeight = 12;
		mMaxHeight = mTextHeight;
		mHTMLText = " ";
		mText = " ";
		mTextColour = 0x000000;
		tabEnabled = false;
		mTryFreeType = true;
		selectable = true;
		mInsertPos = 0;
		jeashInputEnabled = false;
		mDownChar = 0;
		mSelectDrag = -1;

		mLineInfo = [];
		defaultTextFormat = new TextFormat();

		borderColor = 0x000000;
		border = false;
		backgroundColor = 0xffffff;
		background = false;
	}

	override public function toString() { return "[TextField name=" + this.name + " id=" + _jeashId + "]"; }

	override public function jeashGetWidth() : Float { 
		return getBounds(this.stage).width;
	}
	override public function jeashSetWidth(inValue:Float) : Float {
		if (parent != null)
			parent.jeashInvalidateBounds();
		if (_boundsInvalid)
			validateBounds();

		if (inValue != mWidth) {
			mWidth = inValue;
			Rebuild();
		}

		return mWidth;
	}

	override public function jeashGetHeight() : Float { 
		return getBounds(this.stage).height;
	}
	override public function jeashSetHeight(inValue:Float) : Float {
		if (parent != null)
			parent.jeashInvalidateBounds();
		if (_boundsInvalid)
			validateBounds();
		
		if (inValue != mHeight) {
			mHeight = inValue;
			Rebuild();
		}

		return mHeight;
	}

	public function GetType() { return mType; }
	public function SetType(inType:String) : String {
		mType = inType;

		jeashInputEnabled = mType == TextFieldType.INPUT;
		if (mHTMLMode) {
			if (jeashInputEnabled) {
				Lib.jeashSetContentEditable(jeashGraphics.jeashSurface, true);
			} else {
				Lib.jeashSetContentEditable(jeashGraphics.jeashSurface, false);
			}
		} else if (jeashInputEnabled) {
			// implicitly convert text to a HTML field, and set contenteditable
			SetHTMLText(StringTools.replace(mText, "\n", "<BR />"));
			Lib.jeashSetContentEditable(jeashGraphics.jeashSurface, true);
		}

		tabEnabled = type == TextFieldType.INPUT;
		Rebuild();
		return inType;
	}

	public function GetCaret() { return mInsertPos; }
	override function jeashGetGraphics() : jeash.display.Graphics { return jeashGraphics; }

	public function getLineIndexAtPoint(inX:Float,inY:Float) : Int {
		if (mLineInfo.length<1) return -1;
		if (inY<=0) return 0;

		for(l in 0...mLineInfo.length)
			if (mLineInfo[l].mY0 > inY)
				return l==0 ? 0 : l-1;
		return mLineInfo.length-1;
	}

	public function getCharIndexAtPoint(inX:Float,inY:Float) : Int {
		var li = getLineIndexAtPoint(inX,inY);
		if (li<0)
			return -1;

		var line = mLineInfo[li];
		var idx = line.mIndex;
		for(x in line.mX) {
			if (x>inX) return idx;
			idx++;
		}
		return idx;

	}

	public function getCharBoundaries( a:Int ) : Rectangle {
		// TODO
		return null;
	}

	var mMaxWidth:Float;
	var mMaxHeight:Float;
	var mLimitRenderX:Int;

	function RenderRow(inRow:Array<RowChar>, inY:Int, inCharIdx:Int, inAlign:TextFormatAlign, ?inInsert:Int) : Int {
		var h = 0;
		var w = 0;
		for(chr in inRow) {
			if (chr.fh > h)
				h = chr.fh;
			w+=chr.adv;
		}
		if (w>mMaxWidth)
			mMaxWidth = w;

		var full_height = Std.int(h*1.2);


		var align_x = 0;
		var insert_x = 0;
		if (inInsert!=null) {
			// TODO: check if this is necessary.
			if (autoSize != jeash.text.TextFieldAutoSize.NONE) {
				mScrollH = 0;
				insert_x = inInsert;
			} else {
				insert_x = inInsert - mScrollH;
				if (insert_x<0) {
					mScrollH -= ( (mLimitRenderX*3)>>2 ) - insert_x;
				} else if (insert_x > mLimitRenderX) {
					mScrollH +=  insert_x - ((mLimitRenderX*3)>>2);
				}
				if (mScrollH<0)
					mScrollH = 0;
			}
		}

		if (autoSize == jeash.text.TextFieldAutoSize.NONE && w<=mLimitRenderX) {
			if (inAlign == TextFormatAlign.CENTER)
				align_x = (mLimitRenderX-w)>>1;
			else if (inAlign == TextFormatAlign.RIGHT)
				align_x = (mLimitRenderX-w);
		}

		var x_list = new Array<Int>();
		mLineInfo.push( { mY0:inY, mIndex:inCharIdx-1, mX:x_list } );

		var cache_sel_font : FontInstance = null;
		var cache_normal_font : FontInstance = null;

		var x = align_x-mScrollH;
		var x0 = x;
		for(chr in inRow) {
			var adv = chr.adv;
			if (x+adv>mLimitRenderX)
				break;

			x_list.push(x);

			if (x>=0) {
				var font = chr.font;
				if (chr.sel) {
					jeashGraphics.lineStyle();
					jeashGraphics.beginFill(0x202060);
					jeashGraphics.drawRect(x,inY,adv,full_height);
					jeashGraphics.endFill();

					if (cache_normal_font == chr.font) {
						font = cache_sel_font;
					} else {
						font = FontInstance.CreateSolid( chr.font.GetFace(), chr.fh, 0xffffff,1.0 );
						cache_sel_font = font;
						cache_normal_font = chr.font;
					}
				}
				font.RenderChar(jeashGraphics,chr.chr,x,Std.int(inY + (h-chr.fh)));
			}

			x+=adv;
		}

		x+=mScrollH;


		return full_height;
	}

	function Rebuild() {
		if (mHTMLMode) return;

		mLineInfo = [];

		jeashGraphics.clear();

		if (background) {
			jeashGraphics.beginFill(backgroundColor);
			jeashGraphics.drawRect(-2,-2,width+4,height+4);
			jeashGraphics.endFill();
		}

		jeashGraphics.lineStyle(mTextColour);

		var insert_x:Null<Int> = null;

		mMaxWidth = 0;
		//mLimitRenderX = (autoSize == jeash.text.TextFieldAutoSize.NONE) ? Std.int(width) : 999999;
		var wrap = mLimitRenderX = (wordWrap && !jeashInputEnabled) ? Std.int(mWidth) : 999999;
		var char_idx = 0;
		var h:Int = 0;

		var s0 = mSelStart;
		var s1 = mSelEnd;

		for(paragraph in mParagraphs) {
			var row:Array<RowChar> = [];
			var row_width = 0;
			var last_word_break = 0;
			var last_word_break_width = 0;
			var last_word_char_idx = 0;
			var start_idx = char_idx;
			var tx = 0;

			for(span in paragraph.spans) {
				var text = span.text;
				var font = span.font;
				var fh = font.height;
				last_word_break = row.length;
				last_word_break_width = row_width;
				last_word_char_idx = char_idx;

				for(ch in 0...text.length) {

					var g = text.charCodeAt(ch);
					var adv = font.jeashGetAdvance(g);
					if (g==32) {
						last_word_break = row.length;
						last_word_break_width = tx;
						last_word_char_idx = char_idx;
					}

					if ( (tx+adv)>wrap ) {
						if (last_word_break>0) {
							var row_end = row.splice(last_word_break, row.length-last_word_break);
							h+=RenderRow(row,h,start_idx,paragraph.align);
							row = row_end;
							tx -= last_word_break_width;
							start_idx = last_word_char_idx;

							last_word_break = 0;
							last_word_break_width = 0;
							last_word_char_idx = 0;
							if (row_end.length>0 && row_end[0].chr==32) {
								row_end.shift();
								start_idx ++;
							}
						} else {
							h+=RenderRow(row,h,char_idx,paragraph.align);
							row = [];
							tx = 0;
							start_idx = char_idx;
						}
					}
					row.push( { font:font, chr:g, x:tx, fh: fh,
							sel:(char_idx>=s0 && char_idx<s1), adv:adv } );
					tx += adv;
					char_idx++;
				}
			}
			if (row.length>0) {
				h+=RenderRow(row,h,start_idx,paragraph.align,insert_x);
				insert_x = null;
			}
		}

		var w = mMaxWidth;
		if (h<mTextHeight)
			h = mTextHeight;
		mMaxHeight = h;

		switch(autoSize) {
			case jeash.text.TextFieldAutoSize.LEFT:
			case jeash.text.TextFieldAutoSize.RIGHT:
				var x0 = x + width;
				x = mWidth - x0;
			case jeash.text.TextFieldAutoSize.CENTER:
				var x0 = x + width/2;
				x = mWidth/2 - x0;
			default:
				if (wordWrap)
					height = h;
		}

		if (border) {
			jeashGraphics.endFill();
			jeashGraphics.lineStyle(1,borderColor);
			jeashGraphics.drawRect(-2,-2,width+4,height+4);
		}
	}

	public function GetTextWidth() : Float{ return mMaxWidth; }
	public function GetTextHeight() : Float{ return mMaxHeight; }

	public function GetTextColour() { return mTextColour; }
	public function SetTextColour(inCol) {
		mTextColour = inCol;
		RebuildText();
		return inCol;
	}

	public function GetText() {
		if (mHTMLMode)
			ConvertHTMLToText(false);
		return mText;
	}

	public function SetText(inText:String) {
		mText = inText;
		//mHTMLText = inText;
		mHTMLMode = false;
		RebuildText();
		jeashInvalidateBounds();
		return mText;
	}

	public function ConvertHTMLToText(inUnSetHTML:Bool) {
		mText = "";

		for(paragraph in mParagraphs)
		{
			for(span in paragraph.spans)
			{
				mText += span.text;
			}
			// + \n ?
		}

		if (inUnSetHTML)
		{
			mHTMLMode = false;
			RebuildText();
		}
	}

	public function SetAutoSize(inAutoSize:String) : String {
		autoSize = inAutoSize;
		Rebuild();
		return inAutoSize;
	}

	public function SetWordWrap(inWordWrap:Bool) : Bool {
		wordWrap = inWordWrap;
		Rebuild();
		return wordWrap;
	}
	public function SetBorder(inBorder:Bool) : Bool {
		border = inBorder;
		Rebuild();
		return inBorder;
	}

	public function SetBorderColor(inBorderCol:Int) : Int {
		borderColor = inBorderCol;
		Rebuild();
		return inBorderCol;
	}

	public function SetBackgroundColor(inCol:Int) : Int {
		backgroundColor = inCol;
		Rebuild();
		return inCol;
	}

	public function SetBackground(inBack:Bool) : Bool {
		background = inBack;
		Rebuild();
		return inBack;
	}


	public function GetHTMLText() { return mHTMLText; }

	function DecodeColour(col:String) {
		return Std.parseInt("0x"+col.substr(1));
	}

	public function RebuildText() {
		mParagraphs = [];

		if (!mHTMLMode) {
			var font = FontInstance.CreateSolid( mFace, mTextHeight, mTextColour, 1.0  );
			var paras = mText.split("\n");
			for(paragraph in paras)
				mParagraphs.push( { align:mAlign, spans: [ { font : font, text:paragraph+"\n" }] } );
		}
		Rebuild();
	}

	public function SetHTMLText(inHTMLText:String) {
		mParagraphs = new Paragraphs();
		mHTMLText = inHTMLText;

		if (!mHTMLMode) {
			var wrapper : HTMLCanvasElement = cast js.Lib.document.createElement("div");
			wrapper.innerHTML = inHTMLText;

			var destination = new Graphics(wrapper);

			var jeashSurface = jeashGraphics.jeashSurface;
			if (Lib.jeashIsOnStage(jeashSurface)) {
				Lib.jeashAppendSurface(wrapper);
				Lib.jeashCopyStyle(jeashSurface, wrapper);
				Lib.jeashSwapSurface(jeashSurface, wrapper);
				Lib.jeashRemoveSurface(jeashSurface);
			}

			jeashGraphics = destination;
			jeashGraphics.jeashExtent.width = wrapper.width;
			jeashGraphics.jeashExtent.height = wrapper.height;

		} else {
			jeashGraphics.jeashSurface.innerHTML = inHTMLText;
		}

		mHTMLMode = true;
		RebuildText();
		jeashInvalidateBounds();

		return mHTMLText;
	}

	public function appendText(newText : String) {
		this.text += newText;
	}

	public function setSelection(beginIndex : Int, endIndex : Int) {
		// TODO:
	}

	public function jeashGetDefaultTextFormat() {
		return _defaultTextFormat;
	}

	function jeashSetDefaultTextFormat(inFmt:TextFormat) {
		setTextFormat(inFmt);
		_defaultTextFormat = inFmt;
		return inFmt;
	}

	public function getTextFormat(?beginIndex : Int, ?endIndex : Int) : TextFormat {
		return new TextFormat();
	}

	public function setTextFormat(inFmt:TextFormat, ?beginIndex:Int, ?endIndex:Int) {
		if (inFmt.font!=null)
			mFace = inFmt.font;
		if (inFmt.size!=null)
			mTextHeight = Std.int(inFmt.size);
		if (inFmt.align!=null)
			mAlign = inFmt.align;
		if (inFmt.color!=null)
			mTextColour = inFmt.color;

		RebuildText();
		jeashInvalidateBounds();
		return getTextFormat();
	}

	override public function jeashGetObjectUnderPoint(point:Point):DisplayObject 
		if (!visible) return null; 
		else if (this.mText.length > 1) {
			var local = globalToLocal(point);
			if (local.x < 0 || local.y < 0 || local.x > mMaxWidth || local.y > mMaxHeight) return null; else return cast this;
		}
		else return super.jeashGetObjectUnderPoint(point)


	override public function jeashRender(?inMask:HTMLCanvasElement, ?clipRect:Rectangle) {
		if (!jeashVisible) return;

		if (_matrixInvalid || _matrixChainInvalid)
			jeashValidateMatrix();

		if (jeashGraphics.jeashRender(inMask, jeashFilters))
			handleGraphicsUpdated(jeashGraphics);

		var fullAlpha = (parent != null ? parent.alpha : 1) * alpha;
		if (!mHTMLMode && inMask != null) {
			var m = getSurfaceTransform(jeashGraphics);
			Lib.jeashDrawToSurface(jeashGraphics.jeashSurface, inMask, m, fullAlpha, clipRect);
		} else {
			if (jeashTestFlag(DisplayObject.TRANSFORM_INVALID)) {
				var m = getSurfaceTransform(jeashGraphics);
				Lib.jeashSetSurfaceTransform(jeashGraphics.jeashSurface, m);
				jeashClearFlag(DisplayObject.TRANSFORM_INVALID);
			}
			if (fullAlpha != _lastFullAlpha) {
				Lib.jeashSetSurfaceOpacity(jeashGraphics.jeashSurface, fullAlpha);
				_lastFullAlpha = fullAlpha;
			}
			/*if (clipRect != null) {
				var rect = new Rectangle();
				rect.topLeft = this.globalToLocal(this.parent.localToGlobal(clipRect.topLeft));
				rect.bottomRight = this.globalToLocal(this.parent.localToGlobal(clipRect.bottomRight));
				Lib.jeashSetSurfaceClipping(jeashGraphics.jeashSurface, rect);
			}*/
		}
	}
}

import jeash.geom.Matrix;
import jeash.display.Graphics;
import jeash.display.BitmapData;

enum FontInstanceMode {
	fimSolid;
}

class FontInstance {
	static var mSolidFonts = new Hash<FontInstance>();

	var mMode : FontInstanceMode;
	var mColour : Int;
	var mAlpha : Float;
	var mFont : Font;
	var mHeight: Int;
	var mGlyphs: Array<HTMLElement>;
	var mCacheAsBitmap:Bool;
	public var mTryFreeType:Bool;

	public var height(jeashGetHeight,null):Int;

	function new(inFont:Font,inHeight:Int) {
		mFont = inFont;
		mHeight = inHeight;
		mTryFreeType = true;
		mGlyphs = [];
		mCacheAsBitmap = false;
	}

	public function toString() : String {
		return "FontInstance:" + mFont + ":" + mColour + "(" + mGlyphs.length + ")";
	}

	public function GetFace() {
		return mFont.fontName;
	}

	static public function CreateSolid(inFace:String,inHeight:Int,inColour:Int, inAlpha:Float) {
		var id = "SOLID:" + inFace+ ":" + inHeight + ":" + inColour + ":" + inAlpha;
		var f:FontInstance =  mSolidFonts.get(id);
		if (f!=null)
			return f;

		var font : Font = new Font();
		font.jeashSetScale(inHeight);
		font.fontName = inFace;

		if (font==null)
			return null;

		f = new FontInstance(font,inHeight);
		f.SetSolid(inColour,inAlpha);
		mSolidFonts.set(id,f);
		return f;
	}

	function jeashGetHeight():Int { return mHeight; }

	function SetSolid(inCol:Int, inAlpha:Float) {
		mColour = inCol;
		mAlpha = inAlpha;
		mMode = fimSolid;
	}

	public function RenderChar(inGraphics:Graphics,inGlyph:Int,inX:Int, inY:Int) {
		inGraphics.jeashClearLine();
		inGraphics.beginFill(mColour,mAlpha);
		mFont.jeashRender(inGraphics,inGlyph,inX,inY,mTryFreeType);
		inGraphics.endFill();
	}

	public function jeashGetAdvance(inChar:Int) : Int {
		if (mFont==null) return 0;
		return mFont.jeashGetAdvance(inChar, mHeight);
	}
}

