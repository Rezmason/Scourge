package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import lime.utils.Float32Array;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Texture;

class BloomMethod extends ScreenRenderMethod {

    var amount:UInt;
    var kernel:Float32Array;

    public function new(amount:UInt) {
        super();
        this.amount = amount;
        kernel = buildKernel(amount);
    }

    // Grabbed from the same place @alteredq grabbed it from for the three.js example ;-)
    // We lop off the sqrt(2 * pi) * sigma term, since we're going to normalize anyway.
    function gauss(x, sigma) return Math.exp(- (x * x) / (2.0 * sigma * sigma));

    function buildKernel(sigma) {
        var kMaxKernelSize:UInt = 25;
        var kernelSize:UInt = Std.int(2 * Math.ceil(sigma * 3.0) + 1);
        if (kernelSize > kMaxKernelSize) kernelSize = kMaxKernelSize;
        var halfWidth = Std.int((kernelSize - 1) * 0.5);
        var values = [];
        var sum:Float = 0;
        for (ike in 0...kernelSize) {
            values[ike] = gauss(ike - halfWidth, sigma);
            sum += values[ike];
        }
        return new Float32Array([for (value in values) value / sum]);
    }

    override function composeShaders() {
        extensions.push('OES_texture_float');
        extensions.push('OES_texture_float_linear');
        vertShader = getText('shaders/bloom.vert');
        fragShader = getText('shaders/bloom.frag');
    }

    override public function start(renderTarget, args) {
        super.start(renderTarget, args);
        program.setFloat('uBlurDirection', args[0], args[1]);
        program.setFloatVec('uKernel', 1, kernel);
        program.setInt('uIntKernelSize', kernel.length);
        program.setFloat('uFloatKernelSize', kernel.length);
    }

    override public function drawScreen(textures:Map<String, Texture>) {
        program.setDepthTest(false);
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        program.setTextureAt('uTexture', textures['input']);
        program.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
    }
}
