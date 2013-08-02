import chx.formats.der.PEM;
import chx.crypt.RSA;
import chx.crypt.cert.X509Certificate;

class X509 extends haxe.unit.TestCase {
	static var cacert1 : X509Certificate = new X509Certificate(Certs.CaCertPem);
	static var verisign: X509Certificate = new X509Certificate(Certs.Verisign);
	static var thawte : X509Certificate = new X509Certificate(Certs.Thawte);
	static function main()
	{
#if (FIREBUG && !neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		//var x = new X509Certificate(Certs.Verisign);
		//var x = new X509Certificate(Certs.Thawte);

		//trace(cacert1.getCommonName());
		trace(cacert1.getNotAfter());
		//trace(cacert1.isSelfSigned());
		//trace(cacert1.getSubjectPrincipal());

		var r = new haxe.unit.TestRunner();
		r.add(new X509());
		r.run();
	}

	function testFingerprints() {
		assertEquals("10:d8:62:e0:35:cf:4e:ec:c3:11:67:30:fd:85:fe:5f:ab:b9:e5:69",
			cacert1.getFingerprint("sha1").toHex(":"));
		assertEquals("95:08:77:3f:9b:28:03:51:f5:cd:a6:1c:db:92:cb:da",
			cacert1.getFingerprint("md5").toHex(":"));
		assertEquals("44:63:c5:31:d7:cc:c1:00:67:94:61:2b:b6:56:d3:bf:82:57:84:6f",
			verisign.getFingerprint("sha1").toHex(":"));
		assertEquals("74:7b:82:03:43:f0:00:9e:6b:b3:ec:47:bf:85:a5:93",
			verisign.getFingerprint("md5").toHex(":"));
		assertEquals("d2:32:09:ad:23:d3:14:23:21:74:e4:0d:7f:9d:62:13:97:86:63:3a",
			thawte.getFingerprint("sha1").toHex(":"));
		assertEquals("67:cb:9d:c0:13:24:8a:82:9b:b2:17:1e:d1:1b:ec:d4",
			thawte.getFingerprint("md5").toHex(":"));
	}

	function testSigAlg() {
		assertEquals("1.2.840.113549.1.1.5",cacert1.getAlgorithmIdentifier());
		assertEquals("1.2.840.113549.1.1.5",thawte.getAlgorithmIdentifier());
		assertEquals("1.2.840.113549.1.1.2",verisign.getAlgorithmIdentifier());
	}

	function testEmails() {
		var a1 = cacert1.getEmails();
		assertEquals(1, a1.length);
		assertEquals("me@no.domain", a1[0]);
		assertEquals(0, verisign.getEmails().length);
		assertEquals(0,thawte.getEmails().length);
	}

	function testNotAfter() {
		assertEquals("2013-03-05 09:32:14", cacert1.getNotAfter().toString());
	}
}

class Certs {
	static public var CaKeyPem : String =
"-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAN6RwYF1nImZNwa9Koa7d3liuIeO+HArxmxEN3p4HUg4kbDeob1C
yVE0xePuDtt+PZlVtrTeKUJQP24YnETnCM8CAQMCQQCUYSuro72xEM9Z03GvJ6T7
lyWvtKWgHS7y2CT8UBOFec1k02OcND4DNgoTKciCCYEJW9IZSU+CArnbP7P3HNLL
AiEA9bUgbw2DXnw5Igpc69SbB+FasE/BhZxKr6rTATvRjkkCIQDn5IEdRXEN0CqU
vNJ2Q9T0KfFLPy6sYwF4+mYNFmo+VwIhAKPOFZ9eV5RS0MFcPfKNvK/rkcrf1lkS
3HUcjKt9Nl7bAiEAmphWE4Ogs+AcYyiMTtfjTXFLh390cuyrpfxECLmcKY8CIGC2
QYYTkMONd7WvxN1Y9qmXPJ3rkxY71Uya4AwunWwF
-----END RSA PRIVATE KEY-----";

	static public var CaCertPem : String =
"-----BEGIN CERTIFICATE-----
MIICyDCCAnKgAwIBAgIJANeNvhLQbUWCMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMRAwDgYDVQQHEwdNeSBDaXR5MRQw
EgYDVQQKEwtDYWZmZWluZS1oeDEQMA4GA1UEAxMHbWFpbC5tZTEbMBkGCSqGSIb3
DQEJARYMbWVAbm8uZG9tYWluMB4XDTA4MDMwNjA5MzIxNFoXDTEzMDMwNTA5MzIx
NFoweTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUxEDAOBgNVBAcT
B015IENpdHkxFDASBgNVBAoTC0NhZmZlaW5lLWh4MRAwDgYDVQQDEwdtYWlsLm1l
MRswGQYJKoZIhvcNAQkBFgxtZUBuby5kb21haW4wWjANBgkqhkiG9w0BAQEFAANJ
ADBGAkEA3pHBgXWciZk3Br0qhrt3eWK4h474cCvGbEQ3engdSDiRsN6hvULJUTTF
4+4O2349mVW2tN4pQlA/bhicROcIzwIBA6OB3jCB2zAdBgNVHQ4EFgQU1JjJ88zN
YA6AX/+GjFnpObsS8hQwgasGA1UdIwSBozCBoIAU1JjJ88zNYA6AX/+GjFnpObsS
8hShfaR7MHkxCzAJBgNVBAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMRAwDgYD
VQQHEwdNeSBDaXR5MRQwEgYDVQQKEwtDYWZmZWluZS1oeDEQMA4GA1UEAxMHbWFp
bC5tZTEbMBkGCSqGSIb3DQEJARYMbWVAbm8uZG9tYWluggkA142+EtBtRYIwDAYD
VR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAANBAI7qG3P+eQD02k8DeYoEVwr873/H
aHbLc8LZXAQgd5I9CD4lUHTxWrWC/UQg0M7bkShCd7p/j0+Bz09qRoAmXsc=
-----END CERTIFICATE-----";

	// MD2
	static public var Verisign : String =
            "-----BEGIN CERTIFICATE-----\n"+
            "MIICNDCCAaECEAKtZn5ORf5eV288mBle3cAwDQYJKoZIhvcNAQECBQAwXzELMAkG\n"+
            "A1UEBhMCVVMxIDAeBgNVBAoTF1JTQSBEYXRhIFNlY3VyaXR5LCBJbmMuMS4wLAYD\n"+
            "VQQLEyVTZWN1cmUgU2VydmVyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTk0\n"+
            "MTEwOTAwMDAwMFoXDTEwMDEwNzIzNTk1OVowXzELMAkGA1UEBhMCVVMxIDAeBgNV\n"+
            "BAoTF1JTQSBEYXRhIFNlY3VyaXR5LCBJbmMuMS4wLAYDVQQLEyVTZWN1cmUgU2Vy\n"+
            "dmVyIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIGbMA0GCSqGSIb3DQEBAQUAA4GJ\n"+
            "ADCBhQJ+AJLOesGugz5aqomDV6wlAXYMra6OLDfO6zV4ZFQD5YRAUcm/jwjiioII\n"+
            "0haGN1XpsSECrXZogZoFokvJSyVmIlZsiAeP94FZbYQHZXATcXY+m3dM41CJVphI\n"+
            "uR2nKRoTLkoRWZweFdVJVCxzOmmCsZc5nG1wZ0jl3S3WyB57AgMBAAEwDQYJKoZI\n"+
            "hvcNAQECBQADfgBl3X7hsuyw4jrg7HFGmhkRuNPHoLQDQCYCPgmc4RKz0Vr2N6W3\n"+
            "YQO2WxZpO8ZECAyIUwxrl0nHPjXcbLm7qt9cuzovk2C2qUtN8iD3zV9/ZHuO3ABc\n"+
            "1/p3yjkWWW8O6tO1g39NTUJWdrTJXwT4OPjr0l91X817/OWOgHz8UA==\n"+
            "-----END CERTIFICATE-----";

	// X500 Subject, for lookups.
	//"ME4xCzAJBgNVBAYTAlVTMRAwDgYDVQQKEwdFcXVpZmF4MS0wKwYDVQQLEyRFcXVpZmF4IFNlY3Vy"+
	//"ZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHk=",
	static public var Thawte : String =
			"-----BEGIN CERTIFICATE-----\n"+
			"MIIDIDCCAomgAwIBAgIENd70zzANBgkqhkiG9w0BAQUFADBOMQswCQYDVQQGEwJV\n"+
			"UzEQMA4GA1UEChMHRXF1aWZheDEtMCsGA1UECxMkRXF1aWZheCBTZWN1cmUgQ2Vy\n"+
			"dGlmaWNhdGUgQXV0aG9yaXR5MB4XDTk4MDgyMjE2NDE1MVoXDTE4MDgyMjE2NDE1\n"+
			"MVowTjELMAkGA1UEBhMCVVMxEDAOBgNVBAoTB0VxdWlmYXgxLTArBgNVBAsTJEVx\n"+
			"dWlmYXggU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eTCBnzANBgkqhkiG9w0B\n"+
			"AQEFAAOBjQAwgYkCgYEAwV2xWGcIYu6gmi0fCG2RFGiYCh7+2gRvE4RiIcPRfM6f\n"+
			"BeC4AfBONOziipUEZKzxa1NfBbPLZ4C/QgKO/t0BCezhABRP/PvwDN1Dulsr4R+A\n"+
			"cJkVV5MW8Q+XarfCaCMczE1ZMKxRHjuvK9buY0V7xdlfUNLjUA86iOe/FP3gx7kC\n"+
			"AwEAAaOCAQkwggEFMHAGA1UdHwRpMGcwZaBjoGGkXzBdMQswCQYDVQQGEwJVUzEQ\n"+
			"MA4GA1UEChMHRXF1aWZheDEtMCsGA1UECxMkRXF1aWZheCBTZWN1cmUgQ2VydGlm\n"+
			"aWNhdGUgQXV0aG9yaXR5MQ0wCwYDVQQDEwRDUkwxMBoGA1UdEAQTMBGBDzIwMTgw\n"+
			"ODIyMTY0MTUxWjALBgNVHQ8EBAMCAQYwHwYDVR0jBBgwFoAUSOZo+SvSspXXR9gj\n"+
			"IBBPM5iQn9QwHQYDVR0OBBYEFEjmaPkr0rKV10fYIyAQTzOYkJ/UMAwGA1UdEwQF\n"+
			"MAMBAf8wGgYJKoZIhvZ9B0EABA0wCxsFVjMuMGMDAgbAMA0GCSqGSIb3DQEBBQUA\n"+
			"A4GBAFjOKer89961zgK5F7WF0bnj4JXMJTENAKaSbn+2kmOeUJXRmm/kEd5jhW6Y\n"+
			"7qj/WsjTVbJmcVfewCHrPSqnI0kBBIZCe/zuf6IWUrVnZ9NA2zsmWLIodz2uFHdh\n"+
			"1voqZiegDfqnc1zqcPGUIWVEX/r87yloqaKHee9570+sB3c4\n"+
			"-----END CERTIFICATE-----";

}

