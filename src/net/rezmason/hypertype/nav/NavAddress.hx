package net.rezmason.hypertype.nav;

enum NavAddress {
    Gone;
    Page(id:String);
    Back;
    Up;
    Top;
}
