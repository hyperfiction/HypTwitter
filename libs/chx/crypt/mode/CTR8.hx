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
 * Counter mode - a 1 byte block streaming mode. This version updates the
 * counter on every byte (8 bits)
 **/
class CTR8 extends IVBase, implements chx.crypt.IMode {
	/** Bytes encrypted counter **/
	var num : Int;
	/** Point at which to increment counter, in number of bytes **/
	var ctr_inc : Int;

	public function new() {
		super();
		num = 0;
		ctr_inc = 1;
	}

	override public function toString() {
		return "ctr";
	}

	override function getBlockSize() : Int {
		return 1;
	}

	override public function updateEncrypt( b : Bytes, out : Output) : Int {
		#if CAFFEINE_DEBUG
			trace("updateEncrypt: ");
			var orig_b = b.sub(0);
			var orig = out;
			out = new BytesOutput();
		#end

		common(b, out);

		#if CAFFEINE_DEBUG
			var db : Bytes = untyped out.getBytes();
			out = orig;
			trace("Plaintext: " + orig_b.toHex());
			trace("Ciphertext: " + db.toHex());
			trace("");
			out.writeBytes(db,0,db.length);
		#end

		return b.length;
	}

	override public function updateDecrypt( b : Bytes, out : Output ) : Int {
		#if CAFFEINE_DEBUG
			trace("updateDecrypt: ");
			var orig_b = b.sub(0);
			var orig = out;
			out = new BytesOutput();
		#end

		common(b, out);

		#if CAFFEINE_DEBUG
			var db : Bytes = untyped out.getBytes();
			out = orig;
			trace("Plaintext: " + orig_b.toHex());
			trace("Ciphertext: " + db.toHex());
			trace("");
			out.writeBytes(db,0,db.length);
		#end

		return b.length;
	}

	private function common(b:Bytes, out:Output) : Int {
		var n = b.length;
		if(n == 0)
			return 0;

		var e : Bytes = cipher.encryptBlock(currentIV);
		#if CAFFEINE_DEBUG
			trace("Input Block: " + currentIV.toHex());
			trace("Output Block: " + e.toHex());
		#end
		for(i in 0...n) {
			b.set(i, b.get(i) ^ e.get(i));
			num++;
			if(num == ctr_inc) {
				trace(ctr_inc);
				num = 0;
				// increment 'counter'
				var x = currentIV.length-1;
				while(x>=0) {
					currentIV.set(x, currentIV.get(x) + 1);
					if(currentIV.get(x) != 0)
						break;
					x--;
				}
				e = cipher.encryptBlock(currentIV);
			}
		}

		out.writeBytes(b, 0, n);
		return n;
	}

}
