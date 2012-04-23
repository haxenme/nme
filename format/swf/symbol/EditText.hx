package format.swf.symbol;


import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import format.swf.data.SWFStream;
import format.SWF;


class EditText {
	
	
	private var alpha:Float;
	private var autoSize:Bool;
	private var border:Bool;
	private var displayAsPassword:Bool;
	private var html:Bool;
	private var maxChars:Int;
	private var multiline:Bool;
	private var noSelect:Bool;
	private var readOnly:Bool;
	private var rect:Rectangle;
	private var text:String;
	private var textFormat:TextFormat;
	private var useOutlines:Bool;
	private var wasStatic:Bool;
	private var wordWrap:Bool;
	
	
	public function new (swf:SWF, stream:SWFStream, version:Int) {
		
		textFormat = new TextFormat ();
		
		rect = stream.readRect ();
		
		stream.alignBits ();
		
		var hasText = stream.readBool ();
		
		wordWrap = stream.readBool ();
		multiline = stream.readBool ();
		displayAsPassword = stream.readBool ();
		readOnly = stream.readBool ();
		
		var hasColor = stream.readBool ();
		var hasMaxChars = stream.readBool ();
		var hasFont = stream.readBool ();
		var hasFontClass = stream.readBool ();
		
		autoSize = stream.readBool ();
		
		var hasLayout = stream.readBool ();
		
		noSelect = stream.readBool ();
		border = stream.readBool ();
		wasStatic = stream.readBool ();
		html = stream.readBool ();
		useOutlines = stream.readBool ();
		
		if (hasFont) {
			
			var fontID = stream.readID ();
			
			switch (swf.getSymbol (fontID)) {
				
				case fontSymbol (font):
					
					textFormat.font = font.getFontName ();
				
				default:
					
					throw ("Specified font is incorrect type");
				
			}
			
			textFormat.size = stream.readUTwips ();
			
		} else if (hasFontClass) {
			
			var fontName = stream.readString ();
			throw ("Can't reference external font: " + fontName);
			
		}
		
		if (hasColor) {
			
			textFormat.color = stream.readRGB ();
			alpha = stream.readByte () / 255.0;
			
		}
		
		if (hasMaxChars) {
			
			maxChars = stream.readUInt16 ();
			
		} else {
			
			maxChars = 0;
			
		}
		
		if (hasLayout) {
			
			textFormat.align = stream.readAlign ();
			textFormat.leftMargin = stream.readUTwips ();
			textFormat.rightMargin = stream.readUTwips ();
			textFormat.indent = stream.readUTwips ();
			textFormat.leading = stream.readSTwips ();
			
		}
		
		var variableName = stream.readString ();
		
		if (hasText) {
			
			text = stream.readString ();
			
		} else {
			
			text = "";
			
		}

	}
	
	
	public function apply (textField:TextField):Void {
		
		textField.wordWrap = wordWrap;
		textField.multiline = multiline;
		textField.width = rect.width;
		textField.height = rect.height;
		textField.displayAsPassword = displayAsPassword;
		
		if (maxChars > 0) {
			
			textField.maxChars = maxChars;
			
		}
		
		textField.border = border;
		textField.borderColor = 0x000000;
		
		if (readOnly) {
			
			textField.type = TextFieldType.DYNAMIC;
			
		} else {
			
			textField.type = TextFieldType.INPUT;
			
		}
		
		if (autoSize) {
			
			textField.autoSize = TextFieldAutoSize.CENTER;
			
		} else {
			
			textField.autoSize = TextFieldAutoSize.NONE;
			
		}
		
		textField.setTextFormat (textFormat);
		textField.selectable = !noSelect;
		
		//textField.embedFonts = useOutlines;
		
		if (html) {
			
			textField.htmlText = text;
			
		} else {
			
			textField.text = text;
			
		}
		
		// if (!readOnly) textField.stage.focus = textField;
		
	}
	
	
}