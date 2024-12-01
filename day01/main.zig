const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();
    const fileContent = @embedFile("input.txt");

    var timer = try std.time.Timer.start();
    const part1 = try solvePart1(fileContent, &allocator);
    const part2 = try solvePart2(fileContent, &allocator);

    std.debug.print("Part1: {d}\nPart2: {d}\nTime: {d}us\n", .{ part1, part2, timer.lap() / std.time.ns_per_us });
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var left = try std.ArrayList(u32).initCapacity(allocator.*, 1000);
    var right = try std.ArrayList(u32).initCapacity(allocator.*, 1000);
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
    const leftItems = try left.toOwnedSlice();
    const rightItems = try right.toOwnedSlice();
    defer allocator.free(leftItems);
    defer allocator.free(rightItems);

    for (leftItems, 0..) |leftItem, index| {
        const rightItem = rightItems[index];
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
    var left = try std.ArrayList(u32).initCapacity(allocator.*, 1000);
    var bag: [99_999]u8 = [_]u8{0} ** 99_999;
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

    const leftItems = try left.toOwnedSlice();
    defer allocator.free(leftItems);

    for (leftItems) |leftItem| {
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
