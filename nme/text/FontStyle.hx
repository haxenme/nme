package nme.text;


#if flash
@:native ("flash.text.FontStyle")
@:fakeEnum(String) extern enum FontStyle {
	BOLD;
	BOLD_ITALIC;
	ITALIC;
	REGULAR;
}
#end