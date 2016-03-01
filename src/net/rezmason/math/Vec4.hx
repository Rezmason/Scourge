package net.rezmason.math;

@:forward(x, y, z, w)
abstract Vec4({x:Float, y:Float, z:Float, w:Float}) {
    public inline function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) this = {x:x, y:y, z:z, w:w};

    public var r(get, set):Float;
    public var g(get, set):Float;
    public var b(get, set):Float;
    public var a(get, set):Float;

    public inline function copy() return new Vec4(this.x, this.y, this.z, this.w);

    public inline function copyFrom(other:Vec4) {
        set_r(other.r);
        set_g(other.g);
        set_b(other.b);
        set_a(other.a);
    }

    inline function get_r() return this.x;
    inline function set_r(val) return this.x = val;
    inline function get_g() return this.y;
    inline function set_g(val) return this.y = val;
    inline function get_b() return this.z;
    inline function set_b(val) return this.z = val;
    inline function get_a() return this.w;
    inline function set_a(val) return this.w = val;

    @:op(A * B) public inline function multFloat(rhs:Float):Vec4 return new Vec4(this.x * rhs, this.y * rhs, this.z * rhs, this.w * rhs);
    @:op(A / B) public inline function  divFloat(rhs:Float):Vec4 return new Vec4(this.x / rhs, this.y / rhs, this.z / rhs, this.w / rhs);
    @:op(A + B) public inline function  addFloat(rhs:Float):Vec4 return new Vec4(this.x + rhs, this.y + rhs, this.z + rhs, this.w + rhs);
    @:op(A - B) public inline function  subFloat(rhs:Float):Vec4 return new Vec4(this.x - rhs, this.y - rhs, this.z - rhs, this.w - rhs);

    @:op(A * B) public inline function multVec4(rhs:Vec4):Vec4 return new Vec4(this.x * rhs.x, this.y * rhs.y, this.z * rhs.z, this.w * rhs.w);
    @:op(A / B) public inline function  divVec4(rhs:Vec4):Vec4 return new Vec4(this.x / rhs.x, this.y / rhs.y, this.z / rhs.z, this.w / rhs.w);
    @:op(A + B) public inline function  addVec4(rhs:Vec4):Vec4 return new Vec4(this.x + rhs.x, this.y + rhs.y, this.z + rhs.z, this.w + rhs.w);
    @:op(A - B) public inline function  subVec4(rhs:Vec4):Vec4 return new Vec4(this.x - rhs.x, this.y - rhs.y, this.z - rhs.z, this.w - rhs.w);

    @:op(-A) public inline static function inverse(v:Vec4) return new Vec4(-v.x, -v.y, -v.z, -v.w);

    #if lime @:to public function toVector4() return new lime.math.Vector4(this.x, this.y, this.z, this.w); #end

    public inline static function fromHex(hex:UInt):Vec4 {
        return new Vec4(
            (hex >> 16 & 0xFF) / 0xFF, 
            (hex >> 8  & 0xFF) / 0xFF, 
            (hex >> 0  & 0xFF) / 0xFF, 
            (hex >> 24 & 0xFF) / 0xFF
        );
    }
}
