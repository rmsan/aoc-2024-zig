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

fn getGrid(input: []const u8, allocator: *std.mem.Allocator) ![][]const u8 {
    var grid = try std.ArrayList([]const u8).initCapacity(allocator.*, 42);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        grid.appendAssumeCapacity(line);
    }
    return grid.toOwnedSlice();
}

fn check(comptime part: Part, grid: *const [][]const u8, origin: [2]i8, allocator: *std.mem.Allocator) !usize {
    var score: usize = 0;
    var coordSet = std.AutoHashMap([2]i8, void).init(allocator.*);
    var coordStack = try std.ArrayList([2]i8).initCapacity(allocator.*, 9);
    defer coordSet.deinit();
    defer coordStack.deinit();

    coordStack.appendAssumeCapacity(origin);
    while (coordStack.popOrNull()) |coord| {
        switch (part) {
            .Part1 => {
                if (coordSet.contains(coord)) {
                    continue;
                }
                try coordSet.put(coord, {});
            },
            .Part2 => {},
        }

        const coordX: usize = @intCast(coord[0]);
        const coordY: usize = @intCast(coord[1]);

        const valueToCheck = grid.*[coordX][coordY] - '0';
        if (valueToCheck == 9) {
            score += 1;
            continue;
        }

        const neighborsToCheck = try neighbors(grid, coord, allocator);
        for (neighborsToCheck) |neighbor| {
            coordStack.appendAssumeCapacity(neighbor);
        }
        allocator.free(neighborsToCheck);
    }

    return score;
}

fn neighbors(grid: *const [][]const u8, origin: [2]i8, allocator: *std.mem.Allocator) ![][2]i8 {
    const gridSize = grid.len;
    const x: usize = @intCast(origin[0]);
    const y: usize = @intCast(origin[1]);
    const currentHeight = grid.*[x][y];
    var neighborList = try std.ArrayList([2]i8).initCapacity(allocator.*, 4);

    const directions: [4][2]i8 = [_][2]i8{
        [_]i8{ 0, 1 },
        [_]i8{ 1, 0 },
        [_]i8{ 0, -1 },
        [_]i8{ -1, 0 },
    };

    for (directions) |delta| {
        const nX = origin[0] + delta[0];
        const nY = origin[1] + delta[1];
        if (nX < 0 or nY < 0 or nX >= gridSize or nY >= gridSize) {
            continue;
        }
        const nXCoord: usize = @intCast(nX);
        const nYCoord: usize = @intCast(nY);
        if (grid.*[nXCoord][nYCoord] != currentHeight + 1) {
            continue;
        }
        neighborList.appendAssumeCapacity([2]i8{ nX, nY });
    }

    return try neighborList.toOwnedSlice();
}

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const grid = try getGrid(input, allocator);
    defer allocator.free(grid);

    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |character, colIndex| {
            if (character == '0') {
                const origin = [2]i8{ @intCast(rowIndex), @intCast(colIndex) };
                result += try check(Part.Part1, &grid, origin, allocator);
            }
        }
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    const grid = try getGrid(input, allocator);
    defer allocator.free(grid);

    for (grid, 0..) |row, rowIndex| {
        for (row, 0..) |character, colIndex| {
            if (character == '0') {
                const origin = [2]i8{ @intCast(rowIndex), @intCast(colIndex) };
                result += try check(Part.Part2, &grid, origin, allocator);
            }
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 36);
    try std.testing.expectEqual(part2, 81);
}
