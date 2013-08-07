package net.rezmason.scourge.textview;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.scourge.textview.core.Renderer;
import net.rezmason.scourge.textview.rendermethods.PrettyMethod;
import net.rezmason.utils.FlatFont;

class BasicSetup {

    static var UNIT_RECT:Rectangle = new Rectangle(0, 0, 1, 1);

    var stage:Stage;
    var width:Int;
    var height:Int;
    var utils:UtilitySet;

    var glyphTexture:GlyphTexture;

    var prettyMethod:RenderMethod;
    var renderer:Renderer;
    var mainOutputBuffer:OutputBuffer;

    var body:Body;
    var bodyMat:Matrix3D;

    var t:Float;

    public function new(utils:UtilitySet, stage:Stage, fonts:Map<String, FlatFont>):Void {
        this.utils = utils;
        this.stage = stage;
        this.glyphTexture = new GlyphTexture(utils.textureUtil, fonts['full']);

        prettyMethod = new PrettyMethod();
        prettyMethod.load(utils.programUtil, initScene);
    }

    function initScene():Void {
        renderer = new Renderer(utils.drawUtil);
        mainOutputBuffer = utils.drawUtil.getMainOutputBuffer();
        body = new TestBody(0, utils.bufferUtil, glyphTexture, null);
        bodyMat = body.transform;
        onResize();
        t = 0;
        utils.drawUtil.addRenderCall(onRender);
    }

    function onRender(width:Int, height:Int):Void {

        update();

        if (this.width == -1 || this.width != width || this.height == -1 || this.height != height) {
            this.width = width;
            this.height = height;
            onResize();
        }

        renderer.render([body], prettyMethod, mainOutputBuffer);
    }

    function onResize(?event:Event):Void {
        var width:Int = stage.stageWidth;
        var height:Int = stage.stageHeight;

        body.adjustLayout(width, height, UNIT_RECT);
        body.glyphTransform.appendScale(0.8, 0.8, 1);
        mainOutputBuffer.resize(width, height);
    }

    function update():Void {

        t += 0.1;

        bodyMat.identity();
        bodyMat.appendRotation(t * 0.010 * 360, Vector3D.Z_AXIS);
        bodyMat.appendRotation(    0.125 * 360, Vector3D.X_AXIS);
        bodyMat.appendRotation(    0.875 * 360, Vector3D.Z_AXIS);

        bodyMat.appendTranslation(0, 0, 0.5);

        body.update(0.02);
    }
}
