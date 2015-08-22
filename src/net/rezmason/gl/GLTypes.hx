package net.rezmason.gl;

typedef ReadbackData = #if js lime.utils.UInt8Array #elseif flash flash.utils.ByteArray #else lime.utils.UInt8Array #end ;

typedef IndexArray = #if flash flash.Vector<UInt> #else lime.utils.Int16Array #end ;
typedef VertexArray = #if flash flash.Vector<Float> #else lime.utils.Float32Array #end ;

typedef AttribsLocation = #if flash Int #else Int #end ;
typedef UniformLocation = #if flash Int #else lime.graphics.opengl.GLUniformLocation #end ;

typedef NativeVertexBuffer = #if flash flash.display3D.VertexBuffer3D #else lime.graphics.opengl.GLBuffer #end ;
typedef NativeIndexBuffer = #if flash flash.display3D.IndexBuffer3D #else lime.graphics.opengl.GLBuffer #end ;
typedef NativeProgram = #if flash net.rezmason.gl.glsl2agal.Program #else lime.graphics.opengl.GLProgram #end ;
typedef NativeTexture = #if flash flash.display3D.textures.TextureBase #else lime.graphics.opengl.GLTexture #end;

typedef Context = #if flash flash.display3D.Context3D #else Class<lime.graphics.opengl.GL> #end ;
typedef Rectangle = lime.math.Rectangle;
typedef Image = lime.graphics.Image;
typedef Vector4 = #if flash flash.geom.Vector3D #else lime.math.Vector4 #end ;
private typedef _Matrix4 = #if flash flash.geom.Matrix3D #else lime.math.Matrix4 #end ;

@:forward
abstract Matrix4(_Matrix4) {
    public var rawData(get, set):Array<Float>;
    public inline function new() this = new _Matrix4();
    @:to public inline function toMat() return this;
    
    inline function get_rawData():Array<Float> {
        #if flash
            return [for (val in this.rawData) val];
        #else
            return [for (ike in 0...16) this[ike]];
        #end
    }

    inline function set_rawData(array:Array<Float>) {
        #if flash
            this.rawData = flash.Vector.ofArray(cast array);
        #else
            this.copythisFrom(new lime.utils.Float32Array(array));
        #end
        return array;
    }

    inline function assignMat(mat:_Matrix4) this = mat;
    public inline function clone() {
        var other = new Matrix4();
        other.assignMat(this.clone());
        return other;
    }
}
