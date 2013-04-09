/*
 * Copyright (c) 20082012, The Caffeine-hx project contributors
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

package chx.crypt.mode;

import chx.crypt.CipherDirection;
import math.prng.IPrng;

/**
* IV is an abstract base class for modes requiring initialization vectors.
* According to NIST: 
* There are two recommended methods for generating unpredictable IVs. The first
* method is to apply the forward cipher function, under the same key that is used
* for the encryption of the plaintext, to a nonce. The nonce must be a data block
* that is unique to each execution of the encryption operation. For example,
* the nonce may be a counter, as described in Appendix B, or a message number.
* The second method is to generate a random data block using a FIPSapproved
* random number generator.
**/
class IVBase extends ModeBase {
	/**
	 * Beware that this value changes with each crypt operation.
	 * For the original value, consult params.iv
	 **/
	public var iv(getIV, setIV) : Bytes;
	var currentIV : Bytes;

	override public function init(params : CipherParams) : Void {
		super.init(params);
		if(params.prng == null)
			params.prng = new math.prng.Random();

		if(params.iv == null) {
			if(params.direction == DECRYPT)
				throw "IV must be set before decryption";
			var sb = new BytesBuffer();
			for(x in 0...cipher.blockSize)
				sb.addByte(params.prng.next());
			params.iv = sb.getBytes();
		}
		if(params.iv.length < cipher.blockSize)
			params.iv = BytesUtil.leftPad(params.iv, cipher.blockSize);
		currentIV = params.iv.sub(0, cipher.blockSize);
	}

	public function getIV() : Bytes {
		return currentIV;
	}

	override function setCipher(v:IBlockCipher) {
		super.setCipher(v);
		if(v != null && currentIV != null && currentIV.length > v.blockSize)
			currentIV = currentIV.sub(0, v.blockSize);
		return v;
	}

	/**
	 * Set the initialization vector.
	 **/
	public function setIV( s : Bytes ) : Bytes {
		// here we use cipher.blockSize, as it may be different
		// than out mode blockSize
		if(s.length == 0 || (cipher != null && s.length != cipher.blockSize))
			throw("crypt.iv: invalid length. Expected "+cipher.blockSize+" bytes.");
		var len = s.length;
		if(cipher != null && cipher.blockSize < len)
			len = cipher.blockSize;
		currentIV = s.sub(0,len);
		return s;
	}

}
