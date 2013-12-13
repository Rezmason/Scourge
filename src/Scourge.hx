package;

import openfl.Assets.*;
import flash.Lib;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.utils.FlatFont;
import net.rezmason.scourge.textview.Strings;

import net.rezmason.scourge.textview.waves.*;


class Scourge {

    static var fonts:Map<String, FlatFont>;
    static var utils:UtilitySet;

    public static function main():Void {
        #if flash Lib.redirectTraces(); #end
        trace('\n${Strings.SPLASH}');

        fonts = new Map();
        for (name in ['source', 'profont', 'full']) {
            var path = 'flatfonts/${name}_flat';
            fonts[name] = new FlatFont(getBitmapData('$path.png'), getText('$path.json'));
        }

        utils = new UtilitySet(Lib.current.stage, init);
    }

    static function init():Void {
        new net.rezmason.scourge.textview.TextDemo(utils, Lib.current.stage, fonts);

        // new net.rezmason.scourge.textview.Lab(utils, Lib.current.stage, fonts);
        // new net.rezmason.scourge.textview.BasicSetup(utils, Lib.current.stage, fonts);

        // showWavePool();
    }

    static function showWavePool():Void {
        var w:Int = Std.int(Lib.current.stage.stageWidth );
        var h:Int = Std.int(Lib.current.stage.stageHeight);

        var wavePoolShape:WavePoolShape = new WavePoolShape(w + 1);

        var bolus = WaveFunctions.bolus;
        var heartbeat = WaveFunctions.heartbeat;

        // bolus = WaveFunctions.photocopy(bolus, 10);
        // heartbeat = WaveFunctions.photocopy(heartbeat, 10);

        wavePoolShape.pool.addRipple(new Ripple(bolus,     200, 200, 0.95, 300));
        wavePoolShape.pool.addRipple(new Ripple(bolus,     100, 100, 0.99, 060));
        wavePoolShape.pool.addRipple(new Ripple(heartbeat, 100, 150, 0.99, 150));

        Lib.current.y = h / 2;
        Lib.current.addChild(wavePoolShape);
    }
}
