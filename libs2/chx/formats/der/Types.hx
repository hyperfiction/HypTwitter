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
 * Type
 *
 * A few Asn-1 structures
 */
package chx.formats.der;

typedef AsnStruct = {
	var name : String;
	var optional : Bool;
	var extract : Bool; // if a binary copy needs to be kept
	var value : Dynamic;
	var defaultValue : Dynamic;
};

class Types
{
	public static var TLS_CERT:Array<AsnStruct> = [
		{
		name:"signedCertificate",
		optional:false,
		extract:true,
		defaultValue : null,
		value: [
			{
				name:"versionHolder",
				optional:true,
				value: [
				{name:"version"}
				],
				defaultValue: function():Sequence{
					var s:Sequence = new Sequence();
					var v:Integer = new Integer(Bytes.ofHex("00"));
					//s.push(v);
					s.set("version", v);
					return s;
				}()
			},
			{name:"serialNumber"},
			{name:"signature", value: [
				{name:"algorithmId"}
			]},
			{name:"issuer", extract:true, value: [
				{name:"type"},
				{name:"value"}
			]},
			{name:"validity", value: [
				{name:"notBefore"},
				{name:"notAfter"}
			]},
			{name:"subject", extract:true, value: [
			]},
			{name:"subjectPublicKeyInfo", value: [
				{name:"algorithm", value: [
					{name:"algorithmId"}
				]},
				{name:"subjectPublicKey"}
			]},
			{name:"extensions", value: [
			]}
			]
		},
		{
		name:"algorithmIdentifier",
		optional:false,
		extract : false,
		defaultValue : null,
		value: 	[
			{name:"algorithmId"}
			]
		},
		{
		name:"encrypted",
		optional:false,
		extract : false,
		defaultValue : null,
		value:null
		}
	];

	public static var CERTIFICATE:Array<AsnStruct> = [
		{
		name:"tbsCertificate",
		optional:false,
		extract : false,
		defaultValue : null,
		value:[
			{name:"tag0", value:[
				{name:"version"}
			]},
			{name:"serialNumber"},
			{name:"signature"},
			{name:"issuer", value:[
				{name:"type"},
				{name:"value"}
			]},
			{name:"validity", value:[
				{name:"notBefore"},
				{name:"notAfter"}
			]},
			{name:"subject"},
			{name:"subjectPublicKeyInfo", value:[
				{name:"algorithm"},
				{name:"subjectPublicKey"}
			]},
			{name:"issuerUniqueID"},
			{name:"subjectUniqueID"},
			{name:"extensions"}
		]},
		{
		name:"signatureAlgorithm",
		optional:false,
		extract : false,
		defaultValue : null,
		value : null
		},
		{
		name:"signatureValue",
		optional:false,
		extract : false,
		defaultValue : null,
		value : null
		}
	];

	public static var RSA_PUBLIC_KEY:Array<AsnStruct> = [
		{name:"modulus",optional:false,extract:false,defaultValue:null,value:null},
		{name:"publicExponent",optional:false,extract:false,defaultValue:null,value:null}
	];

	public static var RSA_SIGNATURE:Array<AsnStruct> = [
		{name:"algorithm",optional:false,extract:false,defaultValue:null,value:[
			{name:"algorithmId"}
		]},
		{name:"hash",optional:false,extract:false,defaultValue:null,value:null}
	];

}
