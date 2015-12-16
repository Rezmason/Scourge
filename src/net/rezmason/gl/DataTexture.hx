package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.TextureFormat;

#if !flash
    import lime.graphics.opengl.GL;
    import lime.graphics.PixelFormat;
#end

class DataTexture extends Texture {

    public var data(default, null):Data;
    public var width:Int = -1;
    public var height:Int = -1;
    var nativeTexture:NativeTexture;
    var format:TextureFormat;

    public function new(width:Int, height:Int, format:TextureFormat, data:Data):Void {
        super();
        this.width = width;
        this.height = height;
        this.format = format;
        this.data = data;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if !flash
            nativeTexture = GL.createTexture();
        #end
        update();
    }

    inline function update():Void {
        var sizeChanged = nativeTexture == null;
        if (isConnectedToContext()) {
            #if flash
                if (sizeChanged) {
                    if (nativeTexture != null) nativeTexture.dispose();
                    nativeTexture = context.createRectangleTexture(width, height, cast TextureFormat.FLOAT, false);
                }
                (cast nativeTexture).uploadFromByteArray(data.getData(), 0);
            #else
                GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
                // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                
                GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, format, data);
                
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.bindTexture(GL.TEXTURE_2D, null);
            #end
        }
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash nativeTexture.dispose(); #end
        nativeTexture = null;
    }

    override function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {
        if (index != -1) {
            #if flash
                prog.setTextureAt(location, nativeTexture);
            #else
                GL.activeTexture(GL.TEXTURE0 + index);
                GL.uniform1i(location, index);
                GL.bindTexture (GL.TEXTURE_2D, nativeTexture);
            #end
        }
    }
}
