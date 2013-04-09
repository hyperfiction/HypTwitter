/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
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

/*
 * Derived from AS3 implementation Copyright (c) 2007 Henri Torgemane
 */
/**
 * X509CertificateCollection
 *
 * A class to store and index X509 Certificates by Subject. To create your
 * own certificate collection, you will need a PEM encoded certificate, along
 * with the Base64 encoded subject from X509Certificate.getSubjectPrincipal()
 */
package chx.crypt.cert;

class X509CertificateCollection {
	private var _map : Dynamic;

	public function new() {
		_map = {};
	}

	/**
		* Mostly meant for built-in CA loading.
		* This entry-point allows to index CAs without parsing them.
		*
		* @param name		A friendly name. not currently used
		* @param subject	base64 DER encoded Subject principal for the Cert
		* @param pem		PEM encoded certificate data
		*
		*/
	public function addPEMCertificate(name:String, subject:String, pem:String):Void {
		_map.subject = new X509Certificate(pem);
	}

	/**
		* Adds a X509 certificate to the collection.
		* This call will force the certificate to be parsed.
		*
		* @param cert		A X509 certificate
		*
		*/
	public function addCertificate(cert:X509Certificate):Void {
		var subject:String = cert.getSubjectPrincipal();
		_map.subject = cert;
	}

	/**
		* Returns a X509 Certificate present in the collection, given
		* a base64 DER encoded X500 Subject principal
		*
		* @param subject	A Base64 DER-encoded Subject principal
		* @return 			A matching certificate, or null.
		*
		*/
	public function getCertificate(subject:String):X509Certificate {
		return _map.subject;
	}
}
