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

/*
 * Derived from AS3 implementation Copyright (c) 2007 Henri Torgemane
 */
/**
 * PEM
 * @see http://etutorials.org/Programming/secure+programming/Chapter+7.+Public+Key+Cryptography/7.17+Representing+Keys+and+Certificates+in+Plaintext+PEM+Encoding/
 */
package chx.formats.der;
import chx.crypt.RSA;
import chx.crypt.RSAEncrypt;
import math.BigInteger;
import chx.formats.Base64;

class PEM
{
	public static inline var RSA_PRIVATE_KEY_HEADER:String = "-----BEGIN RSA PRIVATE KEY-----";
	public static inline var RSA_PRIVATE_KEY_FOOTER:String = "-----END RSA PRIVATE KEY-----";
	public static inline var RSA_PUBLIC_KEY_HEADER:String = "-----BEGIN PUBLIC KEY-----";
	public static inline var RSA_PUBLIC_KEY_FOOTER:String = "-----END PUBLIC KEY-----";
	public static inline var CERTIFICATE_HEADER:String = "-----BEGIN CERTIFICATE-----";
	public static inline var CERTIFICATE_FOOTER:String = "-----END CERTIFICATE-----";

	/**
	 *
	 * Read an RSA private key structure encoded according to
	 * ftp://ftp.rsasecurity.com/pub/pkcs/ascii/pkcs-1v2.asc
	 * section 11.1.2
	 *
	 * @param str A text with base64 encoded RSAPrivateKey with a standard header and footer
	 * @return RSA private key
	 **/
	public static function readRSAPrivateKey(str:String):RSA {
		var der:Bytes = extractBinary(RSA_PRIVATE_KEY_HEADER, RSA_PRIVATE_KEY_FOOTER, str);
		if (der==null) return null;
		var obj : IAsn1Type = DER.read(der);
		if (Std.is(obj,Set) || Std.is(obj, Sequence))
		{
			var arr:Sequence = cast obj;
			var rsa = new RSA();
			// arr[0] is Version. should be 0. should be checked.
			rsa.setPrivateEx(
				untyped arr.get(1).toHex(),		// N
				untyped arr.get(2).toHex(),		// E
				untyped arr.get(3).toHex(),		// D
				untyped arr.get(4).toHex(),		// P
				untyped arr.get(5).toHex(),		// Q
				untyped arr.get(6).toHex(),		// DMP1
				untyped arr.get(7).toHex(),		// DMQ1
				untyped arr.get(8).toHex()		// IQMP
			);
			return rsa;
		}
		return null;
	}


	/**
	 * Read an RSA public key structure encoded according to
	 * ftp://ftp.rsasecurity.com/pub/pkcs/ascii/pkcs-1v2.asc
	 * section 11.1
	 *
	 * @param str A text with base64 encoded RSAPublicKey with a standard header and footer
	 * @return RSA public key
	 **/
	public static function readRSAPublicKey(str:String) : RSAEncrypt
	{
		//try {
		var der:Bytes = extractBinary(RSA_PUBLIC_KEY_HEADER, RSA_PUBLIC_KEY_FOOTER, str);
		if (der==null || der.length == 0) return null;
		var obj : IAsn1Type = DER.read(der);
		if (Std.is(obj,Set) || Std.is(obj, Sequence)) {
			var seq:Sequence = cast obj;
			// seq[0] = [ <some crap that means "rsaEncryption">, null ]; ( apparently, that's an X-509 Algorithm Identifier.
			if (untyped seq.getContainer(0).get(0).toString() != OID.RSA_ENCRYPTION)
				return null;

			// seq[1] is a ExtractedBytes begging to be parsed as DER
			// there's a 0x00 byte up front. find out why later.
			//untyped seq.get(1).position = 0;
			var eb : ExtractedBytes = cast seq.get(1);
			obj = DER.read(eb.toDER());
			if (Std.is(obj,Set) || Std.is(obj, Sequence))
			{
				seq = cast obj;
				// seq[0] = modulus
				// seq[1] = public expt.
				return new RSAEncrypt(untyped seq.get(0).toHex(), untyped seq.get(1).toHex());
			} else {
				return null;
			}
		} else {
			// dunno
			return null;
		}
		//}
		//catch(e:Dynamic) {
		//	return null;
		//}
	}

	/**
	 * Takes a Base64 certificate with a header and footer and
	 * decodes the cert data into a new Bytes
	 **/
	public static function readCertIntoBytes(str:String):Bytes {
		return extractBinary(CERTIFICATE_HEADER, CERTIFICATE_FOOTER, str);
	}

	private static function extractBinary(header:String, footer:String, str:String) : Bytes {
		var i:Int = str.indexOf(header);
		if (i==-1) return null;
		i += header.length;
		var j:Int = str.indexOf(footer);
		if (j==-1) return null;
		var a = chx.formats.Base64.decode(str.substr(i, j-i));
		//trace(a.length);
		return a;
	}
}

