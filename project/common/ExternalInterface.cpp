#ifndef IPHONE
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>
#include "HypTwitter.h"
#include <stdio.h>

#ifdef ANDROID
	#include <hx/CFFI.h>
	#include <hx/Macros.h>
	#include <jni.h>
	#define  LOG_TAG    "trace"
	#define  ALOG(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#endif

using namespace Hyperfiction;

// Externs -------------------------------------------------------------------------------------------------------------------

	extern "C" void HypTwitter_entry( ){
		
	}
	DEFINE_ENTRY_POINT (HypTwitter_entry);

	extern "C" int HypTwitter_register_prims( ){ 
		return 0; 
	}

// Android ----------------------------------------------------------------------------------------------------------

	#ifdef ANDROID

		AutoGCRoot *eval_callback_intent = 0;

		//
			static value HypTwitter_set_callback( value onCall ){
				ALOG("HypTwitter_set_callback" );
				eval_callback_intent = new AutoGCRoot( onCall );
				return alloc_bool( true );
			}
			DEFINE_PRIM( HypTwitter_set_callback , 1 );

		extern "C"{
			
			JNIEXPORT void JNICALL Java_fr_hyperfiction_HypTwitter_onNewIntent(
																				JNIEnv * env ,
																				jobject obj ,
																				jstring jsIntent_url
																			){
				ALOG("Java_fr_hyperfiction_HypTwitter_onNewIntent" );

				const char *sIntent_url	= env->GetStringUTFChars( jsIntent_url , false );

				val_call1( 
					eval_callback_intent->get( ),
					alloc_string( sIntent_url )
				);

				env->ReleaseStringUTFChars( jsIntent_url , sIntent_url );
				
			}
		}
		
	#endif

// iPhone -------------------------------------------------------------------------------------------------------------------
	
	#ifdef IPHONE
		
		//Reverse auth callback method
		AutoGCRoot *eval_reverse_auth_callback = 0;

		//Set the reverse auth callback
			static value HypTwitter_set_reverse_auth_callback( value onCall ){
				eval_reverse_auth_callback = new AutoGCRoot( onCall );
				return alloc_bool( true );
			}
			DEFINE_PRIM( HypTwitter_set_reverse_auth_callback , 1 );

		//
			value HypTwitter_connect( value sConsumerKey , value sParam ){
				connect( val_string( sConsumerKey ) , val_string( sParam ) );
				return alloc_null( );
			}
			DEFINE_PRIM( HypTwitter_connect , 2 );

		//
			extern "C" void dispatch_event( const char *sType , const char *sArg ){
				printf("HypTwitter : dispatch_event type : %s arg : %s",sType,sArg);
				val_call2( 
							eval_reverse_auth_callback->get( ),
							alloc_string( sType ),
							alloc_string( sArg )
						);
			}

	#endif	