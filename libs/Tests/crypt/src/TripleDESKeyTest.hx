/**
 * TripleDESKeyTest
 * 
 * A test class for TripleDESKey
 * Copyright (c) 2007 Henri Torgemane
 * 
 * See LICENSE.txt for full license information.
 */

import chx.crypt.TripleDes;

class TripleDESKeyTest extends haxe.unit.TestCase
{
	public static function main() {
		#if FIREBUG
			if(haxe.Firebug.detect()) {
				haxe.Firebug.redirectTraces();
			}
		#end
		var r = new haxe.unit.TestRunner();
		r.add(new TripleDESKeyTest());
		r.run();
	}

	/**
	* Lots of vectors at http://csrc.nist.gov/publications/nistpubs/800-20/800-20.pdf
	* XXX move them in here.
	*/
	public function testECB():Void {
		var keys:Array<String> = [
		"010101010101010101010101010101010101010101010101",
		"dd24b3aafcc69278d650dad234956b01e371384619492ac4",
		];
		var pts:Array<String> = [
		"8000000000000000",
		"F36B21045A030303",
		];
		var cts:Array<String> = [
		"95F8A5E5DD31D900",
		"E823A43DEEA4D0A4",
		];

		for (i in 0...keys.length) {
			var key:Bytes = Bytes.ofHex(keys[i]);
			var pt:Bytes = Bytes.ofHex(pts[i]);
			var ede:TripleDes = new TripleDes(key);
			var enc:Bytes = ede.encryptBlock(pt);
			var out:String = enc.toHex().toUpperCase();
			assertEquals(cts[i], out);
			// now go back to plaintext
			var dec:Bytes = ede.decryptBlock(enc);
			out = dec.toHex().toUpperCase();
			assertEquals(pts[i], out);
		}
	}

}