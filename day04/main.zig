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

var gridSize: usize = 0;

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]const u8 {
    var grid = try std.array_list.Managed([]const u8).initCapacity(allocator.*, 140);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        grid.appendAssumeCapacity(line);
    }
    return grid.toOwnedSlice();
}

// inlining the functions make a small difference in performance
inline fn checkHorizontal(grid: [][]const u8, word: *const [4]u8, x: usize, y: usize) usize {
    var result: usize = 0;
    if (y <= gridSize - 4) {
        const same = std.mem.eql(u8, grid[x][y .. y + 4], word);

        if (same) {
            result += 1;
        }

        return result;
    }

    return result;
}

inline fn checkVertical(grid: [][]const u8, word: *const [4]u8, x: usize, y: usize) usize {
    var result: usize = 0;
    if (x <= gridSize - 4) {
        result = 1;
        for (0..4) |k| {
            if (grid[x + k][y] != word[k]) {
                result = 0;
                break;
            }
        }
        return result;
    }

    return result;
}

inline fn checkDiagonalLeft(grid: [][]const u8, word: *const [4]u8, x: usize, y: usize) usize {
    var result: usize = 0;
    if (x <= gridSize - 4 and y <= gridSize - 4) {
        result = 1;
        for (0..4) |k| {
            if (grid[x + k][y + k] != word[k]) {
                result = 0;
                break;
            }
        }
        return result;
    }

    return result;
}

inline fn checkDiagonalRight(grid: [][]const u8, word: *const [4]u8, x: usize, y: usize) usize {
    var result: usize = 0;
    if (x <= gridSize - 4 and y >= 3) {
        result = 1;
        for (0..4) |k| {
            if (grid[x + k][y - k] != word[k]) {
                result = 0;
                break;
            }
        }
        return result;
    }

    return result;
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const grid = try getGrid(input, allocator);
    defer allocator.free(grid);

    gridSize = grid.len;

    const XMAS: [4]u8 = [_]u8{ 'X', 'M', 'A', 'S' };
    const SAMX: [4]u8 = [_]u8{ 'S', 'A', 'M', 'X' };

    for (0..gridSize) |x| {
        for (0..gridSize) |y| {
            // manually inlining the code only makes it marginally faster
            // thought the copying of the grid would be slow
            result += checkHorizontal(grid, &XMAS, x, y);
            result += checkHorizontal(grid, &SAMX, x, y);
            result += checkVertical(grid, &XMAS, x, y);
            result += checkVertical(grid, &SAMX, x, y);
            result += checkDiagonalLeft(grid, &XMAS, x, y);
            result += checkDiagonalLeft(grid, &SAMX, x, y);
            result += checkDiagonalRight(grid, &XMAS, x, y);
            result += checkDiagonalRight(grid, &SAMX, x, y);
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const grid = try getGrid(input, allocator);
    defer allocator.free(grid);

    gridSize = grid.len;
    const farSide = gridSize - 2;

    for (0..farSide) |x| {
        for (0..farSide) |y| {
            var valid: usize = 0;
            if (grid[x + 1][y + 1] == 'A') {
                valid = 1;
                const isLeftUpM = grid[x][y] == 'M';
                const isLeftDownM = grid[x + 2][y] == 'M';
                const isRightUpM = grid[x][y + 2] == 'M';
                const isRightDownM = grid[x + 2][y + 2] == 'M';

                const isLeftUpS = grid[x][y] == 'S';
                const isLeftDownS = grid[x + 2][y] == 'S';
                const isRightUpS = grid[x][y + 2] == 'S';
                const isRightDownS = grid[x + 2][y + 2] == 'S';

                if (!((isLeftUpM and isRightDownS) or (isLeftUpS and isRightDownM))) {
                    valid = 0;
                }

                if (!((isLeftDownM and isRightUpS) or (isLeftDownS and isRightUpM))) {
                    valid = 0;
                }
            }
            result += valid;
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 18);
    try std.testing.expectEqual(part2, 9);
}
