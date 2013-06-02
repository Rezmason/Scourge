package net.rezmason.scourge.textview;

import flash.geom.Matrix3D;
import net.rezmason.scourge.textview.core.*;
import net.rezmason.scourge.textview.rendermethods.*;
import net.rezmason.scourge.textview.utils.UtilitySet;


class HappyPlace {

    var utils:UtilitySet;

    var bodies:Array<Body>;
    var testBody:Body;
    var prettyMethod:RenderMethod;
    var renderer:Renderer;

    function bonk():Void {};

    public function new(utils:UtilitySet, glyphTexture:GlyphTexture):Void {

        this.utils = utils;

        bodies = [];

        testBody = new TestBody(1, utils.bufferUtil, glyphTexture, bonk);
        prettyMethod = new PrettyMethod(utils.programUtil);
        renderer = new Renderer(utils.drawUtil, null);
        bodies.push(testBody);

        testBody.transform.identity();
        testBody.transform.appendScale(2, 2, 1);
        testBody.transform.appendTranslation(0, 0, 1.5);

        testBody.glyphTransform = new Matrix3D();
        testBody.glyphTransform.appendTranslation(-0.5, -0.5, 0);
        testBody.glyphTransform.appendScale(0.02, 0.02, 1);
    }

    public function render(w:Int, h:Int):Void {
        testBody.update(0.1);
        renderer.setSize(w, h);
        renderer.render(bodies, prettyMethod, RenderDestination.SCREEN);
    }
}
