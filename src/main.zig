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

fn gen_opcode(comptime opcode: u8) OpcodeFn {
    switch (opcode) {
        0x00 => return struct {
            pub fn exec() void {
                std.debug.print("NOP\n", .{});
            }
        }.exec,
        else => return struct {
            pub fn exec() void {
                std.debug.print("Unimplemented opcode: 0x{x}\n", .{opcode});
            }
        }.exec,
    }
}

const OpcodeFn = *const fn() void;
const OpcodeTable = [256]OpcodeFn;

fn gen_opcode_table() OpcodeTable {
    comptime var table: OpcodeTable = undefined;

    comptime for (0..table.len) |opcode| {
        table[opcode] = gen_opcode(opcode);
    };

    return table;
}

pub fn main() !void {
    const opcode_table = gen_opcode_table();

    const regs = std.mem.zeroes([8]u8);
    const mem = std.mem.zeroes([0x1000]u8);
    var pc: u16 = 0;

    const opcode = mem[pc];
    opcode_table[opcode]();
    pc += 1;

    _ = regs;

    rl.InitWindow(800, 600, "gb_emulator");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    while (!rl.WindowShouldClose()) {
        rl.BeginDrawing();
        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawFPS(0, 0);
        rl.EndDrawing();
    }
}
