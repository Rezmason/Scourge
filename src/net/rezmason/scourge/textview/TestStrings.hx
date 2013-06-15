package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

class TestStrings {

    public inline static var SPLASH:String =
        ' SSSSS    CCCCC    OOOOO   UU   UU  RRRRRR    GGGGG    EEEEE ' + '\n' +
        'SS       CC   CC  OO   OO  UU   UU  RR   RR  GG       EE   EE' + '\n' +
        'SSSSSSS  CC       OO   OO  UU   UU  RRRRRR   GG  GGG  EEEEEEE' + '\n' +
        '     SS  CC   CC  OO   OO  UU   UU  RR   RR  GG   GG  EE     ' + '\n' +
        ' SSSSS    CCCCC    OOOOO    UUUUU   RR   RR   GGGGG    EEEEE ' + '\n' +
        '                                                             ' + '\n' +
        'Single-Celled  Organisms  Undergo  Rapid  Growth  Enhancement' + '\n' +
    '\n';

    public inline static var STYLED_TEXT:String =
    '§{r:1,g :-0,b:  0,  name:test}' +
    '§{                                                   name:test2}' +
    '§{r:0,                  basis:test,                  name:test3}' +
    '§{g:1,                  basis:test5}' +
    '§{name:anim1, r:1, g:0, b:0, p:-0.01}' +
    '§{name:anim2, r:1, g:1, b:0, p:-0.02}' +
    '§{name:anim3, r:1, g:1, b:1, p:-0.03}' +
    '§{}This is a §{test}test§{}.\n' +
    '∂{period:2, frames:[anim1,anim2,anim3]}eeeeee§{}\n' +
    'This is another §{test2}test§{}.\n' +
    '§{g:1,  p:0.05               , basis:test}This is a third test!§{}\n' +
    '\n\n' +
    '§{name:merp1, p: 0.00, r:0}UP§{}\n\n' +
    '§{name:merp2, p:-0.01, g:0}OVER§{}\n\n' +
    '§{name:merp3, p: 0.01, b:0}DOWN§{}\n\n' +
    '∂{name:animation, period:1, frames:[merp1, merp2, merp3]}DAMN IT§{}\n' +
    'µ{name:button, up:merp1, over:merp2, down:merp3, period:0.2, i:1}  BUTTON TIME!  §{}' +
    '';

    public inline static var SYMBOLS:String = '<>[]{}-=!@#$%^*()_+';
    public inline static var WEIRD_SYMBOLS:String = '¤¬ÎøΔΩ•◊';
    public inline static var BOX_SYMBOLS:String = '   ─ ┘└┴ ┐┌┬│┤├┼';

    public inline static var BOARD:String =
        'X X X X X X X X X X X X X X X X X X X X X X X X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X           1                     2           X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X           0                     3           X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X                                             X\n' +
        'X X X X X X X X X X X X X X X X X X X X X X X X\n' +
    '\n';

    public inline static var ALPHANUMERICS:String =
        'abcdefghijklmnopqrstuvwxyz' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        '0123456789' +
        '';

    public inline static var PUNCTUATION:String = '\'?!.,;:-~/\\`|&';

    public inline static function CHAR_COLORS():Map<Int, Int> {
        return [
            FatChar.fromString('S')[0].code => 0xFF0090,
            FatChar.fromString('C')[0].code => 0xFFC800,
            FatChar.fromString('O')[0].code => 0x30FF00,
            FatChar.fromString('U')[0].code => 0x00C0FF,
            FatChar.fromString('R')[0].code => 0xFF6000,
            FatChar.fromString('G')[0].code => 0xC000FF,
            FatChar.fromString('E')[0].code => 0x0030FF,
        ];
    }
}
