// ignore: camel_case_types
typedef string = String;
// ignore: camel_case_types
typedef object = Object;

void printWarning(String text) {
  print('\x1B[33m$text\x1B[0m');
}

void printError(String text) {
  print('\x1B[31m$text\x1B[0m');
}

void printInfo(String text) {
  print('\x1B[34m$text\x1B[0m');
}

void printSuccess(String text) {
  print('\x1B[32m$text\x1B[0m');
}

extension StringExtension on String {
  List<string> splitAndRemoveEmpty(string sep) =>
      split(sep)..removeWhere((element) => element.isEmpty);
}

extension EnumExtension on Enum
{
  String toShortString() {
    return toString().split('.').last;
  }
}

class Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;
  int get length => _list.length;

  @override
  String toString() => _list.toString();
}