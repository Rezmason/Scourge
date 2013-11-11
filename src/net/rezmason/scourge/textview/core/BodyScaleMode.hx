package net.rezmason.scourge.textview.core;

enum BodyScaleMode {
    EXACT_FIT; // Distort the aspect ratio to fit the body in the rectangle
    NO_BORDER; // Scale the body uniformly to match the dimension of the largest side of the screen
    NO_SCALE; // Perform no scaling logic
    SHOW_ALL; // Scale the body uniformly to match the dimension of the smallest side of the screen

    WIDTH_FIT; // Scale the body uniformly to match the width of the screen
    HEIGHT_FIT; // Scale the body uniformly to match the height of the screen
}
