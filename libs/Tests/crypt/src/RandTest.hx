import math.prng.Random;
import math.prng.TLSPRF;

class RandTest extends haxe.unit.TestCase {
	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new RandTest());

		r.run();
	}

	function doTest(msg, rng:Random) {
		trace("==== Test " + msg + "====");
		for(x in 0...10)
			trace(rng.next());

		var bs = Bytes.alloc(256);
		rng.nextBytes(bs, 0, bs.length);

		trace(bs.toHex());
		trace("");
	}

	/*
	public function test01():Void {
		doTest("ArcFour", new Random());
		doTest("TLSPRF",
			new Random(
				new TLSPRF(
					Bytes.ofString("*(&$!@ekwrhjkq34*$@#&("),
					"slithy toves",
					Bytes.ofString("akljqewo zcwq3$(*@"))));
		assertTrue(true);
	}
	*/

	/**
	* Test Vector as defined in
	* http://www.imc.org/ietf-tls/mail-archive/msg01589.html
	*/
	public function testTLSPRF() {
		var secret:Bytes = Bytes.alloc(48);
		for (i in 0...48)
			secret.set(i, 0xab);

		var label:String = "PRF Testvector";
		var seed:Bytes = Bytes.alloc(64);
		for (i in 0...64)
			seed.set(i, 0xcd);

		var prf:TLSPRF = new TLSPRF(secret, label, seed);
		var out:Bytes = Bytes.alloc(104);
		prf.nextBytes(out, 0, 104);
		var expected:String = "D3 D4 D1 E3 49 B5 D5 15 04 46 66 D5 1D E3 2B AB" +
				" 25 8C B5 21 B6 B0 53 46 3E 35 48 32 FD 97 67 54" +
				" 44 3B CF 9A 29 65 19 BC 28 9A BC BC 11 87 E4 EB" +
				" D3 1E 60 23 53 77 6C 40 8A AF B7 4C BC 85 EF F6" +
				" 92 55 F9 78 8F AA 18 4C BB 95 7A 98 19 D8 4A 5D" +
				" 7E B0 06 EB 45 9D 3A E8 DE 98 10 45 4B 8B 2D 8F" +
				" 1A FB C6 55 A8 C9 A0 13";
		assertEquals(expected, out.toHex(" ").toUpperCase());
	}
}
