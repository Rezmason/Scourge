package net.rezmason.scourge.textview.console;

import net.rezmason.scourge.textview.console.ConsoleTypes;
import net.rezmason.utils.Utf8Utils.*;

using Lambda;

typedef Func = Map<String, String>->Array<String>->String;

class ArgsCommand extends ConsoleCommand {

    inline static var UNRECOGNIZED_PARAM:String = 'Unrecognized parameter.';
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

    override public function getHint(tokens:Array<TextToken>, info:InputInfo, callback:HintCallback):Void {
        var hintTokens:Array<TextToken> = modifyInput(tokens, info);
        callback(tokens, info.tokenIndex, info.caretIndex, hintTokens);
    }

    private function modifyInput(tokens:Array<TextToken>, info:InputInfo):Array<TextToken> {

        var hintTokens:Array<TextToken> = [];

        if (tokens.length == 1) {
            // Let's move the caret to a new token.
            tokens.push({text:''});
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

            if (info.char == ' ') {
                currentArg = rtrim(currentArg);
                currentToken.text = currentArg;
                info.caretIndex = length(currentArg);
                if (length(currentArg) > 0 && currentToken.styleName != Strings.ERROR_HINT_STYLENAME) {
                    completed = true;
                }
            }

            var remainingKeyHints:Array<String> = keyHints.copy();
            var remainingFlagHints:Array<String> = flagHints.copy();

            // Is this a key/flag or a value?
            var upairedKeyCount:Int = 0;
            for (ike in 1...info.tokenIndex) {
                switch (tokens[ike].styleName) {
                    case KEY_STYLENAME:
                        upairedKeyCount++;
                        remainingKeyHints.remove(tokens[ike].text);
                    case VALUE_STYLENAME:
                        upairedKeyCount--;
                    case FLAG_STYLENAME:
                        remainingFlagHints.remove(tokens[ike].text);
                }
            }

            if (info.char != '') currentToken.styleName = null;

            if (upairedKeyCount == 0) {
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
            } else {
                // values
                currentToken.styleName = VALUE_STYLENAME;
                if (completed) showAllHints = true;
            }

            if (errorMessage != null) {
                currentToken.styleName = Strings.ERROR_HINT_STYLENAME;
                hintTokens = [{text:errorMessage, styleName:Strings.ERROR_HINT_STYLENAME}];
            } else if (completed) {
                tokens.push({text:''});
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
        var token:TextToken =  {text:hint, authorID:id};
        if (styleName != null) token.styleName = styleName;
        token.hintData = {tokens:tokens.concat([token, {text:'', restriction:keyRestrictions[hint]}])};
        return token;
    }

    override public function getExec(tokens:Array<TextToken>, callback:ExecCallback):Void {

        var info:InputInfo = {
            tokenIndex:tokens.length - 1,
            caretIndex:length(tokens[tokens.length - 1].text) - 1,
            char: null,
        };

        var hintTokens:Array<TextToken> = modifyInput(tokens, info);

        var output:TextToken = null;

        if (hintTokens.length > 0 && hintTokens[0].styleName == Strings.ERROR_HINT_STYLENAME) {
            output = {text:hintTokens[0].text, styleName:Strings.ERROR_EXEC_STYLENAME};
        } else {
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

            output = {text:func(keyValuePairs, flags)};
        }

        callback([output], true);
    }
}
