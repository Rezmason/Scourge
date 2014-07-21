package net.rezmason.scourge.textview.commands;

import net.rezmason.scourge.textview.console.ConsoleCommand;
import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.console.ConsoleTypes.ConsoleRestriction.*;
import net.rezmason.scourge.textview.console.ConsoleUtils.*;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.ui.UIBody;

using net.rezmason.utils.ArrayUtils;

class SetFontConsoleCommand extends ConsoleCommand {

    var uiBody:UIBody;
    var fontTextures:Map<String, GlyphTexture>;

    public function new(uiBody:UIBody, fontTextures:Map<String, GlyphTexture> = null):Void {
        super();
        name = 'setFont';

        if (fontTextures != null) keys['fontName'] = ALPHANUMERICS;
        keys['size'] = INTEGERS;

        this.uiBody = uiBody;
        this.fontTextures = fontTextures;
    }

    override public function hint(args:ConsoleCommandArgs):Void {
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
        else if (fontTextures != null && args.pendingKey == 'fontName') {
            var val:String = args.pendingValue;
            if (val == null) val = '';
            hints = fontTextures.keys().intoArray().filter(startsWith.bind(_, val)).map(argToHint.bind(_, Value));
            if (hints.length == 0) message = styleError('No matches found.');
        }

        hintSignal.dispatch(message, hints);
    }

    override public function execute(args:ConsoleCommandArgs):Void {

        var message:String = null;

        var size:String = args.keyValuePairs['size'];
        if (size != null) {
            var resizeWorked:Bool = uiBody.setFontSize(Std.parseInt(size));
            if (resizeWorked) message = 'Font size set to $size.';
            else message = styleError('Invalid font size: $size.');
            outputSignal.dispatch(message, false);
        }

        message = null;

        if (fontTextures != null) {
            var fontName:String = args.keyValuePairs['fontName'];
            if (fontName != null) {
                var fontWorked:Bool = uiBody.setFontTexture(fontTextures[fontName]);
                if (fontWorked) message = 'Font set to $fontName.';
                else message = styleError('Invalid font name: $fontName.');
                outputSignal.dispatch(message, false);
            }
        }

        outputSignal.dispatch(null, true);
    }
}
