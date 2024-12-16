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

const Part = enum { Part1, Part2 };

inline fn digits(number: usize) usize {
    return std.math.log10(number) + 1;
}

// return index of an already seen number, otherwise process it next blink
fn indexOf(number: usize, indices: *std.AutoHashMap(usize, usize), todo: *std.ArrayList(usize)) !usize {
    const size = indices.*.count();

    const entry = try indices.*.getOrPut(number);
    if (entry.found_existing) {
        return entry.value_ptr.*;
    }
    entry.value_ptr.* = size;

    todo.*.appendAssumeCapacity(number);
    return size;
}

fn solve(comptime part: Part, input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var stones = try std.ArrayList([2]?usize).initCapacity(allocator.*, 5000);
    var indices = std.AutoHashMap(usize, usize).init(allocator.*);
    var newStones = try std.ArrayList(usize).initCapacity(allocator.*, 8);
    var stonesAmount = try std.ArrayList(usize).initCapacity(allocator.*, 8);

    defer stones.deinit();
    defer indices.deinit();
    defer newStones.deinit();
    defer stonesAmount.deinit();

    var numberIndex: usize = 0;
    var numberIterator = std.mem.tokenizeScalar(u8, input, ' ');
    while (numberIterator.next()) |numberString| : (numberIndex += 1) {
        const number = try std.fmt.parseInt(usize, numberString, 10);
        try indices.put(number, numberIndex);
        newStones.appendAssumeCapacity(number);
        stonesAmount.appendAssumeCapacity(1);
    }

    const iterations = switch (part) {
        .Part1 => 25,
        .Part2 => 75,
    };

    for (0..iterations) |_| {
        const numbers = newStones;
        newStones = try std.ArrayList(usize).initCapacity(allocator.*, 200);

        for (numbers.items) |number| {
            if (number == 0) {
                const toAdd = [2]?usize{ try indexOf(1, &indices, &newStones), undefined };
                stones.appendAssumeCapacity(toAdd);
                continue;
            }

            const digitCount = digits(number);
            if (digitCount % 2 == 0) {
                const left = @divFloor(number, std.math.pow(usize, 10, digitCount / 2));
                const right = @mod(number, std.math.pow(usize, 10, digitCount / 2));
                const toAdd = [2]?usize{ try indexOf(left, &indices, &newStones), try indexOf(right, &indices, &newStones) };
                stones.appendAssumeCapacity(toAdd);
                continue;
            }

            const toAdd = [2]?usize{ try indexOf(number * 2024, &indices, &newStones), undefined };
            stones.appendAssumeCapacity(toAdd);
        }

        const indicesSize = indices.count();
        var next = try std.ArrayList(usize).initCapacity(allocator.*, indicesSize);
        for (0..indicesSize) |_| {
            next.appendAssumeCapacity(0);
        }

        for (stones.items, 0..) |stone, stoneIndex| {
            const amount = stonesAmount.items[stoneIndex];
            next.items[stone[0].?] += amount;
            if (stone[1]) |second| {
                next.items[second] += amount;
            }
        }

        stonesAmount = next;
    }

    for (stonesAmount.items) |item| {
        result += item;
    }

    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return solve(Part.Part1, input, allocator);
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    return solve(Part.Part2, input, allocator);
}

test "test-input" {
    // yeah, yeah.. I know
    var arenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arenaAllocator.deinit();
    var allocator = arenaAllocator.allocator();
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 55312);
    try std.testing.expectEqual(part2, 65601038650482);
}
