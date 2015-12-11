package net.rezmason.hypertype.text;

enum ParagraphAlign {
    ALIGN_LEFT;
    ALIGN_RIGHT;
    ALIGN_CENTER;
    ALIGN_JUSTIFY(secondary:ParagraphAlign);
}
