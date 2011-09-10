package nme.display;


#if flash
@:native ("flash.display.SWFVersion")
@:fakeEnum(UInt) extern enum SWFVersion {
	FLASH1;
	FLASH10;
	FLASH2;
	FLASH3;
	FLASH4;
	FLASH5;
	FLASH6;
	FLASH7;
	FLASH8;
	FLASH9;
}
#end