package net.rezmason.scourge.textview.styles;

enum StyleTag {
    RefTag(sigil:String, reference:String);
    DeclTag(sigil:String, name:String, declaration:Dynamic);
}
