package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

import net.rezmason.gl.utils.ProgramUtil;
import net.rezmason.gl.Program;

class RenderMethod {

    inline static var GLYPH_MAG_LIMIT:Float = 0.7;
    static var unitVec:Vector3D = new Vector3D(1, 0, 0);

    public var program(default, null):Program;
    public var backgroundColor(default, null):Int;
    public var loadedSignal(default, null):Zig<Void->Void>;
    var programUtil:ProgramUtil;
    var glyphMat:Matrix3D;
    var glyphMag:Float;
    var vertShader:String;
    var fragShader:String;

    function new():Void {
        loadedSignal = new Zig<Void->Void>();
    }

    public function load():Void {
        programUtil = new Present(ProgramUtil);

        init();
        composeShaders();

        programUtil.loadProgram(vertShader, fragShader, onProgramLoaded);
    }

    function onProgramLoaded(program:Program):Void {
        this.program = program;
        connectToShaders();
        loadedSignal.dispatch();
    }

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

    function init():Void {
        glyphMag = 1;
        backgroundColor = 0x0;
        glyphMat = new Matrix3D();
    }

    function composeShaders():Void { }
    function connectToShaders():Void { }
    function makeVertexShader():String { return ''; }
    function makeFragmentShader():String { return ''; }
}

