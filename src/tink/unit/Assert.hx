package tink.unit;

import tink.testrunner.Assertion;
import tink.testrunner.Assertions;
import tink.streams.Stream;
import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Assert {
	static var printer = new haxe.macro.Printer();
	
	public static macro function assert(expr:ExprOf<Bool>, ?description:ExprOf<String>, ?pos:ExprOf<haxe.PosInfos>):ExprOf<Assertion> {
		var pre = macro {};
		var assertion = expr;
		
		switch description {
			case macro null:
			default:
				if(Context.unify(Context.typeof(description), Context.getType('haxe.PosInfos'))) {
					pos = description;
					description = macro null;
				}
		}
				
		switch description {
			case macro null:
				description = macro $v{expr.toString()};
				
				// TODO: we can actually do a recursive breakdown: e.g. `a == 1 && b == 2`
				switch expr {
					case { expr: EBinop(op, e1, e2) }:
						
						var operator = printer.printBinop(op);
						var operation = EBinop(op, macro @:pos(e1.pos) lh, macro @:pos(e2.pos) rh).at(expr.pos);
						
						pre = macro {
							// store the values to avoid evaluating the expressions twice
							var lh = $e1; 
							var rh = $e2;
						}
						assertion = operation;
						description = macro $description + ' (' + tink.unit.Assert.stringify(lh) + ' ' + $v{operator} + ' ' + tink.unit.Assert.stringify(rh) + ')';
						
					case macro $e1.match($e2):
						pre = macro {
							var value = $e1;
						}
						assertion = macro @:pos(expr.pos) value.match($e2);
						description = macro $description + ' (' + $v{e1.toString()} + ' => ' + tink.unit.Assert.stringify(value) + ')';
					default:
				}	
			default:
		}
		
		var args = [assertion, description];
		switch pos {
			case macro null: // skip
			case v: args.push(v);
		}
		return pre.concat(macro @:pos(expr.pos) new tink.testrunner.Assertion($a{args}));
	}
	
	public static macro function benchmark(iterations:ExprOf<Int>, body:Expr):ExprOf<tink.testrunner.Assertion> {
		return macro @:pos(body.pos) {
			var i = $iterations;
			var start = haxe.Timer.stamp();
			for(_ in 0...i) $body;
			var dt = haxe.Timer.stamp() - start;
			new tink.testrunner.Assertion(true, 'Benchmark: ' + i + ' iterations = ' + dt + 's');
		}
	}
	
	#if !macro
	public static function fail(e:tink.core.Error, ?pos:haxe.PosInfos):Assertions
		return #if pure Stream.ofError(e) #else Stream.failure(e) #end;
	
	public static function stringify(v:Dynamic) {
		return 
			if(Std.is(v, String) || Std.is(v, Float) || Std.is(v, Bool)) haxe.Json.stringify(v);
			else Std.string(v);
	}
	#end
}
