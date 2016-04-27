package net.rezmason.hypertype.text;

enum ParagraphAlign {
    LEFT;
    RIGHT;
    CENTER;
    JUSTIFY(secondary:ParagraphAlign);
}
