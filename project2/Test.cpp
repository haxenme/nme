#include <Graphics.h>


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable,"Hello");
   MainLoop();
   delete frame;
   return 0;
}
