package net.rezmason.gl;

typedef NativeVertexBuffer = #if flash flash.display3D.VertexBuffer3D #else openfl.gl.GLBuffer #end;
typedef NativeIndexBuffer = #if flash flash.display3D.IndexBuffer3D #else openfl.gl.GLBuffer #end;
typedef Context = #if flash flash.display3D.Context3D #else Class<openfl.gl.GL> #end ;
typedef View = #if flash flash.display.Stage #else openfl.display.OpenGLView #end ;
