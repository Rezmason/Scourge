package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.TextureFormat;

#if ogl
    import lime.graphics.opengl.GL;
    import lime.graphics.PixelFormat;
#end

class DataTexture extends Texture {

    public var data(default, null):Data;
    public var width:Int = -1;
    public var height:Int = -1;
    
    public function new(width:Int, height:Int, format:TextureFormat, data:Data):Void {
        super();
        this.width = width;
        this.height = height;
        this.format = format;
        this.data = data;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if ogl
            nativeTexture = GL.createTexture();
            GL.getExtension('OES_texture_float');
            GL.getExtension('OES_texture_float_linear');
        #end
        update();
    }

    inline function update():Void {
        var sizeChanged = nativeTexture == null;
        if (isConnectedToContext()) {
            #if ogl
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
        nativeTexture = null;
    }
}
