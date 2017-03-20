package;

import tink.testrunner.Runner;
import tink.testrunner.Assertion;
import tink.unit.TestBatch;
import travix.Logger.*;
import haxe.macro.Expr;
import RunTests.assert;

using tink.CoreApi;
using haxe.macro.Tools;

class RunTests {
	static function main() {
		
		var code = 0;
		
		
		#if (cs || java) // https://github.com/HaxeFoundation/haxe/issues/6106
		function assertEquals(expected:Dynamic, actual:Dynamic, ?pos:haxe.PosInfos) {
		#else
		function assertEquals<T>(expected:T, actual:T, ?pos:haxe.PosInfos) {
		#end
			if(expected != actual) {
				println('${pos.fileName}:${pos.lineNumber}: Expected $expected but got $actual ');
				code++;
			}
		}
		
		var futures = [];
		
		// Test: basic
		var normal = new NormalTest();
		var _await = new AwaitTest();
		var exclude = new ExcludeTest();
		futures.push(
			function() return Runner.run(TestBatch.make([
				normal,
				_await,
				exclude,
			])).map(function(result) {
				assertEquals(0, result.failures().length);
				assertEquals('ss2bb2syncaa2bb2syncAssertaa2bb2asyncaa2bb2asyncAssertaa2bb2timeoutaa2bb2nestedDescriptionsaa2bb2multiAssertaa2dd2', normal.result);
				assertEquals('ss2bb2asyncaa2dd2', _await.result);
				assertEquals('ss2bb2includeaa2dd2', exclude.result);
				return Noise;
			})
		);
		
		// Test: include
		var normal = new NormalTest();
		var _await = new AwaitTest();
		var include = new IncludeTest();
		futures.push(
			function() return Runner.run(TestBatch.make([
				normal, 
				_await, 
				include,
			])).map(function(result) {
				assertEquals(0, result.failures().length);
				assertEquals('', normal.result);
				assertEquals('', _await.result);
				assertEquals('ss2bb2includeaa2dd2', include.result);
				return Noise;
			})
		);
		
		
		var iter = futures.iterator();
		function next() {
			if(iter.hasNext()) iter.next()().handle(next);
			else {
				trace('Exiting with code: $code');
				exit(code);
			}
		}
		next();
	}
	
	public static macro function assert(expr:ExprOf<Bool>, ?description:String):ExprOf<Assertion> {
		if(description == null) description = expr.toString();
		return macro new tink.testrunner.Assertion($expr, $v{description});
	}
}

@:name('Custom Test Name')
class NormalTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
		
	@:describe("Sync test")
	public function sync() {
		debug('sync');
		return new Assertion(true, 'Always true');
	}

	@:describe('Sync test using Assert')
	public function syncAssert() {
		debug('syncAssert');
		return assert(true);
	}
		
	@:describe('Async test')
	public function async() {
		debug('async');
		return Future.sync(new Assertion(true, 'Always true'));
	}
		
	@:describe('Async test using Assert')
	public function asyncAssert() {
		debug('asyncAssert');
		return Future.sync(assert(true));
	}
		
	@:timeout(1500) // in ms
	@:describe('Timeout test')
	public function timeout() {
		debug('timeout');
		return Future.async(function(cb) haxe.Timer.delay(function() cb(assert(true)), 1000));
	}
		
	@:describe('Nest')
	@:describe('  your')
	@:describe('    descriptions')
	public function nestedDescriptions() {
		debug('nestedDescriptions');
		return assert(true);
	}
    
	@:describe('Multiple assertions')
	public function multiAssert() {
		debug('multiAssert');
		return [
			assert(true),
			assert(true),
			assert(true),
		];
	}
}

@:await
class AwaitTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
	
	@:describe('Async test powered by tink_await')
	@:async public function async() {
		debug('async');
		var actual = @:await someAsyncValue();
		return assert(actual == 'actual');
	}
  
  function someAsyncValue() 
    return Future.async(function(cb) haxe.Timer.delay(function() cb('actual'), 1000));
}

class IncludeTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
		
	@:include
	public function include() {
		debug('include');
		return assert(true);
	}

	public function skip() {
		debug('skip');
		return assert(true);
	}
}

class ExcludeTest {
	public var result:String;
	
	public function new() {
		result = '';
	}
	
	function debug(msg:String) {
		result += msg;
		return Noise;
	}
	
	@:before public function before() return debug('b');
	@:before public function before2() return debug('b2');
	@:after public function after() return debug('a');
	@:after public function after2() return debug('a2');
	@:startup public function startup() return debug('s');
	@:startup public function startup2() return debug('s2');
	@:shutdown public function shutdown() return debug('d');
	@:shutdown public function shutdown2() return debug('d2');
		
	@:exclude
	public function exclude() {
		debug('exclude');
		return assert(true);
	}

	public function include() {
		debug('include');
		return assert(true);
	}
}