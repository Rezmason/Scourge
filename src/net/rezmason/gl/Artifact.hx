package net.rezmason.gl;

import lime.graphics.opengl.GL;

class Artifact {
    public var extensions(default, null):Array<String>;
    public var isDisposed(default, null):Bool = false;
    public function dispose() isDisposed = true;
    
    inline function new(?extensions) {
        this.extensions = extensions;
        if (this.extensions != null) for (extension in extensions) GL.getExtension(extension);
    }
}
