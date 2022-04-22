const std = @import("std");

pub fn link(
    exe: *std.build.LibExeObjStep,
    comptime root_path: []const u8,
) void {
    var flags = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer flags.deinit();
    if (exe.builder.is_release) {
        flags.append("-DNDEBUG") catch unreachable;
    }
    flags.append("-DCP_USE_DOUBLES=0") catch unreachable;
    flags.append("-Wno-return-type-c-linkage") catch unreachable;
    flags.append("-fno-sanitize=undefined") catch unreachable;

    var lib = exe.builder.addStaticLibrary("chipmunk", null);
    lib.setBuildMode(exe.build_mode);
    lib.setTarget(exe.target);
    lib.linkLibC();
    lib.addIncludeDir(root_path ++ "/src/deps/chipmunk/c/include");
    lib.addCSourceFiles(&.{
        root_path ++ "/src/deps/chipmunk/c/src/chipmunk.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpArbiter.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpArray.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpBBTree.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpBody.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpCollision.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpConstraint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpDampedRotarySpring.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpDampedSpring.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpGearJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpGrooveJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpHashSet.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpHastySpace.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpMarch.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpPinJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpPivotJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpPolyline.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpPolyShape.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpRatchetJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpRobust.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpRotaryLimitJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpShape.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSimpleMotor.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSlideJoint.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpace.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpaceComponent.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpaceDebug.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpaceHash.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpaceQuery.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpaceStep.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSpatialIndex.c",
        root_path ++ "/src/deps/chipmunk/c/src/cpSweep1D.c",
        root_path ++ "/src/deps/chipmunk/c/src/prime.h",
    }, flags.items);
    exe.linkLibrary(lib);
}
