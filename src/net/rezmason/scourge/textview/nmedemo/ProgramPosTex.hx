package net.rezmason.scourge.textview.nmedemo;

import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLTexture;
import openfl.utils.UInt8Array;
import openfl.utils.Float32Array;
import openfl.utils.ArrayBuffer;

class ProgramPosTex
{
   var prog:GLProgram;

   var posLocation:Dynamic;
   var texLocation:Dynamic;
   var primCount:Int;
   var type:Int;
   public var posDims:Int;
   public var texDims:Int;
   var posBuffer:GLBuffer;
   var texBuffer:GLBuffer;
   var samplerLocation:Dynamic;
   public var texture(default,null):GLTexture;

   public function new(vertShader:String, posName:String, texName,
                       fragShader:String, samplerName:String )
   {
      prog = Utils.createProgram(vertShader,fragShader);
      posLocation = GL.getAttribLocation(prog, posName);
      texLocation = GL.getAttribLocation(prog, texName);
      samplerLocation = GL.getUniformLocation(prog, samplerName);
      posDims = 2;
      texDims = 2;
      createTexture();
      fillTexture();
   }

   public function setPosTex( pos:Array<Float>, texCoords:Array<Float>, inPrims:Int, inType:Int)
   {
      primCount = inPrims;
      type = inType;

      if (posBuffer==null)
         posBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(pos), GL.STATIC_DRAW);
      if (texBuffer==null)
         texBuffer = GL.createBuffer();
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(texCoords), GL.STATIC_DRAW);
   }

   public function createTexture()
   {
      texture = GL.createTexture();
      GL.bindTexture(GL.TEXTURE_2D, texture);

      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE );
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE );
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
   }

   public function fillTexture()
   {
      var pixels = new UInt8Array(new ArrayBuffer(256*256*4));

      for(i in 0...256*256*4)
         pixels[i] = Std.random(256);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 256, 256, 0, GL.RGBA, GL.UNSIGNED_BYTE, pixels);
   }

   public function bindTexture()
   {
      GL.bindTexture(GL.TEXTURE_2D, texture);
   }

   public function render()
   {
      GL.useProgram(prog);

      GL.bindBuffer(GL.ARRAY_BUFFER, posBuffer);
      GL.vertexAttribPointer(posLocation, posDims, GL.FLOAT, false, 0, 0);
      GL.bindBuffer(GL.ARRAY_BUFFER, texBuffer);
      GL.vertexAttribPointer(texLocation, texDims, GL.FLOAT, false, 0, 0);

      GL.activeTexture(GL.TEXTURE0);
      bindTexture();
      GL.uniform1i(samplerLocation, 0);

      GL.enableVertexAttribArray(posLocation);
      GL.enableVertexAttribArray(texLocation);
      GL.drawArrays(type, 0, primCount);
      GL.disableVertexAttribArray(texLocation);
      GL.disableVertexAttribArray(posLocation);
   }
}
