/*
 * Copyright (c) 2011, The Caffeine-hx project contributors
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
 * TripleDESKey
 * 
 * An Actionscript 3 implementation of Triple DES
 * Copyright (c) 2007 Henri Torgemane
 * 
 * Derived from:
 * 	The Bouncy Castle Crypto package, 
 * 	Copyright (c) 2000-2004 The Legion Of The Bouncy Castle
 * 	(http://www.bouncycastle.org)
 * 
 * See LICENSE.txt for full license information.
 */
package chx.crypt.symmetric;
import I32;

/**
* This supports 2TDES and 3TDES.
* If the key passed is 128 bits, 2TDES is used.
* If the key has 192 bits, 3TDES is used.
* Other key lengths give "undefined" results.
*/
class TripleDes extends Des
{
	#if (neko || cpp)
	private var key2:Dynamic;
	private var key3:Dynamic;
	#else
	private var encKey2:Array<Int32>;
	private var encKey3:Array<Int32>;
	private var decKey2:Array<Int32>;
	private var decKey3:Array<Int32>;
	#end

	public function new(key:Bytes)
	{
		if(key.length < 16)
			throw new chx.lang.OutsideBoundsException("Must be at least 16 bytes of key data");
		super(key);
		#if (neko || cpp)
			this.key2 = des_create_key(key.sub(8,8).getData());
			if(key.length > 16)
				this.key3 = des_create_key(key.sub(16,8).getData());
			else
				this.key3 = des_create_key(key.sub(0,8).getData());
		#else
			encKey2 = generateWorkingKey(false, key, 8);
			decKey2 = generateWorkingKey(true, key, 8);
			if (key.length>16) {
				encKey3 = generateWorkingKey(true, key, 16);
				decKey3 = generateWorkingKey(false, key, 16);
			} else {
				encKey3 = encKey;
				decKey3 = decKey;
			}
		#end
	}

	public override function dispose():Void
	{
		super.dispose();
		#if (neko || cpp)
			des_destroy_key(key2);
			des_destroy_key(key3);
		#else
			var i:Int = 0;
			if (encKey2!=null) {
				for (i in 0...encKey2.length) { encKey2[i]=0; }
				encKey2=null;
			}
			if (encKey3!=null) {
				for (i in 0...encKey3.length) { encKey3[i]=0; }
				encKey3=null;
			}
			if (decKey2!=null) {
				for (i in 0...decKey2.length) { decKey2[i]=0; }
				decKey2=null;
			}
			if (decKey3!=null) {
				for (i in 0...decKey3.length) { decKey3[i]=0; }
				decKey3=null;
			}
		#end
	}

	public override function encryptBlock(block:Bytes):Bytes
	{
		#if (neko || cpp)
			return Bytes.ofData(des3_encrypt_block(key, key2, key3, block.getData()));
		#else
			var outBlock = Bytes.alloc(block.length);
			desFunc(encKey, block, 0, outBlock, 0);
			desFunc(encKey2, outBlock, 0, outBlock, 0);
			desFunc(encKey3, outBlock, 0, outBlock, 0);
			return outBlock;
		#end
	}

	public override function decryptBlock(block:Bytes):Bytes
	{
		#if (neko || cpp)
			return Bytes.ofData(des3_decrypt_block(key, key2, key3, block.getData()));
		#else
			var outBlock = Bytes.alloc(block.length);
			desFunc(decKey3, block, 0, outBlock, 0);
			desFunc(decKey2, outBlock, 0, outBlock, 0);
			desFunc(decKey, outBlock, 0, outBlock, 0);
			return outBlock;
		#end
	}

	public override function toString():String {
		return "3des";
	}

#if (neko || cpp)
	private static var des_create_key = chx.Lib.load("openssl","des_create_key",1);
	private static var des_destroy_key = chx.Lib.load("openssl","des_create_key",1);
	private static var des3_encrypt_block = chx.Lib.load("openssl","des3_encrypt_block",4);
	private static var des3_decrypt_block = chx.Lib.load("openssl","des3_decrypt_block",4);
#end
}
