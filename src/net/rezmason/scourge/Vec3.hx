package net.rezmason.scourge;

@:forward(r, g, b)
abstract Vec3({r:Float, g:Float, b:Float}) {
    public inline function new(r:Float, g:Float, b:Float) this = {r:r, g:g, b:b};

    public var x(get, set):Float;
    public var y(get, set):Float;
    public var z(get, set):Float;

    public inline function copy() return new Vec3(this.r, this.g, this.b);

    public inline function copyFrom(other:Vec3) {
        set_x(other.x);
        set_y(other.y);
        set_z(other.z);
    }

    inline function get_x() return this.r;
    inline function set_x(val) return this.r = val;

    inline function get_y() return this.g;
    inline function set_y(val) return this.g = val;

    inline function get_z() return this.b;
    inline function set_z(val) return this.b = val;

    @:op(A * B) public inline function multFloat(rhs:Float):Vec3 return new Vec3(this.r * rhs, this.g * rhs, this.b * rhs);
    @:op(A / B) public inline function  divFloat(rhs:Float):Vec3 return new Vec3(this.r / rhs, this.g / rhs, this.b / rhs);
    @:op(A + B) public inline function  addFloat(rhs:Float):Vec3 return new Vec3(this.r + rhs, this.g + rhs, this.b + rhs);
    @:op(A - B) public inline function  subFloat(rhs:Float):Vec3 return new Vec3(this.r - rhs, this.g - rhs, this.b - rhs);

    @:op(A * B) public inline function multVec3(rhs:Vec3):Vec3 return new Vec3(this.r * rhs.r, this.g * rhs.g, this.b * rhs.b);
    @:op(A / B) public inline function  divVec3(rhs:Vec3):Vec3 return new Vec3(this.r / rhs.r, this.g / rhs.g, this.b / rhs.b);
    @:op(A + B) public inline function  addVec3(rhs:Vec3):Vec3 return new Vec3(this.r + rhs.r, this.g + rhs.g, this.b + rhs.b);
    @:op(A - B) public inline function  subVec3(rhs:Vec3):Vec3 return new Vec3(this.r - rhs.r, this.g - rhs.g, this.b - rhs.b);

    @:op(-A) public inline static function inverse(v:Vec3) return new Vec3(-v.r, -v.g, -v.b);

    public inline static function fromHex(hex:Int):Vec3 {
        return new Vec3((hex >> 16 & 0xFF) / 0xFF, (hex >> 8  & 0xFF) / 0xFF, (hex >> 0  & 0xFF) / 0xFF);
    }
}
