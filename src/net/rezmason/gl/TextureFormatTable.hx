package net.rezmason.gl;

typedef TextureFormat = {
    var extensions(default, null): Array<String>;
    var dataFormat(default, null): DataFormat;
    var unpackAlignment(default, null): UInt;
}

class TextureFormatTable {

    static var requirements:Map<DataType, Map<PixelFormat, TextureFormat>> = [
        FLOAT => [
            RGBA => {
                extensions: [
                    'OES_texture_float',
                    'OES_texture_float_linear',
                ],
                dataFormat: RGBA_FLOAT,
                unpackAlignment: 4,
            },
            SINGLE_CHANNEL => {
                extensions: [
                    'OES_texture_float',
                    'OES_texture_float_linear',
                ],
                dataFormat: SINGLE_CHANNEL_FLOAT,
                unpackAlignment: 1,
            },
        ],
        HALF_FLOAT => [
            RGBA => {
                extensions: [
                    // 'OES_texture_float', // may be unnecessary
                    // 'OES_texture_float_linear', // may be unnecessary
                    'OES_texture_half_float',
                    'OES_texture_half_float_linear',
                ],
                dataFormat: RGBA_HALF_FLOAT,
                unpackAlignment: 4,
            },
            SINGLE_CHANNEL => {
                extensions: [
                    // 'OES_texture_float', // may be unnecessary
                    // 'OES_texture_float_linear', // may be unnecessary
                    'OES_texture_half_float',
                    'OES_texture_half_float_linear',
                ],
                dataFormat: SINGLE_CHANNEL_HALF_FLOAT,
                unpackAlignment: 1,
            },
        ],
        UNSIGNED_BYTE => [
            RGBA => {
                extensions: [],
                dataFormat: RGBA_UNSIGNED_BYTE,
                unpackAlignment: 4,
            },
            SINGLE_CHANNEL => {
                extensions: [],
                dataFormat: SINGLE_CHANNEL_UNSIGNED_BYTE,
                unpackAlignment: 1,
            },
        ],
    ];

    public static function getFormat(dataType, pixelFormat) return requirements[dataType][pixelFormat];
}
