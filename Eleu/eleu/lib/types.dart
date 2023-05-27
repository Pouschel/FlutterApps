class Number {
  double DVal = 0;

  Number(double d) {
    assert(d.isFinite);
    this.DVal = d;
  }
  static Number? TryParse(String s) {
    var d = double.tryParse(s);
    if (d == null) return null;
    return Number(d);
  }

  // internal Number(long l) { this.DVal = l; }
  // public bool IsDefined => double.IsFinite(DVal);
  // public bool IsZero => DVal == 0;
  int get IntValue => (DVal - 0.5).round();
  bool get IsInt => IntValue == DVal;
  @override
  String toString() => DVal.toString();
  // private static int Cmp(in Number a, in Number b) => a.DVal.CompareTo(b.DVal);
  // public bool Equals(Number other) => Cmp(this, other) == 0;
  // public int CompareTo(Number other) => Cmp(this, other);
  // public override bool Equals([NotNullWhen(true)] object? obj)
  // {
  // 	if (obj is Number num) return this.Equals(num);
  // 	return false;
  // }
  // public override int GetHashCode() => DVal.GetHashCode();
  // public static Number operator -(in Number a, in Number b)
  // {
  // 	var dres = a.DVal - b.DVal;
  // 	return new Number(dres);
  // }
  // public static Number operator -(in Number a) => new Number(-a.DVal);
  // public static Number operator +(in Number a, in Number b) => new(a.DVal + b.DVal);
  // public static Number operator *(in Number a, in Number b) => new(a.DVal * b.DVal);
  // public static Number operator /(in Number a, in Number b) => new(a.DVal / b.DVal);
  // public static Number operator %(in Number a, in Number b) => new(a.DVal % b.DVal);
}
