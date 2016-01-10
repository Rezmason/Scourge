package net.rezmason.gl;

typedef AttribsLocation = Int;
typedef UniformLocation = lime.graphics.opengl.GLUniformLocation;

typedef NativeVertexBuffer = lime.graphics.opengl.GLBuffer;
typedef NativeIndexBuffer = lime.graphics.opengl.GLBuffer;
typedef NativeProgram = lime.graphics.opengl.GLProgram;
typedef NativeTexture = lime.graphics.opengl.GLTexture;
typedef NativeFramebuffer = lime.graphics.opengl.GLFramebuffer;

typedef Context = Class<lime.graphics.opengl.GL>;
typedef Rectangle = lime.math.Rectangle;
typedef Image = lime.graphics.Image;
typedef Data = lime.utils.ArrayBufferView;
typedef Vector4 = lime.math.Vector4;


private typedef _Matrix4 = lime.math.Matrix4;
@:forward
abstract Matrix4(_Matrix4) {
    public var rawData(get, set):Array<Float>;
    public inline function new() this = new _Matrix4();
    @:to public inline function toMat() return this;
    
    inline function get_rawData():Array<Float> {
        return [for (ike in 0...16) this[ike]];
    }

    inline function set_rawData(array:Array<Float>) {
        this.copythisFrom(new lime.utils.Float32Array(array));
        return array;
    }

    inline function assignMat(mat:_Matrix4) this = mat;
    public inline function clone() {
        var other = new Matrix4();
        other.assignMat(this.clone());
        return other;
    }
}
