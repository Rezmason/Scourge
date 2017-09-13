package net.rezmason.gl;

import lime.graphics.opengl.GL;
import lime.graphics.opengl.WebGL2Context;

class Artifact {
    public var extensions(default, null):Array<String>;
    public var isDisposed(default, null):Bool = false;
    public function dispose() isDisposed = true;

    var context:WebGL2Context;
    
    inline function new(?extensions) {
        context = GL.context;
        this.extensions = extensions;
        if (this.extensions != null) for (extension in extensions) context.getExtension(extension);
    }

    function checkContext() if (context.isContextLost()) context = GL.context;
}
