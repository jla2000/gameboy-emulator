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
    .{ .description = "LD BC, d16", .size = 3, .cycles = 3, .exec = load(WordReg.BC, WordReg.DE) },
    .{ .description = "LD (BC), A", .size = 3, .cycles = 3, .exec = load(WordReg.PSW, WordReg.BC) },
    .{ .description = "LD A, d8", .size = 2, .cycles = 3, .exec = load(ByteReg.A, RomByte{}) },
};

const ByteReg = enum { A, F, B, C, D, E, H, L };
const WordReg = enum { PSW, BC, DE, HL };
const RomByte = struct {};
const RomWord = struct {};

fn to_byte_regs(comptime reg: WordReg) struct { ByteReg, ByteReg } {
    return comptime switch (reg) {
        .PSW => .{ .A, .F },
        .BC => .{ .B, .C },
        .DE => .{ .D, .E },
        .HL => .{ .H, .L },
    };
}

fn read_byte_reg(comptime reg: ByteReg) u8 {
    return regs[@intFromEnum(reg)];
}

fn write_byte_reg(comptime reg: ByteReg, value: u8) void {
    regs[@intFromEnum(reg)] = value;
}

fn read_word_reg(comptime reg: WordReg) u16 {
    const byte_regs = to_byte_regs(reg);
    return @as(u16, regs[@intFromEnum(byte_regs[0])]) << 8 | @as(u16, regs[@intFromEnum(byte_regs[1])]);
}

fn write_word_reg(comptime reg: WordReg, value: u16) void {
    const byte_regs = to_byte_regs(reg);
    regs[@intFromEnum(byte_regs[0])] = @intCast(value >> 8);
    regs[@intFromEnum(byte_regs[1])] = @intCast(value);
}

fn read_byte_rom(comptime _: RomByte) u8 {
    return mem[pc + 1];
}

fn read_word_rom(comptime _: RomWord) u16 {
    return @as(u16, mem[pc + 1]) << 8 | @as(u16, mem[pc + 2]);
}

fn load(comptime dest: anytype, comptime src: anytype) fn () void {
    const read = comptime switch (@TypeOf(src)) {
        ByteReg => read_byte_reg,
        WordReg => read_word_reg,
        RomByte => read_byte_rom,
        RomWord => read_word_rom,
        else => @compileError("Unsupported source operand: " ++ @typeName(@TypeOf(src))),
    };
    const write = comptime switch (@TypeOf(dest)) {
        ByteReg => write_byte_reg,
        WordReg => write_word_reg,
        else => @compileError("Unsupported destination operand: " ++ @typeName(@TypeOf(src))),
    };

    return struct {
        pub fn load() void {
            write(dest, read(src));
        }
    }.load;
}

pub fn nop() void {}

pub fn step() void {
    const opcode = mem[pc];
    const opcode_def = opcode_table[opcode];

    std.debug.print("0x{x:08}: {s}\n", .{ pc, opcode_def.description });

    opcode_def.exec();
    pc += opcode_def.size;
    cycles += opcode_def.cycles;
}
