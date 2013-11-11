package net.rezmason.scourge.textview;

import net.rezmason.utils.FatChar;

class TestStrings {

    public inline static var STYLED_TEXT:String =
    '§{r:1,g :-0,b:  0,  name:test}' +
    '§{                                                   name:test2}' +
    '§{r:0,                  basis:test,                  name:test3}' +
    '§{name:whatever,g:1,                  basis:test5}' +
    '§{name:anim1, r:1, g:0, b:0, p:-0.01}' +
    '§{name:anim2, r:1, g:1, b:0, p:-0.02}' +
    '§{name:anim3, r:1, g:1, b:1, p:-0.03}' +
    '§{}This is a §{test}test§{}.\n' +
    '∂{name:whatever2,period:2, frames:[anim1,anim2,anim3]}eeeeee§{}\n' +
    'This is another §{test2}test§{}.\n' +
    '§{name:whatever3g:1,  p:0.05               , basis:test}This is a third test!§{}\n' +
    '\n\n' +
    '§{name:merp1, p: 0.00, r:0}UP§{}\n\n' +
    '§{name:merp2, p:-0.01, g:0}OVER§{}\n\n' +
    '§{name:merp3, p: 0.01, b:0}DOWN§{}\n\n' +
    '∂{name:animation, period:1, frames:[merp1, merp2, merp3]}DANCE, DAMN IT§{}\n' +
    'µ{name:button, up:merp1, over:merp2, down:merp3, period:0.2, i:1}  BUTTON TIME  §{}\n' +
    '\n' +
    'µ{name:button2, basis:button}  ANOTHER BUTTON  §{}\n' +
    '\n' +
    'µ{button}  BUTTON TIME AGAIN  §{}\n' +
    '§{name:broken, r:hello}ABCD§{}';

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
}
