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
    var left = try std.array_list.Managed(u32).initCapacity(allocator.*, 1000);
    var right = try std.array_list.Managed(u32).initCapacity(allocator.*, 1000);
    defer left.deinit();
    defer right.deinit();
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var first: bool = true;
        var elements = std.mem.tokenizeScalar(u8, line, ' ');
        while (elements.next()) |element| {
            const number = try std.fmt.parseInt(u32, element, 10);
            if (first) {
                left.appendAssumeCapacity(number);
                first = false;
            } else {
                right.appendAssumeCapacity(number);
            }
        }
    }
    std.mem.sortUnstable(u32, left.items, {}, std.sort.asc(u32));
    std.mem.sortUnstable(u32, right.items, {}, std.sort.asc(u32));

    for (left.items, 0..) |leftItem, index| {
        const rightItem = right.items[index];
        if (rightItem > leftItem) {
            result += rightItem - leftItem;
        } else {
            result += leftItem - rightItem;
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var left = try std.array_list.Managed(u32).initCapacity(allocator.*, 1000);
    var bag = std.mem.zeroes([99_999]u8);
    defer left.deinit();
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var first: bool = true;
        var elements = std.mem.tokenizeScalar(u8, line, ' ');
        while (elements.next()) |element| {
            const number = try std.fmt.parseInt(u32, element, 10);
            if (first) {
                left.appendAssumeCapacity(number);
                first = false;
            } else {
                bag[number] += 1;
            }
        }
    }

    for (left.items) |leftItem| {
        result += leftItem * bag[leftItem];
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 11);
    try std.testing.expectEqual(part2, 31);
}
