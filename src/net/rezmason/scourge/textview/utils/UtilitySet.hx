package net.rezmason.scourge.textview.utils;

import nme.display.BitmapData;
import nme.display.Stage3D;
import nme.display3D.Context3D;
import nme.display3D.Context3DTextureFormat;
import nme.display3D.textures.Texture;
import nme.events.Event;
import nme.geom.Matrix;

class UtilitySet {

    var stage3D:Stage3D;
    var context:Context3D;
    var cbk:Void->Void;

    public var textureUtil(default, null):TextureUtil;
    public var drawUtil(default, null):DrawUtil;
    public var programUtil(default, null):ProgramUtil;
    public var bufferUtil(default, null):BufferUtil;

    public function new(stage3D:Stage3D, cbk:Void->Void):Void {
        this.cbk = cbk;
        this.stage3D = stage3D;

        if (stage3D.context3D != null) {
            onCreate();
        } else {
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
            stage3D.requestContext3D();
        }
    }

    function onCreate(?event:Event):Void {
        stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);
        context = stage3D.context3D;

        var cbk:Void->Void = this.cbk;
        this.cbk = null;

        textureUtil = new TextureUtil(context);
        drawUtil = new DrawUtil(context);
        programUtil = new ProgramUtil(context);
        bufferUtil = new BufferUtil(context);

        cbk();
    }

}
