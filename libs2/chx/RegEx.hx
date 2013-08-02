/*
 * Copyright (c) 2009, Russell Weir
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

package chx;

private typedef MatchResult = {
	var ok : Bool;
	var position : Int;
	var length : Int;
	var orMark : Bool;
	var conditional : Bool;
	var extra : Int; // extra # of chars consumed (for $)
};

private typedef ExecResult = {
	var index:Int;
	var leftContext:String;
	var rightContext:String;
	var matches:IntHash<String>;
};

private typedef ExecState = {
	var restoring		: Bool;
	var startPos		: Int;
	var iRuleIdx		: Int;
	var iPos			: Int;
	var conditional		: Bool;
	var matches			: IntHash<String>;
	var index			: Int;
};

private typedef MatchState = {
	var matches : IntHash<String>;
	var index : Int;
	var parentState : MatchState;
}

private enum ERegMatch {
	BeginString; // \A which only matches start of input string
	BeginLine; // ^ which matches line beginnings in multiline mode
	MatchExact(s : String);
	MatchCharCode(c : Int);
	MatchAny;
	MatchAnyOf(ch : IntHash<Bool>);
	MatchNoneOf(ch : IntHash<Bool>);
	CharClass(rules: Array<ERegMatch>);
	MatchLineBreak;
	MatchWordBoundary;
	NotMatchWordBoundary;
	OrMarker;
	Repeat(r : ERegMatch, min:Int, max:Null<Int>, notGreedy: Bool, possessive:Bool);
	Capture(e : RegEx);
	BackRef(n : Int);
	RangeMarker;
	ModCaseInsensitive; // i (?i)
	ModMultiline; // m (?m)
	ModDotAll; // s  (?s)
	ModAllowWhite; // x
	ModCaseInsensitiveOff;
	ModMultilineOff;
	ModDotAllOff;
	ModAllowWhiteOff; // -x
	EndLine; // $ matches @ end of lines in multiline mode
	EndData; //\Z	Match only at end of string, or before newline at the end
	EndString; // \z Match only at end of string
}


private enum StackItem {
	RepeatFrame(id:Int, r : ERegMatch, state:ExecState, info:Dynamic);
	OrFrame(id : Int, state:ExecState);
	ChildFrame(frameId:Int, state:ExecState, e:RegEx, eState:ExecState);
}

// @todo
private enum ChildType {
	Normal;
	//BranchReset; // (?|pattern) not sure how to do this one yet

	// these should not create groups at all
	PatMatchModifier; // (?s) or (?-s) (?pimsx-imsx)

	// these ones create no capture in root.es.matches
	Comment; // (?#text)
	NoBackref; // (?:pattern) Matches without creating backref
	LookAhead; // (?=pattern) /\w+(?=\t)/ matches a word followed by a tab, without including the tab in $&
	NegLookAhead; //(?!pattern)
	LookBehind; // (?<=pattern) /(?<=\t)\w+/ matches a word that follows a tab, without including the tab in $&
	NegLookBehind; //(?<!pattern) /(?<!bar)foo/ matches any occurrence of "foo" that does not follow "bar". Works only for fixed-width look-behind.

	// require no special type
	//Named; # (?'NAME'pattern) # (?<NAME>pattern) A regular capture, just named. Just register in root
}



/**
	The following are not completed: [
	Perl 5.10
	\g1      Backreference to a specific or previous group,
	\g{-1}   number may be negative indicating a previous buffer and may
				optionally be wrapped in curly brackets for safer parsing.
	\g{name} Named backreference
	\k<name> Named backreference
	\K       Keep the stuff left of the \K, don't include it in $&
	\l		lowercase next char (think vi)
	\u		uppercase next char (think vi)
	\L		lowercase till \E (think vi)
	\U		uppercase till \E (think vi)
	\E		end case modification (think vi)
	\Q		quote (disable) pattern metacharacters till \E
	\N{name}	named Unicode character
	\cK		control char          (example: VT)
	\pP	     Match P, named property.  Use \p{Prop} for longer names.
	\PP	     Match non-P
	\X	     Match eXtended Unicode "combining character sequence",
				equivalent to (?:\PM\pM*)
	\C	     Match a single C char (octet) even under Unicode.
			NOTE: breaks up characters into their UTF-8 bytes,
			so you may end up with malformed pieces of UTF-8.
			Unsupported in lookbehind.
	]
	@todo \G Match only at pos() (e.g. at the end-of-match position of prior m//g)

**/
class RegEx #if !flash9 implements EReg #end {
	inline static var NULL_MATCH	: Int = -1;
	public static var chr : Int -> String = String.fromCharCode;
	static var alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	static var numeric = "0123456789";
	static var wordHash : IntHash<Bool>;

	inline static var BEL			= 0x07; // \a
	inline static var BS			= 0x08; // \b
	inline static var HT			= 0x09; // \t
	inline static var LF 			= 0x0A; // \n
	inline static var VT 			= 0x0B; // \v
	inline static var FF 			= 0x0C; // \f
	inline static var CR 			= 0x0D; // \r
	inline static var ESC			= 0x1B; // ESC
	inline static var SPACE			= 0x20; // " "
	inline static var DEL			= 0x7F;
	inline static var NEL			= 0x85; //
	inline static var NBSP			= 0xa0; // NBSP

	#if SUPPORT_UTF8
	inline static var UTF_OSM		= 0x1680; /* OGHAM SPACE MARK */
	inline static var UTF_MVS		= 0x180e; /* MONGOLIAN VOWEL SEPARATOR */
	inline static var UTF_ENQUAD	= 0x2000; /* EN QUAD */
	inline static var UTF_EMQUAD	= 0x2001; /* EM QUAD */
	inline static var UTF_ENSPACE	= 0x2002; /* EN SPACE */
	inline static var UTF_EMSPACE	= 0x2003; /* EM SPACE */
	inline static var UTF_3PSPACE	= 0x2004; /* THREE-PER-EM SPACE */
	inline static var UTF_4PSPACE	= 0x2005; /* FOUR-PER-EM SPACE */
	inline static var UTF_6PSPACE	= 0x2006: /* SIX-PER-EM SPACE */
	inline static var UTF_FSPACE	= 0x2007: /* FIGURE SPACE */
	inline static var UTF_PSPACE	= 0x2008: /* PUNCTUATION SPACE */
	inline static var UTF_TSPACE	= 0x2009: /* THIN SPACE */
	inline static var UTF_HSPACE	= 0x200A: /* HAIR SPACE */
	inline static var UTF_LS		= 0x2028; // LINE SEPARATOR
	inline static var UTF_PS		= 0x2029; // PARAGRAPH SEPARATOR
	inline static var UTF_NNBSPACE	= 0x202f: /* NARROW NO-BREAK SPACE */
	inline static var UTF_MMSPACE	= 0x205f: /* MEDIUM MATHEMATICAL SPACE */
	inline static var UTF_ISPACE	= 0x3000: /* IDEOGRAPHIC SPACE */
	#end


	static var sBEL			= String.fromCharCode(0x07);
	static var sBS			= String.fromCharCode(0x08);
	static var sHT			= "\t";
	static var sLF			= "\n";
	static var sVT			= String.fromCharCode(0x0B);
	static var sFF			= String.fromCharCode(0x0C);
	static var sCR 			= "\r";
	static var sSPACE		= " ";
	static var sNEL			= String.fromCharCode(0x85);

	var type	: ChildType;
	var pattern : String;
	var options : String;
	// options //
	var ignoreCase : Bool;
	var multiline : Bool;
	var dotall : Bool;
	var global : Bool;
	var allowWhite : Bool;
	var noBacktrack : Bool;

	///////////// for Grouping ///////////////////////
	var root(default, null)		: RegEx;
	var parent(default, null)	: RegEx;
	var depth					: Int;
	var namedGroups				: Hash<RegEx>;
	var _groupCount 			: Int; // a 'static' accessed by sub groups
	var _frameIdx				: Int; // a 'static' Frame index number
	var children				: Array<RegEx>;

	///////////// parser vars ////////////////////////
	var groupNumber : Int; // (()) () group number
	var instanceRules : Array<ERegMatch>;
	var parsedPattern : String; // the piece that was extracted from pattern

	var capturesOpened : Int; // count each (
	var capturesClosed : Int; // count each )
	var pass : Int; // (?x) PatMatchModifier requires reparse of rule

	///////////// populate for match() ///////////////
	var input : String; // input string
	var lastIndex: Int;
	var leftContext : String;
	var rightContext : String;

	///////////// backtracking ///////////////////////
	var stack : Array<StackItem>;
	var es : ExecState;

	//////// implements EReg  not used ///////////////
	var r : Dynamic;
	#if flash9
	var result : {> Array<String>, index : Int, input : String };
	#elseif flash
	var index	: Null<Int>;
	var result	: Array<String>;
	var useChxRegEx : Bool;
	var chxRegEx : chx.RegEx;
	var chxRegExOk : Bool;
	#end
	#if (neko || cpp || php)
	var last : String;
	#end
	#if php
	var pattern : String;
	var options : String;
	var re : String;
	var matches : ArrayAccess<Dynamic>;
	#end

	public function new(pattern : String, opt : String, ?parent : RegEx = null) {
		this.type = Normal;
		this.pattern = pattern;
		this.options = opt.toLowerCase();
		this.ignoreCase = (options.indexOf("i") >= 0);
		this.multiline = (options.indexOf("m") >= 0);
		this.dotall = (options.indexOf("s") >= 0);
		this.allowWhite =  (options.indexOf("x") >= 0);
		this.noBacktrack = false;
		this.global = (options.indexOf("g") >= 0);
		this.lastIndex = 0;
		this.children = new Array();
		this.stack = new Array();
		if(parent == null) {
			_groupCount = 0;
			_frameIdx = 0;
			this.root = this;
			this.parent = this;
			this.groupNumber = 0;
			this.capturesOpened = 0;
			this.capturesClosed = 0;
			this.depth = 0;
			this.namedGroups = new Hash();
		} else {
// 			As RegEx instances are created for each group, the
// 			'global static' _groupCount is incremented and the new
// 			instance gets assigned the groupNumber.
			this.root = parent.root;
			this.parent = parent;
			this.groupNumber = ++this.root._groupCount;
			this.depth = parent.depth + 1;
			parent.children.push(this);
		}
		pass = 1;
		var ogn = groupNumber;
		var oco = root.capturesOpened;
		var occ = root.capturesClosed;
		var rv = parse(pattern, 0, false);
		// whitespaced patterns will need reparsing, according to Perl.
		// not so according to common sense and PCRE
		if(rv.reparse) {
			#if DEBUG_PARSER trace("REPARSING " + traceName()); #end
			pass = 2;
			root.capturesOpened = oco;
			root.capturesClosed = occ;
			groupNumber = ogn;
			if(groupNumber < 0)
				groupNumber = 9999;
			children = new Array();
			rv = parse(pattern, 0, false);
		}
		this.instanceRules = rv.rules;

		this.parsedPattern = pattern.substr(0, rv.bytes);
		if(isRoot()) {
			if(pattern.length != rv.bytes)
				throw "RegEx::new : Unexpected characters at position " + rv.bytes;
			if(capturesOpened > capturesClosed)
				throw "Unclosed capture. " + " opened: " + capturesOpened + " closed: " + capturesClosed;
			if(capturesOpened < capturesClosed)
				throw "Unexpected capture closing. " + " opened: " + capturesOpened + " closed: " + capturesClosed;
			#if DEBUG_PARSER
			trace ("Top level consumed pattern " + parsedPattern);
			#end
		}
		switch(type) {
		// look behinds are passed the substring to current position.
		case LookBehind, NegLookBehind:
			instanceRules.push(EndLine);
		default:
		}
	}

	/**
		@todo: Test
	**/
	public function customReplace( s : String, f : EReg -> String ) : String {
		var res = new StringBuf();
		var g = global;
		global = false;
		while(s.length > 0) {
			if(!match(s)) {
				res.add(s);
				break;
			}
			res.add(leftContext);
			res.add(f(cast this));
			s = rightContext;
			if(!global) {
				res.add(rightContext);
				break;
			}
		}
		global = g;
		return res.toString();
	}

	public function match( s : String ) : Bool {
		var res = null;
		for(i in 0...s.length + 1) {
			res = exec(s,null,i);
			if(res != null) {
				lastIndex = i;
				break;
			}
		}
		return (res != null);
	}

	/**
		Returns a matched group or throw an expection if there
		is no such group. If [n = 0], the whole matched substring
		is returned.
	**/
	public function matched( n : Int) : String {
		if(
			n > root.capturesOpened ||
			(n == 0 && root.es.conditional))
				throw "EReg::matched "+ n;
		return es.matches.get(n);
	}

	/**
		Returns the part of the string that was as the left of
		of the matched substring.
	**/
	public function matchedLeft() : String {
		return leftContext;
	}

	/**
		Returns the part of the string that was at the right of
		of the matched substring.
	**/
	public function matchedRight() : String {
		return rightContext;
	}

	/**
		Returns the position of the matched substring within the
		original matched string.
	**/
	public function matchedPos() : { pos : Int, len : Int } {
		return {
			pos : es.index,
			len : es.matches.get(0).length,
		};
	}

	/**
		@todo: Test
	**/
	public function replace(s : String, by : String) {
		return split(s).join(by);
	}

	/**
		@todo Test
	**/
	public function split(s : String) : Array<String> {
		var results = new Array<String>();
		var g = global;
		global = false;
		while(s.length > 0) {
			if(!match(s)) {
				results.push(s);
				break;
			}
			results.push(leftContext);
			if(!global) {
				results.push(rightContext);
				break;
			}
			s = rightContext;
			if(s == "") {
				results.push("");
				break;
			}
		}
		global = g;
		return results;
	}



	//-------------------- implementation -------------------------//
	function isRoot() : Bool {
		return this.root == this;
	}

	/**
		Executes the regular expression on string s.
		@return null if no match
	**/
	function exec( s : String, ?lastExecState : ExecState, ?startPos:Null<Int>=null) : ExecResult
	{
		if(s == null)
			return null;
		var me = this;
		this.input = s;

		if(lastExecState == null) {
			initExecState(startPos);
		} else {
			es = lastExecState;
			es.restoring = true; // just to be sure
			es.iRuleIdx--;
			root.es.matches.remove(groupNumber);
			// no reset of match state, since it should exist.
		}

		var bestMatchState = saveMatchState();
		var mr : MatchResult = null;

		var updatePosition = function(mr : MatchResult) {
			if(me.es.index < 0)
				me.es.index = mr.position;
			me.es.iPos = mr.position + mr.length;
			me.es.matches.set(0, me.input.substr(me.es.index, me.es.iPos - me.es.index));
			me.es.iPos += mr.extra;
			me.es.conditional = me.es.conditional && mr.conditional;
		}

		/*
			Conditional matches are those that have 0 length possibilities.
			ie. "black" ~= |e*| 'matches conditionally' on 0 e's, since
			"black" ~= |e*lack| has to match
		*/

		var popStack = false;
		while(popStack || (++es.iRuleIdx < instanceRules.length && es.iPos <= input.length)) {
			popStack = false;
			if(!es.restoring) {
				#if DEBUG_MATCH
					trace(traceName() + " --- start rule #" + es.iRuleIdx + " " + ruleToString(instanceRules[es.iRuleIdx]));
					trace(traceName() + " Current index: " + es.index);
					trace(traceName() + " Current pos: "+es.iPos);
				#end
				mr = testRule(es.iPos, instanceRules[es.iRuleIdx]);
				#if DEBUG_MATCH trace(traceName() + " Result: " + mr);	#end
			} else {
				mr == null;
				es.restoring = false;
				var cr : StackItem = popFrame();
				if(cr == null) {
					#if DEBUG_MATCH
					trace(traceName() + " no more items in stack");
					#end
					break;
				}
				#if DEBUG_MATCH trace(traceName() + " Restoring at rule #"+es.iRuleIdx + " " + stackItemToString(cr));
				root.traceFrames();
				#end

				switch(cr) {
				case RepeatFrame(_, rule, state, info):
					restoreExecState(state);
					//mr = run(es.iPos, instanceRules[es.iRuleIdx], info);
					mr = testRule(es.iPos, rule, info);
				case OrFrame(_, state):
					restoreExecState(state);
					resetMatchState();
					mr = testRule(es.iPos, instanceRules[es.iRuleIdx]);
				case ChildFrame(id, state, er, eState):
					restoreExecState(state);
					eState.iPos = es.iPos;
					#if DEBUG_MATCH_V
					trace(" +++++ "+traceName() + " Popped child frame " + id + " Rewound to pos:" + es.iPos + " rule #" + es.iRuleIdx);
					#end
					var res = er.exec(input, eState);
					//trace(res);
					if(res == null) {
						mr = {
							ok : false,
							position : er.es.index,
							length : 0,
							orMark : false,
							conditional : false,
							extra : 0,
						}
					}
					else {
						var len =
							if(root.es.matches.get(er.groupNumber) != null)
								root.es.matches.get(er.groupNumber).length
							else
								0;
						es.conditional = es.conditional && er.es.conditional;
						mr = {
							ok : true,
							position : er.es.index,
							length : len,
							orMark : false,
							conditional : er.es.conditional,
							extra : 0,
						}
						#if DEBUG_MATCH
							trace("CHILD FRAME " + er.groupNumber + " MATCHED.");
						#end
					}
				}
			}

			// everything has matched to this point,
			if(mr.orMark) {
				if(isRoot() && es.conditional) {
					#if DEBUG_MATCH
					trace("Root has reached an OrMarker, but has only conditional match. Continuing.");
					#end
					continue;
				}
				var id = root._frameIdx++;
				var st = copyExecState(es);
				st.iPos = es.startPos;
				st.restoring = true;
				st.iRuleIdx++; // skip the OrMarker
				stack.push(OrFrame(id, st));
				if(!isRoot())
					parent.addChildFrame(id, this, st);
				#if DEBUG_MATCH_V
				chx.Lib.println("pushOrFrame dump:");
				root.traceFrames();
				#end
				break;
			}

			if(isValidMatch(es.iPos, mr)) {
				updatePosition(mr);
				continue;
			}
			var found = false;

			if(stack.length > 0) {
				#if DEBUG_MATCH
				trace(traceName() + " +++++++++++++++++++++ Match not found. Stack: ");
				root.traceFrames();
				#end
				es.restoring = true;
				popStack = true;
				continue;
			}

			es.conditional = false;
			// try to find the next OrMarker
			while(++es.iRuleIdx < instanceRules.length) {
				if(instanceRules[es.iRuleIdx] != OrMarker)
					continue;
				// if an end OrMarker
// 					if(es.iRuleIdx == instanceRules.length - 1) {
// 						es.conditional = true;
// 					} else {
					found = true;
// 					}
				break;
			}
			if(found) {
				#if DEBUG_MATCH
				trace(traceName() + " +++++++++++++++++++++ Match not found. Skipped to next OrMarker");
				#end
				if(es.iRuleIdx == instanceRules.length -1) {
					//empty or
					mr = {
						ok : true,
						position : es.iPos,
						length : 0,
						orMark : false,
						conditional : false,
						extra : 0,
					};
					es.matches.set(0, "");
					es.index = es.iPos;
					es.conditional = false;
					root.es.matches.set(groupNumber, "");
					break;
				} else {
					resetMatchState();
					es.iPos = es.startPos;
					continue;
				}
			}
			#if DEBUG_MATCH
			trace(traceName() + " +++++++++++++++++++++ Match not found. No remaining OrMarker");
			trace(es);
			#end
		} // while(++es.iRuleIdx < instanceRules.length && es.iPos <= input.length)

		if(instanceRules.length == 0) {
			//empty rule set
			mr = {
				ok : true,
				position : es.iPos,
				length : 0,
				orMark : false,
				conditional : !isRoot(),
				extra : 0,
			};
			es.matches.set(0, "");
			es.index = es.iPos;
			es.conditional = false;
			root.es.matches.set(groupNumber, "");
		}


		if(mr != null && mr.ok && es.index >= 0) {
			if(		bestMatchState.index < 0 ||
					es.matches.get(0).length >= bestMatchState.matches.get(0).length ||
					es.conditional == false
			) {
				bestMatchState = saveMatchState();
				#if DEBUG_MATCH
					trace(traceName() + " UPDATE BEST MATCH TO " + es.matches.get(0));
				#end
			}
		}

		restoreMatchState(bestMatchState);
		#if DEBUG_MATCH
			trace(traceName() + " Final index: " + es.index + " length: " +  (es.iPos - es.index) + " conditional: " + es.conditional);
		#end
		if(es.index < 0 || es.matches.get(0) == null || (es.matches.get(0).length == 0 && es.conditional)) {
			lastIndex = 0;
			root.es.matches.remove(this.groupNumber);
			es.matches = new IntHash();
			return null;
		}

		var len =  es.matches.get(0).length;
		lastIndex = es.index;
		// makes sure that the match in 0 is of the original string
		// not the potentially modified 'input'
		es.matches.set(0, input.substr(es.index, len));
		root.es.matches.set(groupNumber, es.matches.get(0));

		leftContext = input.substr(0, es.index);
		rightContext = input.substr(es.index + len);

		var ra = new IntHash<String>();
		for(i in es.matches.keys())
			ra.set(i, new String(es.matches.get(i)));
		return {
			index: es.index,
			leftContext: new String(this.leftContext),
			rightContext: new String(this.rightContext),
			matches: ra,
		}
	}

	function isValidMatch(pos : Int, mr : MatchResult) {
		if(mr == null || !mr.ok)
			return false;
		if(pos == mr.position)
			return true;
		if(global) {
			if(es.index < 0)
				return true;
		}
		return false;
	}


	function saveMatchState() : MatchState {
		var sm = new IntHash<String>();
		for(i in es.matches.keys())
			sm.set(i, new String(es.matches.get(i)));
		var pms = parent != this ? parent.saveMatchState() : null;

		return {
			matches : sm,
			index : es.index,
			parentState : pms,
		}
	}

	function restoreMatchState(state : MatchState) : Void {
		es.matches = state.matches;
		es.index = state.index;
		if(state.parentState != null)
			parent.restoreMatchState(state.parentState);
	}

	function resetMatchState() {
		if(es == null)
			initExecState(null);
		es.matches = new IntHash();
		es.index = -1;
// 		#if DEBUG_MATCH
// 		trace("resetMatchState killing stack... TODO?");
// 		#end
// 		stack = new Array();
		for(c in children)
			c.resetMatchState();
	}

	/**
		@todo check noBacktrack inheritance ie. (?>) group types
	**/
	function initExecState(pos:Null<Int>) {
		var p = pos == null ? (global ? lastIndex : 0) : pos;
		es = {
			restoring	: false,
			startPos 	: p,
			iRuleIdx 	: -1,
			iPos		: p,
			conditional : true,
			matches		: new IntHash(),
			index		: -1,
		}
		root.es.matches.remove(this.groupNumber);
		ignoreCase = parent.ignoreCase;
		multiline = parent.multiline;
		dotall = parent.dotall;
		//global does not inherit
		//what about noBacktrack?
		for(c in children)
			c.initExecState(pos);
	}

	static function copyExecState(v : ExecState) : ExecState {
		if(v == null) throw "internal error " + here.lineNumber;
		var mcopy = new IntHash();
		for(i in v.matches.keys())
			mcopy.set(i, new String(v.matches.get(i)));
		return {
			restoring	: v.restoring,
			startPos 	: v.startPos,
			iRuleIdx 	: v.iRuleIdx,
			iPos		: v.iPos,
			conditional : v.conditional,
			matches		: mcopy,
			index		: v.index,
		}
	}

	function restoreExecState(v : ExecState) : Void {
		es = copyExecState(v);
		es.restoring = false;
	}

	/**
	**/
	function testRule(pos:Int, rule:ERegMatch, ?info:Dynamic) : MatchResult {
		if(rule == null) {
			#if (DEBUG_PARSER || DEBUG_MATCH)
				trace(this.toString());
			#end
			throw "internal error " + here.lineNumber;
		}
		#if DEBUG_MATCH
		trace(">>> " + traceName() +" "+ here.methodName + " " + ruleToString(rule) + " group: "+groupNumber+" pos: " + pos);
		#end
		var me = this;
		var origPos = pos;
		var orMark = false;
		var conditional = false;
		var extra = 0;

		var MATCH = function(count : Int) {
			var len : Int = (count == NULL_MATCH ? 0 : pos - origPos);
			return {
				ok			: true,
				position	: origPos,
				length		: len,
				orMark		: orMark,
				conditional : conditional,
				extra		: extra,
			}
		}
		var NOMATCH = function() {
			return {
				ok			: false,
				position	: origPos,
				length		: 0,
				orMark		: orMark,
				conditional : false,
				extra		: extra,
			}
		}

		switch(rule) {
		case BeginString:
			if(pos != 0)
				return NOMATCH();
		case BeginLine:
			if(multiline) {
				if(pos != 0) {
					switch(input.charCodeAt(pos - 1)) {
					case LF,CR,NEL:
					#if SUPPORT_UTF8
					case UTF_LS,UTF_PS:
					#end
					default:
						return NOMATCH();
					}
				}
			}
			else if(pos != 0)
				return NOMATCH();
		case EndLine:
			if(pos < input.length) {
				if(multiline) {
					if(input.charAt(pos) == "\r" && input.charAt(pos+1) == "\n") {
						extra = 2;
					} else if(input.charAt(pos) == "\n") {
						extra = 1;
					} else {
						return NOMATCH();
					}
				} else {
					return NOMATCH();
				}
			}
		case EndData: // \Z
			if(pos < input.length) {
				var mr = testRule(pos, MatchLineBreak);
				if(!mr.ok)
					return NOMATCH();
				if(pos + mr.length + mr.extra < input.length)
					return NOMATCH();
			}
		case EndString: // \z
			if(pos < input.length)
				return NOMATCH();
		case MatchLineBreak: // \R
			// (?>\x0D?\x0A|[\x0A-\x0C\x85\x{2028}\x{2029}])
			if(input.charAt(pos) == "\r" && input.charAt(pos+1) == "\n") {
				pos += 2;
			} else {
				switch(input.charCodeAt(pos)) {
// 				case LF,CR,NEL: // PCRE version
				case LF,VT,FF,NEL: // Perl version
				#if SUPPORT_UTF8
				case UTF_LS,UTF_PS:
				#end
				default:
					return NOMATCH();
				}
				pos++;
			}
		case MatchExact(s):
			if(s == null) {
				if(pos < input.length)
					conditional = true;
			} else {
				if(ignoreCase) {
					if(pos>=input.length || input.substr(pos, s.length).toLowerCase() != s.toLowerCase())
						return NOMATCH();
				}
				else if(pos>=input.length || input.substr(pos, s.length) != s)
					return NOMATCH();
				pos += s.length;
			}
		case MatchCharCode(cc):
			if(pos>=input.length)
				return NOMATCH();
			var cur = input.charCodeAt(pos);
			if(ignoreCase) {
				cc = lowerCaseCode(cc);
				cur = lowerCaseCode(cur);
			}
			if(cur != cc)
				return NOMATCH();
			pos++;
		case MatchAny:
			if(pos>=input.length || (input.substr(pos, 1) == "\n" && !dotall))
				return NOMATCH();
			pos++;
		case MatchAnyOf(ch):
			if(pos>=input.length)
				return NOMATCH();
			var cur = input.charCodeAt(pos);
			if(!ch.exists(cur)) {
				if(ignoreCase) {
					if(!ch.exists(changeCodeCase(cur)))
						return NOMATCH();
				} else {
					return NOMATCH();
				}
			}
			pos++;
		case MatchNoneOf(ch):
			if(pos>=input.length)
				return NOMATCH();
			var cur = input.charCodeAt(pos);
			if(
				cur == null ||
				ch.exists(cur) ||
				(ignoreCase && ch.exists(changeCodeCase(cur)))
			)
				return NOMATCH();
			pos++;
		case CharClass(rules):
			for(r in rules) {
				var rv = testRule(pos, r, null);
				if(!rv.ok)
					return NOMATCH();
			}
			pos++;
		case MatchWordBoundary:
			/*	A word boundary (\b ) is a spot between two characters that has a \w  on one side of it and a \W  on the other side of it (in either order), counting the imaginary characters off the beginning and end of the string as matching a \W */
			var prevIsWord = pos == 0 ? false : isWord(input.charCodeAt(pos-1));
			var curIsWord = pos >= input.length ? false : isWord(input.charCodeAt(pos));
			if(prevIsWord == curIsWord)
				return NOMATCH();
		case NotMatchWordBoundary:
			var prevIsWord = pos == 0 ? false : isWord(input.charCodeAt(pos-1));
			var curIsWord = pos >= input.length ? false : isWord(input.charCodeAt(pos));
			if(prevIsWord != curIsWord)
				return NOMATCH();
		case OrMarker:
			orMark = true;
		case Repeat(e, minCount, maxCount, notGreedy, possessive):
			if(info == null) {
				info = {
				pos : pos,
				origPos : origPos,
				matchState : saveMatchState(),
				lastCount : 0,
				min : minCount,
				max : maxCount,
				};
			} else {
				restoreMatchState(info.matchState);
			}
			pos = info.pos;
			origPos = info.origPos;
			var framePos = pos;
			var ok = false;
			var origStackLen = stack.length;
			var min = info.min;
			var max : Null<Int> = info.max;

			var cgroup : Int = 0;
			var isCapture = switch(e)
			{
				case Capture(er): cgroup=er.groupNumber; true;
				default: false;
			}
			var lastCaptureResult = root.es.matches.get(cgroup);

			var count = 0;
			var mr : MatchResult = null;
			while(pos < input.length && (max == null || count < max)) {
				if(notGreedy && count >= min)
					break;
				mr = testRule(pos, e);
				if(mr == null || !mr.ok || pos != mr.position) {
					if(isCapture) // rewind capture last match
						root.es.matches.set(cgroup, lastCaptureResult);
					break;
				}
				if(isCapture)
					lastCaptureResult = root.es.matches.get(cgroup);
				pos += mr.length + mr.extra;
				count++;
			}
			// mr can be null when notGreedy and zero minimum count

			#if DEBUG_MATCH
			trace(traceName() + " end repeat. Count is " + count + " for rule " + ruleToString(rule));
			#end
			info.lastCount = count;
			if(count < min) {
				rewindStackLength(origStackLen);
				return NOMATCH();
			}

			var push = false;
			if(count == 0 && !notGreedy && minCount != 0)
				conditional = true;
			if(notGreedy) {
				info.min = count + 1;
				if(info.max == null || info.min <= info.max)
					push = true;
			} else {
				info.max = count - 1;
				if(info.min <= info.max)
					push = true;
			}
			if(push && !noBacktrack) {
				#if DEBUG_MATCH
					//trace("******** "+rule+" NOT FINAL. PUSHING " + info);
				#end
				pushRepeatFrame(Repeat(e, info.min, info.max, notGreedy, possessive), framePos, info);
			}
		case Capture(er):
			#if DEBUG_MATCH
				trace(traceName() + " RUNNING CAPTURE "+ er.groupNumber+" at pos: " + pos + " char: " + input.charAt(pos));
			#end
			er.initExecState(pos);
			er.clearStack();
			er.lastIndex = pos;
			er.global = true;

			var ok = false;
			var epos = pos;
			var len = 0;
			var econd = false;
			var eextra = 0;
			switch(er.type) {
			case Normal,NoBackref:
				var res = er.exec(input, null, pos);
				ok = res != null;
				if(ok) {
					#if debug
						if(res.index != er.es.index)
							throw "internal error " + here.lineNumber;
						if(res.matches.get(0) != er.es.matches.get(0))
							throw "internal error " + here.lineNumber;
					#end
					epos = res.index;
					len =  res.matches.exists(0) ? res.matches.get(0).length : 0;
					econd = er.es.conditional;
				}
			case PatMatchModifier:
				throw "internal error " + here.lineNumber;
			case Comment:
				ok = true;
			case LookAhead, NegLookAhead:
				var res = er.exec(input, null, pos);
				ok = res != null;
				if(er.type == NegLookAhead)
					ok = !ok;
				econd = er.es.conditional;
				len = 0;
			case LookBehind, NegLookBehind:
				er.lastIndex = 0;
				#if DEBUG_MATCH_V
				trace("Running " + er.type + " with " + input.substr(0,pos));
				#end
				var res = er.exec(input.substr(0,pos), null, 0);
				ok = res != null;
				if(er.type == NegLookBehind)
					ok = !ok;
				econd = er.es.conditional;
				len = 0;
				eextra = 0;
			}

			var mr = {
				ok : ok,
				position : epos,
				length : len,
				orMark : false,
				conditional : econd,
				extra : eextra,
			};

			if(!mr.ok && !mr.conditional) {
				#if DEBUG_MATCH trace(traceName() + " CAPTURE FAILED"); #end
				return NOMATCH();
			}
			conditional = conditional && er.es.conditional;

			if(!isValidMatch(pos, mr))
				return NOMATCH();

			origPos = mr.position;
			pos = origPos + mr.length;
			#if DEBUG_MATCH
				trace(traceName() + " CAPTURE " + er.groupNumber +" MATCHED new pos:" + pos);
			#end
		case BackRef(n):
			if(root.capturesOpened < n)
				throw "Internal error";
			var mr = testRule(pos, MatchExact(root.es.matches.get(n)));
			if(!mr.ok)
				return NOMATCH();
			pos += mr.length;
			extra = mr.extra;
		case RangeMarker: throw "Internal error";

		case ModCaseInsensitive: ignoreCase = true;
		case ModMultiline: multiline = true;
		case ModDotAll: dotall = true;
		case ModCaseInsensitiveOff: ignoreCase = false;
		case ModMultilineOff: multiline = false;
		case ModDotAllOff: dotall = false;
		case ModAllowWhite, ModAllowWhiteOff: // no effect in matching
		}
		return MATCH(1);
	}

	#if (DEBUG_PARSER || DEBUG_MATCH)
	function traceName() {
		return (groupNumber == 0 ? "root" : groupNumber > 0 ? "capture " + Std.string(groupNumber) : Std.string(type));
	}
	#end

	function parse(inPattern: String, pos : Int, ? inClass : Bool = false) : { bytes: Int, rules : Array<ERegMatch>, reparse : Bool } {
		var me = this;
		var startPos = pos;
		var orLevel = 0;
		#if DEBUG_PARSER
			trace("START PARSE "+ traceName() +" pos: " + pos + (inClass ? " in CLASS" : ""));
		#end

		var curchar : Null<Int> = null;
		var parsedRules : Array<ERegMatch> = new Array();
		var expectRangeEnd = false;
		var patternLen = inPattern.length;
		var atEndMarker : Bool = false;

		var msg = function(k : String, s : String, ?p : Null<Int>=null) : String {
			if(p == null)
				p = pos;
			return k+" "+s+" at position " + Std.string(p);
		}
		var expected = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Expected", s, p);
		}
		var unexpected = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Unexpected", s, p);
		}
		var invalid = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Invalid", s, p);
		}
		var unhandled = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Unhandled (contact developer):", s, p);
		}
		var error = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Parse error:", s, p);
		}
		var backrefNotDefined = function(n:Dynamic, ?p : Null<Int> = null) : String {
			return msg("Backreference " + Std.string(n), "is not a defined group yet", p);
		}
		var peek = function() : Null<Int> {
			return inPattern.charCodeAt(pos+1);
		}
		var tok = function() : Null<Int> {
			return curchar = inPattern.charCodeAt(++pos);
		}
		var untok = function() : Null<Int> {
			return curchar = inPattern.charCodeAt(--pos);
		}
		var consumeAlNum = function(allowUnderscore : Bool, reqAlphaStart:Bool) : String {
			curchar = tok();
			if(reqAlphaStart && !isAlpha(curchar))
				throw invalid("string must begin with alpha character");
			var s = new StringBuf();
			s.addChar(curchar);
			curchar = tok();
			while(pos < inPattern.length && (isAlNum(curchar) || curchar == "_".code) ) {
				s.addChar(curchar);
				curchar = tok();
			}
			curchar = untok();
			return s.toString();
		}
		var consumeNumeric = function(?max:Int=-1) : String {
			var s = new StringBuf();
			var count = 0;
			curchar = tok();
			while(pos < inPattern.length &&
					isNumeric(curchar) &&
					(max < 0 || count++ <= max))
			{
				s.addChar(curchar);
				curchar = tok();
			}
			curchar = untok();
			return s.toString();
		}
		var assert = function(v : Bool, ?msg : String = "") {
			#if debug
			if(!v)
				throw error("Assertion "+msg+(msg.length > 0 ? " ":"") + "failed");
			#end
		}
		var assertCallback = function(f : Void -> Bool, ?msg : String = "") {
			#if debug
			var res : Bool = f();
			if(!res) {
				throw error("Assertion "+msg+(msg.length > 0 ? " ":"") + "failed");
			}
			#end
		}
		var isValidBackreference = function(n : Int) {
			return n <= me.root._groupCount;
		}
		var hasQuantifier = function() {
			var nextChar = peek();
			if(!inClass && (nextChar == "*".code || nextChar == "+".code || nextChar == "?".code || nextChar == "{".code))
				return true;
			return false;
		}
		var checkQuantifier = function() {
			var nextChar = peek();
			if(!inClass && (nextChar == "*".code || nextChar == "+".code || nextChar == "?".code || nextChar == "{".code)) {
				if(parsedRules.length < 1)
					throw unexpected("quantifier");
				else {
					switch(parsedRules[parsedRules.length - 1]) {
					case MatchExact(_), MatchCharCode(_), MatchAny:
					case MatchAnyOf(_), MatchNoneOf(_):
					case MatchLineBreak, MatchWordBoundary:
					case Repeat(_,_,_,_,_):
					case Capture(_):
					case BackRef(_):
					case CharClass(_):
					default:
						throw unexpected("quantifier");
					}
				}
				var lastRule : ERegMatch = parsedRules[parsedRules.length-1];
				var min : Null<Int> = 0;
				var max : Null<Int> = null;
				var qualifier : Null<Int> = null;
				switch(tok()) {
// 				*	   Match 0 or more times
// 				+	   Match 1 or more times
// 				?	   Match 1 or 0 times
// 				{n}    Match exactly n times
// 				{n,}   Match at least n times
// 				{n,m}  Match at least n but not more than m times
//
// 				the "*" quantifier is equivalent to {0,},
// 				the "+" quantifier to {1,},
// 				and the "?" quantifier to {0,1}
				case "*".code:
					qualifier = peek();
				case "+".code:
					min = 1;
					qualifier = peek();
				case "?".code:
					max = 1;
					qualifier = peek();
				case "{".code:
					pos++;
					var cp = inPattern.indexOf(",", pos);
					var bp = inPattern.indexOf("}", pos);
					if(bp < 2)
						throw expected("} to close count");
					qualifier = inPattern.charCodeAt(bp+1);
					var spec = StringTools.trim(inPattern.substr(pos, bp - pos));
					for(y in 0...spec.length) {
						var cc = spec.charCodeAt(y);
						if(!isNumeric(cc) && spec.charAt(y) != "," && !isWhite(cc))
								throw unexpected("character", pos+y);
					}
					if(cp > bp) { // no comma
						min = parseInt(spec);
						if(min == null)
							throw expected("number");
						max = min;
					} else {
						var parts = spec.split(",");
						if(parts.length != 2)
							throw unexpected("comma");
						for(x in 0...parts.length)
							parts[x] = StringTools.trim(parts[x]);
						min = parseInt(parts[0]);
						max = parseInt(parts[1]);
					}
					pos += spec.length;
				}
				var rv = createRepeat(lastRule, min, max, qualifier);
				if(rv.validQualifier)
					pos++;
				parsedRules[parsedRules.length-1] = rv.rule;
			}
		}

		pos--;
		while(pos < patternLen - 1 && !atEndMarker) {
			curchar = tok();
			#if DEBUG_PARSER
				trace(
					traceName() + " pos: " + pos +
					" curchar: " +	(curchar != null ? chr(curchar) : "NULL") +
					" nextChar: " + (peek() != null ? chr(peek()) : "EOL"));
			#end
			if(allowWhite && !inClass) {
				if(curchar != null) {
					if(isWhite(curchar))
						continue;
					if(curchar == "#".code) {
						while(curchar != "\n".code && pos < patternLen - 1) tok();
						continue;
					}
				}
			}
			if(curchar == "\\".code) { // '\'
				curchar = tok();
				// handle octal
				if(isNumeric(curchar)) {
					var numStr : String = chr(curchar) + consumeNumeric(2);
					var doOctal = function() {
						var len = 0;
						while(len < numStr.length) {
							 if(!isOctalDigit(numStr.charCodeAt(len)))
								break;
							len++;
						}
						if(len == 0) {
							if(!inClass)
								throw backrefNotDefined(numStr);
							else
								throw invalid("octal sequence in character class");
						}
						// in case we have pulled invalid octal digits \329
						// where 9 is not a valid digit
						pos = pos - numStr.length + len - 1;
						curchar = tok();
						numStr = numStr.substr(0, len);

						if(numStr.charAt(0) != "0" || numStr.length == 1)
							numStr = "0" + numStr;
						var n = parseOctal(numStr);
						if(n == null)
							throw invalid("octal sequence");
						parsedRules.push(MatchCharCode(n));
					}
					if(inClass) { // no backreferences, must be octal
						doOctal();
					}
					else if(numStr.length == 1) {
						//\1 through \9 are always interpreted as backreferences
						if(numStr == "0")
							doOctal();
						else {
							var n = parseInt(numStr);
							if(n == null)
								throw "internal error " + here.lineNumber;
							if(!isValidBackreference(n))
								throw backrefNotDefined(numStr);
							parsedRules.push(BackRef(n));
						}
					}
					else {
						//\10 as a backreference only if at least 10 left parentheses have opened
						// why do programmers make things difficult? Just for fun?
						if(numStr.charAt(0) == "0") {
							doOctal();
						}
						else {
							var brs = numStr.substr(0);
							var found = false;
							var n : Null<Int> = 0;
							while(brs != null && brs.length > 0) {
								n = parseInt(brs);
								if(n == null) throw "internal error " + here.lineNumber;
								if(isValidBackreference(n)) {
									parsedRules.push(BackRef(n));
									pos = pos - numStr.length + brs.length - 1;
									curchar = tok();
									found = true;
									break;
								}
								brs = brs.substr(0, brs.length - 1);
							}
							if(!found) {
								if(!isOctalDigit(numStr.charCodeAt(0)))
									throw backrefNotDefined(numStr);
								else
									doOctal();
							}
						}
					}
					#if debug
					assertCallback(callback(isNumeric,curchar), " curchar is " + chr(curchar));
					#end
				}
				// handle hex
				else if(curchar == "x".code) {
					curchar = tok();
					var endPos : Int = pos + 2;
					if(curchar == "{".code) {
						var endPos = inPattern.indexOf("}", ++pos);
						if(endPos < 0)
							throw invalid("long hex sequence");
					}
					var hs = inPattern.substr(pos, endPos-pos);
					for(x in 0...hs.length)
						if(!isHexChar(hs.charCodeAt(x)))
							throw invalid("long hex sequence");
					var n = parseInt("0x" + hs);
					if(n == null)
						throw invalid("long hex sequence");
					pos = endPos - 1;
					parsedRules.push(MatchCharCode(n));
				}
				else { // all other escaped chars
					var rule =
					switch(curchar) {
					case "^".code: // Match the beginning of the line
						MatchCharCode(0x5E);
					case ".".code: // Match any character (except newline)
						MatchCharCode(0x2E);
					case "$".code: // Match the end of the line (or before newline at the end)
						MatchCharCode(0x24);
					case "|".code: // Alternation
						MatchCharCode(0x7C);
					case "(".code: // Grouping
						MatchCharCode(0x28);
					case ")".code: // Grouping End
						MatchCharCode(0x29);
					case "[".code: // Character class
						MatchCharCode(0x5B);
					case "]".code: // Character class end
						MatchCharCode(0x5D);
					case "\\".code:
						MatchCharCode(0x5C);
					case "/".code:
						MatchCharCode(0x2F);
					case "?".code:
						MatchCharCode(0x3F);
					//case "0": // \033 octal char (ex ESC) (handled above)
					case "a".code: // \a alarm (BEL)
						MatchCharCode(BEL);
					case "A".code: // \A Match beginning of string
						if(inClass) throw invalid("escape sequence");
						BeginString;
					case "b".code: //\b	Match a word boundary, backspace in classes
						if(inClass)
							MatchCharCode(BS); // // http://perldoc.perl.org/perlre.html
						else
							MatchWordBoundary;
					case "B".code: // \B Match except at a word boundary
						if(inClass) throw invalid("escape sequence");
						NotMatchWordBoundary;
					case "c".code:
						//The expression \cx matches the character control-x.
						//subtract 64 from ASCII code value in decimal of
						//the uppercase letter, except DEL (127) which is Ctrl-?
						var val = peek();
						if(val != null && ((val >= 0x40 && val < 0x5B) || val == 0x3F)) {
							curchar = tok(); // consume it
							if(val == 0x3F)
								MatchCharCode(DEL);
							else
								MatchCharCode(val - 64);
						}
						else
							MatchCharCode(0x63); // 'c'
					case "d".code: // \d [0-9] Match a digit character
						createMatchAnyOf([numeric]);
					case "D".code: // \D [^\d] Match a non-digit character
						createMatchNoneOf([numeric]);
					case "e".code: // \e escape (ESC)
						MatchCharCode(ESC);
					case "f".code: // \f form feed (FF)
						MatchCharCode(FF);
					case "h".code: // \h Horizontal whitespace
						createMatchAnyOfCharCodes([
						#if SUPPORT_UTF8
							HT,SPACE,NBSP,UTF_OSM,UTF_MVS,UTF_ENQUAD,UTF_EMQUAD,
							UTF_ENSPACE,UTF_EMSPACE,UTF_3PSPACE,UTF_4PSPACE,UTF_6PSPACE,
							UTF_FSPACE,UTF_PSPACE,UTF_TSPACE,UTF_HSPACE,UTF_NNBSPACE,
							UTF_MMSPACE,UTF_ISPACE
						#else
							HT,SPACE,NBSP
						#end
						]);
					case "H".code: // \H Not horizontal whitespace
						createMatchNoneOfCharCodes([
						#if SUPPORT_UTF8
							HT,SPACE,NBSP,UTF_OSM,UTF_MVS,UTF_ENQUAD,UTF_EMQUAD,
							UTF_ENSPACE,UTF_EMSPACE,UTF_3PSPACE,UTF_4PSPACE,UTF_6PSPACE,
							UTF_FSPACE,UTF_PSPACE,UTF_TSPACE,UTF_HSPACE,UTF_NNBSPACE,
							UTF_MMSPACE,UTF_ISPACE
						#else
							HT,SPACE,NBSP
						#end
						]);
					case "n".code: // \n newline (LF, NL)
						MatchCharCode(LF);
					case "r".code: // \r return (CR)
						MatchCharCode(CR);
					case "R".code: // \R [CR,LF,CRLF] Linebreak
						//  (?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])
						if(inClass)
							MatchExact("\\R"); // http://perldoc.perl.org/perlre.html
						else
							MatchLineBreak;
					case "s".code: // \s [ \t\r\n\v\f]Match a whitespace character
						createMatchAnyOf([" \t\r\n", sVT, sFF]);
					case "S".code: // \S [^\s] Match a non-whitespace character
						createMatchNoneOf([" \t\r\n", sVT, sFF]);
					case "t".code: // \t	tab (HT, TAB)
						MatchCharCode(0x09);
					case "v".code: // \v Vertical whitespace [\r\n\v]
						createMatchAnyOfCharCodes([
						#if SUPPORT_UTF8
							LF,VT,FF,CR,NEL,UTF_LS,UTF_PS
						#else
							LF,VT,FF,CR,NEL
						#end
						]);
					case "V".code: // \V Not vertical whitespace
						createMatchNoneOfCharCodes([
						#if SUPPORT_UTF8
							LF,VT,FF,CR,NEL,UTF_LS,UTF_PS
						#else
							LF,VT,FF,CR,NEL
						#end
						]);
					case "w".code: // \w [A-Za-z0-9_] Match a "word" character (alphanumeric plus "_")
						createMatchAnyOf([alpha, numeric, "_"]);
					case "W".code: // \W [^\w] Match a non-"word" character
						createMatchNoneOf([alpha, numeric, "_"]);
					//case "x": Handled above // \x1B hex char (example: ESC)
							// \x{263a} long hex char (example: Unicode SMILEY)
					case "z".code: // \z Match only at end of string
						EndString;
					case "Z".code: // \Z	Match only at end of string, or before newline at the end
						EndData;
					default:
// 						throw unhandled("escape sequence char " + curchar);
						MatchCharCode(curchar);
					}
					parsedRules.push(rule);
				}
			} // end escaped portion
			else {
				switch(curchar) {
				case "^".code: // Match the beginning of the line
					if(inClass)
						parsedRules.push(MatchCharCode(0x5E));
					else
						parsedRules.push(BeginLine);
				case ".".code: // Match any character (except newline)
					if(inClass)
						parsedRules.push(MatchCharCode(0x2E));
					else
						parsedRules.push(MatchAny);
				case "$".code: // Match the end of the line (or before newline at the end)
					if(inClass)
						parsedRules.push(MatchCharCode(0x24));
					else
						parsedRules.push(EndLine);
				case "|".code: // Alternation
					if(inClass) {
						parsedRules.push(MatchCharCode(0x7C));
					}
					else {
						if(parsedRules.length == 0)
							throw unexpected("|");
						parsedRules.push(OrMarker);
						orLevel++;
						continue;
					}
				case "(".code: // Grouping
					if(inClass) {
						parsedRules.push(MatchCharCode(0x28));
					} else {
						var ms = inPattern.substr(pos, 4);
						var mm = inPattern.substr(pos, 5);
						this.root.capturesOpened++;
						#if DEBUG_PARSER
							trace("+++ START CAPTURE " + this.root.capturesOpened);
						#end
						var er = new RegEx(inPattern.substr(++pos), this.options, this);
						pos += er.parsedPattern.length -1;

						var rewind = true;
						switch(er.type) {
						case Normal, NoBackref, LookAhead, NegLookAhead, LookBehind, NegLookBehind:
							parsedRules.push(Capture(er));
							if(er.type == Normal)
								rewind = false;
							checkQuantifier();
						#if DEBUG_PARSER
							trace("+++ END CAPTURE " + er.groupNumber + " child consumed "+ er.parsedPattern + (pos+1 >= inPattern.length ? " at EOL" : " next char is '" + chr(peek()) + "'") + " capturesClosed: " + this.root.capturesClosed + " capture: " + ruleToString(parsedRules[parsedRules.length-1]));
						#end
						case PatMatchModifier:
							for(r in er.instanceRules) {
								switch(r) {
								default:
									parsedRules.push(r);
								case ModAllowWhite:
									if(pass == 1 && !allowWhite) {
										allowWhite = true;
										return {
											bytes : 0,
											rules : [],
											reparse : true,
										};
									}
								case ModAllowWhiteOff:
									if(pass == 1 && allowWhite) {
										allowWhite = false;
										return {
											bytes : 0,
											rules : [],
											reparse : true,
										};
									}
								}
							}
						case Comment: // nothing to do
						}
						if(rewind) { // true by default
							root.capturesOpened--;
							root.capturesClosed--;
						}
					}
				case ")".code: // Grouping End
					if(inClass) {
						parsedRules.push(MatchCharCode(0x29));
					} else {
						if(isRoot())
							throw unexpected(")");
						this.root.capturesClosed++;
						if(!isRoot()) {
							atEndMarker = true;
							break;
						}
					}
				case "[".code: // Character class @todo
					//If you want either "-" or "]" itself to be a member of a class,
					// put it at the start of the list (possibly after a "^"), or
					// escape it with a backslash. "-" is also taken literally when it
					// is at the end of the list, just before the closing "]".
					if(inClass) {
						parsedRules.push(MatchCharCode(0x29));
					} else {
						var not = false;
						if(peek() == "^".code) {
							not = true;
							tok();
						}
						var extras = new Array<Int>();
						while(true) {
							switch(peek()) {
							case "-".code, "]".code:
								var n = tok();
								var have = false;
								for(n2 in extras) {
									if(n == n2) {
										untok();
										have = true;
										break;
									}
								}
								if(have) break;
								extras.push(n);
							default: break;
							}
							break;
						}
						tok();
						var ccClosed = false;
						for(i in pos...inPattern.length) {
							if(inPattern.charCodeAt(i) == "]".code) {
								ccClosed = true;
								break;
							}
						}
						if(!ccClosed)
							throw expected("character class definition");

						#if DEBUG_PARSER
							var sp = pos;
							trace(">>> "+traceName()+" START CLASS");
						#end

						var rs = parse(inPattern, pos, true);
						pos += rs.bytes - 1;

						#if DEBUG_PARSER
							trace(">>> Next char is at "+(pos+1)+" char: " + chr(peek()));
						#end

						for(n in extras)
							rs.rules.push(MatchCharCode(n));
						parsedRules.push(mergeClassRules(rs.rules, not));
						checkQuantifier();

						#if DEBUG_PARSER
							trace(">>> "+traceName()+" END CLASS consumed " + rs.bytes + " bytes: " + inPattern.substr(sp, rs.bytes) + " current rules: " + rulesToString(parsedRules));
						#end
					}
				case "]".code: // Character class end
					if(!inClass) {
						parsedRules.push(MatchCharCode(0x5D));
					} else {
						#if DEBUG_PARSER_V
							trace("reached character class end at pos: "+pos);
						#end
						if(expectRangeEnd) {
							// last char is -, which means it's
							// meant to match "-"
							var r = parsedRules.pop();
							if(r != RangeMarker) throw "internal error " + here.lineNumber;
							parsedRules.push(MatchCharCode("-".code));
							expectRangeEnd = false;
						}
						atEndMarker = true;
					}
				case "-".code:
					//@todo:
					//Also, if you try to use the character classes \w , \W , \s, \S , \d ,
					// or \D as beginning or endpoints of a range,
					// the "-" is understood literally.
					if(inClass) {
						if(parsedRules.length == 0) {
							parsedRules.push(MatchCharCode(0x2D));
						} else {
							switch(parsedRules[parsedRules.length-1]) {
							case MatchCharCode(_):
								expectRangeEnd = true;
								parsedRules.push(RangeMarker);
								continue;
							case MatchAnyOf(_), MatchNoneOf(_):
								parsedRules.push(MatchCharCode(0x2D));
							default:
								throw "internal error " + here.lineNumber;
							}
						}
					} else {
						parsedRules.push(MatchCharCode(0x2D));
					}
				case "?".code:
					var resetGroupCount = true;
					if(!inClass && groupNumber > 0 && pos == 0) {
						var c = tok();
						switch(c) {
						default:
							throw unexpected("extended pattern");
						case "P".code: // named pattern
							c = tok();
							switch(c) {
							case "=".code:
								var name = consumeAlNum(true, true);
								try {
									var er = findNamedGroup(name);
									parsedRules.push(BackRef(er.groupNumber));
								} catch(e:Dynamic) {
									throw error(Std.string(e));
								}
							case "<".code, "'".code:
								var endMarker : Null<Int> = c == "<".code ? ">".code : "'".code;
								var name = consumeAlNum(true, true);
								c = tok();
								if(c == null || c != endMarker)
									throw expected(chr(endMarker) + " to terminate named group");
								try {
									registerNamedGroup(this, name);
								} catch(e : Dynamic) {
									throw error(e);
								}
							default:
								throw unexpected("extended pattern identifier " + c);
							}
							resetGroupCount = false;
						case ":".code: // no backreferences
							type = NoBackref;
						case ">".code: // no backtracking. Will not rewind on repeats
							noBacktrack = true;
						case "-".code, "i".code, "m".code, "s".code, "x".code: // PatMatchModifier or normal with different options
							var off = false;
							var expectType : Bool = c == "-".code;
							while(true) {
								switch(c) {
								case "-".code:
									if(expectType)
										throw unexpected("-");
									off = true;
								case "i".code:
									if(off)	parsedRules.push(ModCaseInsensitiveOff);
									else parsedRules.push(ModCaseInsensitive);
									expectType = false; off = false;
								case "m".code:
									if(off) parsedRules.push(ModMultilineOff);
									else parsedRules.push(ModMultiline);
									expectType = false; off = false;
								case "s".code:
									if(off) parsedRules.push(ModDotAllOff);
									else parsedRules.push(ModDotAll);
									expectType = false; off = false;
								case "x".code:
									if(off) {
										parsedRules.push(ModAllowWhiteOff);
										allowWhite = false;
									}
									else {
										parsedRules.push(ModAllowWhite);
										allowWhite = true;
									}
									expectType = false; off = false;
								default: break;
								}
								c = tok();
							}
							if(c == ")".code) { // PatMatchModifier only
								type = PatMatchModifier;
							} else {
								resetGroupCount = false;
							}
							untok();
						case "#".code: // comment 'pattern'
							while(pos < inPattern.length && c != ")".code)
								c = tok();
							type = Comment;
							untok();
						case "=".code: // positive lookahead (zero width)
							type = LookAhead;
						case "!".code: // negative lookahead (zero width)
							type = NegLookAhead;
						case "<".code:
							c = tok();
							switch(c) {
							case "=".code: type = LookBehind;
							case "!".code: type = NegLookBehind;
							default: throw unexpected("look behind type "+ chr(c));
							}
						}
					} else {
						if(inClass)
							parsedRules.push(MatchCharCode("?".code));
						else
							throw unexpected("?");
					}
					if(resetGroupCount) {
						this.groupNumber = -1;
						--this.root._groupCount;
					}
				case "*".code:
					if(inClass)
						parsedRules.push(MatchCharCode("*".code));
					else
						throw unexpected("*");
				default:
					parsedRules.push(MatchCharCode(curchar));
				}
			} // end unescaped char

			if(expectRangeEnd) {
				expectRangeEnd = false;
				var startCode : Int = 0;
				var endCode : Int = 0;

				var tmp = parsedRules.pop();
				switch(tmp) {
				case MatchCharCode(cc):
					endCode = cc;
				default:
					throw unexpected("item " + Std.string(tmp));
				}
				tmp = parsedRules.pop();
				switch(tmp) {
				case RangeMarker:
				default:
					throw unexpected("item " + Std.string(tmp));
				}
				tmp = parsedRules.pop();
				switch(tmp) {
				case MatchCharCode(cc):
					startCode = cc;
				default:
					throw invalid("range");
				}
				try {
					parsedRules.push(createMatchRange(startCode, endCode));
				} catch(e : String) {
					throw error(e);
				}
				continue;
			}

			checkQuantifier();

		} // while(pos < patternLen - 1 && !atEndMarker)

		parsedRules = compactRules(parsedRules);
		#if DEBUG_PARSER
		var msg =
				inClass ?
					"RETURNING from class parser in " + traceName() :
					"RETURNING FROM " + traceName();
		trace(msg + " rules: " + rulesToString(parsedRules) + " captures opened:" + root.capturesOpened + " closed:" + root.capturesClosed + " bytes consumed: " + Std.string(pos - startPos + 1));
		#end
		return {
			bytes : pos - startPos + 1,
			rules : parsedRules,
			reparse : false,
		};
	}

	/**
		Parses a set of rules, compacting multiple MatchCharCode and MatchExact
		rules to single MatchExacts.
	**/
	static function compactRules(rules : Array<ERegMatch>) : Array<ERegMatch> {
		// Compacts the rules
		var newRules = new Array<ERegMatch>();
		var len = rules.length;
		var sb = new StringBuf();
		for(x in 0...len) {
			var r = rules.shift();
			switch(r) {
			case MatchCharCode(cc):
				sb.addChar(cc);
			case MatchExact(s):
				sb.add(s);
			default:
				var s = sb.toString();
				if(s.length > 0) {
					newRules.push(MatchExact(s));
					sb = new StringBuf();
				}
				newRules.push(r);
			}
		}
		if(sb.toString().length > 0) {
			var s = sb.toString();
			newRules.push(MatchExact(s));
		}
		return newRules;
	}

	static function createRepeat(rule : ERegMatch, min : Null<Int>, max : Null<Int>, qualifier : Null<Int>)
		: { validQualifier: Bool, rule : ERegMatch}
	{
		var notGreedy = false;
		var possessive = false;
		var isValid = false;
		switch(qualifier) {
		case "+".code: possessive = true; isValid = true;
		case "?".code: notGreedy = true; isValid = true;
		}
		var minval : Int = 0;
		if(min != null)
			minval = min;
		return {
			validQualifier: isValid,
			rule: Repeat(rule, minval, max, notGreedy, possessive),
		};
	}

	/**
		Takes an array of strings and builds an IntHash of the
		character codes.
		@param a Array of Strings of characters to include
		@return MatchAnyOf()
	**/
	function createMatchAnyOf(a : Array<String>) {
		var b = new Array<Int>();
		for(x in 0...a.length) {
			var s : String = a[x];
			if(s == null)
				continue;
			for(i in 0...s.length)
				b.push(s.charCodeAt(i));
		}
		return createMatchAnyOfCharCodes(b);
	}

	/**
		Takes an array of Ints and builds an IntHash
		@param a Array of Ints of characters to include
		@return MatchAnyOf() containing all the supplied codes
	**/
	function createMatchAnyOfCharCodes(a : Array<Int>) {
		var h = new IntHash();
		for(x in 0...a.length)
			for(i in 0...a.length)
				h.set(a[i], true);
		return MatchAnyOf(h);
	}

	/**
		Takes an array of strings and builds an IntHash of the
		character codes.
		@param a Array of Strings of characters to include
		@return MatchNoneOf() containing all the supplied codes
	**/
	function createMatchNoneOf(a : Array<String>) {
		var r = createMatchAnyOf(a);
		return switch(r) {
		case MatchAnyOf(h):
			MatchNoneOf(h);
		default:
			throw "error";
		}
	}

	/**
		Takes an array of Ints and builds an IntHash
		@param a Array of Ints of characters to include
		@return MatchNoneOf() containing all the supplied codes
	**/
	function createMatchNoneOfCharCodes(a : Array<Int>) {
		var r = createMatchAnyOfCharCodes(a);
		return switch(r) {
		case MatchAnyOf(h):
			MatchNoneOf(h);
		default:
			throw "error";
		}
	}

	/**
		Creates a MatchAnyOf with the character codes from [start] to [end] inclusive
		@param start Starting character
		@param end End character
		@throws String if error in param order or negative params
	**/
	function createMatchRange(start : Int, end:Int) {
		var h = new IntHash<Bool>();
		if(start > end)
			throw "character range order error";
		if(start < 0 || end < 0)
			throw "Negative character range";
		for(i in start...end+1)
			h.set(i, true);
		return MatchAnyOf(h);
	}

	/**
		Modifies any supplied character code for case sensitivity
	**/
	function lowerCaseCode(cc : Int) : Int {
		return
			if(ignoreCase && (cc >= 65 && cc <= 90))
				32 + cc;
			else
				cc;
	}

	function changeCodeCase(cc : Int) : Int {
		return
			if(cc >= 65 && cc <= 90)
				32 + cc;
			else if(cc >= 97 && cc <= 122)
				cc - 32;
			else
				cc;
	}

	static inline function isNumeric(c : Null<Int>) {
		return
			if(c == null)
				throw "null number";
			else
				(c >= 48 && c <= 57);
	}

	static inline function getNumber( c : Null<Int> ) : Null<Int> {
		return
		if(c == null)
			null;
		else (c >= 48 && c <= 57) ? c - 48 : null;
	}

	static inline function isAlpha(c : Null<Int>) {
		return
			if (c==null)
				throw "null character";
			else
				((c >= 65 && c <= 90) || (c >= 97 && c <= 122));
	}

	static inline function isAlNum(c : Null<Int>) {
		return (isNumeric(c) || isAlpha(c));
	}

	static inline function isHexChar(c : Null<Int>) {
		return
			if(c == null)
				throw "null hex char";
			else
				(isNumeric(c) || ((c >= 65 && c <= 70) || (c >= 97 && c <= 102)));
	}

	static inline function isOctalDigit(c : Null<Int>) : Bool {
		return
			if(c == null)
				throw "null octal char";
			else
				(c >= 0x30 && c <= 0x37);
	}

	static inline function isWhite(c : Null<Int>) {
		return
			if(c == null)
				throw "null char";
			else
				(c == 32 || (c >= 9 && c <= 13));
	}

	function isWord(c : Int) {
		if(wordHash == null) {
			wordHash = new IntHash();
			var m = createMatchAnyOf([alpha,numeric,"_"]);
			switch(m) {
			case MatchAnyOf(h):
				wordHash = h;
			default: throw "internal error " + here.lineNumber;
			}
		}
		return wordHash.exists(c);
	}

	function mergeClassRules(rules:Array<ERegMatch>, not:Bool) {
		var hpos = new IntHash<Bool>();
		var hneg = new IntHash<Bool>();
		var pl = false;
		var nl = false;
		var ma = false;

		if(rules.length == 0)
			return null;
		for(x in 0...rules.length) {
			switch(rules[x]) {
			case MatchExact(s):
				if(s.length > 0) pl = true;
				for(i in 0...s.length)
					hpos.set(s.charCodeAt(i), true);
			case MatchCharCode(c):
				pl = true;
				hpos.set(c, true);
			case MatchAny:
				throw "internal error " + here.lineNumber;
			case MatchAnyOf(ch):
				for(k in ch.keys())
					hpos.set(k, true);
				for(k in ch.keys()) { pl = true; break; }
			case MatchNoneOf(ch):
				for(k in ch.keys())
					hneg.set(k, true);
				for(k in ch.keys()) { nl = true; break; }
			#if debug
			case BeginString, BeginLine,OrMarker,RangeMarker:
				throw "internal error " + rules[x];
			case EndLine, EndString, EndData:
				throw "internal error " + rules[x];
			case Repeat(_,_,_,_,_),Capture(_):
				throw "internal error " + rules[x];
			case ModCaseInsensitive, ModMultiline, ModDotAll:
				throw "internal error " + rules[x];
			case ModCaseInsensitiveOff, ModMultilineOff, ModDotAllOff:
				throw "internal error " + rules[x];
			case ModAllowWhite, ModAllowWhiteOff:
				throw "internal error " + rules[x];
			case MatchWordBoundary, NotMatchWordBoundary, BackRef(_):
				throw "internal error " + here.lineNumber;
			case MatchLineBreak:
				throw "internal error " + here.lineNumber;
			case CharClass(_):
				throw "internal error " + here.lineNumber;
			#else
			default:
			#end
			}
		}

		var a = new Array<ERegMatch>();
		if(pl) {
			if(not) a.push(MatchNoneOf(hpos));
			else a.push(MatchAnyOf(hpos));
		}

		if(nl) {
			if(not) a.push(MatchAnyOf(hneg));
			else a.push(MatchNoneOf(hneg));
		}

		if(ma) {
			if(not) {
				hneg = new IntHash();
				hneg.set("\n".code, true);
				a.push(MatchNoneOf(hneg));
			}
			a.push(MatchAny);
		}
		return CharClass(a);
	}

	#if (DEBUG_MATCH || DEBUG_MATCH_V)
	function traceFrames() {
		chx.Lib.println(traceName());
		for(i in stack)
			chx.Lib.println("\t" + stackItemToString(i));
		for(ch in children)
			ch.traceFrames();
	}
	#end

	/**
		Called from a child to add a ChildFrame marker to the stack
	**/
	function addChildFrame( id:Int, r : RegEx, st : ExecState) {
		// todo
		// check if it would actually be a valid match at our position?
		var myState = copyExecState(es);
		stack.push( ChildFrame(id, myState, r, st) );
		if(!isRoot())
			parent.addChildFrame(id, this, myState);
	}

	function pushRepeatFrame(rule:ERegMatch, pos:Int, info:Dynamic) : Void {
		var id = root._frameIdx++;
		var st = copyExecState(es);
		st.iPos = pos;
		stack.push(RepeatFrame(id, rule, st, info));
		if(!isRoot())
			parent.addChildFrame(id, this, st);
		#if DEBUG_MATCH_V
		chx.Lib.println(traceName() + " pushRepeatFrame dump:");
		root.traceFrames();
		#end
	}

	function popFrame() : StackItem {
		if(stack.length == 0)
			return null;
		var rv = stack.pop();
		if(!isRoot()) {
			var id : Int = 0;
			switch(rv) {
			case RepeatFrame(iid,_,_,_), ChildFrame(iid,_,_,_), OrFrame(iid,_):
				id = iid;
			}
			parent.removeFrame(id);
		}
		return rv;
	}

	function removeFrame(id : Int) {
		if(!isRoot())
			parent.removeFrame(id);
		// start from end since most likely to be near end of stack
		var i = stack.length - 1;
		while(i >= 0) {
			var found = false;
			switch(stack[i]) {
			case RepeatFrame(iid,_,_,_), ChildFrame(iid,_,_,_), OrFrame(iid,_):
				if(iid == id)
					found = true;
			}
			if(found) {
				stack.splice(i,1);
				break;
			}
			i--;
		}
	}

	function clearStack() {
		if(stack == null) {
			stack = new Array();
			return;
		}
		var c = popFrame();
		while(null != c) {
			switch(c) {
			case ChildFrame(_, _, e, _):
				e.clearStack();
			default:
			}
			c = popFrame();
		}
	}

	function rewindStackLength(len: Int) {
		while(stack.length > len)
			popFrame();
	}

	/**
		Registers a named group [(?P<name>)]. Groups must start with
		an alpha char, followed by [a-z0-9_]*
		@throws String if group already registered
	**/
	function registerNamedGroup(e : RegEx, name : String) {
		if(root.namedGroups.exists(name))
			throw "group with name " + name + " already exists";
		root.namedGroups.set(name, e);
	}

	function findNamedGroup(name : String) : RegEx {
		if(!root.namedGroups.exists(name))
			throw "group with name " + name + " does not exist";
		return root.namedGroups.get(name);
	}

	//------------ support methods required -----------------------------//
	/**
		This version of parseInt ensures that octal is not processed
	**/
	public static function parseInt( x : String ) : Null<Int> {
		// remove leading 0s
		var preParse = function(ns:String) : { neg:Bool, str: String}
		{
			var neg = false;
			var s = StringTools.ltrim(ns);
			if(s.charAt(0) == "-") {
				neg = true;
				s = s.substr(1);
			}
			else if(s.charAt(0) == "+")
				s = s.substr(1);
			try {
				if(!isNumeric(s.charCodeAt(0)))
					return {str:null, neg:false};
			} catch(e:Dynamic) {
				return {str:null, neg:false};
			}

			if(!StringTools.startsWith(s,"0x")) {
				var l = s.length;
				var p : Int = -1;
				var c : Null<Int> = 0;
				while(c == 0 && p < l-1) {
					p++;
					c = getNumber(s.charCodeAt(p));
					if(c == null)
						return null;
				}
				s = s.substr(p);
			}
			return {str: s, neg:neg };
		}

		untyped {
		#if flash9
		var v = __global__["parseInt"](x);
		if( __global__["isNaN"](v) )
			return null;
		return v;
		#elseif flash
		var res = preParse(x);
		if(res.str == null) return null;
		var v = _global["parseInt"](res.str);
		if( Math.isNaN(v) )
			return null;
		if(res.neg)
			return 0-v;
		return v;
		#elseif neko
		var t = __dollar__typeof(x);
		if( t == __dollar__tint )
			return x;
		if( t == __dollar__tfloat )
			return __dollar__int(x);
		if( t != __dollar__tobject )
			return null;
		var res = preParse(x);
		if(res.str == null) return null;
		var v = __dollar__int(res.str.__s);
		if(res.neg)
			return 0-v;
		return v;
		#elseif js
		var res = preParse(x);
		var v = __js__("parseInt")(res.str);
		if( Math.isNaN(v) )
			return null;
		if(res.neg)
			return 0-v;
		return v;
		#elseif php
		if(!__php__("is_numeric")(x)) return null;
		return x.substr(0, 2).toLowerCase() == "0x" ? __php__("intval(substr($x, 2), 16)") : __php__("intval($x)");
		#else
		return 0;
		#end
		}
	}

	/**
		Convert an Octal String to an Int. Will return null if it can not be parsed.
	**/
	public static function parseOctal( x : String ) : Null<Int> {
		#if flash9
		untyped {
		var v = __global__["parseInt"](x, 8);
		if( __global__["isNaN"](v) )
			return null;
		return v;
		}
		#else
		var neg = false;
		var n : Int = 0;
		var s = StringTools.ltrim(x);
		var accum : Int = 0;
		var l = s.length;

		try {
			if(!isNumeric(s.charCodeAt(0))) {
				if(s.charAt(0) == "-")
					neg = true;
				else if(s.charAt(0) == "+")
					neg = false;
				else
					return null;
				n ++;
				if(n == s.length || !isNumeric(s.charCodeAt(n)))
					return null;
			}
		} catch(e:Dynamic) {
			return null;
		}

		while(n < l) {
			var c : Null<Int> = getNumber(s.charCodeAt(n));
			if( c == null )
				break;
			if( c > 7 )
				return null;
			accum <<= 3;
			accum += c;
			n++;
		}
		if(neg)
			return 0-accum;
		return accum;
		#end
	}


	//----------------- toString methods --------------------------------//
	public function toString() : String {
		var sb = new StringBuf();
		if(groupNumber >= 0) {
			sb.add("RegEx { group: ");
			sb.add((groupNumber == 0 ? "root" : Std.string(groupNumber)));
		} else {
			sb.add("RegEx { ");
			sb.add(Std.string(type));
		}
		sb.add(", ");
		sb.add("depth: ");
		sb.add(depth);
		sb.add(" ");
		sb.add(rulesToString(instanceRules));
		sb.add(" }");
		return sb.toString();
	}

	public function ruleToString(r : ERegMatch) {
		var ofToString = function(h : IntHash<Bool>) : String {
			var sb = new StringBuf();
			for(i in h.keys())
				sb.addChar(i);
			return sb.toString();
		}
		if(r == null)
			return "(null)";
		return switch(r) {
		case MatchCharCode(c):
			"MatchCharCode(" + chr(c) + ")";
		case Repeat(r, min, max, notGreedy, possessive):
			if(notGreedy)
				"Repeat(min:"+min+", max:"+max+" " + ruleToString(r) + ")";
			else
				"RepeatGreedy(min:"+min+", max:"+max+" " + ruleToString(r) + ")";
		case Capture(e):
			"Capture("+e.toString()+")";
		case MatchAnyOf(h):
			"MatchAnyOf(" + ofToString(h) + ")";
		case MatchNoneOf(h):
			"MatchNoneOf(" + ofToString(h) + ")";
		default: Std.string(r);
		}
	}

	public function rulesToString(a : Array<ERegMatch>) {
		var sb = new StringBuf();
		sb.add("[");
		for(i in 0...a.length) {
			sb.add(ruleToString(a[i]));
			if(i < a.length - 1) {
				sb.add(", ");
			}
		}
		sb.add("]");
		return sb.toString();
	}

	public function stackItemToString(r : StackItem) : String {
		return switch(r) {
		case OrFrame(id, state):
			"OrFrame(id:"+id+", pos:"+state.iPos+")";
		case RepeatFrame(id, rule, state, info):
			switch(rule) {
			default:
				throw "internal error " + here.lineNumber;
			case Repeat(r, _, _, notGreedy, possessive):
				ruleToString(Repeat(r, info.min, info.max, notGreedy, possessive));

				if(notGreedy)
					"Repeat(id:"+id+" min:"+info.min+", max:"+info.max+" "+ruleToString(r)+")";
				else
					"RepeatGreedy(id:"+id+" min:"+info.min+", max:"+info.max+" "+ruleToString(r)+")";

			}
		case ChildFrame(id, state, e, eState):
			"ChildFrame(id:"+id+", group:"+e.groupNumber+
			", groupPos: "+eState.iPos+", myPos:"+state.iPos+
			", rule:"+ruleToString(e.instanceRules[eState.iRuleIdx])+")";
		}
	}

/*


By default, a quantified subpattern is "greedy", that is, it will match as many times as possible (given a particular starting location) while still allowing the rest of the pattern to match. If you want it to match the minimum number of times possible, follow the quantifier with a "?". Note that the meanings don't change, just the "greediness":

    *?     Match 0 or more times, not greedily
    +?     Match 1 or more times, not greedily
    ??     Match 0 or 1 time, not greedily
    {n}?   Match exactly n times, not greedily
    {n,}?  Match at least n times, not greedily
    {n,m}? Match at least n but not more than m times, not greedily

By default, when a quantified subpattern does not allow the rest of the overall pattern to match, Perl will backtrack. However, this behaviour is sometimes undesirable. Thus Perl provides the "possessive" quantifier form as well.

    *+     Match 0 or more times and give nothing back
    ++     Match 1 or more times and give nothing back
    ?+     Match 0 or 1 time and give nothing back
    {n}+   Match exactly n times and give nothing back (redundant)
    {n,}+  Match at least n times and give nothing back
    {n,m}+ Match at least n but not more than m times and give nothing back

*/

}
