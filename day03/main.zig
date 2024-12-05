const std = @import("std");
const mvzr = @import("./vendor/mvzr.zig");

pub fn main() !void {
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

fn solvePart1(input: []const u8) !usize {
    var result: usize = 0;
    const regex = mvzr.compile("mul\\(\\d{1,3}\\,\\d{1,3}\\)").?;
    var elements = regex.iterator(input);
    while (elements.next()) |element| {
        // 4 = mul(
        const toSkip = 4;
        const found = input[element.start + toSkip .. element.end - 1];
        const commaPos = std.mem.indexOfScalar(u8, found, ',').?;
        const secondDigitPos = commaPos;
        // (firstDigit,secondDigit) no spaces allowed
        const firstDigit = try std.fmt.parseInt(u32, found[0..secondDigitPos], 10);
        // skip comma
        const secondDigit = try std.fmt.parseInt(u32, found[secondDigitPos + 1 ..], 10);
        result += firstDigit * secondDigit;
    }

    return result;
}

fn solvePart2(input: []const u8) !usize {
    var result: usize = 0;
    const regex = mvzr.compile("do(n\\'t)?\\(|mul\\(\\d{1,3}\\,\\d{1,3}\\)").?;
    var elements = regex.iterator(input);
    var do = true;
    while (elements.next()) |element| {
        if (std.mem.eql(u8, "do(", element.slice)) {
            do = true;
            continue;
        }
        if (std.mem.eql(u8, "don\'t(", element.slice)) {
            do = false;
            continue;
        }
        if (!do) {
            continue;
        }
        const toSkip = 4;
        const found = input[element.start + toSkip .. element.end - 1];
        const commaPos = std.mem.indexOfScalar(u8, found, ',').?;
        const secondDigitPos = commaPos;
        const firstDigit = try std.fmt.parseInt(u32, found[0..secondDigitPos], 10);
        const secondDigit = try std.fmt.parseInt(u32, found[secondDigitPos + 1 ..], 10);
        result += firstDigit * secondDigit;
    }

    return result;
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);
    const part2 = try solvePart2(fileContentTest);

    try std.testing.expectEqual(part1, 161);
    try std.testing.expectEqual(part2, 48);
}
