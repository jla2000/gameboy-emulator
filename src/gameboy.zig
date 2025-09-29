const std = @import("std");

var regs = std.mem.zeroes([8]u8);
var mem = std.mem.zeroes([1024]u8);
var pc: u16 = 0;
var sp: u16 = 0;

pub fn step() void {
    const opcode = mem[pc];

    switch (mem[pc]) {
        0x00 => {}, // NOP
        0x33 => {
            sp += 1;
        },
        else => {
            std.debug.panic("Unimplemented opcode: 0x{x}", .{opcode});
        },
    }

    pc += 1;
}
