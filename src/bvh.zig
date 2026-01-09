const std = @import("std");
const vectors = @import("vectors.zig");
const rays = @import("ray.zig");
const interval = @import("interval.zig");
const shapes = @import("shapes.zig");

const Vec3 = vectors.Vec3;
const Point3 = vectors.Point3;
const Ray = rays.Ray;
const Interval = interval.Interval;
const Hittable = shapes.Hittable;
const HitRecord = shapes.HitRecord;
const Allocator = std.mem.Allocator;

pub const AABB = struct {
    min: Point3,
    max: Point3,

    pub fn init(min: Point3, max: Point3) AABB {
        return .{ .min = min, .max = max };
    }

    pub fn hit(self: AABB, ray: Ray, ray_t: Interval) bool {
        const ray_orig = ray.origin;
        const ray_dir = ray.direction;

        var t_min = ray_t.min;
        var t_max = ray_t.max;

        // Check intersection with all three slabs (X, Y, Z)
        inline for (0..3) |i| {
            const inv_d = 1.0 / ray_dir.e[i];
            var t0 = (self.min.e[i] - ray_orig.e[i]) * inv_d;
            var t1 = (self.max.e[i] - ray_orig.e[i]) * inv_d;

            if (inv_d < 0.0) {
                const temp = t0;
                t0 = t1;
                t1 = temp;
            }

            t_min = if (t0 > t_min) t0 else t_min;
            t_max = if (t1 < t_max) t1 else t_max;

            if (t_max <= t_min)
                return false;
        }

        return true;
    }

    pub fn surrounding_box(box0: AABB, box1: AABB) AABB {
        const small = Point3.init(
            @min(box0.min.x(), box1.min.x()),
            @min(box0.min.y(), box1.min.y()),
            @min(box0.min.z(), box1.min.z()),
        );

        const big = Point3.init(
            @max(box0.max.x(), box1.max.x()),
            @max(box0.max.y(), box1.max.y()),
            @max(box0.max.z(), box1.max.z()),
        );

        return AABB.init(small, big);
    }
};

pub const BVHNode = struct {
    left: ?*BVHNode,
    right: ?*BVHNode,
    bounding_box: AABB,
    object: ?Hittable,

    pub fn hit(self: *BVHNode, ray: Ray, ray_t: Interval, rec: *HitRecord) bool {
        // Early exit if ray doesn't hit this node's bounding box
        if (!self.bounding_box.hit(ray, ray_t))
            return false;

        // If this is a leaf node, test the actual object
        if (self.object) |obj| {
            return switch (obj) {
                .Sphere => |sphere| sphere.hit(ray, ray_t, rec),
            };
        }

        // Otherwise, recursively test children
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        if (self.left) |left| {
            if (left.hit(ray, Interval.init(ray_t.min, closest_so_far), rec)) {
                hit_anything = true;
                closest_so_far = rec.t;
            }
        }

        if (self.right) |right| {
            if (right.hit(ray, Interval.init(ray_t.min, closest_so_far), rec)) {
                hit_anything = true;
            }
        }

        return hit_anything;
    }

    pub fn build(allocator: Allocator, objects: []Hittable, start: usize, end: usize) !*BVHNode {
        const node = try allocator.create(BVHNode);

        const object_span = end - start;

        // Leaf node - contains a single object
        if (object_span == 1) {
            const bbox = get_bounding_box(objects[start]);
            node.* = .{
                .left = null,
                .right = null,
                .bounding_box = bbox,
                .object = objects[start],
            };
            return node;
        }

        // Choose axis to split on (cycle through X, Y, Z based on depth)
        const axis = std.crypto.random.intRangeAtMost(usize, 0, 2);

        // Sort objects along chosen axis
        const comparator = BoxComparator{ .axis = axis };
        std.mem.sort(Hittable, objects[start..end], comparator, box_compare);

        const mid = start + object_span / 2;

        // Recursively build left and right subtrees
        const left = try build(allocator, objects, start, mid);
        const right = try build(allocator, objects, mid, end);

        // Compute bounding box that surrounds both children
        const bbox = AABB.surrounding_box(left.bounding_box, right.bounding_box);

        node.* = .{
            .left = left,
            .right = right,
            .bounding_box = bbox,
            .object = null,
        };

        return node;
    }

    pub fn deinit(self: *BVHNode, allocator: Allocator) void {
        if (self.left) |left| {
            left.deinit(allocator);
            allocator.destroy(left);
        }
        if (self.right) |right| {
            right.deinit(allocator);
            allocator.destroy(right);
        }
    }
};

fn get_bounding_box(obj: Hittable) AABB {
    return switch (obj) {
        .Sphere => |sphere| sphere.bounding_box(),
    };
}

const BoxComparator = struct {
    axis: usize,
};

fn box_compare(context: BoxComparator, a: Hittable, b: Hittable) bool {
    const box_a = get_bounding_box(a);
    const box_b = get_bounding_box(b);
    return box_a.min.e[context.axis] < box_b.min.e[context.axis];
}
