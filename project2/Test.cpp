#include <Graphics.h>

Graphics gGraphics;

void Handler(Event &ioEvent,void *inStage)
{
	Stage *stage = (Stage *)inStage;


	if (ioEvent.mType==etNextFrame)
	{
		Transform t;
		IRenderTarget *target = stage->GetRenderTarget();
		target->BeginRender();
		target->Render(gGraphics,t);
		target->EndRender();
		stage->Flip();
	}
}


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable,"Hello");

	frame->GetStage()->SetEventHandler(Handler,frame->GetStage());

	gGraphics.beginFill(0xff0000);
	gGraphics.moveTo(10,10);
	gGraphics.lineTo(100,100);
	gGraphics.lineTo(100,300);
	gGraphics.lineTo(300,300);
	gGraphics.lineTo(10,10);

   MainLoop();
   delete frame;
   return 0;
}
