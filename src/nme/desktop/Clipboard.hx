package nme.desktop;

#if (!flash)
import nme.Loader;

@:nativeProperty
class Clipboard {
    public var formats(get, null) : Array<ClipboardFormats>;

    private var _htmlText:String = null;
    private var _richText:String = null;
    private var _text:String = null;
    private var _systemClipboard:Bool = false;

    public function new() {

    }

    private function get_formats(): Array<ClipboardFormats> {
        return [HTML_FORMAT, RICH_TEXT_FORMAT, TEXT_FORMAT];
    }

	public function clear() {
        if (!_systemClipboard) {
            _htmlText = null;
            _richText = null;
            _text = null;
        } else
            nme_desktop_clipboard_set_clipboard_text(null);
    }

    public function clearData(format : ClipboardFormats) {
        if (!_systemClipboard) {
            switch (format) {
                case HTML_FORMAT:
                    _htmlText = null;
                case RICH_TEXT_FORMAT:
                    _richText = null;
                case TEXT_FORMAT:
                    _text = null;
                default:
            }
        } else {
            switch (format) {
                case HTML_FORMAT, RICH_TEXT_FORMAT, TEXT_FORMAT:
                    nme_desktop_clipboard_set_clipboard_text(null);
                default:
            }
        }
    }

    public function getData(format : ClipboardFormats, transferMode : ClipboardTransferMode = null) : Dynamic {
        if (transferMode == null)
            transferMode = ORIGINAL_PREFERRED;

        if (!_systemClipboard) {
            return switch (format) {
                case HTML_FORMAT: _htmlText;
                case RICH_TEXT_FORMAT: _richText;
                case TEXT_FORMAT: _text;
                default: null;
            }
        } else {
            return switch (format) {
                case HTML_FORMAT, RICH_TEXT_FORMAT, TEXT_FORMAT: nme_desktop_clipboard_get_clipboard_text();
                default: null;
            }
        }
    }

    public function hasFormat(format : ClipboardFormats) : Bool
    {
        if (!_systemClipboard) {
            return switch (format) {
                case HTML_FORMAT: _htmlText != null;
                case RICH_TEXT_FORMAT: _richText != null;
                case TEXT_FORMAT: _text != null;
                default: false;
            }
        } else {
            return switch (format) {
                case HTML_FORMAT, RICH_TEXT_FORMAT, TEXT_FORMAT: nme_desktop_clipboard_has_clipboard_text();
                default: false;
            }
        }
    }

    public function setData(format : ClipboardFormats, data : Dynamic, serializable : Bool = true): Bool {
        if (!_systemClipboard) {
            switch (format) {
                case HTML_FORMAT:
                    _htmlText = data;
                    return true;
                case RICH_TEXT_FORMAT:
                    _richText = data;
                    return true;
                case TEXT_FORMAT:
                    _text = data;
                    return true;
                default:
                    return false;
            }
        } else {
            switch (format) {
                case HTML_FORMAT, RICH_TEXT_FORMAT, TEXT_FORMAT:
                    return nme_desktop_clipboard_set_clipboard_text(data);
                default:
                    return false;
            }
        }
    }

    public function setDataHandler(format : ClipboardFormats, handler : Dynamic, serializable : Bool = true) {
        throw "Clipboard.setDataHandler not implemented";
        return false;
    }

	public static var generalClipboard(get,null) : Clipboard;
    private static var _generalClipboard: Clipboard = null;
    private static function get_generalClipboard() {
        if(_generalClipboard == null) {
            _generalClipboard = new Clipboard();
            _generalClipboard._systemClipboard = true;
        }
        return _generalClipboard;
    }

    // Native Methods
    private static var nme_desktop_clipboard_set_clipboard_text = Loader.load("nme_desktop_clipboard_set_clipboard_text", 1);
    private static var nme_desktop_clipboard_has_clipboard_text = nme.PrimeLoader.load("nme_desktop_clipboard_has_clipboard_text", "b");
    private static var nme_desktop_clipboard_get_clipboard_text = Loader.load("nme_desktop_clipboard_get_clipboard_text", 0);
}
#else
typedef Clipboard = flash.desktop.Clipboard;
#end
