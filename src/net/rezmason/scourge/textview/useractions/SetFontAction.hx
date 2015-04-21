package net.rezmason.scourge.textview.useractions;

import net.rezmason.scourge.textview.console.UserAction;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.scourge.textview.core.FontManager;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.ui.UIElement;
import net.rezmason.utils.santa.Present;

class SetFontAction extends UserAction {

    var uiBody:UIElement;
    var fontManager:FontManager;

    public function new(uiBody:UIElement):Void {
        super();
        name = 'setFont';

        keys['fontName'] = ALPHANUMERICS;
        keys['size'] = INTEGERS;

        this.uiBody = uiBody;
        fontManager = new Present(FontManager);
    }

    override public function hint(args:UserActionArgs):Void {
        var message:String = null;
        var hints:Array<ConsoleToken> = null;
        if (args.pendingKey == 'size') {
            if (args.pendingValue == '') {
                message = 'Must be between 14 and 72.';
            } else {
                var size:Int = Std.parseInt(args.pendingValue);
                if (size < 14) message = 'Size is too small.';
                if (size > 72) message = 'Size is too large.';
            }
        } 
        else if (args.pendingKey == 'fontName') {
            var val:String = args.pendingValue;
            if (val == null) val = '';
            hints = fontManager.fontNames().filter(startsWith.bind(_, val)).map(argToHint.bind(_, Value));
            if (hints.length == 0) message = styleError('No matches found.');
        }

        hintSignal.dispatch(message, hints);
    }

    override public function execute(args:UserActionArgs):Void {

        var message:String = null;

        var size:String = args.keyValuePairs['size'];
        if (size != null) {
            var resizeWorked:Bool = uiBody.setFontSize(Std.parseInt(size));
            if (resizeWorked) message = 'Font size set to $size.';
            else message = styleError('Invalid font size: $size.');
            outputSignal.dispatch(message, false);
        }

        message = null;

        var fontName:String = args.keyValuePairs['fontName'];
        if (fontName != null) {
            uiBody.setFontTexture(fontManager.getFontByName(fontName));
            outputSignal.dispatch('Font set to $fontName.', false);
        }

        outputSignal.dispatch(null, true);
    }
}
