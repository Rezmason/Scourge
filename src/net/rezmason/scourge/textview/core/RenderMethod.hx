package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

import net.rezmason.gl.GLSystem;
import net.rezmason.gl.Program;

class RenderMethod {

    inline static var GLYPH_MAG_LIMIT:Float = 0.7;
    static var unitVec:Vector3D = new Vector3D(1, 0, 0);

    public var program(default, null):Program;
    public var programLoaded(get, null):Bool;
    public var backgroundColor(default, null):Int;
    public var loadedSignal(default, null):Zig<Void->Void>;
    var glSys:GLSystem;
    var glyphMat:Matrix3D;
    var glyphMag:Float;
    var vertShader:String;
    var fragShader:String;

    function new():Void {
        loadedSignal = new Zig();
        glyphMag = 1;
        backgroundColor = 0x0;
        glyphMat = new Matrix3D();
        composeShaders();
        glSys = new Present(GLSystem);
    }

    public function load():Void {
        if (program == null) program = glSys.createProgram(vertShader, fragShader);
        if (program.loaded) onProgramLoaded();
        else program.onLoad = onProgramLoaded;
    }

    function onProgramLoaded():Void loadedSignal.dispatch();

    public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void { }
    public function activate():Void { }
    public function deactivate():Void { }

    public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        glyphMat.identity();
        glyphMat.append(glyphTransform);
        glyphMat.appendScale(glyphMag, glyphMag, 1);

        /*
        #if debug
            if (glyphMat.transformVector(unitVec).length > GLYPH_MAG_LIMIT) throw 'You blew the glyph mag fuse!';
        #end
        */
    }

    public function setSegment(segment:BodySegment):Void { }

    function composeShaders():Void { }
    function makeVertexShader():String { return ''; }
    function makeFragmentShader():String { return ''; }

    inline function get_programLoaded():Bool return program != null && program.loaded;
}

