package nme.text;
#if (cpp || neko)

@:nativeProperty
class SoftKeyboardType
{
    public static inline var CONTACT : String = "contact";//A keypad designed for entering a person's name or phone number.
    public static inline var DEFAULT : String = "default";//Default keyboard for the current input method.
    public static inline var EMAIL : String = "email";//A keyboard optimized for specifying email addresses.
    public static inline var NUMBER : String = "number";//A numeric keypad designed for PIN entry.
    public static inline var PUNCTUATION : String = "punctuation";//A numeric keypad designed for PIN entry.
    public static inline var URL : String = "url";//A keyboard optimized for entering URLs.

    public function new()
    {
    }
}

#else
typedef SoftKeyboardType = flash.text.SoftKeyboardType;
#end
