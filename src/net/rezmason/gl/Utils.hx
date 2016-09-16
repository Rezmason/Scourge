package net.rezmason.gl;

typedef FormatRequirement = {
    var extensions: Array<String>;
    var dataFormat: DataFormat;
}

class Utils {

    static var requirements:Map<DataType, Map<PixelFormat, FormatRequirement>> = [
        FLOAT => [
            RGBA => {
                extensions: [
                    'OES_texture_float',
                    'OES_texture_float_linear',
                ],
                dataFormat: RGBA_FLOAT,
            },
            SINGLE_CHANNEL => {
                extensions: [
                    'OES_texture_float',
                    'OES_texture_float_linear',
                ],
                dataFormat: SINGLE_CHANNEL_FLOAT,
            },
        ],
        HALF_FLOAT => [
            RGBA => {
                extensions: [
                    'OES_texture_float', // may be unnecessary
                    'OES_texture_float_linear', // may be unnecessary
                    'OES_texture_half_float',
                    'OES_texture_half_float_linear',
                ],
                dataFormat: RGBA_HALF_FLOAT,
            },
            SINGLE_CHANNEL => {
                extensions: [
                    'OES_texture_float', // may be unnecessary
                    'OES_texture_float_linear', // may be unnecessary
                    'OES_texture_half_float',
                    'OES_texture_half_float_linear',
                ],
                dataFormat: SINGLE_CHANNEL_HALF_FLOAT,
            },
        ],
        UNSIGNED_BYTE => [
            RGBA => {
                extensions: [],
                dataFormat: RGBA_UNSIGNED_BYTE,
            },
            SINGLE_CHANNEL => {
                extensions: [],
                dataFormat: SINGLE_CHANNEL_UNSIGNED_BYTE,
            },
        ],
    ];

    public static function getExtensions(dataType, pixelFormat) return requirements[dataType][pixelFormat].extensions;
    public static function getDataFormat(dataType, pixelFormat) return requirements[dataType][pixelFormat].dataFormat;
}
