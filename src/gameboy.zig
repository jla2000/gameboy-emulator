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
    nop(),
    load(WordReg.BC, LoadWord.ROM),
    load(Indirect{WordReg.BC}, ByteReg.A),
};

const ByteReg = enum { A, F, B, C, D, E, H, L };
const WordReg = enum { PSW, BC, DE, HL };
const LoadByte = enum { ROM };
const LoadWord = enum { ROM };
const Indirect = struct { WordReg };

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

fn load_byte(comptime src: LoadByte) u8 {
    return switch (src) {
        .ROM => mem[pc + 1],
    };
}

fn load_word(comptime src: LoadWord) u16 {
    return switch (src) {
        .ROM => @as(u16, mem[pc + 1]) << 8 | @as(u16, mem[pc + 2]),
    };
}

fn load_indirect(comptime src: Indirect) u8 {
    const address = read_word_reg(src[0]);
    return mem[address];
}

fn write_indirect(comptime dst: Indirect, value: u8) void {
    const address = read_word_reg(dst[0]);
    mem[address] = value;
}

fn load(comptime dest: anytype, comptime src: anytype) Opcode {
    const read, const read_size, const read_cycles = comptime switch (@TypeOf(src)) {
        ByteReg => .{ read_byte_reg, 0, 0 },
        WordReg => .{ read_word_reg, 0, 0 },
        LoadByte => .{ load_byte, 1, 1 },
        LoadWord => .{ load_word, 2, 2 },
        Indirect => .{ load_indirect, 0, 1 },
        else => @compileError("Unsupported source operand: " ++ @typeName(@TypeOf(src))),
    };
    const write, const write_cycles = comptime switch (@TypeOf(dest)) {
        ByteReg => .{ write_byte_reg, 0 },
        WordReg => .{ write_word_reg, 0 },
        Indirect => .{ write_indirect, 1 },
        else => @compileError("Unsupported destination operand: " ++ @typeName(@TypeOf(src))),
    };

    return .{
        .cycles = 1 + read_cycles + write_cycles,
        .size = 1 + read_size,
        .description = "LD " ++ format_operand(dest) ++ ", " ++ format_operand(src),
        .exec = struct {
            fn load() void {
                write(dest, read(src));
            }
        }.load,
    };
}

fn format_operand(comptime operand: anytype) []const u8 {
    return comptime switch (@TypeOf(operand)) {
        ByteReg => @tagName(operand),
        WordReg => @tagName(operand),
        LoadByte => "d8",
        LoadWord => "d16",
        Indirect => "(" ++ @tagName(operand[0]) ++ ")",
        else => @compileError("Unknown operand: " ++ @typeName(@TypeOf(operand))),
    };
}

pub fn nop() Opcode {
    return .{ .description = "NOP", .size = 1, .cycles = 1, .exec = struct {
        fn nop() void {}
    }.nop };
}

pub fn step() void {
    const opcode = mem[pc];
    const opcode_def = opcode_table[opcode];

    std.debug.print("0x{x:08}: {s}\n", .{ pc, opcode_def.description });

    opcode_def.exec();
    pc += opcode_def.size;
    cycles += opcode_def.cycles;
}
