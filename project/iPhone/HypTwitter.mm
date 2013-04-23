#include <HypTwitter.h>
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Twitter/TWRequest.h>

#define TWITTER_URL @"https://api.twitter.com/oauth/access_token"

namespace hyptwitter{

	ACAccountStore *accountStore;

	//
		typedef void( *FunctionType)( );
		extern "C"{
			void hyptwitter_dispatch_event( const char *sType , const char *sArg );
		}

	//
		void connect( const char *sConsumerKey , const char *sAuthParam ){
			NSLog(@"connect");

			//Params
				NSString *nsConsumerKey	= [[NSString alloc] initWithUTF8String:sConsumerKey];
				NSString *nsAuthParam	= [[NSString alloc] initWithUTF8String:sAuthParam];
				NSLog( @"%@",nsConsumerKey);
				NSLog( @"%@",nsAuthParam);

		    //  Assume that we stored the result of Step 1 into a var 'resultOfStep1'

		     NSDictionary *step2Params = [[NSMutableDictionary alloc] init];

		    [step2Params setValue:nsConsumerKey forKey:@"x_reverse_auth_target"];
		    [step2Params setValue:nsAuthParam 	forKey:@"x_reverse_auth_parameters"];


		    NSURL *url2 = [NSURL URLWithString:TWITTER_URL];

		    SLRequest *stepTwoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url2 parameters:step2Params];


			accountStore = [[ACAccountStore alloc] init];
			ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
			[accountStore requestAccessToAccountsWithType:twitterType withCompletionHandler:^(BOOL granted, NSError *error) {

		    	if (!granted) {

				hyptwitter_dispatch_event( "ERROR" ,"not granted");

		    	} else {

		    		// obtain all the local account instances
		    		NSArray *accounts = [accountStore accountsWithAccountType:twitterType];

		    		// for simplicity, we will choose the first account returned - in your app,
		    		// you should ensure that the user chooses the correct Twitter account
		    		// to use with your application.  DO NOT FORGET THIS STEP.
		    		[stepTwoRequest setAccount:[accounts objectAtIndex:0]];



		    		// execute the request
		    		[stepTwoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {


					if ([urlResponse statusCode] == 200) {
						NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
						NSLog(@"The user's info for your server:\n%@", responseStr);
						hyptwitter_dispatch_event( "OK" ,[ responseStr UTF8String ]);

					}else{
						NSLog(@"Call failed");
						hyptwitter_dispatch_event( "ERROR" , [[error localizedDescription] UTF8String]);
					}
				}];

		    	}

		    }];
		}
}
