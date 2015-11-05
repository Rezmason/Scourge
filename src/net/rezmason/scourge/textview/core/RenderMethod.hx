package net.rezmason.scourge.textview.core;

import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.OutputBuffer;
import net.rezmason.gl.Program;

class RenderMethod {

    public var program(default, null):Program;
    public var programLoaded(get, null):Bool;
    public var backgroundColor(default, null):Vec3;
    public var loadedSignal(default, null):Zig<Void->Void>;
    var glSys:GLSystem;
    var vertShader:String;
    var fragShader:String;

    function new():Void {
        loadedSignal = new Zig();
        backgroundColor = new Vec3(0, 0, 0);
        composeShaders();
        glSys = new Present(GLSystem);
    }

    public function load():Void {
        if (program == null) program = glSys.createProgram(vertShader, fragShader);
        if (program.loaded) onProgramLoaded();
        else program.onLoad = onProgramLoaded;
    }

    function onProgramLoaded():Void loadedSignal.dispatch();

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

    inline function get_programLoaded():Bool return program != null && program.loaded;
}

