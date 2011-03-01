/*
 *  Main.cpp
 *
 *  Boot code for NME.
 *  You can remove the printfs if you like, but you need hxcpp_set_top_of_stack and
 *   nme_register_prims(if you want NME).
 *
 */



#include <stdio.h>


extern "C" int nme_register_prims();
extern "C" const char *hxRunLibrary();
extern "C" void hxcpp_set_top_of_stack();
	
	
extern "C" int main(int argc, char *argv[])	
{
	printf("Starting ...\n" );
	hxcpp_set_top_of_stack();
	nme_register_prims();
 
	printf("Running\n");
 	const char *err = hxRunLibrary();
	if (err) {
		printf(" Error %s\n", err );
		return -1;
	}
	printf("Done!\n");
	return 0;
}
