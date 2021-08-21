package nuke;

abstract Value(String) to String from String {
  @:from public inline static function compound(values:Array<Value>) {
    return new Value(values.join(' '));
  }

  public inline static function list(values:Array<Value>) {
    return new Value(values.join(', '));
  }

  @:from public inline static function ofInt(value:Int) {
    return new Value(Std.string(value));
  }

  @:from public inline static function ofFloat(value:Float) {
    return new Value(Std.string(value));
  }

  @:op(A+B)
  public function add(b:Value) {
    return new Value('cacl(${this} + $b)');
  }

  @:op(A-B)
  public function sub(b:Value) {
    return new Value('cacl(${this} - $b)');
  }
  
  @:op(A*B)
  public function mult(b:Value) {
    return new Value('cacl(${this} * $b)');
  }

  @:op(A/B)
  public function div(b:Value) {
    return new Value('cacl(${this} / $b)');
  }
  
  public inline function new(value) {
    this = value;
  }
}
