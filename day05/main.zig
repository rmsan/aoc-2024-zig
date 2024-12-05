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

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");

    const rulesSegment = segments.next().?;
    const updatesSegment = segments.next().?;

    var rulesIterator = std.mem.tokenizeScalar(u8, rulesSegment, '\n');
    var updatesIterator = std.mem.tokenizeScalar(u8, updatesSegment, '\n');

    var rulesMap = std.AutoHashMap(u8, std.AutoHashMap(u8, void)).init(allocator.*);
    defer {
        var it = rulesMap.valueIterator();
        while (it.next()) |item| {
            item.deinit();
        }
        rulesMap.deinit();
    }
    while (rulesIterator.next()) |ruleSegment| {
        var numbers = std.mem.tokenizeScalar(u8, ruleSegment, '|');
        const firstNumberString = numbers.next().?;
        const secondNumberString = numbers.next().?;
        const firstNumber = try std.fmt.parseInt(u8, firstNumberString, 10);
        const secondNumber = try std.fmt.parseInt(u8, secondNumberString, 10);
        const entry = try rulesMap.getOrPut(secondNumber);
        if (!entry.found_existing) {
            var map = std.AutoHashMap(u8, void).init(allocator.*);
            try map.put(firstNumber, {});
            entry.value_ptr.* = map;
        } else {
            try entry.value_ptr.*.put(firstNumber, {});
        }
    }

    var updateList = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator.*, 250);
    defer {
        const innerListArray: []std.ArrayList(u8) = updateList.items;
        for (innerListArray) |innerList| {
            innerList.deinit();
        }
        updateList.deinit();
    }
    while (updatesIterator.next()) |updateSegment| {
        var updateInnerList = try std.ArrayList(u8).initCapacity(allocator.*, 25);
        var numbers = std.mem.tokenizeScalar(u8, updateSegment, ',');
        while (numbers.next()) |numberString| {
            const number = try std.fmt.parseInt(u8, numberString, 10);
            updateInnerList.appendAssumeCapacity(number);
        }
        updateList.appendAssumeCapacity(updateInnerList);
    }

    for (updateList.items) |list| {
        const valid = isSortedBy(rulesMap, list.items);

        if (valid) {
            const middle = @divFloor(list.items.len - 1, 2);
            result += list.items[middle];
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var segments = std.mem.tokenizeSequence(u8, input, "\n\n");

    const rulesSegment = segments.next().?;
    const updatesSegment = segments.next().?;

    var rulesIterator = std.mem.tokenizeScalar(u8, rulesSegment, '\n');
    var updatesIterator = std.mem.tokenizeScalar(u8, updatesSegment, '\n');

    var rulesMap = std.AutoHashMap(u8, std.AutoHashMap(u8, void)).init(allocator.*);
    defer {
        var it = rulesMap.valueIterator();
        while (it.next()) |item| {
            item.deinit();
        }
        rulesMap.deinit();
    }
    while (rulesIterator.next()) |ruleSegment| {
        var numbers = std.mem.tokenizeScalar(u8, ruleSegment, '|');
        const firstNumberString = numbers.next().?;
        const secondNumberString = numbers.next().?;
        const firstNumber = try std.fmt.parseInt(u8, firstNumberString, 10);
        const secondNumber = try std.fmt.parseInt(u8, secondNumberString, 10);
        const entry = try rulesMap.getOrPut(secondNumber);
        if (!entry.found_existing) {
            var map = std.AutoHashMap(u8, void).init(allocator.*);
            try map.put(firstNumber, {});
            entry.value_ptr.* = map;
        } else {
            try entry.value_ptr.*.put(firstNumber, {});
        }
    }

    var updateList = try std.ArrayList(std.ArrayList(u8)).initCapacity(allocator.*, 250);
    defer {
        const innerListArray: []std.ArrayList(u8) = updateList.items;
        for (innerListArray) |innerList| {
            innerList.deinit();
        }
        updateList.deinit();
    }
    while (updatesIterator.next()) |updateSegment| {
        var updateInnerList = try std.ArrayList(u8).initCapacity(allocator.*, 25);
        var numbers = std.mem.tokenizeScalar(u8, updateSegment, ',');
        while (numbers.next()) |numberString| {
            const number = try std.fmt.parseInt(u8, numberString, 10);
            updateInnerList.appendAssumeCapacity(number);
        }
        updateList.appendAssumeCapacity(updateInnerList);
    }

    for (updateList.items) |list| {
        const valid = isSortedBy(rulesMap, list.items);

        if (!valid) {
            std.mem.sortUnstable(u8, list.items, rulesMap, cmdRule);
            const middle = @divFloor(list.items.len - 1, 2);
            result += list.items[middle];
        }
    }

    return result;
}

fn isSortedBy(rulesMap: std.AutoHashMap(u8, std.AutoHashMap(u8, void)), items: []u8) bool {
    for (0..items.len - 1) |itemIndex| {
        const a = items[itemIndex];
        const b = items[itemIndex + 1];
        if (!cmdRule(rulesMap, a, b)) {
            return false;
        }
    }
    return true;
}

fn cmdRule(context: std.AutoHashMap(u8, std.AutoHashMap(u8, void)), a: u8, b: u8) bool {
    const hasRule = context.get(b);
    if (hasRule) |rule| {
        return rule.contains(a);
    }
    return false;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 143);
    try std.testing.expectEqual(part2, 123);
}
