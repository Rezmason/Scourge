package net.rezmason.scourge.textview.console;

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

    public var frozen(default, null):Bool;
    public var keyboardSignal(default, null):Zig<Int->Int->Bool->Bool->Void>;
    public var clickSignal(default, null):Zig<String->Void>;
    var executing:Bool;

    var caretStyle:AnimatedStyle;
    var caretSpan:Span;

    var prompt:String;
    var caretCharCode:Int;
    var inputString:String;
    var outputString:String;
    var hintString:String;

    var frozenQueue:List<FrozenInteraction>;

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
        keyboardSignal = new Zig();
        clickSignal = new Zig();
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
                if (hintString != null) interactiveText += hintString;
            }

            interactiveDoc.setText(swapTabsWithSpaces(interactiveText));
        }

        compositeDoc.clear();
        compositeDoc.append(logDoc);
        compositeDoc.append(interactiveDoc);
    }

    override public function receiveInteraction(id:Int, interaction:Interaction):Void {
        if (frozen) {
            frozenQueue.add({id:id, interaction:interaction});
        } else {
            switch (interaction) {
                case KEYBOARD(type, key, char, shift, alt, ctrl) if (type == KEY_DOWN || type == KEY_REPEAT):
                    keyboardSignal.dispatch(key, char, alt, ctrl);
                case _: super.receiveInteraction(id, interaction);
            }
        }
    }

    override function handleSpanMouseInteraction(span:Span, type:MouseInteractionType):Void {
        super.handleSpanMouseInteraction(span, type);
        clickSignal.dispatch(span.id);
    }

    override public function updateSpans(delta:Float):Void {
        caretStyle.updateSpan(caretSpan, delta);
        super.updateSpans(delta);
    }

    public function addToText(text:String):Void {
        addedText += text;
        isDirty = isLogDocAppended = true;
    }

    public function clearText():Void {
        mainText = '';
        addedText = '';
        isLogDocAppended = false;
        isDirty = isLogDocDirty = true;
    }

    public function setInput(str:String):Void {
        if (str == null) str = '';
        if (inputString != str) {
            inputString = str;
            isDirty = isInteractiveDocDirty = true;
        }
    }

    public function setOutput(str:String):Void {
        if (str == null) str = '';
        if (outputString != str) {
            outputString = str;
            isDirty = isInteractiveDocDirty = true;
        }
    }

    public function setHint(str:String):Void {
        if (str == null) str = '';
        if (hintString != str) {
            hintString = str;
            isDirty = isInteractiveDocDirty = true;
        }
    }

    public inline function freeze():Void {
        frozen = true;
    }

    public inline function unfreeze():Void {
        frozen = false;
        while (!frozenQueue.isEmpty() && !frozen) {
            var leftovers:FrozenInteraction = frozenQueue.pop();
            receiveInteraction(leftovers.id, leftovers.interaction);
        }
    }
}
