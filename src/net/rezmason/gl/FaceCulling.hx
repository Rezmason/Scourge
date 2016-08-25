package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract FaceCulling(Int) to Int {
    var FRONT = GL.FRONT;
    var BACK = GL.BACK;
    var FRONT_AND_BACK = GL.FRONT_AND_BACK;
}
