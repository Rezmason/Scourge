package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;

typedef Func = Map<String, String>->Array<String>->String;

class ArgsCommand extends ConsoleCommand {

    inline static var UNRECOGNIZED_PARAM:String = 'Unrecognized parameter';
    inline static var UNSPECIFIED_VALUE:String = 'Unspecified value for key: ';
    inline static var STYLES:String =
            'µ{name:key,  basis:__input, r:0.5, g:1.0, b:1.0}' +
            'µ{name:val,  basis:__input, r:1.0, g:0.5, b:1.0}' +
            'µ{name:flag, basis:__input, r:1.0, g:1.0, b:0.5}';
    inline static var KEY_STYLENAME:String = 'key';
    inline static var VALUE_STYLENAME:String = 'val';
    inline static var FLAG_STYLENAME:String = 'flag';

    var func:Map<String, String>->Array<String>->String;
    var keyHints:Array<String>;
    var flagHints:Array<String>;
    var keyRestrictions:Map<String, String>;

    public function new(func:Func, keyHints:Array<String>, flagHints:Array<String>, keyRestrictions:Map<String, String>, hidden:Bool = false):Void {
        super(hidden);
        this.func = func;
        this.keyHints = keyHints;
        this.flagHints = flagHints;
        this.keyRestrictions = keyRestrictions;
        tokenStyles = STYLES;
    }

    override public function requestHints(tokens:Array<TextToken>, info:InputInfo):Void {
        var hintTokens:Array<TextToken> = modifyInput(tokens, info);
        hintsGeneratedSignal.dispatch(hintTokens);
        inputGeneratedSignal.dispatch(tokens, info.tokenIndex, info.caretIndex);
    }

    private function modifyInput(tokens:Array<TextToken>, info:InputInfo):Array<TextToken> {

        var hintTokens:Array<TextToken> = [];

        if (tokens.length == 1) {
            // Let's move the caret to a new token.
            tokens.push(makeToken(''));
            info.tokenIndex = 1;
            info.caretIndex = 0;
        }

        if (info.tokenIndex > 0) {

            if (info.char != '' && tokens.length > info.tokenIndex + 1) {
                tokens.splice(info.tokenIndex + 1, tokens.length);
            }

            var prevTokens:Array<TextToken> = tokens.copy();
            prevTokens.pop();
            var flagHintToToken:String->TextToken = hintToToken.bind(prevTokens, _, FLAG_STYLENAME);
            var keyHintToToken :String->TextToken = hintToToken.bind(prevTokens, _,  KEY_STYLENAME);

            var usedKeyHints:Map<String, Bool> = new Map();
            var usedFlagHints:Map<String, Bool> = new Map();

            var currentToken:TextToken = tokens[info.tokenIndex];
            var currentArg:String = currentToken.text;
            var completed:Bool = false;
            var showAllHints:Bool = false;
            var errorMessage:String = null;

            var remainingKeyHints:Array<String> = keyHints.copy();
            var remainingFlagHints:Array<String> = flagHints.copy();

            // Is this a key/flag or a value?
            var unpairedKey:Bool = false;
            for (ike in 1...info.tokenIndex) {
                switch (tokens[ike].styleName) {
                    case KEY_STYLENAME:
                        if (!unpairedKey) {
                            unpairedKey = true;
                            remainingKeyHints.remove(tokens[ike].text);
                        } else {

                        }
                    case FLAG_STYLENAME:
                        remainingFlagHints.remove(tokens[ike].text);
                    case VALUE_STYLENAME:
                        unpairedKey = false;
                    case _:
                        if (length(tokens[ike].text) > 0) {
                            tokens[ike].styleName = Strings.ERROR_HINT_STYLENAME;
                            errorMessage = UNRECOGNIZED_PARAM;
                        }
                }
            }

            if (info.char == ' ') {
                currentArg = rtrim(currentArg);
                currentToken.text = currentArg;
                info.caretIndex = length(currentArg);
                if (length(currentArg) > 0) {
                    if (currentToken.styleName != VALUE_STYLENAME && !(flagHints.has(currentArg) || keyHints.has(currentArg))) {
                        info.char = '';
                    } else if (currentToken.styleName != Strings.ERROR_HINT_STYLENAME) {
                        completed = true;
                    }
                }
            }

            if (info.char != '') currentToken.styleName = null;

            if (remainingKeyHints.has(currentArg)) currentToken.styleName = KEY_STYLENAME;
            else if (remainingFlagHints.has(currentArg)) currentToken.styleName = FLAG_STYLENAME;

            if (unpairedKey) {
                // values
                currentToken.styleName = VALUE_STYLENAME;
                if (completed) showAllHints = true;
            } else {
                // keys and flags

                if (completed) {
                    if (flagHints.has(currentArg)) {
                        currentToken.styleName = FLAG_STYLENAME;
                        remainingFlagHints.remove(currentArg);
                        showAllHints = true;
                    } else if (keyHints.has(currentArg)) {
                        currentToken.styleName = KEY_STYLENAME;
                        remainingKeyHints.remove(currentArg);
                    }
                } else {
                    var matchingKeyHints:Array<String> = remainingKeyHints.filter(hintMatchesArg.bind(_, currentArg));
                    var matchingFlagHints:Array<String> = remainingFlagHints.filter(hintMatchesArg.bind(_, currentArg));
                    if (matchingFlagHints.length > 0) hintTokens = hintTokens.concat(matchingFlagHints.map(flagHintToToken));
                    if ( matchingKeyHints.length > 0) hintTokens = hintTokens.concat( matchingKeyHints.map(keyHintToToken));
                    if (hintTokens.length == 0 && length(currentArg) > 0) errorMessage = UNRECOGNIZED_PARAM;
                }
            }

            if (errorMessage != null) {
                currentToken.styleName = Strings.ERROR_HINT_STYLENAME;
                hintTokens = [makeToken(errorMessage, Strings.ERROR_HINT_STYLENAME)];
            } else if (completed) {
                tokens.push(makeToken('', null, keyRestrictions[currentToken.text]));

                info.tokenIndex++;
                info.caretIndex = 0;

                if (showAllHints) {
                    hintTokens = hintTokens.concat( remainingKeyHints.map(keyHintToToken));
                    hintTokens = hintTokens.concat(remainingFlagHints.map(flagHintToToken));
                }
            }
        }

        return hintTokens;
    }

    function tokenMatchesArg(token:TextToken, arg:String):Bool return token.text == arg;

    function hintMatchesArg(hint:String, arg:String):Bool return hint.indexOf(arg) == 0;

    function hintToToken(tokens:Array<TextToken>, hint:String, styleName:String = null):TextToken {
        var token:TextToken = makeToken(hint);
        token.authorID = id;
        if (styleName != null) token.styleName = styleName;
        token.data = {tokens:tokens.concat([token, makeToken('', null, keyRestrictions[hint])])};
        return token;
    }

    override public function execute(tokens:Array<TextToken>):Void {

        var info:InputInfo = {
            tokenIndex:tokens.length - 1,
            caretIndex:length(tokens[tokens.length - 1].text) - 1,
            char: null,
        };

        var hintTokens:Array<TextToken> = modifyInput(tokens, info);

        var output:TextToken = null;

        if (hintTokens.length > 0 && hintTokens[0].styleName == Strings.ERROR_HINT_STYLENAME) {
            output = makeToken(hintTokens[0].text, Strings.ERROR_EXEC_STYLENAME);
        } else {

            var unspecifiedValue:Bool = false;

            for (ike in 0...tokens.length - 1) {
                if (tokens[ike].styleName == KEY_STYLENAME && tokens[ike + 1].styleName == VALUE_STYLENAME) {
                    if (tokens[ike + 1].text == '') {
                        tokens[ike].styleName = Strings.ERROR_HINT_STYLENAME;
                        output = makeToken(UNSPECIFIED_VALUE + tokens[ike].text, Strings.ERROR_EXEC_STYLENAME);
                        unspecifiedValue = true;
                        break;
                    }
                }
            }

            if (!unspecifiedValue) {
                var keyValuePairs:Map<String, String> = new Map();
                var flags:Array<String> = [];

                var currentKey:String = null;
                for (ike in 1...tokens.length) {
                    var token:TextToken = tokens[ike];
                    switch (token.styleName) {
                        case FLAG_STYLENAME: flags.push(token.text);
                        case KEY_STYLENAME: currentKey = token.text;
                        case VALUE_STYLENAME: keyValuePairs[currentKey] = token.text;
                        case Strings.ERROR_HINT_STYLENAME:
                    }
                }

                output = makeToken(func(keyValuePairs, flags));
            }
        }

        outputGeneratedSignal.dispatch([output], true);
    }
}
