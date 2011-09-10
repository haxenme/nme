#if flash

package nme.text;


@:native ("flash.text.FontType")
@:fakeEnum(String) extern enum FontType {
	DEVICE;
	EMBEDDED;
	EMBEDDED_CFF;
}


#end