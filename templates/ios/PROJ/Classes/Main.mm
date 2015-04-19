/*
 *  Main.mm
 *
 *  Boot code for NME.
 *
 */

#import <Foundation/Foundation.h>

extern "C" const char *hxRunLibrary();
extern "C" void hxcpp_set_top_of_stack();
   
extern "C" int main(int argc, char *argv[])   
{
   NSLog(@"Launching ::APP_PACKAGE::");
   //printf("Starting ...\n" );
   hxcpp_set_top_of_stack();

   //printf("Running\n");

   const char *err = NULL;
       err = hxRunLibrary();
   if (err) {
      printf(" Error %s\n", err );
      return -1;
   }

   //printf("Done!\n");
   return 0;
}
