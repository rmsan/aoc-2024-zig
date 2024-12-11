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

const Block = union(enum) {
    Empty: usize,
    File: [2]usize,
};

const File = struct {
    id: usize,
    size: usize,
    offset: usize,
};

const Space = struct {
    size: usize,
    offset: usize,
};

fn solvePart1(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var blockList = try std.ArrayList(Block).initCapacity(allocator.*, 20_000);
    defer blockList.deinit();
    const inputSize = input.len;
    var i: usize = 0;
    var nextFileId: usize = 0;
    while (i < inputSize) : (i += 1) {
        var toCheck = input[i];
        if (std.ascii.isDigit(toCheck)) {
            blockList.appendAssumeCapacity(Block{ .File = [2]usize{ nextFileId, toCheck - '0' } });
            nextFileId += 1;
        }

        i += 1;
        if (i < inputSize) {
            toCheck = input[i];

            blockList.appendAssumeCapacity(Block{ .Empty = toCheck - '0' });
        }
    }

    var backIndex = blockList.items.len - 1;

    var position: usize = 0;
    var fillId: usize = 0;
    var remaining: usize = 0;

    const lastBlock = blockList.items[backIndex];
    switch (lastBlock) {
        .File => {
            fillId = lastBlock.File[0];
            remaining = lastBlock.File[1];
        },
        .Empty => {},
    }

    for (0..blockList.items.len) |index| {
        if (index >= backIndex) {
            break;
        }

        const front = blockList.items[index];
        switch (front) {
            .File => {
                const fileId = front.File[0];
                const fileSize = front.File[1];

                result += fileId * (position * 2 + fileSize - 1) * fileSize / 2;
                position += fileSize;
            },
            .Empty => {
                var hole = front.Empty;

                while (hole > 0) {
                    const min = @min(hole, remaining);
                    hole -= min;
                    remaining -= min;
                    result += fillId * (position * 2 + min - 1) * min / 2;
                    position += min;

                    if (remaining == 0) {
                        backIndex -= 2;
                        if (backIndex <= index) {
                            break;
                        }
                        switch (blockList.items[backIndex]) {
                            .File => {
                                const block = blockList.items[backIndex].File;
                                const fileId = block[0];
                                const fileSize = block[1];
                                fillId = fileId;
                                remaining = fileSize;
                            },
                            .Empty => {},
                        }
                    }
                }
            },
        }
    }

    for (0..remaining) |_| {
        result += position * fillId;
        position += 1;
    }

    return result;
}

fn solvePart2(input: []const u8, allocator: *std.mem.Allocator) !usize {
    var result: usize = 0;
    var blockList = try std.ArrayList(Block).initCapacity(allocator.*, 20_000);
    defer blockList.deinit();
    const inputSize = input.len;
    var i: usize = 0;
    var nextFileId: usize = 0;
    while (i < inputSize) : (i += 1) {
        var toCheck = input[i];
        if (std.ascii.isDigit(toCheck)) {
            blockList.appendAssumeCapacity(Block{ .File = [2]usize{ nextFileId, toCheck - '0' } });
            nextFileId += 1;
        }

        i += 1;
        if (i < inputSize) {
            toCheck = input[i];

            blockList.appendAssumeCapacity(Block{ .Empty = toCheck - '0' });
        }
    }

    var offset: usize = 0;
    var fileList = try std.ArrayList(File).initCapacity(allocator.*, 10_000);
    var spaceList = try std.ArrayList(Space).initCapacity(allocator.*, 10_000);
    defer {
        fileList.deinit();
        spaceList.deinit();
    }

    for (blockList.items) |block| {
        switch (block) {
            .File => {
                const fileBlock = block.File;
                const fileId = fileBlock[0];
                const fileSize = fileBlock[1];
                fileList.appendAssumeCapacity(File{ .id = fileId, .size = fileSize, .offset = offset });
                offset += fileSize;
            },
            .Empty => {
                const emptyBlock = block.Empty;
                spaceList.appendAssumeCapacity(Space{ .size = emptyBlock, .offset = offset });
                offset += emptyBlock;
            },
        }
    }

    var cache: [10]usize = [_]usize{0} ** 10;

    // it whould be nice to have either a iterator for lists or a simple way to reverse items
    var fileIndex = fileList.items.len - 1;
    while (fileIndex > 0) : (fileIndex -= 1) {
        const file = fileList.items[fileIndex];

        var found = false;
        if (cache[file.size] <= file.id) {
            for (cache[file.size]..file.id) |index| {
                if (spaceList.items[index].size >= file.size) {
                    const spaceOffset = spaceList.items[index].offset;
                    result += file.id * (spaceOffset * 2 + file.size - 1) * file.size / 2;
                    spaceList.items[index].size -= file.size;
                    spaceList.items[index].offset += file.size;
                    cache[file.size] = index;
                    found = true;
                    break;
                }
            }
        }
        if (!found) {
            result += file.id * (file.offset * 2 + file.size - 1) * file.size / 2;
            cache[file.size] = std.math.maxInt(usize);
        }
    }

    return result;
}

test "test-input" {
    var allocator = std.testing.allocator;
    const fileContentTest = @embedFile("test.txt");

    const part1 = try solvePart1(fileContentTest, &allocator);
    const part2 = try solvePart2(fileContentTest, &allocator);

    try std.testing.expectEqual(part1, 1928);
    try std.testing.expectEqual(part2, 2858);
}
