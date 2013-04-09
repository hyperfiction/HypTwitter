package fr.hyperfiction;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.*;
import android.util.Log;

import org.haxe.nme.GameActivity;

/**
 * ...
 * @author shoe[box]
 */

public class HypTwitter{

	static public native void onNewIntent( String jsIntent_url );
	static{
		System.loadLibrary( "HypTwitter" );
	}

	private static String TAG = "trace";//HypTwitter";

	// -------o constructor
		
		/**
		* constructor
		*
		* @param	
		* @return	void
		*/
		private HypTwitter( ) {
			
		}
	
	// -------o public
		
		public static void onIntent( String s ){
			trace("s ::: "+s);
			onNewIntent( s );
		}

	// -------o private
	
	// -------o misc
		
		/**
		* 
		* 
		* @public
		* @return	void
		*/
		public static void trace( String s ){
			Log.i( TAG, s );
		}
}