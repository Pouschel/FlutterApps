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

  late Map funcMap = {"toString": _toString, "print": print};

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

  static void DefineAll(IInterpreter vm) {
    var funcClass = NativeFunctions();
    funcClass.vm = vm;
    funcClass.funcMap.forEach((name, value) {
      vm.DefineNative(name, (p0) => value(name, p0));
    });

    // for (var (name, method) in funcClass.GetFunctions())
    // {
    // 	if (method.IsStatic)
    // 		vm.DefineNative(name, (NativeFn)Delegate.CreateDelegate(typeof(NativeFn), method));
    // 	else
    // 		vm.DefineNative(name, (NativeFn)Delegate.CreateDelegate(typeof(NativeFn), funcClass, method));
    // }
  }
}