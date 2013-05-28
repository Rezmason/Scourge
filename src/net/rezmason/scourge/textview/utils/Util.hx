package net.rezmason.scourge.textview.utils;

import openfl.display.OpenGLView;

/**
 *
 *  Here's the full list of Flash-dependent types of these utils:
 *
 *  flash.display.Stage3D;
 *  flash.display3D.Context3D;
 *  flash.display3D.Context3DBlendFactor;
 *  flash.display3D.Context3DCompareMode;
 *  flash.display3D.Context3DProgramType;
 *  flash.display3D.Context3DTextureFormat;
 *  flash.display3D.Context3DVertexBufferFormat;
 *  flash.display3D.IndexBuffer3D;
 *  flash.display3D.Program3D;
 *  flash.display3D.textures.Texture;
 *  flash.display3D.textures.TextureBase;
 *  flash.display3D.VertexBuffer3D;
 **/

class Util {
    var view:OpenGLView;
    public function new(view:OpenGLView):Void { this.view = view; }
}
