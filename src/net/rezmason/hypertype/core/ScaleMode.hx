package net.rezmason.hypertype.core;

enum ScaleMode {
    EXACT_FIT; // Distort the aspect ratio to fit the content in the box
    NO_BORDER; // Scale the content uniformly to match the dimension of the largest side of the box
    NO_SCALE; // Perform no scaling logic
    SHOW_ALL; // Scale the content uniformly to match the dimension of the smallest side of the box

    WIDTH_FIT; // Scale the content uniformly to match the width of the box
    HEIGHT_FIT; // Scale the content uniformly to match the height of the box
}
