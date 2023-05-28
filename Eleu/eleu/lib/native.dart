// ignore_for_file: file_names
import 'dart:math';

import 'eleu.dart';
import 'interpret/interpreting.dart';
import 'types.dart';

class EleuNativeError extends EleuRuntimeError {
  EleuNativeError(String msg) : super(null, msg);
}

class NativeFunctionBase {
  IInterpreter? vm;
  IInterpreter get Vm => vm!;

  static void CheckArgLen(List<Object> args, int nMinArgs, String name) =>
      CheckArgLenMulti(args, nMinArgs, -1, name);

  static void CheckArgLenMulti(
      List<Object> args, int nMinArgs, int nMaxArgs, String name) {
    if (name[0] == '@') name = name.substring(1);
    if (nMaxArgs < 0) if (args.length != nMinArgs)
      throw EleuNativeError(
          "Die Funktion '${name}' erwartet genau ${nMinArgs} Argumente");
    else
      return;
    if (args.length < nMinArgs || args.length > nMaxArgs)
      throw EleuNativeError(
          "Die Funktion '${name}' erwartet mindestens ${nMinArgs} und höchstens ${nMaxArgs} Argumente");
  }

  static T CheckArgType<T>(int zeroIndex, List<Object> args, String funcName) {
    if (args.length > zeroIndex) {
      var arg = args[zeroIndex];
      if (arg is T) return arg as T;
      String tn = "";
      if (arg is Number)
        tn = "number";
      else if (arg is String)
        tn = "string";
      else if (arg is bool) tn = "boolean";
      throw EleuNativeError(
          "In der Funktion ${funcName} muss das ${zeroIndex + 1}. Argument vom Typ '${tn}' sein!");
    } else
      throw EleuNativeError(
          "In der Funktion ${funcName} muss das ${zeroIndex + 1}. Argument vorhanden sein!");
  }

  static int CheckIntArg(int zeroIndex, List<Object> args) {
    if (args.length > zeroIndex) {
      var arg = args[zeroIndex];
      if (arg is Number) {
        if (arg.IsInt) return arg.IntValue;
      }
    }
    throw EleuNativeError("Argument ${zeroIndex + 1} muss eine ganze Zahl sein.");
  }
  // public IEnumerable<(string name, MethodInfo method)> GetFunctions()
  // {
  // 	var type = this.GetType();
  // 	var flags = BindingFlags.Static | BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public;
  // 	foreach (var mi in type.GetMethods(flags))
  // 	{
  // 		if (mi.ReturnType != typeof(object)) continue;
  // 		var pars = mi.GetParameters();
  // 		if (pars.Length != 1) continue;
  // 		if (pars[0].ParameterType != typeof(object[])) continue;
  // 		string name = mi.Name;
  // 		if (name[0] == '@')
  // 			name = name[1..];
  // 		yield return (name, mi);
  // 	}
  // }

  // public static void DefineAll<T>(IInterpreter vm) where T : NativeFunctionBase, new()
  // {
  // 	var funcClass = new T() { vm = vm };
  // 	foreach (var (name, method) in funcClass.GetFunctions())
  // 	{
  // 		if (method.IsStatic)
  // 			vm.DefineNative(name, (NativeFn)Delegate.CreateDelegate(typeof(NativeFn), method));
  // 		else
  // 			vm.DefineNative(name, (NativeFn)Delegate.CreateDelegate(typeof(NativeFn), funcClass, method));
  // 	}
  // }
}

class NativeFunctions extends NativeFunctionBase {
  Random rand = Random();

  late Map funcMap = {
    "toString": _toString,
    "print": print,
    "sqrt": _sqrt,
    "_abs": _abs,
    "acos": _acos,
    "asin": _asin,
    "ceil": _ceil,
    "cos": _cos,
    "floor": _floor,
    "log10": _log10,
    "sin": _sin,"pow":_pow, "random":_random,"typeof":_typeof
  };

  NativeFunctions() {
    //funcMap = {"toString": _toString};
  }

  Object _toString(String name, List<Object> args) {
    NativeFunctionBase.CheckArgLen(args, 1, name);
    return Stringify(args[0]);
  }

  Object print(String name, List<Object> args) {
    NativeFunctionBase.CheckArgLen(args, 1, name);
    var s = Stringify(args[0]);
    Vm.options.Out.WriteLine(s);
    return NilValue;
  }

  static Number MathFunc(double Function(double) func, OList args, string name) {
    NativeFunctionBase.CheckArgLenMulti(args, 1, -1, name);
    var arg = NativeFunctionBase.CheckArgType<Number>(0, args, name);
    var result = func(arg.DVal);
    if (result.isInfinite)
      throw EleuNativeError(
          "Das Ergebnis von '${name}(${arg})' ist zu groß (oder klein) für den unterstützten Zahlentyp.");
    if (!(result.isFinite))
      throw EleuNativeError("Das Ergebnis von '${name}(${arg})' ist nicht definiert.");
    return Number(result);
  }

  static object _sqrt(string name, OList args) => MathFunc(sqrt, args, name);
  static object _abs(string name, OList args) => MathFunc((n) => n.abs(), args, name);
  static object _acos(string name, OList args) => MathFunc(acos, args, name);
  static object _asin(string name, OList args) => MathFunc(asin, args, name);
  static object _ceil(string name, OList args) =>
      MathFunc((x) => x.ceil().toDouble(), args, name);
  static object _cos(string name, OList args) => MathFunc(cos, args, name);
  static object _floor(string name, OList args) =>
      MathFunc((x) => x.floor().toDouble(), args, name);
  static object _log10(string name, OList args) =>
      MathFunc((x) => log(x) / ln10, args, name);
  static object _sin(string name, OList args) => MathFunc(sin, args, name);
	static object _pow(string name, OList args)
	{
		NativeFunctionBase.CheckArgLen(args, 2,name);
		var bas = NativeFunctionBase.CheckArgType<Number>(0, args,name);
		var exp = NativeFunctionBase.CheckArgType<Number>(1, args,name);
		var result = pow(bas.DVal, exp.DVal);
		if (result.isInfinite)
			throw EleuNativeError("Das Ergebnis von 'pow(${bas},${exp})' ist zu groß (oder klein) für den unterstützten Zahlentyp.");
		if (!(result.isFinite))
			throw EleuNativeError("Das Ergebnis von 'pow(${bas},${exp})' ist nicht definiert.");
		return Number(result.toDouble());
	}
	object _random(string name, OList args)
	{
		NativeFunctionBase.CheckArgLen(args, 0,name);
		return Number (rand.nextDouble());
	}
	static object _typeof(string name, OList args)
	{
		NativeFunctionBase.CheckArgLen(args, 1,name);
		var arg = args[0];
		switch(arg)
		{
			case bool : return "boolean";
			case Number : return "number";
			case string :return "string";
			case EleuClass cl : return "metaclass ${cl.Name}";
			case EleuInstance inst: "class ${inst.klass.Name}";
			case ICallable : return "function";
			default: return "undefined";
		}
    return "undefined";
	}
  static void DefineAll(IInterpreter vm) {
    var funcClass = NativeFunctions();
    funcClass.vm = vm;
    funcClass.funcMap.forEach((name, value) {
      vm.DefineNative(name, (p0) => value(name, p0));
    });
  }
}
