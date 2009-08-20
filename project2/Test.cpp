#include <Graphics.h>

Graphics gGraphics;
Transform gTransform;

void Handler(Event &ioEvent,void *inStage)
{
	Stage *stage = (Stage *)inStage;


	if (ioEvent.mType==etNextFrame)
	{
		Transform t;
		Surface *surface = stage->GetPrimarySurface();

		if (surface->BeginHardwareRender(0))
		{
         surface->EndHardwareRender();
		}
		else
		{
			// gGraphics.Render(surface,gTransform);
		}
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

	// Extent2DF ext = gGraphics.GetExtent(gTransform);

   MainLoop();
   delete frame;
   return 0;
}
