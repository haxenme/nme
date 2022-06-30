#include <interface/vmcs_host/vc_dispmanx.h>
#include <bcm_host.h>
#include <stdio.h>


static void *getBcmFunc(const char *inFuncName)
{
   static void *bcmLib = 0;
   if (!bcmLib)
   {
      bcmLib = dlopen("libbcm_host.so", RTLD_NOW|RTLD_GLOBAL);
      if (!bcmLib)
         bcmLib = dlopen("/opt/vc/lib/libbcm_host.so", RTLD_NOW|RTLD_GLOBAL);
      if (!bcmLib)
      {
         printf("Could not open libbcm_host.so\n");
         exit(-1);
      }
      printf("Found bcmLib!\n");
   }

   void *result = (void *)dlsym(bcmLib, inFuncName);
   if (!result)
   {
         printf("Could not find %s in libbcm_host.so\n", inFuncName);
         exit(-1);
   }
   return result;
}


#define BCM_LOAD(name, ret, types, args) \
   typedef ret (*funcType)types; \
   static funcType func = 0; \
   if (!func) func = (funcType)getBcmFunc(name); \
   func args;


void bcm_host_init(void)
{
   typedef void (*type)(void);
   static type func = 0;
   if (!func) func = (type)getBcmFunc("bcm_host_init");
   func();
}

int32_t graphics_get_display_size( const uint16_t display_number,
                                   uint32_t *width,
                                   uint32_t *height)
{
   BCM_LOAD("graphics_get_display_size", int32_t, (const uint16_t, uint32_t *, uint32_t *), (display_number, width, height) )
}



VCHPRE_ int VCHPOST_ vc_dispmanx_rect_set( VC_RECT_T *rect, uint32_t x_offset, uint32_t y_offset, uint32_t width, uint32_t height )
{
   BCM_LOAD("vc_dispmanx_rect_set", int, (VC_RECT_T *, uint32_t, uint32_t, uint32_t, uint32_t), (rect,x_offset,y_offset,width,height) )
}



VCHPRE_ DISPMANX_RESOURCE_HANDLE_T VCHPOST_ vc_dispmanx_resource_create( VC_IMAGE_TYPE_T type, uint32_t width, uint32_t height, uint32_t *native_image_handle )
{
   BCM_LOAD("vc_dispmanx_resource_create", DISPMANX_RESOURCE_HANDLE_T, (VC_IMAGE_TYPE_T,uint32_t,uint32_t,uint32_t *),(type,width,height,native_image_handle) )
}



VCHPRE_ int VCHPOST_ vc_dispmanx_resource_write_data( DISPMANX_RESOURCE_HANDLE_T res, VC_IMAGE_TYPE_T src_type, int src_pitch, void * src_address, const VC_RECT_T * rect )
{
   BCM_LOAD("vc_dispmanx_resource_write_data", int, (DISPMANX_RESOURCE_HANDLE_T, VC_IMAGE_TYPE_T, int, void *,const VC_RECT_T *), (res,src_type,src_pitch, src_address, rect ) )
}



VCHPRE_ int VCHPOST_ vc_dispmanx_resource_delete( DISPMANX_RESOURCE_HANDLE_T res )
{
   BCM_LOAD("vc_dispmanx_resource_delete", int, (DISPMANX_RESOURCE_HANDLE_T), (res) )
}



VCHPRE_ DISPMANX_DISPLAY_HANDLE_T VCHPOST_ vc_dispmanx_display_open( uint32_t device )
{
   BCM_LOAD("vc_dispmanx_display_open", DISPMANX_DISPLAY_HANDLE_T, (uint32_t),(device) )
}



VCHPRE_ DISPMANX_UPDATE_HANDLE_T VCHPOST_ vc_dispmanx_update_start( int32_t priority )
{
   BCM_LOAD("vc_dispmanx_update_start", DISPMANX_UPDATE_HANDLE_T, (uint32_t), (priority) )
}



VCHPRE_ DISPMANX_ELEMENT_HANDLE_T VCHPOST_ vc_dispmanx_element_add ( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_DISPLAY_HANDLE_T display,
                                                                     int32_t layer, const VC_RECT_T *dest_rect, DISPMANX_RESOURCE_HANDLE_T src,
                                                                     const VC_RECT_T *src_rect, DISPMANX_PROTECTION_T protection, 
                                                                     VC_DISPMANX_ALPHA_T *alpha,
                                                                     DISPMANX_CLAMP_T *clamp, DISPMANX_TRANSFORM_T transform )
{
   BCM_LOAD("vc_dispmanx_element_add", DISPMANX_ELEMENT_HANDLE_T, 
                      ( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_DISPLAY_HANDLE_T display,
                        int32_t layer, const VC_RECT_T *dest_rect, DISPMANX_RESOURCE_HANDLE_T src,
                        const VC_RECT_T *src_rect, DISPMANX_PROTECTION_T protection, 
                        VC_DISPMANX_ALPHA_T *alpha,
                        DISPMANX_CLAMP_T *clamp, DISPMANX_TRANSFORM_T transform ),
                      ( update, display,
                        layer, dest_rect, src,
                        src_rect, protection, 
                        alpha,
                        clamp, transform ) )
}




VCHPRE_ int VCHPOST_ vc_dispmanx_element_remove( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_ELEMENT_HANDLE_T element )
{
   BCM_LOAD("vc_dispmanx_element_remove", int, (DISPMANX_UPDATE_HANDLE_T, DISPMANX_ELEMENT_HANDLE_T), (update, element) )
}



VCHPRE_ int VCHPOST_ vc_dispmanx_update_submit( DISPMANX_UPDATE_HANDLE_T update, DISPMANX_CALLBACK_FUNC_T cb_func, void *cb_arg )
{
   BCM_LOAD("vc_dispmanx_update_submit", int, (DISPMANX_UPDATE_HANDLE_T, DISPMANX_CALLBACK_FUNC_T, void *),(update, cb_func, cb_arg) )
}



VCHPRE_ int VCHPOST_ vc_dispmanx_update_submit_sync( DISPMANX_UPDATE_HANDLE_T update )
{
   BCM_LOAD("vc_dispmanx_update_submit_sync", int, (DISPMANX_UPDATE_HANDLE_T), (update) );
}



VCHPRE_ int VCHPOST_ vc_dispmanx_element_change_attributes( DISPMANX_UPDATE_HANDLE_T update, 
                                                            DISPMANX_ELEMENT_HANDLE_T element,
                                                            uint32_t change_flags,
                                                            int32_t layer,
                                                            uint8_t opacity,
                                                            const VC_RECT_T *dest_rect,
                                                            const VC_RECT_T *src_rect,
                                                            DISPMANX_RESOURCE_HANDLE_T mask,
                                                            DISPMANX_TRANSFORM_T transform )
{
   BCM_LOAD("vc_dispmanx_element_change_attributes", int, ( DISPMANX_UPDATE_HANDLE_T update, 
                                                            DISPMANX_ELEMENT_HANDLE_T element,
                                                            uint32_t change_flags,
                                                            int32_t layer,
                                                            uint8_t opacity,
                                                            const VC_RECT_T *dest_rect,
                                                            const VC_RECT_T *src_rect,
                                                            DISPMANX_RESOURCE_HANDLE_T mask,
                                                            DISPMANX_TRANSFORM_T transform ),
                                                          ( update, 
                                                            element,
                                                            change_flags,
                                                            layer,
                                                            opacity,
                                                            dest_rect,
                                                            src_rect,
                                                            mask,
                                                            transform ) )
}




VCHPRE_ int VCHPOST_ vc_dispmanx_vsync_callback( DISPMANX_DISPLAY_HANDLE_T display, DISPMANX_CALLBACK_FUNC_T cb_func, void *cb_arg )
{
   BCM_LOAD("vc_dispmanx_vsync_callback", int, (DISPMANX_DISPLAY_HANDLE_T, DISPMANX_CALLBACK_FUNC_T,void *), (display, cb_func, cb_arg) )
}







