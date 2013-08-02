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

package chx.crypt.rsa;

import chx.lang.Exception;
import chx.lang.IllegalArgumentException;

//http://tools.ietf.org/html/rfc2313 section 8.1

/**
 * Pads with 0xFF bytes
 **/
class PadPkcs1Type1 extends PadBlockBase, implements IBlockPad {
	/** only for Type1, the byte to pad with, default 0xFF **/
	public var padByte(getPadByte,setPadByte) : Int;
	var padCount : Int;
	var typeByte : Int;

	public function new(size:Int) {
		Reflect.setField(this,"blockSize",size);
		setPadCount(8);
		typeByte = 1;
		padByte = 0xFF;
	}

	public function getBytesReadPerBlock() : Int {
		return textSize;
	}

	public function pad( s : Bytes ) : Bytes {
		if(s.length > textSize)
			throw new Exception("Unable to pad block: provided buffer is " + s.length + " max is " + textSize);
		var sb = new BytesBuffer();
		sb.addByte(0);
		sb.addByte(typeByte);
		var n = blockSize - s.length - 3; //padCount + (textSize - s.length);
		while(n-- > 0) {
			sb.addByte(getPadByte());
		}
		sb.addByte(0);
		sb.add(s);

		var rv = sb.getBytes();
		#if CAFFEINE_DEBUG
		trace("==Padded: " + BytesUtil.hexDump(rv));
		#end
		return rv;
	}

	public function unpad( s : Bytes ) : Bytes {
		// src string may be shorter than block size. This happens when
		// converting to BigIntegers then to padded string before calling
		// unpad.
		var i : Int = 0;
		#if CAFFEINE_DEBUG
		trace("==Unpadding Padded: " + BytesUtil.hexDump(s));
		#end
		var sb = new BytesBuffer();
		while(i < s.length) {
			while( i < s.length && s.get(i) == 0) ++i;
			if(s.length-i-3-padCount < 0) {
				throw new Exception("Unexpected short message");
			}
			if(s.get(i) != typeByte)
				throw new Exception("Expected marker "+ typeByte + " at position "+i + " [" + BytesUtil.hexDump(s) + "]");
			if(++i >= s.length)
				return sb.getBytes();
			while(i < s.length && s.get(i) != 0) ++i;
			i++;
			var n : Int = 0;
			while(i < s.length && n++ < textSize )
				sb.addByte(s.get(i++));
		}
		return sb.getBytes();
	}

	public function calcNumBlocks(len : Int) : Int {
		return Math.ceil(len/textSize);
	}

	/** number of bytes padding needs per block **/
	override public function blockOverhead() : Int { return 3 + padCount; }

	/**
		PKCS1 has a 3 + padCount byte overhead per block. For RSA
		padCount should be the default 8, for a total of 11 bytes
		overhead per block.
	**/
	public function setPadCount(x : Int) : Int {
		if(x + 3 >= blockSize)
			throw new IllegalArgumentException("Internal padding size exceeds crypt block size");
		padCount = x;
		textSize = blockSize - 3 - padCount;
		return x;
	}

	private function setBlockSize( x : Int ) : Int {
		this.blockSize = x;
		this.textSize = x - 3 - padCount;
		if(textSize <= 0)
			throw new IllegalArgumentException("Block size " + x + " to small for Pkcs1 with padCount "+padCount);
		return x;
	}

	public function getPadByte() : Int {
		return this.padByte;
	}

	public function setPadByte(x : Int) : Int {
		this.padByte = x & 0xFF;
		return x;
	}
}
