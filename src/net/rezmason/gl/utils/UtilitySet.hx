package net.rezmason.gl.utils;

import flash.display.Stage;

#if flash
    import flash.events.Event;
#else
    import openfl.gl.GL;
#end

import net.rezmason.gl.utils.Util;

class UtilitySet {

    public var textureUtil(default, null):TextureUtil;
    public var drawUtil(default, null):DrawUtil;
    public var programUtil(default, null):ProgramUtil;
    public var bufferUtil(default, null):BufferUtil;

    var cbk:Void->Void;
    var view:View;
    var context:Context;

    public function new(stage:Stage, cbk:Void->Void):Void {
        this.cbk = cbk;

        #if flash
            view = stage;
            var stage3D = view.stage3Ds[0];
            if (stage3D.context3D != null) {
                context = stage3D.context3D;
                init();
            } else {
                stage3D.addEventListener(Event.CONTEXT3D_CREATE, onCreate);
                stage3D.requestContext3D();
            }
        #else
            if (View.isSupported) {
                view = new ReadbackView();
                context = GL;
                stage.addChild(view);
                init();
            } else {
                trace('OpenGLView isn\'t supported.');
            }
        #end
    }

    #if flash
        function onCreate(event:Event):Void {
            event.target.removeEventListener(Event.CONTEXT3D_CREATE, onCreate);
            context = view.stage3Ds[0].context3D;
            init();
        }
    #end

    function init():Void {

        var cbk:Void->Void = this.cbk;
        this.cbk = null;

        textureUtil = new TextureUtil(view, context);
        drawUtil = new DrawUtil(view, context);
        programUtil = new ProgramUtil(view, context);
        bufferUtil = new BufferUtil(view, context);

        haxe.Timer.delay(cbk, 0);
    }
}

#if !flash
    class ReadbackView extends View {
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
#end
