const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
});

const gb = @import("gameboy.zig");

const WINDOW_SCALE = 4;
const WINDOW_WIDTH = WINDOW_SCALE * gb.DISPLAY_WIDTH;
const WINDOW_HEIGHT = WINDOW_SCALE * gb.DISPLAY_HEIGHT;

pub fn main() !void {
    gb.step();

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "gameboy-emulator");
    defer rl.CloseWindow();

    const display_texture = rl.LoadTextureFromImage(rl.Image{
        .data = null,
        .width = gb.DISPLAY_WIDTH,
        .height = gb.DISPLAY_HEIGHT,
        .format = rl.PIXELFORMAT_UNCOMPRESSED_GRAYSCALE,
        .mipmaps = 1,
    });

    var random_data = std.mem.zeroes([gb.DISPLAY_WIDTH * gb.DISPLAY_HEIGHT]u8);
    for (&random_data) |*value| {
        value.* = @intCast(rl.GetRandomValue(0, 255));
    }

    rl.UpdateTexture(display_texture, &random_data);

    rl.SetTargetFPS(60);
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        rl.DrawTexturePro(display_texture, rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(display_texture.width),
            .height = @floatFromInt(display_texture.height),
        }, rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = WINDOW_WIDTH,
            .height = WINDOW_HEIGHT,
        }, rl.Vector2{
            .x = 0,
            .y = 0,
        }, 0, rl.WHITE);
        rl.DrawFPS(0, 0);
        rl.EndDrawing();
    }
}
