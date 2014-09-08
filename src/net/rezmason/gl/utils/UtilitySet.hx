package net.rezmason.gl.utils;

import flash.display.Stage;
import flash.geom.Rectangle;

import net.rezmason.gl.GLTypes;

#if flash
    import flash.events.Event;
    import flash.display3D.Context3DRenderMode;
    import flash.display3D.Context3DProfile;
#else
    import openfl.gl.GL;
#end

using Lambda;

class UtilitySet {

    public var textureUtil(default, null):TextureUtil;
    public var drawUtil(default, null):DrawUtil;
    public var programUtil(default, null):ProgramUtil;
    public var bufferUtil(default, null):BufferUtil;

    public var onRender:Int->Int->Void;

    var cbk:Void->Void;
    var view:View;
    var context:Context;
    #if flash var stageRect:Rectangle; #end

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
                stage3D.requestContext3D(cast Context3DRenderMode.AUTO, cast "standard"); // Context3DProfile.STANDARD
            }
        #else
            if (View.isSupported) {
                view = new View();
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

        #if flash
            stageRect = new Rectangle(0, 0, 1, 1);
            view.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            view.addEventListener(Event.RESIZE, onResize);
        #else
            view.render = handleRender;
        #end

        haxe.Timer.delay(cbk, 0);
    }

    function handleRender(rect:Rectangle):Void {
        if (onRender != null) onRender(Std.int(rect.width), Std.int(rect.height));
    }

    #if flash
        function onResize(event:Event):Void {
            stageRect.width = view.stageWidth;
            stageRect.height = view.stageHeight;
        }

        function onEnterFrame(event:Event):Void {
            handleRender(stageRect);
        }
    #end
}
