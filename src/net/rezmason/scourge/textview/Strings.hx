package net.rezmason.scourge.textview;

class Strings {

    public inline static var SPLASH:String =
        ' SSSSS    CCCCC    OOOOO   UU   UU  RRRRRR    GGGGG    EEEEE ' + '\n' +
        'SS       CC   CC  OO   OO  UU   UU  RR   RR  GG       EE   EE' + '\n' +
        'SSSSSSS  CC       OO   OO  UU   UU  RRRRRR   GG  GGG  EEEEEEE' + '\n' +
        '     SS  CC   CC  OO   OO  UU   UU  RR   RR  GG   GG  EE     ' + '\n' +
        ' SSSSS    CCCCC    OOOOO    UUUUU   RR   RR   GGGGG    EEEEE ' + '\n' +
        '                                                             ' + '\n' +
        'Single-Celled  Organisms  Undergo  Rapid  Growth  Enhancement' + '\n' +
    '\n';

    public inline static var CARET_STYLE:String = '§{name:_c1,i:1}§{name:_c2,i:0}∂{name:caret,period:1,frames:[_c1,_c2]}';
    public inline static var BREATHING_PROMPT_STYLE:String = '§{name:_br1,f:0.2}§{name:_br2,f:0.6}∂{name:breathingprompt,period:3.5,frames:[_br1,_br2], s:1.7}';
    public inline static var INPUT_STYLE:String = '§{name:hint1,r:0.6,g:0.6,b:0.6,s:0.7}§{name:valid1,p:0.01}§{name:invalid1,p:-0.01}«{name:input1, hint:hint1, valid:valid1, invalid:invalid1, period:1}';

    public inline static var ALPHANUMERICS:String =
        'abcdefghijklmnopqrstuvwxyz' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        '0123456789' +
        '';

    public inline static var SYMBOLS:String = '<>[]{}-=!@#$%^*()_+';
    public inline static var WEIRD_SYMBOLS:String = '¤¬ÎøΔΩ•◊';
    public inline static var BOX_SYMBOLS:String = '   └ │┌├ ┘─┴┐┤┬┼';
    public inline static var PUNCTUATION:String = '\'\"?!.,;:-~/\\`|&';
}
