import '../scanning.dart';

abstract class ExprStmtBase
{
	InputStatus? Status;
	
  @override
  String toString() 
		=> Status !=null ? Status.toString() : "a ${this.runtimeType}";
}