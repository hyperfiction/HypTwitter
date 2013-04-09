import java.lang.System;
import java.math.BigInteger;

class BiTest {

public static void main(String args[]) {
	String bufh = "1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff007768617420697320746865726520666f7220796f7520746f20646f3f0a";
	String nh = "00bdb119666ebeeb1ffb9c6a304b4fb3eb0561d937d497582ca355b7a307e011cd8188c44227a266b29494bc81ae8cf81893dba4cedd4a87e472f5fc2f93aaf107b898188af926bf20644f8d33cd54afa83f59c3eed8bd1632a9277e3329aeb460d8272b66f5c7740535411e66df536a29c0f6602e9a32f93b22a34aa7bc9cd2f7";
	String eh = "10001";
	String dh = "3766f339349d3444fa12dbfcd0f22d65360437121458439b7df4fa1676a55dedbca87a51ac0bc59ce0c27430180ffa220b853a246503709f2b6866c86a83a1b39371d3dbc8f9de9d3acab256d1cb1948a3422af77457fca29b509aa90f95b09f0f9017f2c6684c191d27f8e2ee7e50271575dd744f8abe57c26e69b87cde8341";

	BigInteger biBuf = new BigInteger(bufh, 16);
	BigInteger biExp = new BigInteger(eh, 16);
	BigInteger biMod = new BigInteger(nh, 16);

	BigInteger result = biBuf.modPow(biExp, biMod);
// 	System.out.println("modPow");
// 	System.out.println(result.toString(16));
// 	System.out.println("biBuf x biMod");
 	System.out.println(biBuf.multiply(biMod));
// 	System.out.println("biBuf % biMod");
 	System.out.println(biBuf.mod(biMod));
// 	System.out.println("biBuf square");
 	System.out.println(biBuf.multiply(biBuf));
// 	System.out.println("biBuf/biExp");
 	System.out.println(biBuf.divide(biExp));
}


}
