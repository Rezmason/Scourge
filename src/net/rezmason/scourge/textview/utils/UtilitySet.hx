package net.rezmason.scourge.textview.utils;

import flash.display.Stage;
import openfl.display.OpenGLView;

class UtilitySet {

    public var textureUtil(default, null):TextureUtil;
    public var drawUtil(default, null):DrawUtil;
    public var programUtil(default, null):ProgramUtil;
    public var bufferUtil(default, null):BufferUtil;

    public function new(stage:Stage, cbk:Void->Void):Void {

        var view:OpenGLView;

        if (OpenGLView.isSupported) {
            view = new OpenGLView();
            stage.addChildAt(view, 0);

            textureUtil = new TextureUtil(view);
            drawUtil = new DrawUtil(view);
            programUtil = new ProgramUtil(view);
            bufferUtil = new BufferUtil(view);

            cbk();

        } else {
            trace("OpenGLView isn't supported.");
        }
    }

}
