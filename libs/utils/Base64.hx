/**
 * ...
 * @author Renaud Bardet
 * Copyright Mandalagames 2010
 */

package utils;
import haxe.BaseCode;
import haxe.io.Bytes;

// IMPORTS


// CLASS
class Base64
{

	public static inline var BASE64_CHARS : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" ;
	public static inline var BASE64URL_CHARS : String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_" ;
	
	public static function encode (_string : String) : String  {
		
		return BaseCode.encode(_string, BASE64_CHARS) + complement( _string );
		
	}
	
	public static function decode (_string : String) : String  {
		
		return BaseCode.decode(_string.split("=")[0], BASE64_CHARS) ;
		
	}
	
	public static function urlEncode (_string : String) : String  {
		
		return BaseCode.encode(_string, BASE64URL_CHARS) + complement( _string ) ;
		
	}
	
	public static function urlDecode (_string : String) : String
	{
		return BaseCode.decode(_string.split("=")[0], BASE64URL_CHARS) ;
	}
	
	private static function complement( _s : String )
	{
		var complement = Bytes.ofString( _s ).length % 3 ;
		
		return if ( complement == 0 )
			""
		else if ( complement == 2 )
			"="
		else if ( complement == 1 )
			"==";		
	}
	
}