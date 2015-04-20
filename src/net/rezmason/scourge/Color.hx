package net.rezmason.scourge;

@:forward(r, g, b)
abstract Color({r:Float, g:Float, b:Float}) {
    public function new(r:Float, g:Float, b:Float) this = {r:r, g:g, b:b};

    @:op(A * B) public inline function multFloat(rhs:Float):Color return new Color(this.r * rhs, this.g * rhs, this.b * rhs);
    @:op(A / B) public inline function  divFloat(rhs:Float):Color return new Color(this.r / rhs, this.g / rhs, this.b / rhs);
    @:op(A + B) public inline function  addFloat(rhs:Float):Color return new Color(this.r + rhs, this.g + rhs, this.b + rhs);
    @:op(A - B) public inline function  subFloat(rhs:Float):Color return new Color(this.r - rhs, this.g - rhs, this.b - rhs);

    @:op(A * B) public inline function multColor(rhs:Color):Color return new Color(this.r * rhs.r, this.g * rhs.g, this.b * rhs.b);
    @:op(A / B) public inline function  divColor(rhs:Color):Color return new Color(this.r / rhs.r, this.g / rhs.g, this.b / rhs.b);
    @:op(A + B) public inline function  addColor(rhs:Color):Color return new Color(this.r + rhs.r, this.g + rhs.g, this.b + rhs.b);
    @:op(A - B) public inline function  subColor(rhs:Color):Color return new Color(this.r - rhs.r, this.g - rhs.g, this.b - rhs.b);

    public inline static function fromHex(rgb:Int):Color {
        return new Color((rgb >> 16 & 0xFF) / 0xFF, (rgb >> 8  & 0xFF) / 0xFF, (rgb >> 0  & 0xFF) / 0xFF);
    }
}
