package net.rezmason.hypertype.useractions;

import lime.Assets.*;
import net.rezmason.hypertype.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.hypertype.console.ConsoleTypes;
import net.rezmason.hypertype.console.ConsoleUtils.*;
import net.rezmason.hypertype.console.UserAction;
import net.rezmason.hypertype.core.SystemCalls;
import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.utils.santa.Present;

using net.rezmason.utils.ArrayUtils;
using Lambda;

typedef WindowSize = {width:UInt, height:UInt};

class SetWindowSizeAction extends UserAction {

    inline static var MIN_SIZE = 100;
    inline static var MAX_SIZE = 1152;

    var sceneGraph:SceneGraph;
    var systemCalls:SystemCalls;
    var presets:Map<String, WindowSize>;
    var presetNames:Array<String>;

    public function new():Void {
        super();
        name = 'setWindowSize';
        keys['width'] = INTEGERS;
        keys['height'] = INTEGERS;
        keys['preset'] = ALPHANUMERICS;
        flags.push('landscape');
        flags.push('portrait');

        systemCalls = new Present(SystemCalls);
        sceneGraph = new Present(SceneGraph);

        presets = [
            'oldSchool' => {width:800, height:600},
            'iPhone4' => {width:960, height:640},
            'iPhone6' => {width:1334, height:750},
            'iPad' => {width:1024, height:768},
        ];

        presetNames = [for (key in presets.keys()) key];
    }

    override public function hint(args:UserActionArgs):Void {
        var message:String = null;
        var hints:Array<ConsoleToken> = null;
        if (args.pendingKey == 'width' || args.pendingKey == 'height') {
            if (args.pendingValue == '') {
                message = 'Must be between $MIN_SIZE and $MAX_SIZE.';
            } else {
                var size:Int = Std.parseInt(args.pendingValue);
                if (size < MIN_SIZE) message = 'Size is too small.';
                if (size > MAX_SIZE) message = 'Size is too large.';
            }
        } else if (args.pendingKey == 'preset') {
            var val:String = args.pendingValue;
            if (val == null) val = '';
            hints = presetNames.filter(startsWith.bind(_, val)).map(argToHint.bind(_, Value));
            if (hints.length == 0) message = styleError('No matches found.');
        }

        hintSignal.dispatch(message, hints);
    }

    override public function execute(args:UserActionArgs):Void {

        var message:String = null;

        var width:UInt  = sceneGraph.width;
        var height:UInt = sceneGraph.height;

        var preset:WindowSize = presets[args.keyValuePairs['preset']];
        if (preset != null) {
            width = preset.width;
            height = preset.height;
        }

        var widthValue:String = args.keyValuePairs['width'];
        if (widthValue != null) width = Std.parseInt(widthValue);
        var heightValue:String = args.keyValuePairs['height'];
        if (heightValue != null) height = Std.parseInt(heightValue);

        if ((args.flags.has('portrait') && width > height) || (args.flags.has('landscape') && width < height)) {
            var oldWidth = width;
            width = height;
            height = oldWidth;
        }

        message = null;

        if (width < MIN_SIZE || width > MAX_SIZE) {
            message = styleError('Invalid width: $width.');
            outputSignal.dispatch(message, true);
        } else if (height < MIN_SIZE || height > MAX_SIZE) {
            message = styleError('Invalid height: $height.');
            outputSignal.dispatch(message, true);
        } else {
            systemCalls.resizeWindowSignal.dispatch(width, height);
            message = 'Window resized to $width x $height.';
            outputSignal.dispatch(message, true);
        }
    }
}
