package net.rezmason.gl.utils;

import flash.display.Stage;
import openfl.display.OpenGLView;
import openfl.gl.GL;

class UtilitySet {

    public var textureUtil(default, null):TextureUtil;
    public var drawUtil(default, null):DrawUtil;
    public var programUtil(default, null):ProgramUtil;
    public var bufferUtil(default, null):BufferUtil;

    public function new(stage:Stage, cbk:Void->Void):Void {

        var view:OpenGLView;

        if (OpenGLView.isSupported) {
            view = new OpenGLView();
            stage.addChild(view);

            textureUtil = new TextureUtil(view);
            drawUtil = new DrawUtil(view);
            programUtil = new ProgramUtil(view);
            bufferUtil = new BufferUtil(view);

            haxe.Timer.delay(cbk, 0);

        } else {
            trace("OpenGLView isn't supported.");
        }
    }

}

class ReadbackOpenGLView extends OpenGLView {
    public function new():Void {
        super();

        #if js
        if (nmeGraphics != null) {
            nmeContext = nmeGraphics.nmeSurface.getContextWebGL({ preserveDrawingBuffer: true });
            #if debug
            nmeContext = untyped WebGLDebugUtils.makeDebugContext(nmeContext);
            #end
        }
        GL.nmeContext = nmeContext;
        #end
    }
}
