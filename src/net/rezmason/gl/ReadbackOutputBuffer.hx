package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

#if ogl
    import lime.graphics.opengl.GL;
#end

class ReadbackOutputBuffer extends OutputBuffer {

    #if ogl
        var texture:BufferTexture;
    #end

    function new():Void {
        super();
        #if ogl
            texture = new BufferTexture(UNSIGNED_BYTE);
        #end
    }

    override function connectToContext(context:Context):Void {
        super.connectToContext(context);
        #if ogl
            texture.connectToContext(context);
        #end
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if ogl
            texture.disconnectFromContext();
        #end
    }

    override public function resize(width:Int, height:Int):Bool {

        if (!super.resize(width, height)) return false;

        #if ogl
            texture.resize(width, height);
        #end

        return true;
    }

    public inline function createReadbackData():ReadbackData {
        return new ReadbackData(#if ogl width * height * 4 #end);
    }

    public inline function readBack(outputBuffer:OutputBuffer, data:ReadbackData):Void {
        #if ogl
            GL.bindFramebuffer(GL.FRAMEBUFFER, texture.frameBuffer);
            GL.readPixels(0, 0, width, height, GL.RGBA, texture.format, data);
        #end
    }

    override function activate():Void {
        #if ogl
            GL.bindFramebuffer(GL.FRAMEBUFFER, texture.frameBuffer);
        #end
    }
}
