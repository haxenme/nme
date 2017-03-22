/***************************************************************************/
/*                                                                         */
/* Project:     OpenSLP - OpenSource implementation of Service Location    */
/*              Protocol                                                   */
/*                                                                         */
/* File:        slp.h                                                      */
/*                                                                         */
/* Abstract:    Main header file for the SLP API exactly as described by   */
/*              rfc2614.  This is the only file that needs to be included  */
/*              in order make all SLP API declarations.                    */
/*                                                                         */
/* Author(s)    Matt Peterson <mpeterson@caldera.com>                      */
/*-------------------------------------------------------------------------*/
/*                                                                         */
/*     Please submit patches to http://www.openslp.org                     */
/*                                                                         */
/*-------------------------------------------------------------------------*/
/*                                                                         */
/* Copyright (C) 2000 Caldera Systems, Inc                                 */
/* All rights reserved.                                                    */
/*                                                                         */
/* Redistribution and use in source and binary forms, with or without      */
/* modification, are permitted provided that the following conditions are  */
/* met:                                                                    */ 
/*                                                                         */
/*      Redistributions of source code must retain the above copyright     */
/*      notice, this list of conditions and the following disclaimer.      */
/*                                                                         */
/*      Redistributions in binary form must reproduce the above copyright  */
/*      notice, this list of conditions and the following disclaimer in    */
/*      the documentation and/or other materials provided with the         */
/*      distribution.                                                      */
/*                                                                         */
/*      Neither the name of Caldera Systems nor the names of its           */
/*      contributors may be used to endorse or promote products derived    */
/*      from this software without specific prior written permission.      */
/*                                                                         */
/* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS     */
/* `AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      */
/* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR   */
/* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE CALDERA      */
/* SYSTEMS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, */
/* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT        */
/* LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  */
/* DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON       */
/* ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT */
/* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE   */
/* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.    */
/*                                                                         */
/***************************************************************************/

#if(!defined SLP_H_INCLUDED)
#define SLP_H_INCLUDED

#if(defined __cplusplus)
extern "C"
{
#endif

#if defined(_WIN32) && defined(_MSC_VER)
/* MSVC auto-exports, BCB uses .def file */
# define SLPCALLBACK
# ifdef LIBSLP_EXPORTS
#  define SLPEXP __declspec(dllexport)
# elif defined(LIBSLP_STATIC)
#  define SLPEXP
# else
#  define SLPEXP __declspec(dllimport)
# endif
# define SLPAPI
#else
# define SLPCALLBACK
# define SLPEXP
# define SLPAPI
#endif

/*==========================================================================*/
/* lifetime values, in  seconds, that are frequently used.                  */
/*==========================================================================*/
#define SLP_LIFETIME_DEFAULT 10800   /* 3 hours  */
#define SLP_LIFETIME_MAXIMUM 65535   /* 18 hours */


/*==========================================================================*/
/* SLPError                                                                 */
/* ---------                                                                */
/* The SLPError type represents error codes that are returned from API      */
/* functions.                                                               */
typedef int SLPError;

#define  SLP_LAST_CALL              1

/* passed to callback functions when the API                            */
/* library has no more data for them and therefore no further calls     */
/* will be made to the callback on the currently outstanding operation. */
/* The callback can use this to signal the main body of the client code */
/* that no more data will be forthcoming on the operation, so that the  */
/* main body of the client code can break out of data collection loops. */
/* On * the last call of a callback during both a synchronous and       */
/* asynchronous call, the error code parameter has value SLP_LAST_CALL, */
/* and the other parameters are all NULL. If no results are returned by */
/* an API operation, then only one call is made, with the error         */
/* parameter set to SLP_LAST_CALL.                                      */

#define SLP_OK                      0

/* indicates that the no error occurred during the operation.           */

#define SLP_LANGUAGE_NOT_SUPPORTED  -1

/* No DA or SA has service advertisement or attribute information       */
/* in the language requested, but at least one DA or SA indicated,      */
/* via the LANGUAGE_NOT_SUPPORTED error code, that it might have        */
/* information for that service in another language                     */

#define SLP_PARSE_ERROR             -2

/* The SLP message was rejected by a remote SLP agent.  The API         */
/* returns this error only when no information was retrieved, and       */
/* at least one SA or DA indicated a protocol error.  The data          */
/* supplied through the API may be malformed or a may have been         */
/* damaged in transit.                                                  */

#define SLP_INVALID_REGISTRATION    -3

/* The API may return this error if an attempt to register a            */
/* service was rejected by all DAs because of a malformed URL or        */
/* attributes.  SLP does not return the error if at least one DA        */
/* accepted the registration.                                           */

#define SLP_SCOPE_NOT_SUPPORTED     -4

/* The API returns this error if the SA has been configured with        */
/* net.slp.useScopes value-list of scopes and the SA request did        */
/* not specify one or more of these allowable scopes, and no            */
/* others.  It may be returned by a DA or SA if the scope included      */
/* in a request is not supported by the DA or SA.                       */

#define SLP_AUTHENTICATION_ABSENT   -6

/* if the SLP framework supports authentication, this error arises      */
/* when the UA or SA failed to send an authenticator for requests       */
/* or registrations in a protected scope.                               */

#define SLP_AUTHENTICATION_FAILED   -7

/* If the SLP framework supports authentication, this error arises      */
/* when a authentication on an SLP message failed                       */

#define SLP_INVALID_UPDATE          -13

/* An update for a non-existing registration was issued, or the         */
/* update includes a service type or scope different than that in       */
/* the initial registration, etc.                                       */

#define SLP_REFRESH_REJECTED        -15

/* The SA attempted to refresh a registration more frequently           */
/* than the minimum refresh interval.  The SA should call the           */
/* appropriate API function to obtain the minimum refresh interval      */
/* to use.                                                              */

#define SLP_NOT_IMPLEMENTED         -17

/* If an unimplemented feature is used, this error is returned.         */

#define SLP_BUFFER_OVERFLOW         -18

/* An outgoing request overflowed the maximum network MTU size.         */
/* The request should be reduced in size or broken into pieces and      */
/* tried again.                                                         */

#define SLP_NETWORK_TIMED_OUT       -19

/* When no reply can be obtained in the time specified by the           */
/* configured timeout interval for a unicast request, this error        */
/* is returned.                                                         */

#define SLP_NETWORK_INIT_FAILED     -20

/* If the network cannot initialize properly, this error is             */
/* returned.  Will also be returned if an SA or DA agent (slpd)         */
/* can not be contacted. See SLPRegReport() callback.                   */

#define SLP_MEMORY_ALLOC_FAILED     -21

/* Out of memory error */

#define SLP_PARAMETER_BAD           -22

/* If a parameter passed into an interface is bad, this error is        */
/* returned.                                                            */

#define SLP_NETWORK_ERROR           -23

/* The failure of networking during normal operations causes this       */
/* error to be returned.                                                */

#define SLP_INTERNAL_SYSTEM_ERROR   -24

/* A basic failure of the API causes this error to be returned.         */
/* This occurs when a system call or library fails.  The operation      */
/* could not recover.                                                   */

#define SLP_HANDLE_IN_USE           -25

/* In the C API, callback functions are not permitted to                */
/* recursively call into the API on the same SLPHandle, either          */
/* directly or indirectly.  If an attempt is made to do so, this        */
/* error is returned from the called API function.                      */

#define SLP_TYPE_ERROR              -26

	
#ifndef UNICAST_NOT_SUPPORTED
/* The SLP UA needs to send a unicast query to a SA because this SA has */
/* sent a packet > MTU size                                            */
# define SLP_RETRY_UNICAST           -27
#endif

	
/* If the API supports type checking of registrations against           */
/* service type templates, this error can arise if the attributes       */
/* in a registration do not match the service type template for         */
/* the service.                                                         */

/*==========================================================================*/
/* SLPBoolean                                                               */
/*------------                                                              */
/* The SLPBoolean enum is used as a boolean flag.                           */
typedef enum
{
    SLP_FALSE = 0,
    SLP_TRUE = 1
} SLPBoolean;


/*==========================================================================*/
/* SLPSrvURL                                                                */
/*-----------                                                               */
/* The SLPSrvURL structure is filled in by the SLPParseSrvURL() function    */
/* with information parsed from a character buffer containing a service     */
/* URL. The fields correspond to different parts of the URL. Note that      */
/* the structure is in conformance with the standard Berkeley sockets       */
/* struct servent, with the exception that the pointer to an array of       */
/* characters for aliases (s_aliases field) is replaced by the pointer      */
/* to host name (s_pcHost field).                                           */
typedef struct srvurl
{
    char *s_pcSrvType;
    /* A pointer to a character string containing the service              */
    /* type name, including naming authority.  The service type            */
    /* name includes the "service:" if the URL is of the service:          */
    /* scheme.                                                             */

    char *s_pcHost;
    /* A pointer to a character string containing the host                 */
    /* identification information.                                         */

    int   s_iPort;
    /* The port number, or zero if none.  The port is only available       */
    /* if the transport is IP.                                             */

    char *s_pcNetFamily;
    /* A pointer to a character string containing the network address      */
    /* family identifier.  Possible values are "ipx" for the IPX           */
    /* family, "at" for the Appletalk family, and "" (i.e.  the empty      */
    /* string) for the IP address family.                                  */

    char *s_pcSrvPart;
    /* The remainder of the URL, after the host identification.            */

} SLPSrvURL;
/*=========================================================================*/


#if(!defined SLPHANDLE_INTERNAL)

/*=========================================================================*/
typedef void* SLPHandle;
/*                                                                         */
/* The SLPHandle type is returned by SLPOpen() and is a parameter to all   */
/* SLP functions.  It serves as a handle for all resources allocated on    */
/* behalf of the process by the SLP library.  The type is opaque, since    */
/* the exact nature differs depending on the implementation.               */
/*=========================================================================*/
#endif



/*=========================================================================*/
typedef void SLPCALLBACK SLPRegReport(SLPHandle hSLP,
                          SLPError errCode,
                          void *pvCookie);
/*                                                                         */
/* The SLPRegReport callback type is the type of the callback function     */
/* to the SLPReg(), SLPDereg(), and SLPDelAttrs() functions.               */
/*                                                                         */
/* hSLP     The SLPHandle used to initiate the operation.                  */
/*                                                                         */
/* errCode  An error code indicating if an error occurred during the       */
/*          operation.                                                     */
/*                                                                         */
/* pvCookie Memory passed down from the client code that called the        */
/*          original API function, starting the operation.  May be NULL.   */
/*=========================================================================*/


/*=========================================================================*/
typedef SLPBoolean SLPCALLBACK SLPSrvTypeCallback(SLPHandle hSLP,
                                      const char* pcSrvTypes,
                                      SLPError errCode,
                                      void *pvCookie);
/*                                                                         */
/* The SLPSrvTypeCallback type is the type of the callback function        */
/* parameter to SLPFindSrvTypes() function.  If the hSLP handle            */
/* parameter was opened asynchronously, the results returned through the   */
/* callback MAY be uncollated.  If the hSLP handle parameter was opened    */
/* synchronously, then the returned results must be collated and           */
/* duplicates eliminated.                                                  */
/*                                                                         */
/* hSLP         The SLPHandle used to initiate the operation.              */
/*                                                                         */
/* pcSrvTypes   A character buffer containing a comma separated, null      */
/*              terminated list of service types.                          */
/*                                                                         */
/* errCode      An error code indicating if an error occurred during the   */
/*              operation.  The callback should check this error code befor*/
/*              processing the parameters.  If the error code is other than*/
/*              SLP_OK, then the API library may choose to terminate the   */
/*              outstanding operation.                                     */
/*                                                                         */
/* pvCookie     Memory passed down from the client code that called the    */
/*              original API function, starting the operation.  May be NULL*/
/*                                                                         */
/* Returns      The client code should return SLP_TRUE if more data is     */
/*              desired, otherwise return SLP_FALSE                        */
/*=========================================================================*/


/*=========================================================================*/
typedef SLPBoolean SLPCALLBACK SLPSrvURLCallback(SLPHandle hSLP,
                                     const char* pcSrvURL,
                                     unsigned short sLifetime,
                                     SLPError errCode,
                                     void *pvCookie);
/*                                                                         */
/* The SLPSrvURLCallback type is the type of the callback function         */
/* parameter to SLPFindSrvs() function.  If the hSLP handle parameter      */
/* was opened asynchronously, the results returned through the callback    */
/* MAY be uncollated.  If the hSLP handle parameter was opened             */
/* synchronously, then the returned results must be collated and           */
/* duplicates eliminated.                                                  */
/*                                                                         */
/* hSLP         The SLPHandle used to initiate the operation.              */
/*                                                                         */
/* pcSrvURL     A character buffer containing the returned service URL.    */
/*              May be NULL if errCode not SLP_OK.                         */
/*                                                                         */
/* sLifetime    An unsigned short giving the life time of the service      */
/*              advertisement, in seconds.  The value must be an unsigned  */
/*              integer less than or equal to SLP_LIFETIME_MAXIMUM.        */
/*                                                                         */
/* errCode      An error code indicating if an error occurred during the   */
/*              operation.  The callback should check this error code      */
/*              before processing the parameters.  If the error code is    */
/*              other than SLP_OK, then the API library may choose to      */
/*              terminate the outstanding operation. SLP_LAST_CALL is      */
/*              returned when no more services are available and the       */
/*              callback will not be called again..                        */
/*                                                                         */
/* pvCookie     Memory passed down from the client code that called the    */
/*              original API function, starting the operation.             */
/*              May be NULL.                                               */
/*                                                                         */
/* Returns      The client code should return SLP_TRUE if more data is     */
/*              desired, otherwise return SLP_FALSE                        */
/*=========================================================================*/


/*=========================================================================*/
typedef SLPBoolean SLPCALLBACK SLPAttrCallback(SLPHandle hSLP,
                                   const char* pcAttrList,
                                   SLPError errCode,
                                   void *pvCookie); 
/*                                                                         */
/* The SLPAttrCallback type is the type of the callback function           */
/* parameter to SLPFindAttrs() function.                                   */
/*                                                                         */
/* The behavior of the callback differs depending on whether the           */
/* attribute request was by URL or by service type.  If the                */
/* SLPFindAttrs() operation was originally called with a URL, the          */
/* callback is called once regardless of whether the handle was opened     */
/* asynchronously or synchronously.  The pcAttrList parameter contains     */
/* the requested attributes as a comma separated list (or is empty if no   */
/* attributes matched the original tag list).                              */
/*                                                                         */
/* If the SLPFindAttrs() operation was originally called with a service    */
/* type, the value of pcAttrList and calling behavior depend on whether    */
/* the handle was opened asynchronously or synchronously.  If the handle   */
/* was opened asynchronously, the callback is called every time the API    */
/* library has results from a remote agent.  The pcAttrList parameter      */
/* MAY be uncollated between calls.  It contains a comma separated list    */
/* with the results from the agent that immediately returned results.      */
/* If the handle was opened synchronously, the results must be collated    */
/* from all returning agents and the callback is called once, with the     */
/* pcAttrList parameter set to the collated result.                        */
/*                                                                         */
/* hSLP         The SLPHandle used to initiate the operation.              */
/*                                                                         */
/* pcAttrList   A character buffer containing a comma separated, null      */
/*              terminated list of attribute id/value assignments, in SLP  */
/*              wire format; i.e.  "(attr-id=attr-value-list)".            */
/*                                                                         */
/* errCode      An error code indicating if an error occurred during the   */
/*              operation.  The callback should check this error code      */
/*              before processing the parameters.  If the error code is    */
/*              other than SLP_OK, then the API library may choose to      */
/*              terminate the outstanding operation.                       */
/*                                                                         */
/* pvCookie     Memory passed down from the client code that called the    */
/*              original API function, starting the operation.             */
/*              May be NULL.                                               */
/*                                                                         */
/* Returns      The client code should return SLP_TRUE if more data is     */
/*              desired,otherwise return SLP_FALSE                         */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPOpen(const char *pcLang,
                             SLPBoolean isAsync,
                             SLPHandle *phSLP);
/*                                                                         */
/* Returns a SLPHandle handle in the phSLP parameter for the language      */
/* locale passed in as the pcLang parameter.  The client indicates if      */
/* operations on the handle are to be synchronous or asynchronous          */
/* through the isAsync parameter.  The handle encapsulates the language    */
/* locale for SLP requests issued through the handle, and any other        */
/* resources required by the implementation.  However, SLP properties      */
/* are not encapsulated by the handle; they are global.  The return        */
/* value of the function is an SLPError code indicating the status of      */
/* the operation.  Upon failure, the phSLP parameter is NULL.              */
/*                                                                         */
/* An SLPHandle can only be used for one SLP API operation at a time.      */
/* If the original operation was started asynchronously, any attempt to    */
/* start an additional operation on the handle while the original          */
/* operation is pending results in the return of an SLP_HANDLE_IN_USE      */
/* error from the API function.  The SLPClose() API function terminates    */
/* any outstanding calls on the handle.  If an implementation is unable    */
/* to support a asynchronous( resp.  synchronous) operation, due to        */
/* memory constraints or lack of threading support, the                    */
/* SLP_NOT_IMPLEMENTED flag may be returned when the isAsync flag is       */
/* SLP_TRUE (resp.  SLP_FALSE).                                            */
/*                                                                         */
/* pcLang   A pointer to an array of characters containing the RFC 1766    */
/*          Language Tag RFC 1766 for the natural language locale of       */
/*          requests and registrations issued on the handle. Pass in NULL  */
/*          or the empty string, "" to use the default locale              */
/*                                                                         */
/* isAsync  An SLPBoolean indicating whether the SLPHandle should be opened*/
/*          for asynchronous operation or not.                             */
/*                                                                         */
/* phSLP    A pointer to an SLPHandle, in which the open SLPHandle is      */
/*          returned.  If an error occurs, the value upon return is NULL.  */
/*                                                                         */
/* Returns  SLPError code                                                  */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP void SLPAPI SLPClose(SLPHandle hSLP);
/*                                                                         */
/* Frees all resources associated with the handle.  If the handle was      */
/* invalid, the function returns silently.  Any outstanding synchronous    */
/* or asynchronous operations are cancelled so their callback functions    */
/* will not be called any further.                                         */
/*                                                                         */
/* SLPHandle    A SLPHandle handle returned from a call to SLPOpen().      */
/*=========================================================================*/


#ifndef MI_NOT_SUPPORTED
/*=========================================================================*/
SLPEXP SLPError SLPAssociateIFList( SLPHandle hSLP, const char* McastIFList);
/*                                                                         */
/* Associates a list of interfaces McastIFList on which multicast needs to */
/* be done with a particular SLPHandle hSLP. McastIFList is a comma        */
/* separated list of host interface IP addresses.                          */
/*                                                                         */
/* hSLP                 The SLPHandle with which the interface list is to  */
/*                      be associated with.                                */
/*                                                                         */
/* McastIFList          A comma separated list of host interface IP        */
/*                      addresses on which multicast needs to be done.     */
/*                                                                         */
/* Returns  SLPError code                                                  */
/*=========================================================================*/
#endif /* MI_NOT_SUPPORTED */


#ifndef UNICAST_NOT_SUPPORTED
/*=========================================================================*/
SLPEXP SLPError SLPAssociateIP( SLPHandle hSLP, const char* unicast_ip);
/*                                                                         */
/* Associates an IP address unicast_ip with a particular SLPHandle hSLP.   */
/* unicast_ip is the IP address of the SA/DA from which service is         */
/* requested.                                                              */
/*                                                                         */
/* hSLP                 The SLPHandle with which the unicast_ip address is */
/*                      to be associated with.                             */
/*                                                                         */
/* unicast_ip           IP address of the SA/DA from which service is      */
/*                      requested.                                         */
/*                                                                         */
/* Returns  SLPError code                                                  */
/*=========================================================================*/
#endif


#define SLP_REG_FLAG_FRESH      (1)
#define SLP_REG_FLAG_WATCH_PID  (1 << 1)

/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPReg(SLPHandle   hSLP,
                const char  *pcSrvURL,
                const unsigned short usLifetime,
                const char  *pcSrvType,
                const char  *pcAttrs,
                SLPBoolean fresh,
                SLPRegReport callback,
                void *pvCookie); 
/*                                                                         */
/* Registers the URL in pcSrvURL having the lifetime usLifetime with the   */
/* attribute list in pcAttrs.  The pcAttrs list is a comma separated       */
/* list of attribute assignments in the wire format (including escaping    */
/* of reserved characters).  The usLifetime parameter must be nonzero      */
/* and less than or equal to SLP_LIFETIME_MAXIMUM. If the fresh flag is    */
/* SLP_TRUE, then the registration is new (the SLP protocol FRESH flag     */
/* is set) and the registration replaces any existing registrations.       */
/* The pcSrvType parameter is a service type name and can be included      */
/* for service URLs that are not in the service:  scheme.  If the URL is   */
/* in the service:  scheme, the pcSrvType parameter is ignored.  If the    */
/* fresh flag is SLP_FALSE, then an existing registration is updated.      */
/* Registrations and updates take place in the language locale of the      */
/* hSLP handle.                                                            */
/*                                                                         */
/* hSLP         The language specific SLPHandle on which to register the   */
/*              advertisement.                                             */
/*                                                                         */
/* pcSrvURL     The URL to register.  May not be the empty string. May not */
/*              be NULL.  Must conform to SLP Service URL syntax.          */
/*              SLP_INVALID_REGISTRATION will be returned if it does not.  */
/*                                                                         */
/* usLifetime   An unsigned short giving the life time of the service      */
/*              advertisement, in seconds.  The value must be an unsigned  */
/*              integer less than or equal to SLP_LIFETIME_MAXIMUM and     */
/*              greater than zero. If SLP_LIFETIME_MAXIMUM is used, the    */
/*              registration will remain for the life of the calling       */
/*              process.  Also, OpenSLP, will not allow registrations to   */
/*              be made with SLP_LIFETIME_MAXIMUM unless                   */
/*              SLP_REG_FLAG_WATCH_PID is also used                        */
/*                                                                         */
/* pcSrvType    This parameter is ALWAYS ignored since the SLP Service URL */
/*              syntax required for the pcSrvURL encapsulates the service  */
/*              type.                                                      */
/*                                                                         */
/* pcAttrs      A comma separated list of attribute assignment expressions */
/*              for the attributes of the advertisement.  Use empty string,*/
/*              "" for no attributes.                                      */
/*                                                                         */
/* fresh        Use of non-fresh registrations is deprecated.  SLP_TRUE    */
/*              must be passed in for this parameter or SLP_BAD_PARAMETER  */
/*              will be returned                                           */
/*                                                                         */
/* callback     A SLPRegReport callback to report the operation completion */
/*              status.                                                    */
/*                                                                         */
/* pvCookie     Memory passed to the callback code from the client.  May be*/
/*              NULL.                                                      */
/*                                                                         */
/* Returns:     If an error occurs in starting the operation, one of the   */
/*              SLPError codes is returned.                                */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPDereg(SLPHandle  hSLP,
                  const char *pcSrvURL,
                  SLPRegReport callback,
                  void *pvCookie);   
/*                                                                         */
/* Deregisters the advertisement for URL pcURL in all scopes where the     */
/* service is registered and all language locales.  The deregistration     */
/* is not just confined to the locale of the SLPHandle, it is in all       */
/* locales.  The API library is required to perform the operation in all   */
/* scopes obtained through configuration.                                  */
/*                                                                         */
/* hSLP         The language specific SLPHandle to use for deregistering.  */
/*                                                                         */
/* pcSrvURL     The SLP Service URL to deregister.  May not be the empty   */
/*              string.  May not be NULL. Must conform to SLP Service URL  */
/*              syntax or SLP_INVALID_REGISTRATION will be returned.       */
/*                                                                         */
/* callback     A callback to report the operation completion status.      */
/*                                                                         */
/* pvCookie     Memory passed to the callback code from the client.  May be*/
/*              NULL.                                                      */
/*                                                                         */
/* Returns:     If an error occurs in starting the operation, one of the   */
/*              SLPError codes is returned.                                */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPDelAttrs(SLPHandle   hSLP,
                     const char  *pcSrvURL,
                     const char  *pcAttrs,
                     SLPRegReport callback,
                     void *pvCookie); 
/*                                                                         */
/* Delete the selected attributes in the locale of the SLPHandle.  The     */
/* API library is required to perform the operation in all scopes          */
/* obtained through configuration.                                         */
/*                                                                         */
/* hSLP         The language specific SLPHandle to use for deleting        */
/*              attributes.                                                */
/*                                                                         */
/* pcSrvURL     The SLP Service URL of the advertisement from which the    */
/*              attributes should be deleted. May not be the empty string. */
/*                                                                         */
/* pcAttrs      A comma separated list of attribute ids for the attributes */
/*              to deregister.  May not be the empty string.               */
/*                                                                         */
/* callback     A callback to report the operation completion status.      */
/*                                                                         */
/* pvCookie     Memory passed to the callback code from the client.  May be*/
/*              NULL.                                                      */
/*                                                                         */
/* Returns      If an error occurs in starting the operation, one of the   */
/*              SLPError codes is returned.                                */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPFindSrvTypes(SLPHandle    hSLP,
                         const char  *pcNamingAuthority,
                         const char  *pcScopeList,
                         SLPSrvTypeCallback callback,
                         void *pvCookie);  
/*                                                                         */
/* The SLPFindSrvType() function issues an SLP service type request for    */
/* service types in the scopes indicated by the pcScopeList.  The          */
/* results are returned through the callback parameter.  The service       */
/* types are independent of language locale, but only for services         */
/* registered in one of scopes and for the indicated naming authority.     */
/*                                                                         */
/* If the naming authority is "*", then results are returned for all       */
/* naming authorities.  If the naming authority is the empty string,       */
/* i.e.  "", then the default naming authority, "IANA", is used.  "IANA"   */
/* is not a valid naming authority name, and it is a PARAMETER_BAD error   */
/* to include it explicitly.                                               */
/*                                                                         */
/* The service type names are returned with the naming authority intact.   */
/* If the naming authority is the default (i.e.  empty string) then it     */
/* is omitted, as is the separating ".".  Service type names from URLs     */
/* of the service:  scheme are returned with the "service:" prefix         */
/* intact.  See RFC 2609 for more information on the syntax of service     */
/* type names.                                                             */
/*                                                                         */
/* hSLP                 The SLPHandle on which to search for types.        */
/*                                                                         */
/* pcNamingAuthority    The naming authority to search.  Use "*" for all   */
/*                      naming authorities and the empty string, "", for   */
/*                      the default naming authority.                      */
/*                                                                         */
/* pcScopeList          A pointer to a string containing comma separated   */
/*                      list of scope names to search for service types.   */
/*                      May not be the empty string, "".                   */
/*                                                                         */
/* callback             A callback function through which the results of   */
/*                      the operation are reported.                        */
/*                                                                         */
/* pvCookie             Memory passed to the callback code from the client.*/
/*                      May be NULL.                                       */
/*                                                                         */
/* Returns              If an error occurs in starting the operation, one  */
/*                      of the SLPError codes is returned.                 */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPFindSrvs(SLPHandle  hSLP,
                     const char *pcServiceType,
                     const char *pcScopeList,
                     const char *pcSearchFilter,
                     SLPSrvURLCallback callback,
                     void *pvCookie);
/*                                                                         */
/* Issue the query for services on the language specific SLPHandle and     */
/* return the results through the callback.  The parameters determine      */
/* the results                                                             */
/*                                                                         */
/* hSLP             The language specific SLPHandle on which to search for */
/*                  services.                                              */
/*                                                                         */
/* pcServiceType    The Service Type String, including authority string if */
/*                  any, for the request, such as can be discovered using  */
/*                  SLPSrvTypes(). This could be, for example              */
/*                  "service:printer:lpr" or "service:nfs".  May not be    */
/*                  the empty string or NULL.                              */
/*                                                                         */
/*                                                                         */
/* pcScopeList      A pointer to a char containing comma separated list of */
/*                  scope names.  Pass in the NULL or the empty string ""  */
/*                  to find services in all the scopes the local host is   */
/*                  configured query.                                      */
/*                                                                         */
/* pcSearchFilter   A query formulated of attribute pattern matching       */
/*                  expressions in the form of a LDAPv3 Search Filter.     */
/*                  If this filter is NULL or empty, i.e.  "", all         */
/*                  services of the requested type in the specified scopes */
/*                  are returned.                                          */
/*                                                                         */
/* callback         A callback function through which the results of the   */
/*                  operation are reported. May not be NULL                */
/*                                                                         */
/* pvCookie         Memory passed to the callback code from the client.    */
/*                  May be NULL.                                           */
/*                                                                         */
/* Returns:         If an error occurs in starting the operation, one of   */
/*                  the SLPError codes is returned.                        */
/*                                                                         */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPFindAttrs(SLPHandle   hSLP,
                      const char *pcURLOrServiceType,
                      const char *pcScopeList,
                      const char *pcAttrIds,
                      SLPAttrCallback callback,
                      void *pvCookie);  
/*                                                                         */
/* This function returns service attributes matching the attribute ids     */
/* for the indicated service URL or service type.  If pcURLOrServiceType   */
/* is a service URL, the attribute information returned is for that        */
/* particular advertisement in the language locale of the SLPHandle.       */
/*                                                                         */
/* If pcURLOrServiceType is a service type name (including naming          */
/* authority if any), then the attributes for all advertisements of that   */
/* service type are returned regardless of the language of registration.   */
/* Results are returned through the callback.                              */
/*                                                                         */
/* The result is filtered with an SLP attribute request filter string      */
/* parameter, the syntax of which is described in RFC 2608. If the filter  */
/* string is the empty string, i.e.  "", all attributes are returned.      */
/*                                                                         */
/* hSLP                 The language specific SLPHandle on which to search */
/*                      for attributes.                                    */
/*                                                                         */
/* pcURLOrServiceType   The service URL or service type.  See RFC 2608 for */
/*                      URL and service type syntax.  May not be the empty */
/*                      string.                                            */
/*                                                                         */
/* pcScopeList          A pointer to a char containing a comma separated   */
/*                      list of scope names. Pass in NULL or the empty     */
/*                      string "" to find services in all the scopes the   */
/*                      local host is configured query.                    */
/*                                                                         */
/* pcAttrIds            A comma separated list of attribute ids to return. */
/*                      Use NULL or the empty string, "", to indicate all  */
/*                      values. Wildcards are not currently supported      */
/*                                                                         */
/* callback             A callback function through which the results of   */
/*                      the operation are reported.                        */
/*                                                                         */
/* pvCookie             Memory passed to the callback code from the client.*/
/*                      May be NULL.                                       */
/*                                                                         */
/* Returns:             If an error occurs in starting the operation, one  */
/*                      of the SLPError codes is returned.                 */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP unsigned short SLPAPI SLPGetRefreshInterval();
/*                                                                         */
/* Returns the maximum across all DAs of the min-refresh-interval          */
/* attribute.  This value satisfies the advertised refresh interval        */
/* bounds for all DAs, and, if used by the SA, assures that no refresh     */
/* registration will be rejected.  If no DA advertises a min-refresh-      */
/* interval attribute, a value of 0 is returned.                           */
/*                                                                         */
/* Returns: If no error, the maximum refresh interval value allowed by all */
/*          DAs (a positive integer).  If no DA advertises a               */
/*          min-refresh-interval attribute, returns 0.  If an error occurs,*/
/*          returns an SLP error code.                                     */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPFindScopes(SLPHandle hSLP,
                       char** ppcScopeList);
/*                                                                         */
/* Sets ppcScopeList parameter to a pointer to a comma separated list      */
/* including all available scope values.  The list of scopes comes from    */
/* a variety of sources:  the configuration file's net.slp.useScopes       */
/* property, unicast to DAs on the net.slp.DAAddresses property, DHCP,     */
/* or through the DA discovery process.  If there is any order to the      */
/*  scopes, preferred scopes are listed before less desirable scopes.      */
/* There is always at least one name in the list, the default scope,       */
/* "DEFAULT".                                                              */
/*                                                                         */
/* hSLP         The SLPHandle on which to search for scopes.               */
/*                                                                         */
/* ppcScopeList A pointer to char pointer into which the buffer pointer is */
/*              placed upon return.  The buffer is null terminated.  The   */
/*              memory should be freed by calling SLPFree().               */
/*                                                                         */
/* Returns:     If no error occurs, returns SLP_OK, otherwise, the a       */
/*              ppropriate error code.                                     */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPParseSrvURL(const char *pcSrvURL,
                        SLPSrvURL** ppSrvURL);
/*                                                                         */
/* Parses the URL passed in as the argument into a service URL structure   */
/* and returns it in the ppSrvURL pointer.  If a parse error occurs,       */
/* returns SLP_PARSE_ERROR.  The structure returned in ppSrvURL should be  */
/* freed with SLPFreeURL().  If the URL has no service part, the           */
/* s_pcSrvPart  string is the empty string, "", i.e.  not NULL. If         */
/* pcSrvURL is not a service:  URL, then the s_pcSrvType field in the      */
/* returned data structure is the URL's scheme, which might not be the     */
/* same as the service type under which the URL was registered.  If the    */
/* transport is IP, the s_pcTransport field is the empty string.  If the   */
/* transport is not IP or there is no port number, the s_iPort field is    */
/* zero.                                                                   */
/*                                                                         */
/* pcSrvURL A pointer to a character buffer containing the null terminated */
/*          URL string to parse.                                           */
/*                                                                         */
/* ppSrvURL A pointer to a pointer for the SLPSrvURL structure to receive  */
/*          the parsed URL. The memory should be freed by a call to        */
/*          SLPFree() when no longer needed.                               */
/*                                                                         */
/* Returns: If no error occurs, the return value is SLP_OK. Otherwise, the */
/*          appropriate error code is returned.                            */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPEscape(const char* pcInbuf,
                   char** ppcOutBuf,
                   SLPBoolean isTag); 
/*                                                                         */
/* Process the input string in pcInbuf and escape any SLP reserved         */
/* characters.  If the isTag parameter is SLPTrue, then look for bad tag   */
/* characters and signal an error if any are found by returning the        */
/* SLP_PARSE_ERROR code.  The results are put into a buffer allocated by   */
/* the API library and returned in the ppcOutBuf parameter.  This buffer   */
/* should be deallocated using SLPFree() when the memory is no longer      */
/* needed.                                                                 */
/*                                                                         */
/* pcInbuf      Pointer to he input buffer to process for escape           */
/*              characters.                                                */
/*                                                                         */
/* ppcOutBuf    Pointer to a pointer for the output buffer with the SLP    */
/*              reserved characters escaped.  Must be freed using          */
/*              SLPFree()when the memory is no longer needed.              */
/*                                                                         */
/* isTag        When true, the input buffer is checked for bad tag         */
/*              characters.                                                */
/*                                                                         */
/* Returns:     Return SLP_PARSE_ERROR if any characters are bad tag       */
/*              characters and the isTag flag is true, otherwise SLP_OK,   */
/*              or the appropriate error code if another error occurs.     */
/*=========================================================================*/



/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPUnescape(const char* pcInbuf,
                     char** ppcOutBuf,
                     SLPBoolean isTag);
/*                                                                         */
/* Process the input string in pcInbuf and unescape any SLP reserved       */
/* characters.  If the isTag parameter is SLPTrue, then look for bad tag   */
/* characters and signal an error if any are found with the                */
/* SLP_PARSE_ERROR code.  No transformation is performed if the input      */
/* string is an opaque.  The results are put into a buffer allocated by    */
/* the API library and returned in the ppcOutBuf parameter.  This buffer   */
/* should be deallocated using SLPFree() when the memory is no longer      */
/* needed.                                                                 */
/*                                                                         */
/* pcInbuf      Pointer to he input buffer to process for escape           */
/*              characters.                                                */
/*                                                                         */
/* ppcOutBuf    Pointer to a pointer for the output buffer with the SLP    */
/*              reserved characters escaped.  Must be freed using          */
/*              SLPFree() when the memory is no longer needed.             */
/*                                                                         */
/* isTag        When true, the input buffer is checked for bad tag         */
/*              characters.                                                */
/*                                                                         */
/* Returns:     Return SLP_PARSE_ERROR if any characters are bad tag       */
/*              characters and the isTag flag is true, otherwise SLP_OK,   */
/*              or the appropriate error code if another error occurs.     */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP void SLPAPI SLPFree(void* pvMem);
/*                                                                         */
/* Frees memory returned from SLPParseSrvURL(), SLPFindScopes(),           */
/* SLPEscape(), and SLPUnescape().                                         */
/*                                                                         */
/* pvMem    A pointer to the storage allocated by the SLPParseSrvURL(),    */
/*          SLPEscape(), SLPUnescape(), or SLPFindScopes() function.       */
/*          Ignored if NULL.                                               */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP const char* SLPAPI SLPGetProperty(const char* pcName);
/*                                                                         */
/* Returns the value of the corresponding SLP property name.  The returned */
/* string is owned by the library and MUST NOT be freed.                   */
/*                                                                         */
/* pcName   Null terminated string with the property name, from            */
/*          Section 2.1 of RFC 2614.                                       */
/*                                                                         */
/* Returns: If no error, returns a pointer to a character buffer containing*/
/*          the property value.  If the property was not set, returns the  */
/*          default value.  If an error occurs, returns NULL. The returned */
/*          string MUST NOT be freed.                                      */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP void SLPAPI SLPSetProperty(const char *pcName,
                    const char *pcValue);
/*                                                                         */
/* Sets the value of the SLP property to the new value.  The pcValue       */
/* parameter should be the property value as a string.                     */
/*                                                                         */
/* pcName   Null terminated string with the property name, from Section    */
/*          2.1. of RFC 2614.                                              */
/*                                                                         */
/* pcValue  Null terminated string with the property value, in UTF-8       */
/*          character encoding.                                            */
/*=========================================================================*/


/*=========================================================================*/
SLPEXP SLPError SLPAPI SLPParseAttrs(const char* pcAttrList,
                       const char *pcAttrId,
                       char** ppcAttrVal);
/*                                                                         */
/* Used to get individual attribute values from an attribute string that   */
/* is passed to the SLPAttrCallback                                        */
/*                                                                         */
/* pcAttrList (IN) A character buffer containing a comma separated, null   */
/*                 terminated list of attribute id/value assignments, in   */
/*                 SLP wire format; i.e.  "(attr-id=attr-value-list)"      */
/*                                                                         */
/* pcAttrId (IN)   The string indicating which attribute value to return.  */
/*                 MUST not be null.  MUST not be the empty string ("").   */
/*                                                                         */
/* ppcAttrVal (OUT) A pointer to a pointer to the buffer to receive        */
/*                 attribute value.  The memory should be freed by a call  */
/*                 to SLPFree() when no longer needed.                     */
/*                                                                         */
/* Returns: Returns SLP_PARSE_ERROR if an attribute of the specified id    */
/*          was not found otherwise SLP_OK                                 */
/*=========================================================================*/

#if(defined __cplusplus)
}
#endif

#endif  /* (!defined SLP_H_INCLUDED) */
