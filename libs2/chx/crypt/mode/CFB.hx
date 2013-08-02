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

package chx.crypt.mode;

import chx.io.BytesOutput;
import chx.io.Output;

/**
 * Cipher Feedback block mode
 **/
class CFB extends IVBase, implements chx.crypt.IMode {

	override public function toString() {
		return "cfb" + (cipher == null ? "??" : Std.string(cipher.blockSize * 8));
	}

	override public function updateEncrypt( b : Bytes, out : Output) : Int {
		#if CAFFEINE_DEBUG
			trace("updateEncrypt: ");
			var pt : String = b.toHex();
			var orig = out;
			out = new BytesOutput();
		#end

		var n = cipher.blockSize;
		if(b.length != n)
			return 0;

		#if CAFFEINE_DEBUG
			trace("Input Block: " + currentIV.toHex());
		#end
		currentIV = cipher.encryptBlock(currentIV);
		
		var tmp = Bytes.alloc(n);
		for(i in 0...n)
			tmp.set(i, currentIV.get(i) ^ b.get(i));
		
		#if CAFFEINE_DEBUG
			trace("Output Block: " + currentIV.toHex());
			trace("Plaintext: " + pt);
			trace("Ciphertext: " + tmp.toHex());
			out = orig;
		#end
		out.writeBytes(tmp,0,n);
		currentIV.blit(0, tmp, 0, n);
		return n;
	}

	override public function updateDecrypt( b : Bytes, out : Output ) : Int {
		#if CAFFEINE_DEBUG
			trace("updateEncrypt: ");
			var pt : String = b.toHex();
			var orig = out;
			out = new BytesOutput();
		#end

		var n = cipher.blockSize;
		if(b.length != n)
			return 0;

		#if CAFFEINE_DEBUG
			trace("Input Block: " + currentIV.toHex());
		#end
		currentIV = cipher.encryptBlock(currentIV);
		var tmp : Bytes = b.sub(0,n);
		
		for(i in 0...n)
			b.set(i, currentIV.get(i) ^ b.get(i));

		#if CAFFEINE_DEBUG
			trace("Output Block: " + currentIV.toHex());
			trace("Ciphertext: " + pt);
			trace("Plaintext: " + b.toHex());
			out = orig;
		#end
		currentIV.blit(0, tmp, 0, n);
		out.writeBytes(b,0,n);
		return n;
	}

}
