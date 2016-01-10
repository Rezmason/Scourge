package net.rezmason.gl;

import lime.graphics.opengl.GL;
@:enum abstract BlendFactor(Int) to Int {
    var ZERO                        = GL.ZERO;
    var ONE                         = GL.ONE;
    var SOURCE_COLOR                = GL.SRC_COLOR;
    var ONE_MINUS_SOURCE_COLOR      = GL.ONE_MINUS_SRC_COLOR;
    var SOURCE_ALPHA                = GL.SRC_ALPHA;
    var ONE_MINUS_SOURCE_ALPHA      = GL.ONE_MINUS_SRC_ALPHA;
    var DESTINATION_ALPHA           = GL.DST_ALPHA;
    var ONE_MINUS_DESTINATION_ALPHA = GL.ONE_MINUS_DST_ALPHA;
    var DESTINATION_COLOR           = GL.DST_COLOR;
    var ONE_MINUS_DESTINATION_COLOR = GL.ONE_MINUS_DST_COLOR;
    var SOURCE_ALPHA_SATURATE       = GL.SRC_ALPHA_SATURATE;
}
