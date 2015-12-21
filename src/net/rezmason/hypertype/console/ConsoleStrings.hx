package net.rezmason.hypertype.console;

class ConsoleStrings {

    public inline static var CARET_STYLE:String = '§{name:_c1,f:0.2}§{name:_c2,f:0}∂{name:caret,period:1,frames:[_c1,_c2],s:1.5,a:1,ease:Quart_easeOut}';
    public inline static var CARET_STYLENAME:String = 'caret';
    public inline static var WAIT_STYLES:String =
        '§{name:_w1,s:1.5}§{name:_w2,s:1}' +
        '∂{name:wait_a,period:0.6,frames:[_w1,_w2,_w2],r:0.5,g:0.5,b:0.5}' +
        '∂{name:wait_b,period:0.6,frames:[_w2,_w1,_w2],r:0.5,g:0.5,b:0.5}' +
        '∂{name:wait_c,period:0.6,frames:[_w2,_w2,_w1],r:0.5,g:0.5,b:0.5}';

    public inline static var BREATHING_PROMPT_STYLE:String = '§{name:_br1,f:0}§{name:_br2,f:0.2}∂{name:breathingprompt,period:3.5,frames:[_br1,_br2], s:1.7, persist:true}';
    public inline static var BREATHING_PROMPT_STYLENAME:String = 'breathingprompt';

    public inline static var ACTION_HINT_STYLE:String = '§{name:__action_hint, r:0.8, g:0.8, b:0.8, f:-0.1}';
    public inline static var ACTION_HINT_STYLENAME:String = '__action_hint';

    public inline static var INTERPRETER_STYLES:String =
        'µ{name:__Key_input, basis:__input, r:1, g:0.5, b:0.5}' +
        'µ{name:__Value_input, basis:__input, r:1, g:1, b:0.5}' +
        'µ{name:__Flag_input, basis:__input, r:0.5, g:1, b:0.5}' +
        'µ{name:__ActionName_input, basis:__input, r:0.5, g:1, b:1}' +
        'µ{name:__TailMarker_input, basis:__input, r:0.5, g:0.5, b:1}' +
        'µ{name:__Tail_input, basis:__input, r:1, g:0.5, b:1}';

    public inline static var KEY_STYLENAME:String = '__Key_input';
    public inline static var VALUE_STYLENAME:String = '__Value_input';
    public inline static var FLAG_STYLENAME:String = '__Flag_input';
    public inline static var ACTION_NAME_STYLENAME:String = '__ActionName_input';
    public inline static var TAIL_STYLENAME:String = '__Tail_input';
    public inline static var TAIL_MARKER_STYLENAME:String = '__TailMarker_input';

    public inline static var INPUT_STYLE:String =
        '§{name:__input_over, i:0.2}' +
        'µ{name:__input, over:__input_over, period:0.}';
    public inline static var INPUT_STYLENAME:String = '__input';

    public inline static var ERROR_STYLES:String =
        'µ{name:__errorInput, basis:__input, g:0, b:0}' +
        '§{name:__errorOutput, g:0, b:0, f:0.2, a:1}';
    public inline static var ERROR_INPUT_STYLENAME:String = '__errorInput';
    public inline static var ERROR_OUTPUT_STYLENAME:String = '__errorOutput';

    public inline static var CARET_CHAR:String = '|';
    public inline static var WAIT_INDICATOR:String = ' §{wait_a}•§{} §{wait_b}•§{} §{wait_c}•§{} ';
    public inline static var PROMPT:String = ' => ';
}
