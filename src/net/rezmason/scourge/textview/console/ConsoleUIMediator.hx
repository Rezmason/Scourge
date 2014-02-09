package net.rezmason.scourge.textview.console;

import flash.ui.Keyboard;

import haxe.Utf8;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.text.*;
import net.rezmason.utils.FlatFont;
import net.rezmason.utils.Utf8Utils.*;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.textview.core.GlyphUtils;

private typedef FrozenInteraction = { id:Int, interaction:Interaction };

class ConsoleUIMediator extends UIMediator {

    inline static var INPUT_PREFIX:String = '__input_';
    inline static var OUTPUT_PREFIX:String = '__output_';
    inline static var HINT_PREFIX:String = '__hint_';

    public var frozen(get, set):Bool;
    var executing:Bool;

    var caretStyle:AnimatedStyle;
    var caretSpan:Span;

    var prompt:String;
    var caretCharCode:Int;
    var inputString:String;
    var outputString:String;
    var hintString:String;

    var frozenQueue:List<FrozenInteraction>;
    var _frozen:Bool;

    var interactiveDoc:Document;
    var appendedDoc:Document;

    var addedText:String;

    var isLogDocDirty:Bool;
    var isLogDocAppended:Bool;
    var isInteractiveDocDirty:Bool;

    public function new():Void {
        super();
        loadStyles([
            Strings.BREATHING_PROMPT_STYLE,
            Strings.WAIT_STYLES,
            Strings.INPUT_STYLE,
            Strings.ERROR_STYLES,
        ].join(''));
        interactiveDoc = new Document();
        interactiveDoc.shareWith(compositeDoc);
        appendedDoc = new Document();
        appendedDoc.shareWith(compositeDoc);
        isLogDocDirty = false;
        isLogDocAppended = false;
        isInteractiveDocDirty = false;
        setPrompt('scourge', 0x3060FF);
        for (span in Parser.parse(Strings.CARET_STYLE).spans) if (Std.is(span.style, AnimatedStyle)) caretSpan = span;
        caretStyle = cast caretSpan.style;
        caretCharCode = Utf8.charCodeAt(Strings.CARET_CHAR, 0);
        addedText = '';
        inputString = '';
        outputString = '';
        hintString = '';
        frozenQueue = new List();
        frozen = false;
        executing = false;
        isInteractiveDocDirty = true;
    }

    public inline function loadStyles(dec:String):Void compositeDoc.loadStyles(dec);

    override public function styleCaret(caretGlyph:Glyph, font:FlatFont):Void {
        caretSpan.removeAllGlyphs();
        caretSpan.addGlyph(caretGlyph);
        caretGlyph.set_char(caretCharCode, font);
    }

    public function setPrompt(name:String, color:Int):Void {

        var r:Float = (color >> 16 & 0xFF) / 0xFF;
        var g:Float = (color >> 8  & 0xFF) / 0xFF;
        var b:Float = (color >> 0  & 0xFF) / 0xFF;

        prompt =
        '∂{name:head_prompt_$name, basis:${Strings.BREATHING_PROMPT_STYLENAME}, r:$r, g:$g, b:$b}Ω' +
        '§{name:prompt_$name, r:$r, g:$g, b:$b} $name§{}${Strings.PROMPT}§{}';
    }

    override function combineDocs():Void {

        if (isLogDocDirty) {
            isLogDocDirty = false;
            logDoc.setText(swapTabsWithSpaces(mainText));
        }

        if (isLogDocAppended) {
            isLogDocAppended = false;

            mainText += addedText;
            appendedDoc.setText(swapTabsWithSpaces(addedText));
            appendedDoc.removeInteraction();
            logDoc.append(appendedDoc);
            appendedDoc.clear();
            appendedDoc.shareWith(logDoc);
            addedText = '';
        }

        if (isInteractiveDocDirty) {
            isInteractiveDocDirty = false;

            var interactiveText:String = (length(mainText) > 0 ? '\n' : '') + outputString;

            if (executing) {
                interactiveText += Strings.WAIT_INDICATOR;
            } else {
                interactiveText += prompt + inputString;
                interactiveText += '\n'; // Always added, because there's always input
                if (false) interactiveText += '\t' + hintString;
            }

            interactiveDoc.setText(swapTabsWithSpaces(interactiveText));
        }

        compositeDoc.clear();
        compositeDoc.append(logDoc);
        compositeDoc.append(interactiveDoc);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
        if (frozen) frozenQueue.add({id:id, interaction:interaction});
        switch (interaction) {
            case KEYBOARD(type, key, char, shift, alt, ctrl) if (type == KEY_DOWN || type == KEY_REPEAT):
                switch (key) {
                    case Keyboard.BACKSPACE: handleBackspace(alt, ctrl);
                    case Keyboard.ENTER: handleEnter();
                    case Keyboard.ESCAPE: handleEscape();
                    case Keyboard.LEFT: handleCaretNudge(alt, ctrl, true);
                    case Keyboard.RIGHT: handleCaretNudge(alt, ctrl);
                    case Keyboard.UP: handleUp();
                    case Keyboard.DOWN: handleDown();
                    case Keyboard.TAB: handleTab();
                    case _: handleChar(char);
                }
            case _: super.receiveInteraction(id, interaction);
        }
    }

    override function handleSpanMouseInteraction(span:Span, type:MouseInteractionType):Void {
        super.handleSpanMouseInteraction(span, type);
        if (span.id.indexOf(INPUT_PREFIX) == 0) {

        } else if (span.id.indexOf(OUTPUT_PREFIX) == 0) {

        } else if (span.id.indexOf(HINT_PREFIX) == 0) {

        }
    }

    override public function updateSpans(delta:Float):Void {
        caretStyle.updateSpan(caretSpan, delta);
        super.updateSpans(delta);
    }

    public function addToText(text:String):Void {
        addedText += text;
        isDirty = true;
        isLogDocAppended = true;
    }

    public function clearText():Void {
        mainText = '';
        addedText = '';
        isDirty = true;
        isLogDocDirty = true;
        isLogDocAppended = false;
    }

    inline function handleBackspace(alt:Bool, ctrl:Bool):Void {
        inputString = '';
        isDirty = isInteractiveDocDirty = true;
        caretStyle.startSpan(caretSpan, 0);
    }

    inline function handleEnter():Void {

    }

    inline function handleTab():Void {

    }

    inline function handleEscape():Void {

    }

    inline function handleCaretNudge(alt:Bool, ctrl:Bool, nudgeLeft:Bool = false):Void {

    }

    inline function handleUp():Void {

    }

    inline function handleDown():Void {

    }

    inline function handleChar(charCode:Int):Void {
        if (charCode > 0) {
            inputString += String.fromCharCode(charCode);
            isDirty = isInteractiveDocDirty = true;

            caretStyle.startSpan(caretSpan, 0);
        }
    }

    inline function get_frozen():Bool return _frozen;

    inline function set_frozen(val:Bool):Bool {
        if (_frozen && !val) {
            _frozen = false;
            emptyFrozenQueue();
        }
        _frozen = val;
        return val;
    }

    inline function emptyFrozenQueue():Void {
        while (!frozenQueue.isEmpty()) {
            var leftovers:FrozenInteraction = frozenQueue.pop();
            receiveInteraction(leftovers.id, leftovers.interaction);
        }
    }
}
