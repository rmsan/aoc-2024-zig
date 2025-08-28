const std = @import("std");

pub fn main() !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = arenaAllocator.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part1Time = timer.lap() / std.time.ns_per_us;
    const part2 = try solvePart2(fileContent, &allocator);
    const part2Time = timer.lap() / std.time.ns_per_us;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}us\n", .{ part1, part2, part1Time, part2Time });
}

fn check(testValue: usize, testeeList: []usize, index: usize, concat: bool) bool {
    const testee = testeeList[index];
    if (index == 0) {
        if (testValue == testee) {
            return true;
        }
        return false;
    }

    const remainder = @mod(testValue, testee);

    if (remainder == 0 and check(@divFloor(testValue, testee), testeeList, index - 1, concat)) {
        return true;
    }
    if (concat and endsWith(testValue, testee)) {
        // a / (10 ^ digits(b))
        // here division and floor
        // example: a = 123, b = 23
        // digits(b)  = 2
        // 123 / (10 ^ 2)
        // 123 / 100 = 1
        const testValueNew: usize = @divFloor(testValue, std.math.pow(usize, 10, digits(testee)));
        if (check(testValueNew, testeeList, index - 1, true)) {
            return true;
        }
    }

    if (testValue < testee) {
        return false;
    }
    return check(testValue - testee, testeeList, index - 1, concat);
}

fn endsWith(a: usize, b: usize) bool {
    if (a < b) {
        return false;
    }
    // (a - b) % (10 ^ digits(b))
    // example: a = 123, b = 23
    // digits(b)  = 2
    // (123 - 23) % (10 ^ 2)
    // (100) % (100) = 0
    return (@mod(a - b, std.math.pow(usize, 10, digits(b)))) == 0;
}

fn digits(number: usize) usize {
    // log_10(number) + 1
    // example: number = 1234
    // log_10(1234) + 1
    // 3 + 1 = 4
    return std.math.log10(number) + 1;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var elements = std.mem.tokenizeScalar(u8, line, ':');
        const toTestString = elements.next().?;
        const toTest = try std.fmt.parseInt(usize, toTestString, 10);
        const testeesString = elements.next().?;
        var testees = std.mem.tokenizeScalar(u8, testeesString, ' ');
        var testeeList = try std.array_list.Managed(usize).initCapacity(allocator.*, 12);
        defer testeeList.deinit();
        while (testees.next()) |testee| {
            const testeeNumber = try std.fmt.parseInt(usize, testee, 10);
            testeeList.appendAssumeCapacity(testeeNumber);
        }
        if (check(toTest, testeeList.items, testeeList.items.len - 1, false)) {
            result += toTest;
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var elements = std.mem.tokenizeScalar(u8, line, ':');
        const toTestString = elements.next().?;
        const toTest = try std.fmt.parseInt(usize, toTestString, 10);
        const testeesString = elements.next().?;
        var testees = std.mem.tokenizeScalar(u8, testeesString, ' ');
        var testeeList = try std.array_list.Managed(usize).initCapacity(allocator.*, 12);
        defer testeeList.deinit();
        while (testees.next()) |testee| {
            const testeeNumber = try std.fmt.parseInt(usize, testee, 10);
            testeeList.appendAssumeCapacity(testeeNumber);
        }
        const indexToStart = testeeList.items.len - 1;
        if (check(toTest, testeeList.items, indexToStart, false)) {
            result += toTest;
        } else if (check(toTest, testeeList.items, indexToStart, true)) {
            result += toTest;
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 3749);
    try std.testing.expectEqual(part2, 11387);
}

test "endwith" {
    {
        const result = endsWith(67016584, 584);
        const toTestNew: usize = @divFloor(67016584, std.math.pow(usize, 10, digits(584)));
        try std.testing.expectEqual(result, true);
        try std.testing.expectEqual(toTestNew, 67016);
    }
    {
        const result = endsWith(123456, 57);
        try std.testing.expectEqual(result, false);
    }
}
