package net.rezmason.scourge.textview.utils;

import nme.display3D.Context3D;

/**
 *
 *  Here's the full list of Flash-dependent types of these utils:
 *
 *  nme.display.Stage3D;
 *  nme.display3D.Context3D;
 *  nme.display3D.Context3DBlendFactor;
 *  nme.display3D.Context3DCompareMode;
 *  nme.display3D.Context3DProgramType;
 *  nme.display3D.Context3DTextureFormat;
 *  nme.display3D.Context3DVertexBufferFormat;
 *  nme.display3D.IndexBuffer3D;
 *  nme.display3D.Program3D;
 *  nme.display3D.textures.Texture;
 *  nme.display3D.textures.TextureBase;
 *  nme.display3D.VertexBuffer3D;
 **/

class Util {
    var context:Context3D;
    public function new(context:Context3D):Void { this.context = context; }
}
