package net.rezmason.scourge.textview.text;

enum StyleTag {
    RefTag(sigil:String, reference:String);
    DeclTag(sigil:String, name:String, declaration:Dynamic);
}
