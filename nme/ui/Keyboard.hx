package nme.ui;
#if (cpp || neko)


class Keyboard
{
	
	public static var A : Int = 65;
	public static var B : Int = 66;
	public static var C : Int = 67;
	public static var D : Int = 68;
	public static var E : Int = 69;
	public static var F : Int = 70;
	public static var G : Int = 71;
	public static var H : Int = 72;
	public static var I : Int = 73;
	public static var J : Int = 74;
	public static var K : Int = 75;
	public static var L : Int = 76;
	public static var M : Int = 77;
	public static var N : Int = 78;
	public static var O : Int = 79;
	public static var P : Int = 80;
	public static var Q : Int = 81;
	public static var R : Int = 82;
	public static var S : Int = 83;
	public static var T : Int = 84;
	public static var U : Int = 85;
	public static var V : Int = 86;
	public static var W : Int = 87;
	public static var X : Int = 88;
	public static var Y : Int = 89;
	public static var Z : Int = 90;

	public static var ALTERNATE : Int = 18;
	public static var BACKQUOTE : Int = 192;
	public static var BACKSLASH : Int = 220;
	public static var BACKSPACE : Int = 8;
	public static var CAPS_LOCK : Int = 20;
	public static var COMMA : Int = 188;
	public static var COMMAND : Int = 15;
	public static var CONTROL : Int = 17;
	public static var DELETE : Int = 46;
	public static var DOWN : Int = 40;
	public static var END : Int = 35;
	public static var ENTER : Int = 13;
	public static var EQUAL : Int = 187;
	public static var ESCAPE : Int = 27;
	public static var F1 : Int = 112;
	public static var F2 : Int = 113;
	public static var F3 : Int = 114;
	public static var F4 : Int = 115;
	public static var F5 : Int = 116;
	public static var F6 : Int = 117;
	public static var F7 : Int = 118;
	public static var F8 : Int = 119;
	public static var F9 : Int = 120;
	public static var F10 : Int = 121;
	public static var F11 : Int = 122;
	public static var F12 : Int = 123;
	public static var F13 : Int = 124;
	public static var F14 : Int = 125;
	public static var F15 : Int = 126;
	public static var HOME : Int = 36;
	public static var INSERT : Int = 45;
	public static var LEFT : Int = 37;
	public static var LEFTBRACKET : Int = 219;
	public static var MINUS : Int = 189;
	public static var NUMBER_0 : Int = 48;
	public static var NUMBER_1 : Int = 49;
	public static var NUMBER_2 : Int = 50;
	public static var NUMBER_3 : Int = 51;
	public static var NUMBER_4 : Int = 52;
	public static var NUMBER_5 : Int = 53;
	public static var NUMBER_6 : Int = 54;
	public static var NUMBER_7 : Int = 55;
	public static var NUMBER_8 : Int = 56;
	public static var NUMBER_9 : Int = 57;
	public static var NUMPAD : Int = 21;
	public static var NUMPAD_0 : Int = 96;
	public static var NUMPAD_1 : Int = 97;
	public static var NUMPAD_2 : Int = 98;
	public static var NUMPAD_3 : Int = 99;
	public static var NUMPAD_4 : Int = 100;
	public static var NUMPAD_5 : Int = 101;
	public static var NUMPAD_6 : Int = 102;
	public static var NUMPAD_7 : Int = 103;
	public static var NUMPAD_8 : Int = 104;
	public static var NUMPAD_9 : Int = 105;
	public static var NUMPAD_ADD : Int = 107;
	public static var NUMPAD_DECIMAL : Int = 110;
	public static var NUMPAD_DIVIDE : Int = 111;
	public static var NUMPAD_ENTER : Int = 108;
	public static var NUMPAD_MULTIPLY : Int = 106;
	public static var NUMPAD_SUBTRACT : Int = 109;
	public static var PAGE_DOWN : Int = 34;
	public static var PAGE_UP : Int = 33;
	public static var PERIOD : Int = 190;
	public static var QUOTE : Int = 222;
	public static var RIGHT : Int = 39;
	public static var RIGHTBRACKET : Int = 221;
	public static var SEMICOLON : Int = 186;
	public static var SHIFT : Int = 16;
	public static var SLASH : Int = 191;
	public static var SPACE : Int = 32;
	public static var TAB : Int = 9;
	public static var UP : Int = 38;

	//public static var capsLock(default,null) : Bool;
	//public static var numLock(default,null) : Bool;
	//public static function isAccessible() : Bool;
	
}


#elseif js


class Keyboard
{
	public static var KEY_0			= 48;
	public static var KEY_1			= 49;
	public static var KEY_2			= 50;
	public static var KEY_3			= 51;
	public static var KEY_4			= 52;
	public static var KEY_5			= 53;
	public static var KEY_6			= 54;
	public static var KEY_7			= 55;
	public static var KEY_8			= 56; public static var KEY_9			= 57; 
	public static var A			= 65;
	public static var B			= 66;
	public static var C			= 67;
	public static var D			= 68;
	public static var E			= 69;
	public static var F			= 70;
	public static var G			= 71;
	public static var H			= 72;
	public static var I			= 73;
	public static var J			= 74;
	public static var K			= 75;
	public static var L			= 76;
	public static var M			= 77;
	public static var N			= 78;
	public static var O			= 79;
	public static var P			= 80;
	public static var Q			= 81;
	public static var R			= 82;
	public static var S			= 83;
	public static var T			= 84;
	public static var U			= 85;
	public static var V			= 86;
	public static var W			= 87;
	public static var X			= 88;
	public static var Y			= 89;
	public static var Z			= 90;

	/* Numeric keypad */
	public static var NUMPAD_0		= 96;
	public static var NUMPAD_1		= 97;
	public static var NUMPAD_2		= 98;
	public static var NUMPAD_3		= 99;
	public static var NUMPAD_4		= 100;
	public static var NUMPAD_5		= 101;
	public static var NUMPAD_6		= 102;
	public static var NUMPAD_7		= 103;
	public static var NUMPAD_8		= 104;
	public static var NUMPAD_9		= 105;
	public static var NUMPAD_MULTIPLY	= 106;
	public static var NUMPAD_ADD		= 107;
	public static var NUMPAD_ENTER		= 108;
	public static var NUMPAD_SUBTRACT		= 109;
	public static var NUMPAD_DECIMAL		= 110;
	public static var NUMPAD_DIVIDE		= 111;


	/* Function keys */
	public static var F1			= 112;
	public static var F2			= 113;
	public static var F3			= 114;
	public static var F4			= 115;
	public static var F5			= 116;
	public static var F6			= 117;
	public static var F7			= 118;
	public static var F8			= 119;
	public static var F9			= 120;
	//  F10 is used by flash.
	public static var F10		= 121;
	public static var F11		= 122;
	public static var F12		= 123;
	public static var F13		= 124;
	public static var F14		= 125;
	public static var F15		= 126;


	public static var BACKSPACE		= 8;
	public static var TAB		= 9;
	public static var ENTER		= 13;
	public static var SHIFT		= 16;
	public static var CONTROL		= 17;
	public static var CAPS_LOCK		= 18;
	public static var ESCAPE		= 27;
	public static var SPACE		= 32;
	public static var PAGE_UP		= 33;
	public static var PAGE_DOWN		= 34;
	public static var END		= 35;
	public static var HOME		= 36;
	public static var LEFT		= 37;
	public static var RIGHT		= 39;
	public static var UP		= 38;
	public static var DOWN		= 40;
	public static var INSERT		= 45;
	public static var DELETE		= 46;
	public static var NUMLOCK		= 144;
	public static var BREAK		= 19;

	// Mozilla keyCodes
	// reference: https://developer.mozilla.org/en/DOM/Event/UIEvent/KeyEvent
	public static var DOM_VK_CANCEL	= 3;
	public static var DOM_VK_HELP	= 6;
	public static var DOM_VK_BACK_SPACE	= 8;
	public static var DOM_VK_TAB	= 9;
	public static var DOM_VK_CLEAR	= 12;
	public static var DOM_VK_RETURN	= 13;
	public static var DOM_VK_ENTER	= 14;
	public static var DOM_VK_SHIFT	= 16;
	public static var DOM_VK_CONTROL	= 17;
	public static var DOM_VK_ALT	= 18;
	public static var DOM_VK_PAUSE	= 19;
	public static var DOM_VK_CAPS_LOCK	= 20;
	public static var DOM_VK_ESCAPE	= 27;
	public static var DOM_VK_SPACE	= 32;
	public static var DOM_VK_PAGE_UP	= 33;
	public static var DOM_VK_PAGE_DOWN	= 34;
	public static var DOM_VK_END	= 35;
	public static var DOM_VK_HOME	= 36;
	public static var DOM_VK_LEFT	= 37;
	public static var DOM_VK_UP	= 38;
	public static var DOM_VK_RIGHT	= 39;
	public static var DOM_VK_DOWN	= 40;
	public static var DOM_VK_PRINTSCREEN	= 44;
	public static var DOM_VK_INSERT	= 45;
	public static var DOM_VK_DELETE	= 46;
	public static var DOM_VK_0	= 48;
	public static var DOM_VK_1	= 49;
	public static var DOM_VK_2	= 50;
	public static var DOM_VK_3	= 51;
	public static var DOM_VK_4	= 52;
	public static var DOM_VK_5	= 53;
	public static var DOM_VK_6	= 54;
	public static var DOM_VK_7	= 55;
	public static var DOM_VK_8	= 56;
	public static var DOM_VK_9	= 57;
	public static var DOM_VK_SEMICOLON	= 59;
	public static var DOM_VK_EQUALS	= 61;
	public static var DOM_VK_A	= 65;
	public static var DOM_VK_B	= 66;
	public static var DOM_VK_C	= 67;
	public static var DOM_VK_D	= 68;
	public static var DOM_VK_E	= 69;
	public static var DOM_VK_F	= 70;
	public static var DOM_VK_G	= 71;
	public static var DOM_VK_H	= 72;
	public static var DOM_VK_I	= 73;
	public static var DOM_VK_J	= 74;
	public static var DOM_VK_K	= 75;
	public static var DOM_VK_L	= 76;
	public static var DOM_VK_M	= 77;
	public static var DOM_VK_N	= 78;
	public static var DOM_VK_O	= 79;
	public static var DOM_VK_P	= 80;
	public static var DOM_VK_Q	= 81;
	public static var DOM_VK_R	= 82;
	public static var DOM_VK_S	= 83;
	public static var DOM_VK_T	= 84;
	public static var DOM_VK_U	= 85;
	public static var DOM_VK_V	= 86;
	public static var DOM_VK_W	= 87;
	public static var DOM_VK_X	= 88;
	public static var DOM_VK_Y	= 89;
	public static var DOM_VK_Z	= 90;
	public static var DOM_VK_CONTEXT_MENU	= 93;
	public static var DOM_VK_NUMPAD0	= 96;
	public static var DOM_VK_NUMPAD1	= 97;
	public static var DOM_VK_NUMPAD2	= 98;
	public static var DOM_VK_NUMPAD3	= 99;
	public static var DOM_VK_NUMPAD4	= 100;
	public static var DOM_VK_NUMPAD5	= 101;
	public static var DOM_VK_NUMPAD6	= 102;
	public static var DOM_VK_NUMPAD7	= 103;
	public static var DOM_VK_NUMPAD8	= 104;
	public static var DOM_VK_NUMPAD9	= 105;
	public static var DOM_VK_MULTIPLY	= 106;
	public static var DOM_VK_ADD	= 107;
	public static var DOM_VK_SEPARATOR	= 108;
	public static var DOM_VK_SUBTRACT	= 109;
	public static var DOM_VK_DECIMAL	= 110;
	public static var DOM_VK_DIVIDE	= 111;
	public static var DOM_VK_F1	= 112;
	public static var DOM_VK_F2	= 113;
	public static var DOM_VK_F3	= 114;
	public static var DOM_VK_F4	= 115;
	public static var DOM_VK_F5	= 116;
	public static var DOM_VK_F6	= 117;
	public static var DOM_VK_F7	= 118;
	public static var DOM_VK_F8	= 119;
	public static var DOM_VK_F9	= 120;
	public static var DOM_VK_F10	= 121;
	public static var DOM_VK_F11	= 122;
	public static var DOM_VK_F12	= 123;
	public static var DOM_VK_F13	= 124;
	public static var DOM_VK_F14	= 125;
	public static var DOM_VK_F15	= 126;
	public static var DOM_VK_F16	= 127;
	public static var DOM_VK_F17	= 128;
	public static var DOM_VK_F18	= 129;
	public static var DOM_VK_F19	= 130;
	public static var DOM_VK_F20	= 131;
	public static var DOM_VK_F21	= 132;
	public static var DOM_VK_F22	= 133;
	public static var DOM_VK_F23	= 134;
	public static var DOM_VK_F24	= 135;
	public static var DOM_VK_NUM_LOCK	= 144;
	public static var DOM_VK_SCROLL_LOCK	= 145;
	public static var DOM_VK_COMMA	= 188;
	public static var DOM_VK_PERIOD	= 190;
	public static var DOM_VK_SLASH	= 191;
	public static var DOM_VK_BACK_QUOTE	= 192;
	public static var DOM_VK_OPEN_BRACKET	= 219;
	public static var DOM_VK_BACK_SLASH	= 220;
	public static var DOM_VK_CLOSE_BRACKET	= 221;
	public static var DOM_VK_QUOTE	= 222;
	public static var DOM_VK_META	= 224;

	public static var DOM_VK_KANA	= 21;
	public static var DOM_VK_HANGUL	= 21;
	public static var DOM_VK_JUNJA	= 23;
	public static var DOM_VK_FINAL	= 24;
	public static var DOM_VK_HANJA	= 25;
	public static var DOM_VK_KANJI	= 25;
	public static var DOM_VK_CONVERT	= 28;
	public static var DOM_VK_NONCONVERT	= 29;
	public static var DOM_VK_ACEPT	= 30;
	public static var DOM_VK_MODECHANGE	= 31;
	public static var DOM_VK_SELECT	= 41;
	public static var DOM_VK_PRINT	= 42;
	public static var DOM_VK_EXECUTE	= 43;
	public static var DOM_VK_SLEEP	= 95;

	static public function jeashConvertWebkitCode(code:String) : Int {
		switch(code.toLowerCase()) {
			case "backspace": return BACKSPACE;
			case "tab": return TAB;
			case "enter": return ENTER;
			case "shift": return SHIFT;
			case "control": return CONTROL;
			case "capslock": return CAPS_LOCK;
			case "escape": return ESCAPE;
			case "space": return SPACE;
			case "pageup": return PAGE_UP;
			case "pagedown": return PAGE_DOWN;
			case "end": return END;
			case "home": return HOME;
			case "left": return LEFT;
			case "right": return RIGHT;
			case "up": return UP;
			case "down": return DOWN;
			case "insert": return INSERT;
			case "delete": return DELETE;
			case "numlock": return NUMLOCK;
			case "break": return BREAK;
		}
		if (code.indexOf("U+") == 0)
			return Std.parseInt('0x' + code.substr(3));

		throw "Unrecognised key code: " + code;
		return 0;
	}

	static public function jeashConvertMozillaCode(code:Int) :Int
	{
		switch(code)
		{
			case DOM_VK_BACK_SPACE: return BACKSPACE;
			case DOM_VK_TAB: return TAB;
			case DOM_VK_RETURN: return ENTER;
			case DOM_VK_ENTER: return ENTER;
			case DOM_VK_SHIFT: return SHIFT;
			case DOM_VK_CONTROL: return CONTROL;
			case DOM_VK_CAPS_LOCK: return CAPS_LOCK;
			case DOM_VK_ESCAPE: return ESCAPE;
			case DOM_VK_SPACE: return SPACE;
			case DOM_VK_PAGE_UP: return PAGE_UP;
			case DOM_VK_PAGE_DOWN: return PAGE_DOWN;
			case DOM_VK_END: return END;
			case DOM_VK_HOME: return HOME;
			case DOM_VK_LEFT: return LEFT;
			case DOM_VK_RIGHT: return RIGHT;
			case DOM_VK_UP: return UP;
			case DOM_VK_DOWN: return DOWN;
			case DOM_VK_INSERT: return INSERT;
			case DOM_VK_DELETE: return DELETE;
			case DOM_VK_NUM_LOCK: return NUMLOCK;
			default:
						      return code;
		}
	}

	static public var capsLock(default,null):Bool;
	static public var numLock(default,null):Bool;

	static public function isAccessible()
	{
		// default browser security restrictions are always enforced
		return false;
	}

}


#else
typedef Keyboard = flash.ui.Keyboard;
#end