package nme.desktop;

#if (cpp || neko)
enum ClipboardTransferMode {
	CLONE_ONLY;
	CLONE_PREFERRED;
	ORIGINAL_ONLY;
	ORIGINAL_PREFERRED;
}
#else
typedef ClipboardTransferMode = flash.desktop.ClipboardTransferMode;
#end