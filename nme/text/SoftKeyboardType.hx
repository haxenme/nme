package nme.text;
#if (!flash)

@:nativeProperty
class SoftKeyboardType
{
    public static inline var DEFAULT : Int = 0;//Default keyboard for the current input method.
    public static inline var CONTACT : Int = 1;//A keypad designed for entering a person's name or phone number.
    public static inline var EMAIL : Int = 2;//A keyboard optimized for specifying email addresses.
    public static inline var NUMBER : Int = 3;//A numeric keypad designed for PIN entry.
    public static inline var PUNCTUATION : Int = 4;//A numeric keypad designed for PIN entry.
    public static inline var URL : Int = 5;//A keyboard optimized for entering URLs.

    public static inline var ANDROID_VISIBLE_PASSWORD: Int = 101;
    public static inline var IOS_ASCII: Int = 102;

    public function new()
    {
    }
}

#else
typedef SoftKeyboardType = flash.text.SoftKeyboardType;
#end
