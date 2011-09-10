#if flash


package nme.text;


@:native ("flash.text.FontStyle")
@:fakeEnum(String) extern enum FontStyle {
	BOLD;
	BOLD_ITALIC;
	ITALIC;
	REGULAR;
}


#end