package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Vector3D;

import net.rezmason.gl.utils.ProgramUtil;
import net.rezmason.gl.Program;

class RenderMethod {

    inline static var GLYPH_MAG_LIMIT:Float = 0.7;
    static var unitVec:Vector3D = new Vector3D(1, 0, 0);

    public var program(default, null):Program;
    public var backgroundColor(default, null):Int;
    var programUtil:ProgramUtil;
    var glyphMat:Matrix3D;
    var glyphMag:Float;
    var vertShader:String;
    var fragShader:String;

    var onLoaded:Void->Void;

    public function new():Void {}

    public function load(programUtil:ProgramUtil, onLoaded:Void->Void):Void {
        this.programUtil = programUtil;
        this.onLoaded = onLoaded;

        init();
        composeShaders();

        programUtil.loadProgram(vertShader, fragShader, onProgramLoaded);
    }

    function onProgramLoaded(program:Program):Void {
        this.program = program;
        connectToShaders();
        this.onLoaded();
        this.onLoaded = null;
    }

    public function setMatrices(cameraMat:Matrix3D, bodyMat:Matrix3D):Void { }
    public function activate():Void { }
    public function deactivate():Void { }

    public function setGlyphTexture(glyphTexture:GlyphTexture, glyphTransform:Matrix3D):Void {
        glyphMat.identity();
        glyphMat.append(glyphTexture.matrix);
        glyphMat.append(glyphTransform);
        glyphMat.appendScale(glyphMag, glyphMag, 1);

        #if debug
            if (glyphMat.transformVector(unitVec).length > GLYPH_MAG_LIMIT) throw 'You blew the glyph mag fuse!';
        #end
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

