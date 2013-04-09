/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chx.formats;

import haxe.BaseCode;

class Base64 {
	private static var enc : BaseCode;

	/**
	* Encodes any bytes buffer to base64
	*
	* @param bytes Buffer to encode
	* @return Base64 encoded string
	**/
	public static function encode(bytes : Bytes) : String {
		var ext : String = switch (bytes.length % 3) {
		case 1: "==";
		case 2: "=";
		case 0: "";
		}
		if(enc == null)
			enc = new BaseCode(Bytes.ofString(Constants.DIGITS_BASE64));
		return enc.encodeBytes(bytes).toString() + ext;
	}

	/**
	* Attempt to decode a base64 encoded String. If the String can not
	* be decoded, null will be returned.
	*
	* @param s Base64 encoded string
	* @return New bytes buffer with decoded data, or null on error.
	**/
	public static function decode(s : String) : Bytes {
		s = StringTools.stripWhite(s);
		s = StringTools.replace(s,"=","");
		if(enc == null)
			enc = new BaseCode(Bytes.ofString(Constants.DIGITS_BASE64));
		return
			try enc.decodeBytes( Bytes.ofString(s) )
			catch( e:Dynamic) null;
	}
}

