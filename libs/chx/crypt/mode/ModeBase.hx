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

import chx.crypt.CipherParams;
import chx.crypt.IBlockCipher;
import chx.crypt.IPad;
import chx.crypt.padding.PadPkcs5;
import chx.io.BytesOutput;
import chx.io.Output;

/**
 * Abstract base class for crypto modes. Default mode is PKCS5
 **/
class ModeBase implements IMode {
	public var cipher(default, setCipher) : IBlockCipher;
	public var padding(default,setPadding) : IPad;
	public var blockSize(getBlockSize,never) : Int;
	
	var params : CipherParams;
	
	public function new() {
		padding = new PadPkcs5();
	}

	public function toString() {
		return "??";
	}

	public function updateEncrypt( b : Bytes, out : Output) : Int {
		throw new chx.lang.FatalException("not implemented");
		return 0;
	}
	
	public function updateDecrypt( b : Bytes, out : Output ) : Int {
		throw new chx.lang.FatalException("not implemented");
		return 0;
	}

	// true except for streaming modes, which should override this
	function getBlockSize() : Int {
		return cipher.blockSize;
	}

	function setCipher(v:IBlockCipher) {
		this.cipher = v;
		if(padding != null)
			padding.blockSize = cipher.blockSize;
		return v;
	}

	function setPadding(v:IPad) {
		this.padding = v;
		if(this.cipher != null)
			this.padding.blockSize = this.cipher.blockSize;
		return v;
	}

	public function init(params : CipherParams) : Void {
		this.params = params;
	}

	public function finalEncrypt( b : Bytes, out : Output) : Int {
		var n = blockSize;
		var buf = padding.pad(b);
		Assert.isEqual(0, buf.length % n);

		var ptr = 0;
		var rv = 0;
		while(ptr < buf.length) {
			n = updateEncrypt(buf.sub(ptr,n), out);
			ptr += n;
			rv += n;
			if(n == 0)
				throw "error";
		}
		return rv;
	}

	public function finalDecrypt( b : Bytes, out : Output ) : Int {
		var n = blockSize;
		Assert.isTrue(b.length % n == 0);
		var bo = new BytesOutput();
		var ptr = 0;
		var rv = 0;
		while(ptr < b.length) {
			n = updateDecrypt(b.sub(ptr,n), bo);
			ptr += n;
			rv += n;
			if(n == 0)
				throw "error";
		}
		var u = padding.unpad(bo.getBytes());
		out.writeBytes(u, 0, u.length);
		return rv;
	}
}