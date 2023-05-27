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
  @override
  bool operator ==(Object other) {
    if (other is Number) DVal == other.DVal;
    return false;
  }

  @override
  int get hashCode => DVal.hashCode;

  static int Cmp(Number a, Number b) => a.DVal.compareTo(b.DVal);
  int CompareTo(Number other) => Cmp(this, other);

  Number operator +(Number a) => Number(this.DVal + a.DVal);
  Number operator -(Number a) => Number(this.DVal - a.DVal);
  Number operator -() => Number(-this.DVal);
  Number operator *(Number b) => Number(this.DVal * b.DVal);
  Number operator /(Number b) => Number(this.DVal / b.DVal);
  Number operator %(Number b) => Number(this.DVal % b.DVal);
}
