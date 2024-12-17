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

const Part = enum { Part1, Part2 };

inline fn det(a: isize, b: isize, c: isize, d: isize) isize {
    return a * d - b * c;
}

fn solve(comptime part: Part, input: []const u8) !isize {
    var result: isize = 0;
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");

    while (segments.next()) |segment| {
        var lines = std.mem.tokenizeScalar(u8, segment, '\n');
        var A: [2]isize = std.mem.zeroes([2]isize);
        var B: [2]isize = std.mem.zeroes([2]isize);
        var prize: [2]isize = std.mem.zeroes([2]isize);
        const buttonAString = lines.next().?;
        const buttonBString = lines.next().?;
        const prizeString = lines.next().?;

        const aCommaPos = std.mem.indexOfScalar(u8, buttonAString, ',').?;
        A[0] = try std.fmt.parseInt(isize, buttonAString[12..aCommaPos], 10);
        A[1] = try std.fmt.parseInt(isize, buttonAString[aCommaPos + 4 ..], 10);

        const bCommaPos = std.mem.indexOfScalar(u8, buttonBString, ',').?;
        B[0] = try std.fmt.parseInt(isize, buttonBString[12..bCommaPos], 10);
        B[1] = try std.fmt.parseInt(isize, buttonBString[bCommaPos + 4 ..], 10);

        const prizeCommaPos = std.mem.indexOfScalar(u8, prizeString, ',').?;
        prize[0] = try std.fmt.parseInt(isize, prizeString[9..prizeCommaPos], 10);
        prize[1] = try std.fmt.parseInt(isize, prizeString[prizeCommaPos + 4 ..], 10);
        switch (part) {
            .Part1 => {},
            .Part2 => {
                prize[0] += 10_000_000_000_000;
                prize[1] += 10_000_000_000_000;
            },
        }

        const ax = A[0];
        const ay = A[1];
        const bx = B[0];
        const by = B[1];
        const px = prize[0];
        const py = prize[1];

        const d = det(ax, bx, ay, by);
        if (d == 0) {
            continue;
        }

        const d1 = det(px, py, bx, by);
        if (@mod(d1, d) != 0) {
            continue;
        }

        const a = @divFloor(d1, d);

        const d2 = det(ax, ay, px, py);
        if (@mod(d2, d) != 0) {
            continue;
        }

        const b = @divFloor(d2, d);

        result += a * 3 + b;
    }

    return result;
}

fn solvePart1(input: []const u8) !isize {
    return solve(Part.Part1, input);
}

fn solvePart2(input: []const u8) !isize {
    return solve(Part.Part2, input);
}

test "test-input" {
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest);
    const part2 = try solvePart2(fileContentTest);

    try std.testing.expectEqual(part1, 480);
    try std.testing.expectEqual(part2, 875318608908);
}
