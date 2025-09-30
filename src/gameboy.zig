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
    .{ .description = "LD BC, d16", .size = 3, .cycles = 3, .exec = load(.{ .word_reg = .BC }, .word_const) },
    .{ .description = "LD (BC), A", .size = 3, .cycles = 3, .exec = load(.{ .word_reg = .BC }, .{ .byte_reg = .A }) },
};

const OperandTag = enum {
    byte_reg,
    word_reg,
    byte_reg_indirect,
    word_reg_indirect,
    byte_const,
    word_const,
};

const ByteReg = enum { A, F, B, C, D, E, H, L };
const WordReg = enum { PSW, BC, DE, HL };

const Operand = union(OperandTag) {
    byte_reg: ByteReg,
    word_reg: WordReg,
    byte_reg_indirect: ByteReg,
    word_reg_indirect: WordReg,
    byte_const,
    word_const,

    pub fn value_type(comptime self: Operand) type {
        return comptime switch (self) {
            .byte_reg => u8,
            .word_reg => u16,
            .byte_const => u8,
            .word_const => u16,
            else => unreachable,
        };
    }

    pub fn write(comptime self: Operand, comptime T: type, value: T) void {
        switch (self) {
            OperandTag.byte_reg => |reg| regs[@intFromEnum(reg)] = value,
            OperandTag.word_reg => |reg| write_word_reg(reg, value),
            else => unreachable,
        }
    }

    pub fn read(self: Operand, comptime T: type) T {
        return switch (self) {
            OperandTag.byte_reg => |reg| regs[@intFromEnum(reg)],
            else => unreachable,
        };
    }
};

pub fn nop() void {}

fn word_to_byte_regs(comptime reg: WordReg) struct { ByteReg, ByteReg } {
    return comptime switch (reg) {
        .PSW => .{ .A, .F },
        .BC => .{ .B, .C },
        .DE => .{ .D, .E },
        .HL => .{ .H, .L },
    };
}

fn write_word_reg(comptime reg: WordReg, value: u16) void {
    const byte_regs = word_to_byte_regs(reg);
    regs[@intFromEnum(byte_regs[0])] = @intCast(value >> 8);
    regs[@intFromEnum(byte_regs[1])] = @intCast(value);
}

fn read_word_reg(comptime reg: WordReg) u16 {
    const byte_regs = word_to_byte_regs(reg);
    return @as(u16, regs[@intFromEnum(byte_regs[0])]) << 8 | @as(u16, regs[@intFromEnum(byte_regs[1])]);
}

fn read_word(address: u16) u16 {
    return @as(u16, mem[address]) << 8 | @as(u16, mem[address + 1]);
}

fn write_word(address: u16, value: u16) void {
    mem[address] = @intCast(value >> 8);
    mem[address + 1] = @intCast(value);
}

pub fn load(comptime dest_reg: Operand, comptime src_reg: Operand) fn () void {
    return struct {
        pub fn load() void {
            const dst_type = dest_reg.value_type();
            const src_type = src_reg.value_type();

            const value = src_reg.read(src_type);
            dest_reg.write(dst_type, value);
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
