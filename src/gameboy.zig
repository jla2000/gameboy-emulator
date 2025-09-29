const std = @import("std");

var mem = std.mem.zeroes([1024]u8);
var pc: u16 = 0;
var sp: u16 = 0;

pub fn step() void {
    const opcode = mem[pc];

    switch (mem[pc]) {
        else => {
            std.debug.print("Unimplemented opcode: 0x{x}", .{opcode});
        },
    }

    pc += 1;
}
