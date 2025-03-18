const std = @import("std");
const gl = @import("zopengl").bindings;
const zstbi = @import("zstbi");

pub const Texture2D = struct {
    const Self = @This();

    id: gl.Uint,

    pub const Format = enum(comptime_int) {
        RGB = gl.RGB,
        RGBA = gl.RGBA,
    };

    pub fn init(
        path: [:0]const u8,
        format: Format,
    ) !Self {
        var image = try zstbi.Image.loadFromFile(
            path,
            0,
        );
        defer image.deinit();

        var id: gl.Uint = undefined;
        gl.genTextures(1, &id);
        gl.bindTexture(gl.TEXTURE_2D, id);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST_MIPMAP_NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            @intFromEnum(format),
            @as(gl.Int, @intCast(image.width)),
            @as(gl.Int, @intCast(image.height)),
            0,
            @intFromEnum(format),
            gl.UNSIGNED_BYTE,
            @ptrCast(image.data),
        );
        gl.generateMipmap(gl.TEXTURE_2D);

        return Self{
            .id = id,
        };
    }

    pub fn deinit(self: Self) void {
        gl.deleteTextures(1, &self.id);
    }

    pub fn bind(self: Self) void {
        gl.bindTexture(gl.TEXTURE_2D, self.id);
    }

    pub fn unbind() void {
        gl.bindTexture(gl.TEXTURE_2D, 0);
    }
};
