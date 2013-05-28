package net.rezmason.scourge.textview.nmedemo;

import flash.display.Stage;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;

import openfl.display.OpenGLView;
import openfl.gl.GL;

class NMEDemo
{
   public function new(stage:Stage)
   {
      var ogl = new OpenGLView();

      var colouredTriangle = new ColourBlend();

      var vertices = [
         -100.0,-100,
         200,20,
         20,200 ];
      var texture = [
          0.0,  0.0,
          4.0,  0.0,
          0.0,  4.0,
        ];
      colouredTriangle.setPosTex(vertices, texture, 3, GL.TRIANGLES);

      var colours = [
          1.0,  0.0,  0.0,  1.0,    // red
          0.0,  1.0,  0.0,  1.0,    // green
          0.0,  0.0,  1.0,  1.0     // blue
        ];
      colouredTriangle.setExtra(colours,4);

      // create frame buffer...
      var frameBuffer = GL.createFramebuffer();
      GL.bindFramebuffer(GL.FRAMEBUFFER,frameBuffer);

      // create empty texture
      var tex = GL.createTexture();
      GL.bindTexture(GL.TEXTURE_2D, tex);
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
      GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_NEAREST);
      GL.generateMipmap(GL.TEXTURE_2D);
      GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, 512, 512, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);

      var renderbuffer = GL.createRenderbuffer();
      GL.bindRenderbuffer(GL.RENDERBUFFER, renderbuffer);
      GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, 512, 512);

      GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, tex, 0);
      GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderbuffer);

      GL.bindTexture(GL.TEXTURE_2D, null);
      GL.bindRenderbuffer(GL.RENDERBUFFER, null);
      GL.bindFramebuffer(GL.FRAMEBUFFER, null);

      //gl.bindFramebuffer(gl.FRAMEBUFFER, frameBuffer);
      //draw ...
      //gl.bindFramebuffer(gl.FRAMEBUFFER, null);


      var posX = 200.0;
      var posY = 120.0;
      var rot  = 0.0;

      var quad = new TextureRect();

      stage.addChild(ogl);

      ogl.render = function(rect:Rectangle)
      {
         // Use the display list rectangle..
         var w = rect.width;
         var h = rect.height;
         GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(w), Std.int(h));


         // Only need the scissor if we want to limit the clear
         GL.scissor(Std.int(rect.x), Std.int(rect.y), Std.int(w), Std.int(h));
         GL.enable(GL.SCISSOR_TEST);
         GL.clearColor(0.1,0.2,0.5,1);
         GL.clear(GL.COLOR_BUFFER_BIT);
         GL.disable(GL.SCISSOR_TEST);

         // Render old buffer...
         quad.render();

         // Reverse Y - so 0,0 is top left...
         colouredTriangle.setTransform(Matrix3D.createOrtho(0,w, h,0, 1000, -1000),
                                       Matrix3D.create2D(posX, posY, 1, rot ) );

         colouredTriangle.render();

         // Copy screen rect into different sized texture to create stretch/swirl effect....
         /*
         quad.bindTexture();
         GL.copyTexImage2D(GL.TEXTURE_2D, 0, GL.RGB,
             Std.int(rect.x), Std.int(rect.y), Std.int(rect.width-1), Std.int(rect.height-1), 0);

         */

         GL.useProgram(null);
         rot = rot + 1.0;
      }

   }
}
