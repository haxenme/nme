#include <Graphics.h>

void Handler(Event &ioEvent,void *inStage)
{
	Stage *stage = (Stage *)inStage;
	if (ioEvent.mType==etNextFrame)
	{
		stage->Flip();
	}
}


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable,"Hello");

	frame->GetStage()->SetEventHandler(Handler,frame->GetStage());

   MainLoop();
   delete frame;
   return 0;
}
