package net.rezmason.scourge.textview.nmedemo;

import flash.display.Shape;
import flash.display.BitmapData;
import flash.geom.Matrix3D;

import openfl.gl.GL;

class ColourBlend extends ProgramPosTexExtra
{
   var bmp:BitmapData;
   var uProj:Dynamic;
   var uMV:Dynamic;

   public function new()
   {
      var vertShader =
        "attribute vec2 aPos;" +
        "attribute vec4 aVertexColor;" +
        "attribute vec2 aTexCoord;" +
        "uniform mat4 uProj;" +
        "uniform mat4 uMV;" +
        "varying vec4 vColor;" +
        "varying vec2 vTexCoord;" +
        "void main() {" +
        " gl_Position = uProj * uMV * vec4(aPos, 0.0, 1.0);" +
        " vColor = aVertexColor;" +
        " vTexCoord = aTexCoord;" +
        "}";

      var fragShader = // - not on desktop ?
	  #if !desktop
	  'precision mediump float;' +
	  #end
        "varying vec4 vColor;" +
        "varying vec2 vTexCoord;" +
        "uniform sampler2D uSampler;" +
        "void main() {" +
        "gl_FragColor = vColor * texture2D(uSampler, vTexCoord);"+
        "}";

      super(vertShader,"aPos","aTexCoord","aVertexColor", fragShader,"uSampler");

      uProj = GL.getUniformLocation(prog, "uProj");
      uMV = GL.getUniformLocation(prog, "uMV");
   }

   public function setTransform(inProj:Matrix3D, inMv:Matrix3D)
   {
      GL.useProgram(prog);
      GL.uniformMatrix3D(uProj, false, inProj );
      GL.uniformMatrix3D(uMV  , false, inMv );
   }

   override public function createTexture()
   {
      bmp = new BitmapData(64,64,false,0xffffffff);
   }
   override public function fillTexture()
   {
      var shape = new Shape();
      var gfx = shape.graphics;
      gfx.beginFill(0xff0000);
      gfx.drawCircle(32,32,30);
      bmp.draw(shape);
   }
   override public function bindTexture() { GL.bindBitmapDataTexture(bmp); }

}
