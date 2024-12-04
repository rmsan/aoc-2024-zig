const std = @import("std");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

const direction = enum {
    ASC,
    DESC,
};

inline fn isValid(numbers: *[8]u8, skip: ?usize) bool {
    var prevNumber: ?u8 = null;
    var currentDirection: ?direction = null;
    for (numbers, 0..) |number, index| {
        if (number == 0) {
            break;
        }
        if (skip) |skipIndex| {
            if (skipIndex == index) {
                continue;
            }
        }
        var distance: u8 = 0;
        if (prevNumber) |pNumber| {
            if (pNumber < number) {
                if (currentDirection == direction.DESC) {
                    return false;
                }
                currentDirection = direction.ASC;
                distance = number - pNumber;
            } else {
                if (currentDirection == direction.ASC) {
                    return false;
                }
                currentDirection = direction.DESC;
                distance = pNumber - number;
            }
            if (distance > 3 or distance < 1) {
                return false;
            }
        }
        prevNumber = number;
    }
    return true;
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var elements = std.mem.tokenizeScalar(u8, line, ' ');
        var numbers = std.mem.zeroes([8]u8);
        var index: usize = 0;
        while (elements.next()) |element| {
            const number = try std.fmt.parseInt(u8, element, 10);
            numbers[index] = number;
            index += 1;
        }
        if (isValid(&numbers, null)) {
            result += 1;
        }
    }

    return result;
}

fn solvePart2(input: []const u8) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var elements = std.mem.tokenizeScalar(u8, line, ' ');
        var numbers = std.mem.zeroes([8]u8);
        var index: usize = 0;
        while (elements.next()) |element| {
            const number = try std.fmt.parseInt(u8, element, 10);
            numbers[index] = number;
            index += 1;
        }
        index += 1;

        var goodRun = false;
        var skip: ?usize = null;
        for (0..index) |runIndex| {
            const valid = isValid(&numbers, skip);
            if (valid) {
                goodRun = true;
                break;
            }
            skip = runIndex;
        }

        if (goodRun) {
            result += 1;
        }
    }

    return result;
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);
    const part2 = try solvePart2(fileContentTest);

    try std.testing.expectEqual(part1, 2);
    try std.testing.expectEqual(part2, 4);
}
