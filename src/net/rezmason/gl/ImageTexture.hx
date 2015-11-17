package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.TextureFormat;

#if !flash
    import lime.graphics.opengl.GL;
    import lime.graphics.PixelFormat;
#end

class ImageTexture extends Texture {

    public var image(default, null):Image;
    var width:Int = -1;
    var height:Int = -1;
    var nativeTexture:NativeTexture;

    public function new(image:Image):Void {
        super();
        this.image = image;
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if !flash
            nativeTexture = GL.createTexture();
        #end
        update();
    }

    public inline function update():Void {
        var sizeChanged = nativeTexture == null || width != image.width || height != image.height;
        width = image.width;
        height = image.height;
        if (isConnectedToContext()) {
            #if flash
                if (sizeChanged) {
                    if (nativeTexture != null) nativeTexture.dispose();
                    nativeTexture = context.createRectangleTexture(width, height, cast TextureFormat.FLOAT, false);
                }
                var bmd = @:privateAccess image.buffer.__srcBitmapData;
                (cast nativeTexture).uploadFromBitmapData(bmd);
            #else
                image.data;
                GL.bindTexture(GL.TEXTURE_2D, nativeTexture);
                // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
                
                image.format = PixelFormat.RGBA32;
                GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, image.width, image.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, image.data);
                
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
        width = -1;
        height = -1;
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
