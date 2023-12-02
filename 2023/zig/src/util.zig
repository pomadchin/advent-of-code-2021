pub const std = @import("std");
pub const Allocator = std.mem.Allocator;
pub const List = std.ArrayList;
pub const Map = std.AutoHashMap;
pub const StrMap = std.StringHashMap;
pub const BitSet = std.DynamicBitSet;
pub const Tuple = std.meta.Tuple;
pub const Str = []const u8;

pub var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

pub const test_allocator = std.testing.allocator;

// Add utility functions here

// Useful stdlib functions
pub const tokenize = std.mem.tokenize;
pub const split = std.mem.split;
pub const indexOf = std.mem.indexOfScalar;
pub const indexOfAny = std.mem.indexOfAny;
pub const indexOfStr = std.mem.indexOfPosLinear;
pub const lastIndexOf = std.mem.lastIndexOfScalar;
pub const lastIndexOfAny = std.mem.lastIndexOfAny;
pub const lastIndexOfStr = std.mem.lastIndexOfLinear;
pub const trim = std.mem.trim;
pub const sliceMin = std.mem.min;
pub const sliceMax = std.mem.max;
pub const eql = std.mem.eql;

pub const parseInt = std.fmt.parseInt;
pub const parseFloat = std.fmt.parseFloat;

pub const min = std.math.min;
pub const min3 = std.math.min3;
pub const max = std.math.max;
pub const max3 = std.math.max3;

pub const print = std.debug.print;
pub const assert = std.debug.assert;

pub const sort = std.sort.sort;
pub const asc = std.sort.asc;
pub const desc = std.sort.desc;

pub const isDigit = std.ascii.isDigit;

pub fn splitStr(buffer: []const u8, delimiter: []const u8) std.mem.SplitIterator(u8, std.mem.DelimiterType.sequence) {
    return std.mem.split(u8, buffer, delimiter);
}

pub fn splitStrDropFirst(buffer: []const u8, delimiter: []const u8) std.mem.SplitIterator(u8, std.mem.DelimiterType.sequence) {
    var it = splitStr(buffer, delimiter);
    _ = it.next().?;
    return it;
}

pub fn foldSlice(
    comptime T: type,
    slice: []const T,
    initial: T,
    func: *const fn (T, T) T,
) T {
    var acc = initial;
    for (slice) |element| acc = func(acc, element);
    return acc;
}

// var acc = util.foldIteratorStrMap(usize, bag.valueIterator(), 1, struct {
//     fn func(a: usize, x: usize) usize {
//         return a * x;
//     }
// }.func);
pub fn foldIteratorStrMap(
    comptime T: type,
    iterator: StrMap(T).ValueIterator,
    initial: T,
    func: *const fn (T, T) T,
) T {
    var acc = initial;
    var it = iterator;
    while (it.next()) |element| acc = func(acc, element.*);
    return acc;
}

// ---------------------- //
// Below functions I discovered on a zig reddit, very helpful. Grabbed from the @danvk github repo.
// I will use that repo as a guide to discover a better approach to writing zig.
// ---------------------- //

// Read u32s delimited by spaces or tabs from a line of text.
pub fn readInts(comptime IntType: type, line: []const u8, nums: *std.ArrayList(IntType)) !void {
    var it = std.mem.splitAny(u8, line, ", \t");
    while (it.next()) |s| {
        if (s.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(IntType, s, 10);
        try nums.append(num);
    }
}

pub fn extractIntsIntoBuf(comptime IntType: type, str: []const u8, buf: []IntType) ![]IntType {
    var i: usize = 0;
    var n: usize = 0;

    while (i < str.len) {
        const c = str[i];
        if (isDigit(c)) {
            const start = i;
            i += 1;
            while (i < str.len) {
                const c2 = str[i];
                if (!isDigit(c2)) {
                    break;
                }
                i += 1;
            }
            buf[n] = try std.fmt.parseInt(IntType, str[start..i], 10);
            n += 1;
        } else {
            i += 1;
        }
    }
    return buf[0..n];
}

pub fn splitOne(line: []const u8, delim: []const u8) ?struct { head: []const u8, rest: []const u8 } {
    const maybeIdx = std.mem.indexOf(u8, line, delim);
    // XXX is there a more idiomatic way to write this pattern?
    if (maybeIdx) |idx| {
        return .{ .head = line[0..idx], .rest = line[(idx + delim.len)..] };
    } else {
        return null;
    }
}

pub fn splitIntoArrayList(input: []const u8, delim: []const u8, array_list: *std.ArrayList([]const u8)) !void {
    array_list.clearAndFree();
    var it = std.mem.splitSequence(u8, input, delim);
    while (it.next()) |part| {
        try array_list.append(part);
    }
    // std.fmt.bufPrint(buf: []u8, comptime fmt: []const u8, args: anytype)
    // std.fmt.bufPrintIntToSlice(buf: []u8, value: anytype, base: u8, case: Case, options: FormatOptions)
}

// Split the string into a pre-allocated buffer of slices.
// The buffer must be large enough to accommodate the number of parts.
// The returned slices point into the input string.
pub fn splitIntoBuf(str: []const u8, delim: []const u8, buf: [][]const u8) [][]const u8 {
    var rest = str;
    var i: usize = 0;
    while (splitOne(rest, delim)) |s| {
        buf[i] = s.head;
        rest = s.rest;
        i += 1;
    }
    buf[i] = rest;
    i += 1;
    return buf[0..i];
}

pub fn readInputFile(filename: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    const fileSize = stat.size;
    return try file.reader().readAllAlloc(allocator, fileSize);
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualDeep = std.testing.expectEqualDeep;

test "splitIntoBuf" {
    var buf: [8][]const u8 = undefined;
    const parts = splitIntoBuf("abc,def,,gh12", ",", &buf);
    try expectEqual(@as(usize, 4), parts.len);
    try expectEqualDeep(@as([]const u8, "abc"), parts[0]);
    try expectEqualDeep(@as([]const u8, "def"), parts[1]);
    try expectEqualDeep(@as([]const u8, ""), parts[2]);
    try expectEqualDeep(@as([]const u8, "gh12"), parts[3]);
    // const expected = [_][]const u8{ "abc", "def", "", "gh12" };
    // expectEqualDeep(@as([][]const u8, &[_][]const u8{ "abc", "def", "", "gh12" }), parts);
}

test "extractIntsIntoBuf" {
    var buf: [8]i32 = undefined;
    var ints = try extractIntsIntoBuf(i32, "12, 38, -233", &buf);
    try expect(eql(i32, &[_]i32{ 12, 38, -233 }, ints));

    ints = try extractIntsIntoBuf(i32, "zzz343344ddkd", &buf);
    try expect(eql(i32, &[_]i32{343344}, ints));

    ints = try extractIntsIntoBuf(i32, "not a number", &buf);
    try expect(eql(i32, &[_]i32{}, ints));
}
