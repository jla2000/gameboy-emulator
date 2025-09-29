const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
});

const Register = enum {
    A, B, C, D, E, F, H, L,
};

const Flags = enum {
    Z, N, H, C,
};

pub fn main() !void {
    const regs = std.mem.zeroes([8]u8);
    const mem = std.mem.zeroes([0x1000]u8);
    const pc: u16 = 0;

    _ = regs;
    _ = mem;
    _ = pc;

    rl.InitWindow(800, 600, "gameboy-emulator");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawFPS(0, 0);
        rl.EndDrawing();
    }
}
