const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
});

const gb = @import("gameboy.zig");

pub fn main() !void {
    gb.step();

    rl.InitWindow(800, 600, "gameboy-emulator");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);
    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        rl.DrawFPS(0, 0);
        rl.EndDrawing();
    }
}
