/*
 * Copyright (c) 2012, The Caffeine-hx project contributors
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

package chx.crypt;
import chx.crypt.mode.IVBase;
import chx.crypt.padding.PadPkcs5;
import chx.lang.UnsupportedException;
import chx.io.BytesOutput;
import chx.io.Output;

/**
 * To encrypt or decrypt in multiple steps, use the update followed by the final
 * method. To encrypt or decrypt in a single step, the 'final' method can be used
 * without a preceding 'update'.
 **/
class Cipher {
	public var params(default,null) : CipherParams;
	public var direction(default, null) : CipherDirection;
	public var algo(default, null) : IBlockCipher;
	public var mode(default, null) : IMode;
	public var pad(default, null) : IPad;
	public var blockSize(default,null) : Int;

	var initialized : Bool;
	var buf : Bytes;
	var bufsize : Int;
	var ptr : Int;
	

	var modeUpdate : Bytes->Output->Int;
	var modeFinal : Bytes->Output->Int;

	/**
	 * Create a cipher from a decryption algorithm, a mode and a padding method.
	 * @param algo Block cipher
	 * @param mode Encryption mode (CBC, ECB etc.)
	 * @param pad Padding for stream. If null, will default to PadPkcs5
	 * @param initFunc if provided, will be called after construction with this Cipher as a parameter
	 **/
	public function new(algo:IBlockCipher, mode:IMode, pad:IPad=null, initFunc : Cipher->Void = null) {
		if(pad == null)
			pad = new PadPkcs5();
		this.algo = algo;
		this.mode = mode;
		this.pad = pad;

		mode.cipher = algo;
		mode.padding = pad;
		initialized = false;
		if(initFunc != null)
			initFunc(this);
	}

	/**
	 * Initialize the Cipher for encryption or decryption.
	 * @param direction For encrypt or decrypt, overrides direction setting in params
	 * @param params
	 **/
	public function init(direction:CipherDirection, params : CipherParams=null) : Void {
		initialized = true;
		this.direction = direction;
		switch(direction) {
		case ENCRYPT:
			modeUpdate = mode.updateEncrypt;
			modeFinal = mode.finalEncrypt;
		case DECRYPT:
			modeUpdate = mode.updateDecrypt;
			modeFinal = mode.finalDecrypt;
		}
		if(params == null)
			this.params = new CipherParams();
		else
			this.params = params.clone();
		this.params.direction = direction;

		mode.cipher = algo;
		mode.padding = pad;

		//algo.init(this.params);
		mode.init(this.params);
		//pad.init();

		// streaming modes will have blocksizes less than that of the
		// underlying crypt
		this.blockSize = mode.blockSize;
		this.bufsize = this.blockSize == 1 ? 1 : this.blockSize;
		buf = Bytes.alloc(this.bufsize);
		ptr = 0;
	}

	/**
	 * Update the cipher with any number of bytes.
	 * @param input Bytes object with bytes to encrypt or decrypt
	 * @param inputOffset Offset into 'input' to read from
	 * @param inputLen Number of bytes to read from 'input'
	 * @param out An Output stream of any kind
	 * @return The number of bytes consumed from 'input', which may be less than inputLen
	 **/
	public function update(input:Bytes, inputOffset:Int, inputLen:Int, out:Output) : Int {

		if(inputLen <= 0)
			return 0;
		var rv = inputLen;
		if(blockSize == 1) {
			for(i in 0...inputLen) {
				buf.set(0, input.get(inputOffset + i));
				modeUpdate(buf, out);
			}
		} else {
			// here we always have to reserve at least one block un-crypted when
			// blocksize != 1, since padding may be in the last block and must
			// be handled in final()
			while(inputLen > 0) {
				// flush out buf if it is full and we have more incoming
				if(ptr == blockSize) {
					var written = modeUpdate(buf, out);
					Assert.isTrue(written == blockSize);
					ptr = 0;
				}
				var num = Std.int(Math.min(bufsize-ptr, inputLen));
				if(num <= 0) {
					break;
				}
				// fill up the buf again
				for(i in 0...num) {
					Assert.isTrue(ptr + i < bufsize);
					buf.set(i+ptr, input.get(i + inputOffset));
				}
				inputLen -= num;
				inputOffset += num;
				ptr += num;
				Assert.isTrue(ptr <= bufsize);
			}
		}
		return rv;
	}

	/**
	 * Update and finalize the cipher with any number of bytes.
	 * @param input Bytes object with bytes to encrypt or decrypt
	 * @param inputOffset Offset into 'input' to read from
	 * @param inputLen Number of bytes to read from 'input'
	 * @param out An Output stream of any kind
	 * @return Number of bytes written to 'out' (which may be more or less than read from 'input')
	 **/
	public function final(input:Bytes, inputOffset:Int, inputLen:Int, out:Output) : Int {
		var rv : Int = 0;
		var read : Int = 1;
		while(inputLen > 0 && read > 0) {
			read = update(input,inputOffset,inputLen,out);
			rv += read;
			inputOffset += read;
			inputLen -= read;
		}
		var rem : Bytes = buf.sub(0,ptr);
		rv += modeFinal(rem, out);
		//rv += rem.length;
		return rv;
	}

	/**
	 * Return the initial IV set for this crypt
	 **/
	public function getIV() : Bytes {
		return params.iv;
	}

	/**
	 * As the IV changes during crypt, this will return its current value
	 **/
	public function getCurrentIV() : Bytes {
		if(!Std.is(mode, IVBase))
			return params.iv;
		var ivm : IVBase = cast mode;
		return ivm.iv;
	}
}
