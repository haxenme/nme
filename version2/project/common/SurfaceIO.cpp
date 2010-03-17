#include <stdio.h>
#include <Surface.h>
extern "C" {
#include <jpeglib.h>
#include <png.h>
}
#include <setjmp.h>

using namespace nme;

struct ErrorData
{
   struct jpeg_error_mgr base; // base
   jmp_buf on_error;     // return;
};

static void OnError(j_common_ptr cinfo)
{
   ErrorData * err = (ErrorData *)cinfo->err;
   // return...
   longjmp(err->on_error, 1);
}

static Surface *TryJPEG(FILE *inFile)
{
   struct jpeg_decompress_struct cinfo;

   // Don't exit on error!
   struct ErrorData jpegError;
   cinfo.err = jpeg_std_error(&jpegError.base);
   jpegError.base.error_exit = OnError;

   Surface *result = 0;
   uint8 *row_buf = 0;

   // Establish the setjmp return context for ErrorFunction to use
   if (setjmp(jpegError.on_error))
   {
      if (row_buf)
         free(row_buf);
      if (result)
         result->DecRef();

      jpeg_destroy_decompress(&cinfo);
      return 0;
   }

   // Initialize the JPEG decompression object.
   jpeg_create_decompress(&cinfo);

   // Specify data source (ie, a file)
   jpeg_stdio_src(&cinfo, inFile);

   // Read file parameters with jpeg_read_header().
   if (jpeg_read_header(&cinfo, TRUE)!=JPEG_HEADER_OK)
      return 0;

   cinfo.out_color_space = JCS_RGB;

   // Start decompressor.
   jpeg_start_decompress(&cinfo);

   result = new SimpleSurface(cinfo.output_width, cinfo.output_height, pfXRGB);
   result->IncRef();


   RenderTarget target = result->BeginRender(Rect(cinfo.output_width, cinfo.output_height));


   row_buf = (uint8 *)malloc(cinfo.output_width * 3);

   int c0_idx = gC0IsRed ? 0 : 2;
   int c1_idx = 2-c0_idx;

   while (cinfo.output_scanline < cinfo.output_height)
   {
      uint8 * src = row_buf;
      uint8 * dest = target.Row(cinfo.output_scanline);

      jpeg_read_scanlines(&cinfo, &row_buf, 1);

      uint8 *end = dest + cinfo.output_width*4;
      while (dest<end)
      {
         dest[0] = src[c0_idx];
         dest[1] = src[1];
         dest[2] = src[c1_idx];
         dest[3] = 0xff;
         dest+=4;
         src+=3;
      }
   }
   result->EndRender();

   free(row_buf);

   // Finish decompression.
   jpeg_finish_decompress(&cinfo);

   // Release JPEG decompression object
   jpeg_destroy_decompress(&cinfo);

   return result;
}

static void user_error_fn(png_structp png_ptr, png_const_charp error_msg) { }
static void user_warning_fn(png_structp png_ptr, png_const_charp warning_msg) { }

static Surface *TryPNG(FILE *inFile)
{
	png_structp png_ptr;
   png_infop info_ptr;
   png_uint_32 width, height;
   int bit_depth, color_type, interlace_type;

   /* Create and initialize the png_struct with the desired error handler
    * functions.  If you want to use the default stderr and longjump method,
    * you can supply NULL for the last three parameters.  We also supply the
    * the compiler header file version, so that we know if the application
    * was compiled with a compatible version of the library.  REQUIRED
    */
   png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING,
      0, user_error_fn, user_warning_fn);

   if (png_ptr == NULL)
      return (0);

   /* Allocate/initialize the memory for image information.  REQUIRED. */
   info_ptr = png_create_info_struct(png_ptr);
   if (info_ptr == NULL)
   {
      png_destroy_read_struct(&png_ptr, png_infopp_NULL, png_infopp_NULL);
      return (0);
   }

   /* Set error handling if you are using the setjmp/longjmp method (this is
    * the normal method of doing things with libpng).  REQUIRED unless you
    * set up your own error handlers in the png_create_read_struct() earlier.
    */

	Surface *result = 0;
	RenderTarget target;

   if (setjmp(png_jmpbuf(png_ptr)))
   {
		if (result)
		{
			result->EndRender();
			result->DecRef();
		}

      /* Free all of the memory associated with the png_ptr and info_ptr */
      png_destroy_read_struct(&png_ptr, &info_ptr, png_infopp_NULL);
      /* If we get here, we had a problem reading the file */
      return (0);
   }

   png_init_io(png_ptr, inFile);

   png_read_info(png_ptr, info_ptr);
   png_get_IHDR(png_ptr, info_ptr, &width, &height, &bit_depth, &color_type,
       &interlace_type, NULL, NULL);

	bool has_alpha = color_type== PNG_COLOR_TYPE_GRAY_ALPHA ||
                    color_type==PNG_COLOR_TYPE_RGB_ALPHA;
   /* Add filler (or alpha) byte (before/after each RGB triplet) */
   png_set_expand(png_ptr);
   png_set_filler(png_ptr, 0xff, PNG_FILLER_AFTER);
   //png_set_gray_1_2_4_to_8(png_ptr);
   png_set_palette_to_rgb(png_ptr);
   png_set_gray_to_rgb(png_ptr);


	if (!gC0IsRed)
      png_set_bgr(png_ptr);

	result = new SimpleSurface(width,height,has_alpha ? pfARGB : pfXRGB);
	result->IncRef();
	target = result->BeginRender(Rect(width,height));

   for (int i = 0; i < height; i++)
   {
      png_bytep anAddr = (png_bytep) target.Row(i);
      png_read_rows(png_ptr, (png_bytepp) &anAddr, NULL, 1);
   }

	result->EndRender();

   /* read rest of file, and get additional chunks in info_ptr - REQUIRED */
   png_read_end(png_ptr, info_ptr);

   /* clean up after the read, and free any memory allocated - REQUIRED */
   png_destroy_read_struct(&png_ptr, &info_ptr, png_infopp_NULL);

   /* that's it */
   return result;
}

namespace nme {

Surface *Surface::Load(const OSChar *inFilename)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
      return 0;

   Surface *result = TryJPEG(file);
   if (!result)
   {
      rewind(file);
		result = TryPNG(file);
   }

   fclose(file);
   return result;
}

}
