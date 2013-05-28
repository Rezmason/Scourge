package net.rezmason.scourge.textview.nmedemo;

import openfl.gl.GL;
import openfl.utils.Float32Array;

class ProgramPosTexExtra extends ProgramPosTex
{
   var extraLocation:Dynamic;
   var extraBuffer:Dynamic;
   public var extraDims:Int;

   public function new(vertShader:String, posName:String, texName, extraName:String, fragShader:String, samplerName:String )
   {
      super(vertShader,posName, texName,fragShader,samplerName);
      extraLocation = GL.getAttribLocation(prog, extraName);
      extraDims = 4;
   }

   public function setExtra( extra:Array<Float>, dim:Int )
   {
      extraDims = dim;
      if (extraBuffer==null)
         extraBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, extraBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(extra), GL.STATIC_DRAW);
   }


   override public function render()
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, posDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.vertexAttribPointer(texLocation, texDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, extraBuffer);
      GL.vertexAttribPointer(extraLocation, extraDims, GL.FLOAT, false, 0, 0);

      GL.activeTexture(GL.TEXTURE0);
      bindTexture();
      GL.uniform1i(samplerLocation, 0);

      GL.enableVertexAttribArray(posLocation);
      GL.enableVertexAttribArray(texLocation);
      GL.enableVertexAttribArray(extraLocation);
      GL.drawArrays(type, 0, primCount);
      GL.disableVertexAttribArray(texLocation);
      GL.disableVertexAttribArray(posLocation);
      GL.disableVertexAttribArray(extraLocation);
   }

}
