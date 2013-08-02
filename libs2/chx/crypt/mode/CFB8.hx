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
 * CFB8 mode - a 1 byte block streaming mode
 **/
class CFB8 extends IVBase, implements chx.crypt.IMode {

	override public function toString() {
		return "cfb8";
	}

	override function getBlockSize() : Int {
		return 1;
	}

	override public function updateEncrypt( b : Bytes, out : Output) : Int {
		#if CAFFEINE_DEBUG
			trace("updateEncrypt: ");
			trace("IV " + iv.toHex());
			trace("Plaintext: " + b.toHex());
			var orig = out;
			out = new BytesOutput();
		#end

		var n = cipher.blockSize;
		if(b.length == 0)
			return 0;

		for(i in 0...b.length) {
			var val = b.get(i);
			#if CAFFEINE_DEBUG
				trace("Input Block: " + b.toHex());
			#end
			var tmp = iv.sub(0, n);
			iv = cipher.encryptBlock(iv);
			#if CAFFEINE_DEBUG
				trace("Output Block: " + iv.toHex());
			#end
			val = val ^ iv.get(0);

			for(j in 0...n-1)
				iv.set(j, tmp.get(j+1));
			iv.set(n-1, val);

			out.writeByte(val);

			#if CAFFEINE_DEBUG
				var db : Bytes = untyped out.getBytes();
				out = orig;
				trace("Ciphertext: " + db.toHex());
				trace("");
				out.writeBytes(db,0,db.length);
			#end
		}

		return b.length;
	}

	override public function updateDecrypt( b : Bytes, out : Output ) : Int {
		#if CAFFEINE_DEBUG
			trace("updateDecrypt: ");
			trace("IV " + iv.toHex());
			trace("Ciphertext: " + b.toHex());
			var orig = out;
			out = new BytesOutput();
		#end

		var n = cipher.blockSize;
		if(b.length == 0)
			return 0;

		for(i in 0...b.length) {
			var val = b.get(i);
			//var orig = val;
			#if CAFFEINE_DEBUG
				trace("Input Block: " + iv.toHex());
			#end
			var tmp = iv.sub(0, n);
			iv = cipher.encryptBlock(iv);
			val = val ^ iv.get(0);
			#if CAFFEINE_DEBUG
				trace("Output Block: " + iv.toHex());
			#end

			for(j in 0...n-1)
				iv.set(j, tmp.get(j+1));
			iv.set(n-1, b.get(i));

			out.writeByte(val);

			#if CAFFEINE_DEBUG
				var db : Bytes = untyped out.getBytes();
				out = orig;
				//trace("Output Block: " + db.toHex());
				trace("Plaintext: " + db.toHex());
				trace("");
				out.writeBytes(db,0,db.length);
			#end
		}

		return b.length;
	}


}
