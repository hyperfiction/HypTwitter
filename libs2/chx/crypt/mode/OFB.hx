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
 * Output Feedback mode
 **/
class OFB extends IVBase, implements chx.crypt.IMode {

	override public function toString() {
		return "ofb";
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
		if(b.length != n)
			return 0;
		common(b, out);

		#if CAFFEINE_DEBUG
			var db : Bytes = untyped out.getBytes();
			out = orig;
			trace("Output Block: " + db.toHex());
			trace("Ciphertext: " + db.toHex());
			trace("");
			out.writeBytes(db,0,db.length);
		#end

		return n;
	}

	override public function updateDecrypt( b : Bytes, out : Output ) : Int {
		#if CAFFEINE_DEBUG
			trace("updateDecrypt: ");
			trace("IV " + iv.toHex());
			trace("Plaintext: " + b.toHex());
			var orig = out;
			out = new BytesOutput();
		#end

		var n = cipher.blockSize;
		if(b.length != n)
			return 0;
		common(b, out);

		#if CAFFEINE_DEBUG
			var db : Bytes = untyped out.getBytes();
			out = orig;
			trace("Output Block: " + db.toHex());
			trace("Ciphertext: " + db.toHex());
			trace("");
			out.writeBytes(db,0,db.length);
		#end

		return n;
	}

	private function common(b:Bytes, out:Output) : Int {
		var n = cipher.blockSize;
		if(b.length != n)
			return 0;
		iv = cipher.encryptBlock(iv);

		for(i in 0...n)
			b.set(i, b.get(i) ^ iv.get(i));
		#if CAFFEINE_DEBUG
			trace("Input Block: " + b.toHex());
		#end
		out.writeBytes(b, 0, n);
		return n;
	}

}
