const std = @import("std");

var regs = std.mem.zeroes([8]u8);
var mem = std.mem.zeroes([1024]u8);
var pc: u16 = 0;
var sp: u16 = 0;
var cycles: usize = 0;

const Opcode = struct {
    description: []const u8,
    size: u8,
    cycles: u8,
    exec: *const fn () void,
};

const opcode_table = [_]Opcode{
    .{ .description = "NOP", .size = 1, .cycles = 1, .exec = nop },
    .{ .description = "LD BC, d16", .size = 3, .cycles = 3, .exec = load(.{ .word_reg = .{ .BC, .Normal } }, .word_const) },
    .{ .description = "LD (BC), A", .size = 3, .cycles = 3, .exec = load(.{ .word_reg = .{ .BC, .Indirect } }, .{ .byte_reg = .{ .A, .Normal } }) },
};

const OperandTag = enum {
    byte_reg,
    word_reg,
    byte_const,
    word_const,
};

const ByteReg = enum { A, F, B, C, D, E, H, L };
const WordReg = enum { PSW, BC, DE, HL };

const Addressing = enum {
    Normal,
    Indirect,
};

const Operand = union(OperandTag) {
    byte_reg: struct { ByteReg, Addressing },
    word_reg: struct { WordReg, Addressing },
    byte_const,
    word_const,
};

pub fn nop() void {}

pub fn load(comptime dest_reg: Operand, comptime src_reg: Operand) fn () void {
    return struct {
        pub fn load() void {
            var value = std.mem.zeroes(comptime switch (dest_reg) {
                .byte_reg => u8,
                .word_reg => u16,
                else => unreachable,
            });

            switch (src_reg) {
                OperandTag.byte_reg => |byte_reg| value = regs[@intFromEnum(byte_reg[0])],
                OperandTag.word_reg => |word_reg| {
                    const upper, const lower = switch (word_reg[0]) {
                        .PSW => .{ .A, .F },
                        .BC => .{ .B, .C },
                        .DE => .{ .D, .E },
                        .HL => .{ .H, .L },
                    };
                    value = @as(u16, regs[@intFromEnum(upper)]) << 8 | @as(u16, regs[@intFromEnum(lower)]);

                    switch (word_reg[1]) {
                        Addressing.Normal => {},
                        Addressing.Indirect => value = mem[value],
                    }
                },
                OperandTag.byte_const => value = mem[pc + 1],
                OperandTag.word_const => value = @as(u16, mem[pc + 1]) << 8 | @as(u16, mem[pc + 2]),
            }

            switch (dest_reg) {
                OperandTag.byte_reg => |byte_reg| regs[@intFromEnum(byte_reg[0])] = value,
                OperandTag.word_reg => |word_reg| {
                    const upper: ByteReg, const lower: ByteReg = switch (word_reg[0]) {
                        .PSW => .{ .A, .F },
                        .BC => .{ .B, .C },
                        .DE => .{ .D, .E },
                        .HL => .{ .H, .L },
                    };
                    switch (word_reg[1]) {
                        Addressing.Normal => {
                            regs[@intFromEnum(upper)] = @intCast(value >> 8);
                            regs[@intFromEnum(lower)] = @intCast(value);
                        },
                        Addressing.Indirect => {
                            const addr = @as(u16, regs[@intFromEnum(upper)]) << 8 | @as(u16, regs[@intFromEnum(lower)]);
                            mem[addr] = @intCast(value >> 8);
                            mem[addr + 1] = @intCast(value);
                        },
                    }
                },
                else => unreachable,
            }
        }
    }.load;
}

pub fn step() void {
    const opcode = mem[pc];
    const opcode_def = opcode_table[opcode];

    std.debug.print("0x{x:08}: {s}\n", .{ pc, opcode_def.description });

    opcode_def.exec();
    pc += opcode_def.size;
    cycles += opcode_def.cycles;
}
