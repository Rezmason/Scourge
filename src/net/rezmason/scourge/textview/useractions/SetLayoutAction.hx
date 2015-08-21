package net.rezmason.scourge.textview.useractions;

import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.scourge.textview.ui.UIElement;

class SetLayoutAction extends UserAction {

    var uiBody:UIElement;

    public function new(uiBody:UIElement):Void {
        super();
        name = 'setLayout';

        keys['x'] = REALS;
        keys['y'] = REALS;
        keys['width'] = REALS;
        keys['height'] = REALS;

        this.uiBody = uiBody;
    }

    override public function hint(args:UserActionArgs):Void {
        var message:String = null;
        var hints:Array<ConsoleToken> = null;
        if (args.pendingValue == '') {
            message = 'Must be between 0 and 1.';
        } else {
            var value = Std.parseFloat(args.pendingValue);
            if (value < 0) message = '${args.pendingKey} is too small.';
            if (value > 1) message = '${args.pendingKey} is too large.';
        }
        hintSignal.dispatch(message, hints);
    }

    override public function execute(args:UserActionArgs):Void {
        var message:String = null;
        var x:Float = args.keyValuePairs['x'] != null ? Std.parseFloat(args.keyValuePairs['x']) : 0;
        var y:Float = args.keyValuePairs['y'] != null ? Std.parseFloat(args.keyValuePairs['y']) : 0;
        var width:Float = args.keyValuePairs['width'] != null ? Std.parseFloat(args.keyValuePairs['width']) : 1;
        var height:Float = args.keyValuePairs['height'] != null ? Std.parseFloat(args.keyValuePairs['height']) : 1;
        
        var setLayoutWorked:Bool = uiBody.setLayout(x, y, width, height);
        if (setLayoutWorked) message = 'Layout set to [$x, $y, $width, $height].';
        else message = styleError('Invalid layout: [$x, $y, $width, $height].');
        outputSignal.dispatch(message, false);
        
        message = null;
        outputSignal.dispatch(null, true);
    }
}
