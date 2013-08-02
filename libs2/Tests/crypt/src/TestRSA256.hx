import chx.crypt.RSA;

/*
	Test of a 256 bit RSA key
*/
class TestRSA256 {
	public static function main() {
#if !neko
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var msg = "Hello";
		// a 256 bit key
		var dmp1 : String = "3";
		var dmq1 : String = "3";
		var coeff : String = "3e5323aa1e3c5ac2860f6b389d08d885";
		var d : String = "7911b7cc5b6501e30c69945bce1ffe3fe21e66ee5d4c6a77297904d2e1daeb23";
		var e : String = "3";
		var n : String = "b59a93b2891782d4929e5e89b52ffd61852704c3ee7b15643ffe53910d3bad19";
		var p : String = "f155e239a68fb5a0208e2abe6787d1d7";
		var q : String = "c0a38824bbf8c011613aa19652eb7a8f";
		var rsa = new RSA();
		rsa.setPrivateEx(n, e,d, p, q, null, null, coeff);
		trace(rsa);

		var e = rsa.encrypt(Bytes.ofString(msg));
		var u = rsa.decrypt(e).toString();
		if(msg != u)
			trace("failed");
		else
			trace("ok");

	}
}
