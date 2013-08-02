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

package chx.protocols.memedb;

/**
* Response codes from MemeDB transactions. Codes that are used are individually documented,
* the others are standard HTTP response codes as documented at
* http://java.sun.com/products/servlet/2.2/javadoc/javax/servlet/http/HttpServletResponse.html
*
*/
class ResponseCodes {

	public static inline var ACCEPTED : Int = 202;
	public static inline var BAD_GATEWAY : Int = 502;
	/** The query was badly formatted, script errors, invalid json objects **/
	public static inline var BAD_REQUEST : Int = 400;
	/** Document may not be saved due to revision conflict **/
	public static inline var CONFLICT : Int = 409;
	public static inline var CONTINUE : Int = 100;
	/** Document was successfully created **/
	public static inline var CREATED : Int = 201;
	public static inline var EXPECTATION_FAILED : Int = 417;
	public static inline var FORBIDDEN : Int = 403;
	public static inline var GATEWAY_TIMEOUT : Int = 504;
	public static inline var GONE : Int = 410;
	public static inline var HTTP_VERSION_NOT_SUPPORTED : Int = 505;
	/** Server has encountered an error **/
	public static inline var INTERNAL_SERVER_ERROR  : Int = 500;
	public static inline var LENGTH_REQUIRED  : Int = 411;
	public static inline var METHOD_NOT_ALLOWED : Int = 405;
	public static inline var MOVED_PERMANENTLY : Int = 301;
	public static inline var MOVED_TEMPORARILY : Int = 302;
	public static inline var MULTIPLE_CHOICES  : Int = 300;
	public static inline var NO_CONTENT : Int = 204;
	public static inline var NON_AUTHORITATIVE_INFORMATION : Int = 203;
	public static inline var NOT_ACCEPTABLE : Int = 406;
	/** Document, database or view not found **/
	public static inline var NOT_FOUND  : Int = 404;
	public static inline var NOT_IMPLEMENTED : Int = 501;
	public static inline var NOT_MODIFIED  : Int = 304;
	/** Last transaction completed successfully **/
	public static inline var OK : Int = 200;
	public static inline var PARTIAL_CONTENT : Int = 206;
	public static inline var PAYMENT_REQUIRED : Int = 402;
	public static inline var PRECONDITION_FAILED : Int = 412;
	public static inline var PROXY_AUTHENTICATION_REQUIRED : Int = 407;
	public static inline var REQUEST_ENTITY_TOO_LARGE : Int = 413;
	public static inline var REQUEST_TIMEOUT : Int = 408;
	public static inline var REQUEST_URI_TOO_LONG : Int = 414;
	public static inline var REQUESTED_RANGE_NOT_SATISFIABLE : Int = 416;
	public static inline var RESET_CONTENT : Int = 205;
	public static inline var SEE_OTHER : Int = 303;
	public static inline var SERVICE_UNAVAILABLE : Int = 503;
	public static inline var SWITCHING_PROTOCOLS : Int = 101;
	/** Credentials are not adequate for access to db or whatever last action was **/
	public static inline var UNAUTHORIZED : Int = 401;
	public static inline var UNSUPPORTED_MEDIA_TYPE : Int = 415;
	public static inline var USE_PROXY : Int = 305;

}