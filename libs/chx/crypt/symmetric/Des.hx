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
* DESKey
*
* Derived from:
*              An Actionscript 3 implementation of the Data Encryption Standard (DES)
*              Copyright (c) 2007 Henri Torgemane
* Which in turn derives from:
*              The Bouncy Castle Crypto package,
*              Copyright (c) 2000-2004 The Legion Of The Bouncy Castle
*              (http://www.bouncycastle.org)
*
* See LICENSE.txt for full license information.
*/
package chx.crypt.symmetric;
import I32;

/**
* DES Key. In neko requires the openssl ndll.
**/
class Des implements IBlockCipher
{
	public var blockSize(__getBlockSize,null) : Int;
	#if (neko || useOpenSSL)
	var key:Dynamic;
	#else
	/*
	* what follows is mainly taken from "Applied Cryptography", by Bruce
	* Schneier, however it also bears great resemblance to Richard
	* Outerbridge's D3DES...
	*/
	private static var Df_Key:Array<Int32> = [ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef, 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32,
					0x10, 0x89, 0xab, 0xcd, 0xef, 0x01, 0x23, 0x45, 0x67 ];

	private static var bytebit:Array<Int32> = [ 128, 64, 32, 16, 8, 4, 2, 1 ];

	private static var bigbyte:Array<Int32> = [ 0x800000, 0x400000, 0x200000, 0x100000, 0x80000, 0x40000, 0x20000, 0x10000, 0x8000,
					0x4000, 0x2000, 0x1000, 0x800, 0x400, 0x200, 0x100, 0x80, 0x40, 0x20, 0x10, 0x8, 0x4, 0x2, 0x1 ];

	/*
	* Use the key schedule specified in the Standard (ANSI X3.92-1981).
	*/

	private static var pc1:Array<Int32> = [ 56, 48, 40, 32, 24, 16, 8, 0, 57, 49, 41, 33, 25, 17, 9, 1, 58, 50, 42, 34, 26, 18, 10, 2,
					59, 51, 43, 35, 62, 54, 46, 38, 30, 22, 14, 6, 61, 53, 45, 37, 29, 21, 13, 5, 60, 52, 44, 36, 28, 20, 12,
					4, 27, 19, 11, 3 ];

	private static var totrot:Array<Int32> = [ 1, 2, 4, 6, 8, 10, 12, 14, 15, 17, 19, 21, 23, 25, 27, 28 ];

	private static var pc2:Array<Int32> = [ 13, 16, 10, 23, 0, 4, 2, 27, 14, 5, 20, 9, 22, 18, 11, 3, 25, 7, 15, 6, 26, 19, 12, 1, 40,
					51, 30, 36, 46, 54, 29, 39, 50, 44, 32, 47, 43, 48, 38, 55, 33, 52, 45, 41, 49, 35, 28, 31 ];

	private static var SP1:Array<Int32> = [ 0x01010400, 0x00000000, 0x00010000, 0x01010404, 0x01010004, 0x00010404, 0x00000004,
					0x00010000, 0x00000400, 0x01010400, 0x01010404, 0x00000400, 0x01000404, 0x01010004, 0x01000000, 0x00000004,
					0x00000404, 0x01000400, 0x01000400, 0x00010400, 0x00010400, 0x01010000, 0x01010000, 0x01000404, 0x00010004,
					0x01000004, 0x01000004, 0x00010004, 0x00000000, 0x00000404, 0x00010404, 0x01000000, 0x00010000, 0x01010404,
					0x00000004, 0x01010000, 0x01010400, 0x01000000, 0x01000000, 0x00000400, 0x01010004, 0x00010000, 0x00010400,
					0x01000004, 0x00000400, 0x00000004, 0x01000404, 0x00010404, 0x01010404, 0x00010004, 0x01010000, 0x01000404,
					0x01000004, 0x00000404, 0x00010404, 0x01010400, 0x00000404, 0x01000400, 0x01000400, 0x00000000, 0x00010004,
					0x00010400, 0x00000000, 0x01010004 ];

	private static var SP2:Array<Int32> = [ 0x80108020, 0x80008000, 0x00008000, 0x00108020, 0x00100000, 0x00000020, 0x80100020,
					0x80008020, 0x80000020, 0x80108020, 0x80108000, 0x80000000, 0x80008000, 0x00100000, 0x00000020, 0x80100020,
					0x00108000, 0x00100020, 0x80008020, 0x00000000, 0x80000000, 0x00008000, 0x00108020, 0x80100000, 0x00100020,
					0x80000020, 0x00000000, 0x00108000, 0x00008020, 0x80108000, 0x80100000, 0x00008020, 0x00000000, 0x00108020,
					0x80100020, 0x00100000, 0x80008020, 0x80100000, 0x80108000, 0x00008000, 0x80100000, 0x80008000, 0x00000020,
					0x80108020, 0x00108020, 0x00000020, 0x00008000, 0x80000000, 0x00008020, 0x80108000, 0x00100000, 0x80000020,
					0x00100020, 0x80008020, 0x80000020, 0x00100020, 0x00108000, 0x00000000, 0x80008000, 0x00008020, 0x80000000,
					0x80100020, 0x80108020, 0x00108000 ];

	private static var SP3:Array<Int32> = [ 0x00000208, 0x08020200, 0x00000000, 0x08020008, 0x08000200, 0x00000000, 0x00020208,
					0x08000200, 0x00020008, 0x08000008, 0x08000008, 0x00020000, 0x08020208, 0x00020008, 0x08020000, 0x00000208,
					0x08000000, 0x00000008, 0x08020200, 0x00000200, 0x00020200, 0x08020000, 0x08020008, 0x00020208, 0x08000208,
					0x00020200, 0x00020000, 0x08000208, 0x00000008, 0x08020208, 0x00000200, 0x08000000, 0x08020200, 0x08000000,
					0x00020008, 0x00000208, 0x00020000, 0x08020200, 0x08000200, 0x00000000, 0x00000200, 0x00020008, 0x08020208,
					0x08000200, 0x08000008, 0x00000200, 0x00000000, 0x08020008, 0x08000208, 0x00020000, 0x08000000, 0x08020208,
					0x00000008, 0x00020208, 0x00020200, 0x08000008, 0x08020000, 0x08000208, 0x00000208, 0x08020000, 0x00020208,
					0x00000008, 0x08020008, 0x00020200 ];

	private static var SP4:Array<Int32> = [ 0x00802001, 0x00002081, 0x00002081, 0x00000080, 0x00802080, 0x00800081, 0x00800001,
					0x00002001, 0x00000000, 0x00802000, 0x00802000, 0x00802081, 0x00000081, 0x00000000, 0x00800080, 0x00800001,
					0x00000001, 0x00002000, 0x00800000, 0x00802001, 0x00000080, 0x00800000, 0x00002001, 0x00002080, 0x00800081,
					0x00000001, 0x00002080, 0x00800080, 0x00002000, 0x00802080, 0x00802081, 0x00000081, 0x00800080, 0x00800001,
					0x00802000, 0x00802081, 0x00000081, 0x00000000, 0x00000000, 0x00802000, 0x00002080, 0x00800080, 0x00800081,
					0x00000001, 0x00802001, 0x00002081, 0x00002081, 0x00000080, 0x00802081, 0x00000081, 0x00000001, 0x00002000,
					0x00800001, 0x00002001, 0x00802080, 0x00800081, 0x00002001, 0x00002080, 0x00800000, 0x00802001, 0x00000080,
					0x00800000, 0x00002000, 0x00802080 ];

	private static var SP5:Array<Int32> = [ 0x00000100, 0x02080100, 0x02080000, 0x42000100, 0x00080000, 0x00000100, 0x40000000,
					0x02080000, 0x40080100, 0x00080000, 0x02000100, 0x40080100, 0x42000100, 0x42080000, 0x00080100, 0x40000000,
					0x02000000, 0x40080000, 0x40080000, 0x00000000, 0x40000100, 0x42080100, 0x42080100, 0x02000100, 0x42080000,
					0x40000100, 0x00000000, 0x42000000, 0x02080100, 0x02000000, 0x42000000, 0x00080100, 0x00080000, 0x42000100,
					0x00000100, 0x02000000, 0x40000000, 0x02080000, 0x42000100, 0x40080100, 0x02000100, 0x40000000, 0x42080000,
					0x02080100, 0x40080100, 0x00000100, 0x02000000, 0x42080000, 0x42080100, 0x00080100, 0x42000000, 0x42080100,
					0x02080000, 0x00000000, 0x40080000, 0x42000000, 0x00080100, 0x02000100, 0x40000100, 0x00080000, 0x00000000,
					0x40080000, 0x02080100, 0x40000100 ];

	private static var SP6:Array<Int32> = [ 0x20000010, 0x20400000, 0x00004000, 0x20404010, 0x20400000, 0x00000010, 0x20404010,
					0x00400000, 0x20004000, 0x00404010, 0x00400000, 0x20000010, 0x00400010, 0x20004000, 0x20000000, 0x00004010,
					0x00000000, 0x00400010, 0x20004010, 0x00004000, 0x00404000, 0x20004010, 0x00000010, 0x20400010, 0x20400010,
					0x00000000, 0x00404010, 0x20404000, 0x00004010, 0x00404000, 0x20404000, 0x20000000, 0x20004000, 0x00000010,
					0x20400010, 0x00404000, 0x20404010, 0x00400000, 0x00004010, 0x20000010, 0x00400000, 0x20004000, 0x20000000,
					0x00004010, 0x20000010, 0x20404010, 0x00404000, 0x20400000, 0x00404010, 0x20404000, 0x00000000, 0x20400010,
					0x00000010, 0x00004000, 0x20400000, 0x00404010, 0x00004000, 0x00400010, 0x20004010, 0x00000000, 0x20404000,
					0x20000000, 0x00400010, 0x20004010 ];

	private static var SP7:Array<Int32> = [ 0x00200000, 0x04200002, 0x04000802, 0x00000000, 0x00000800, 0x04000802, 0x00200802,
					0x04200800, 0x04200802, 0x00200000, 0x00000000, 0x04000002, 0x00000002, 0x04000000, 0x04200002, 0x00000802,
					0x04000800, 0x00200802, 0x00200002, 0x04000800, 0x04000002, 0x04200000, 0x04200800, 0x00200002, 0x04200000,
					0x00000800, 0x00000802, 0x04200802, 0x00200800, 0x00000002, 0x04000000, 0x00200800, 0x04000000, 0x00200800,
					0x00200000, 0x04000802, 0x04000802, 0x04200002, 0x04200002, 0x00000002, 0x00200002, 0x04000000, 0x04000800,
					0x00200000, 0x04200800, 0x00000802, 0x00200802, 0x04200800, 0x00000802, 0x04000002, 0x04200802, 0x04200000,
					0x00200800, 0x00000000, 0x00000002, 0x04200802, 0x00000000, 0x00200802, 0x04200000, 0x00000800, 0x04000002,
					0x04000800, 0x00000800, 0x00200002 ];

	private static var SP8:Array<Int32> = [ 0x10001040, 0x00001000, 0x00040000, 0x10041040, 0x10000000, 0x10001040, 0x00000040,
					0x10000000, 0x00040040, 0x10040000, 0x10041040, 0x00041000, 0x10041000, 0x00041040, 0x00001000, 0x00000040,
					0x10040000, 0x10000040, 0x10001000, 0x00001040, 0x00041000, 0x00040040, 0x10040040, 0x10041000, 0x00001040,
					0x00000000, 0x00000000, 0x10040040, 0x10000040, 0x10001000, 0x00041040, 0x00040000, 0x00041040, 0x00040000,
					0x10041000, 0x00001000, 0x00000040, 0x10040040, 0x00001000, 0x00041040, 0x10001000, 0x00000040, 0x10000040,
					0x10040000, 0x10040040, 0x10000000, 0x00040000, 0x10001040, 0x00000000, 0x10041040, 0x00040040, 0x10000040,
					0x10040000, 0x10001000, 0x10001040, 0x00000000, 0x10041040, 0x00041000, 0x00041000, 0x00001040, 0x00001040,
					0x00040040, 0x10000000, 0x10041000 ];

	var key:Bytes;
	var encKey:Array<Int32>;
	var decKey:Array<Int32>;
	#end

	public function new(key:Bytes) {
		if(key.length < 8)
			throw new chx.lang.OutsideBoundsException("Must be 8 bytes of key data");
		#if (neko || useOpenSSL)
			this.key = des_create_key(key.sub(0,8).getData());
		#else
			this.key = key;
			this.encKey = generateWorkingKey(true, key, 0);
			this.decKey = generateWorkingKey(false, key, 0);
		#end
	}

	public function getBlockSize():Int
	{
		return 8;
	}

	function __getBlockSize():Int {
		return 8;
	}

	public function decryptBlock(block:Bytes):Bytes
	{
		#if (neko || useOpenSSL)
			return Bytes.ofData(des_decrypt_block(key, block.getData()));
		#else
			var outBlock = Bytes.alloc(block.length);
			desFunc(decKey, block, 0, outBlock, 0);
			return outBlock;
		#end
	}

	public function dispose():Void
	{
		#if (neko || useOpenSSL)
			des_destroy_key(key);
		#else
			for (i in 0...encKey.length) { encKey[i]=0; }
			for (i in 0...decKey.length) { decKey[i]=0; }
			encKey=null;
			decKey=null;
			for (i in 0...key.length) { key.set(i, 0); }
			key = null;
		#end
	}

	public function encryptBlock(block:Bytes):Bytes
	{
		#if (neko || useOpenSSL)
			return Bytes.ofData(des_encrypt_block(key, block.getData()));
		#else
			var outBlock = Bytes.alloc(block.length);
			desFunc(encKey, block, 0, outBlock, 0);
			return outBlock;
		#end
	}

	#if !(neko || useOpenSSL)
	/**
	* generate an integer based working key based on our secret key and what we
	* processing we are planning to do.
	*
	* Acknowledgements for this routine go to James Gillogly & Phil Karn.
	*/
	function generateWorkingKey(encrypting:Bool, key:Bytes, off:Int):Array<Int32>
	{
		//int[] newKey = new int[32];
		var newKey:Array<Int32> = [];
		//boolean[] pc1m = new boolean[56], pcr = new boolean[56];
		var pc1m:Array<Bool> = new Array();
		var pcr:Array<Bool> = new Array();

		var l:Int;

		for (j in 0...56)
		{
			l = pc1[j];
			pc1m[j] = ((key.get(off + (l >>> 3)) & bytebit[l & 07]) != 0);
		}

		for (i in 0...16)
		{
			var m:Int;
			var n:Int;

			if (encrypting)
			{
				m = i << 1;
			}
			else
			{
				m = (15 - i) << 1;
			}

			n = m + 1;
			newKey[m] = newKey[n] = 0;

			for (j in 0...28)
			{
				l = j + totrot[i];
				if (l < 28)
				{
					pcr[j] = pc1m[l];
				}
				else
				{
					pcr[j] = pc1m[l - 28];
				}
			}

			for (j in 28...56)
			{
				l = j + totrot[i];
				if (l < 56)
				{
					pcr[j] = pc1m[l];
				}
				else
				{
					pcr[j] = pc1m[l - 28];
				}
			}

			for (j in 0...24)
			{
				if (pcr[pc2[j]])
				{
					newKey[m] |= bigbyte[j];
				}

				if (pcr[pc2[j + 24]])
				{
					newKey[n] |= bigbyte[j];
				}
			}
		}

		//
		// store the processed key
		//
		var i:Int = 0;
		while(i < 32)
		{
			var i1:Int32;
			var i2:Int32;

			i1 = newKey[i];
			i2 = newKey[i + 1];

			newKey[i] = ((i1 & 0x00fc0000) << 6) | ((i1 & 0x00000fc0) << 10) | ((i2 & 0x00fc0000) >>> 10)
							| ((i2 & 0x00000fc0) >>> 6);

			newKey[i + 1] = ((i1 & 0x0003f000) << 12) | ((i1 & 0x0000003f) << 16) | ((i2 & 0x0003f000) >>> 4)
							| (i2 & 0x0000003f);
			i += 2;
		}
		return newKey;
	}

	/**
	* the DES engine.
	*/
	private function desFunc(wKey:Array<Int32>, inp:Bytes, inOff:Int, out:Bytes, outOff:Int):Void
	{
		var work:Int32 = 0;
		var right:Int32 = 0;
		var left:Int32 = 0;

		left = (inp.get(inOff + 0) & 0xff) << 24;
		left |= (inp.get(inOff + 1) & 0xff) << 16;
		left |= (inp.get(inOff + 2) & 0xff) << 8;
		left |= (inp.get(inOff + 3) & 0xff);

		right = (inp.get(inOff + 4) & 0xff) << 24;
		right |= (inp.get(inOff + 5) & 0xff) << 16;
		right |= (inp.get(inOff + 6) & 0xff) << 8;
		right |= (inp.get(inOff + 7) & 0xff);

		work = ((left >>> 4) ^ right) & 0x0f0f0f0f;
		right ^= work;
		left ^= (work << 4);
		work = ((left >>> 16) ^ right) & 0x0000ffff;
		right ^= work;
		left ^= (work << 16);
		work = ((right >>> 2) ^ left) & 0x33333333;
		left ^= work;
		right ^= (work << 2);
		work = ((right >>> 8) ^ left) & 0x00ff00ff;
		left ^= work;
		right ^= (work << 8);
		right = ((right << 1) | ((right >>> 31) & 1)) & 0xffffffff;
		work = (left ^ right) & 0xaaaaaaaa;
		left ^= work;
		right ^= work;
		left = ((left << 1) | ((left >>> 31) & 1)) & 0xffffffff;

		for (round in 0...8)
		{
			var fval:Int32 = 0;

			work = (right << 28) | (right >>> 4);
			work ^= wKey[round * 4 + 0];
			fval = SP7[work & 0x3f];
			fval |= SP5[(work >>> 8) & 0x3f];
			fval |= SP3[(work >>> 16) & 0x3f];
			fval |= SP1[(work >>> 24) & 0x3f];
			work = right ^ wKey[round * 4 + 1];
			fval |= SP8[work & 0x3f];
			fval |= SP6[(work >>> 8) & 0x3f];
			fval |= SP4[(work >>> 16) & 0x3f];
			fval |= SP2[(work >>> 24) & 0x3f];
			left ^= fval;
			work = (left << 28) | (left >>> 4);
			work ^= wKey[round * 4 + 2];
			fval = SP7[work & 0x3f];
			fval |= SP5[(work >>> 8) & 0x3f];
			fval |= SP3[(work >>> 16) & 0x3f];
			fval |= SP1[(work >>> 24) & 0x3f];
			work = left ^ wKey[round * 4 + 3];
			fval |= SP8[work & 0x3f];
			fval |= SP6[(work >>> 8) & 0x3f];
			fval |= SP4[(work >>> 16) & 0x3f];
			fval |= SP2[(work >>> 24) & 0x3f];
			right ^= fval;
		}

		right = (right << 31) | (right >>> 1);
		work = (left ^ right) & 0xaaaaaaaa;
		left ^= work;
		right ^= work;
		left = (left << 31) | (left >>> 1);
		work = ((left >>> 8) ^ right) & 0x00ff00ff;
		right ^= work;
		left ^= (work << 8);
		work = ((left >>> 2) ^ right) & 0x33333333;
		right ^= work;
		left ^= (work << 2);
		work = ((right >>> 16) ^ left) & 0x0000ffff;
		left ^= work;
		right ^= (work << 16);
		work = ((right >>> 4) ^ left) & 0x0f0f0f0f;
		left ^= work;
		right ^= (work << 4);

		out.set(outOff + 0, ((right >>> 24) & 0xff));
		out.set(outOff + 1, ((right >>> 16) & 0xff));
		out.set(outOff + 2, ((right >>> 8) & 0xff));
		out.set(outOff + 3, (right & 0xff));
		out.set(outOff + 4, ((left >>> 24) & 0xff));
		out.set(outOff + 5, ((left >>> 16) & 0xff));
		out.set(outOff + 6, ((left >>> 8) & 0xff));
		out.set(outOff + 7, (left & 0xff));
	}
	#end

	public function toString():String {
		return "DES";
	}


#if (neko || useOpenSSL)
	public static function __init__()
	{
		chx.Lib.initDll("openssl");
	}

	private static var des_create_key = chx.Lib.load("openssl","des_create_key",1);
	private static var des_destroy_key = chx.Lib.load("openssl","des_create_key",1);
	private static var des_encrypt_block = chx.Lib.load("openssl","des_encrypt_block",2);
	private static var des_decrypt_block = chx.Lib.load("openssl","des_decrypt_block",2);
#end
}

