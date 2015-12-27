package net.rezmason.hypertype.core;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.Program;
import net.rezmason.math.Vec3;
import net.rezmason.utils.santa.Present;

class RenderMethod {

    public var program(default, null):Program;
    public var backgroundColor(default, null):Vec3;
    var glSys:GLSystem;
    var vertShader:String;
    var fragShader:String;

    function new():Void {
        backgroundColor = new Vec3(0, 0, 0);
        composeShaders();
        glSys = new Present(GLSystem);
        program = glSys.createProgram(vertShader, fragShader);
    }

    public inline function start(outputBuffer:OutputBuffer):Void {
        activate();
        glSys.start(outputBuffer);
        glSys.clear(backgroundColor.r, backgroundColor.g, backgroundColor.b);
    }

    public inline function finish():Void {
        setSegment(null);
        deactivate();
        glSys.finish();
    }

    function activate():Void {}
    function deactivate():Void {}
    function setBody(body:Body):Void { }

    public function drawBody(body:Body):Void {
        setBody(body);
        for (segment in body.segments) {
            setSegment(segment);
            glSys.draw(segment.indexBuffer, 0, segment.numGlyphs * Almanac.TRIANGLES_PER_GLYPH);
        }
    }

    public function setSegment(segment:BodySegment):Void { }

    function composeShaders():Void { }
    function makeVertexShader():String { return ''; }
    function makeFragmentShader():String { return ''; }
}

