package net.rezmason.gl;

typedef AttribsLocation = #if ogl Int #end ;
typedef UniformLocation = #if ogl lime.graphics.opengl.GLUniformLocation #end ;

typedef NativeVertexBuffer = #if ogl lime.graphics.opengl.GLBuffer #end ;
typedef NativeIndexBuffer = #if ogl lime.graphics.opengl.GLBuffer #end ;
typedef NativeProgram = #if ogl lime.graphics.opengl.GLProgram #end ;
typedef NativeTexture = #if ogl lime.graphics.opengl.GLTexture #end ;
typedef NativeFramebuffer = #if ogl lime.graphics.opengl.GLFramebuffer #end ;

typedef Context = #if ogl Class<lime.graphics.opengl.GL> #end ;
typedef Rectangle = lime.math.Rectangle;
typedef Image = lime.graphics.Image;
typedef Data = lime.utils.ArrayBufferView;
typedef Vector4 = #if ogl lime.math.Vector4 #end ;


private typedef _Matrix4 = #if ogl lime.math.Matrix4 #end ;
@:forward
abstract Matrix4(_Matrix4) {
    public var rawData(get, set):Array<Float>;
    public inline function new() this = new _Matrix4();
    @:to public inline function toMat() return this;
    
    inline function get_rawData():Array<Float> {
        #if ogl
            return [for (ike in 0...16) this[ike]];
        #end
    }

    inline function set_rawData(array:Array<Float>) {
        #if ogl
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
