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
    const part2Time = timer.lap() / std.time.ns_per_ms;

    std.debug.print("Part1: {d}\nPart2: {d}\nTime1: {d}us\nTime2: {d}ms\n", .{ part1, part2, part1Time, part2Time });
}

fn getGridList(input: []const u8, allocator: *std.mem.Allocator) !std.ArrayList([]u8) {
    var grid = try std.ArrayList([]u8).initCapacity(allocator.*, 130);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const mutLine = try allocator.alloc(u8, line.len);
        std.mem.copyForwards(u8, mutLine, line);
        grid.appendAssumeCapacity(mutLine);
    }
    return grid;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var grid = try getGridList(input, allocator);
    defer {
        for (grid.items) |item| {
            allocator.free(item);
        }
        grid.deinit();
    }

    const size = grid.items.len;

    var start = std.mem.zeroes([2]usize);
    for (grid.items, 0..) |row, rowIndex| {
        for (row, 0..) |_, colIndex| {
            if (row[colIndex] == '^') {
                start = [_]usize{ rowIndex, colIndex };
            }
        }
    }

    patrol(&grid, start, size);

    for (grid.items) |row| {
        for (row) |col| {
            if (col == 'X') {
                result += 1;
            }
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var grid = try getGridList(input, allocator);
    defer {
        for (grid.items) |item| {
            allocator.free(item);
        }
        grid.deinit();
    }

    const size = grid.items.len;

    var start = std.mem.zeroes([2]usize);
    for (grid.items, 0..) |row, rowIndex| {
        for (row, 0..) |_, colIndex| {
            if (row[colIndex] == '^') {
                start = [_]usize{ rowIndex, colIndex };
                break;
            }
        }
    }

    var gridToCheck = try grid.clone();
    defer gridToCheck.deinit();

    patrol(&grid, start, size);

    var visitedList = try std.ArrayList([2]usize).initCapacity(allocator.*, 6000);
    defer visitedList.deinit();
    for (grid.items, 0..) |row, rowIndex| {
        for (row, 0..) |col, colIndex| {
            const isStart = rowIndex == start[0] and colIndex == start[1];
            if (col == 'X' and !isStart) {
                visitedList.appendAssumeCapacity([2]usize{ rowIndex, colIndex });
            }
        }
    }

    for (visitedList.items) |visited| {
        const rowIndex = visited[0];
        const colIndex = visited[1];
        gridToCheck.items[rowIndex][colIndex] = '#';
        if (checkLoop(&gridToCheck, start, size)) {
            result += 1;
        }
        gridToCheck.items[rowIndex][colIndex] = '.';
    }

    return result;
}

fn patrol(grid: *std.ArrayList([]u8), start: [2]usize, size: usize) void {
    var steps: usize = 0;
    var dir: usize = 0;
    var x = start[0];
    var y = start[1];
    var startx = x;
    var starty = y;

    grid.items[x][y] = 'X';
    while (x >= 0 and y >= 0 and x < size and y < size and steps < (size * size)) {
        const toCheck = grid.items[x][y];
        if (toCheck == '#') {
            dir += 1;
            dir %= 4;
            x = startx;
            y = starty;
        } else {
            startx = x;
            starty = y;
            grid.items[x][y] = 'X';
            steps += 1;
        }

        switch (dir) {
            0 => {
                if (x > 0) {
                    x -= 1;
                }
            },
            1 => y += 1,
            2 => x += 1,
            3 => {
                if (y > 0) {
                    y -= 1;
                }
            },
            else => unreachable,
        }
    }
}

fn checkLoop(grid: *std.ArrayList([]u8), start: [2]usize, size: usize) bool {
    var steps: usize = 0;
    var dir: usize = 0;
    var x = start[0];
    var y = start[1];
    var startx = x;
    var starty = y;

    // Using std.mem.zeros prevents the compiler from building in ReleaseFast mode
    var visited: [2 << 17]u1 = [_]u1{0} ** (2 << 17);
    while (x >= 0 and y >= 0 and x < size and y < size and steps < (size * size)) {
        const toCheck = grid.items[x][y];

        const toCheckList: usize = x | y << 8 | dir << 16;

        const isThere = visited[toCheckList];

        if (isThere == 1) {
            if (x > 0 and y > 0) {
                if (x < size and y < size) {
                    return true;
                }
            }
        }

        visited[toCheckList] = 1;

        if (toCheck == '#') {
            dir += 1;
            dir %= 4;
            x = startx;
            y = starty;
        } else {
            startx = x;
            starty = y;
            steps += 1;
        }

        switch (dir) {
            0 => {
                if (x > 0) {
                    x -= 1;
                }
            },
            1 => y += 1,
            2 => x += 1,
            3 => {
                if (y > 0) {
                    y -= 1;
                }
            },
            else => unreachable,
        }
    }
    return false;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 41);
    try std.testing.expectEqual(part2, 6);
}
