const std = @import("std");
const utils = @import("utils.zig");
const colors = @import("color.zig");
const rays = @import("ray.zig");
const vectors = @import("vectors.zig");
const interval = @import("interval.zig");
const material = @import("material.zig");
const bvh = @import("bvh.zig");

const math = std.math;

const Point3 = vectors.Point3;
const Vec3 = vectors.Vec3;
const Ray = rays.Ray;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Interval = interval.Interval;
const Material = material.Material;
const AABB = bvh.AABB;
const BVHNode = bvh.BVHNode;

pub const Hittable = union(enum) {
    Sphere: Sphere,
};

pub const HittableList = struct {
    objects: ArrayList(Hittable),
    bvh_root: ?*BVHNode,
    gpa: Allocator,

    pub fn init(gpa: Allocator) !HittableList {
        return .{
            .gpa = gpa,
            .objects = try ArrayList(Hittable).initCapacity(gpa, 500),
            .bvh_root = null,
        };
    }

    pub fn deinit(self: *HittableList) void {
        if (self.bvh_root) |root| {
            root.deinit(self.gpa);
            self.gpa.destroy(root);
        }
        self.objects.deinit(self.gpa);
    }

    pub fn add(self: *HittableList, item: Hittable) !void {
        try self.objects.append(self.gpa, item);
    }

    pub fn clear(self: *HittableList) !void {
        self.objects.clearAndFree(self.gpa);
    }

    pub fn build_bvh(self: *HittableList) !void {
        if (self.objects.items.len == 0) return;
        self.bvh_root = try BVHNode.build(self.gpa, self.objects.items, 0, self.objects.items.len);
    }

    pub fn hit(self: HittableList, ray: Ray, ray_t: Interval, rec: *HitRecord) bool {
        // Use BVH if available
        if (self.bvh_root) |root| {
            return root.hit(ray, ray_t, rec);
        }

        // Fallback to linear search
        var temp_rec: HitRecord = undefined;
        var hit_anything = false;
        var closest_so_far = ray_t.max;

        for (self.objects.items) |object| {
            const did_hit = switch (object) {
                .Sphere => |sphere| sphere.hit(ray, Interval.init(ray_t.min, closest_so_far), &temp_rec),
            };
            if (did_hit) {
                hit_anything = true;
                closest_so_far = temp_rec.t;
                rec.* = temp_rec;
            }
        }

        return hit_anything;
    }
};

pub const HitRecord = struct {
    p: Point3,
    normal: Vec3,
    t: f64,
    front_face: bool,
    material: Material,

    pub fn set_face_normal(self: *HitRecord, ray: Ray, outward_normal: Vec3) void {
        // Sets the hit record normal vector.
        // NOTE: the parameter `outward_normal` is assumed to have unit length.

        self.front_face = ray.direction.dotProd(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.negate();
    }
};

pub const Sphere = struct {
    center: Point3,
    radius: f64,
    material: Material,

    pub fn init(center: Point3, radius: f64, mat: Material) Sphere {
        return .{
            .center = center,
            .radius = if (radius < 0) 0.0 else radius,
            .material = mat,
        };
    }

    pub fn bounding_box(self: Sphere) AABB {
        const rvec = Vec3.init(self.radius, self.radius, self.radius);
        return AABB.init(
            self.center.sub(rvec),
            self.center.add(rvec),
        );
    }

    pub fn hit(self: Sphere, ray: Ray, ray_t: Interval, rec: *HitRecord) bool {
        const oc = self.center.sub(ray.origin);
        const a = ray.direction.length_squared();
        const h = ray.direction.dotProd(oc);
        const c = oc.length_squared() - self.radius * self.radius;

        const discriminant = h * h - a * c;
        if (discriminant < 0)
            return false;

        const sqrtd = math.sqrt(discriminant);

        // Find the nearest root that lies in the acceptable range.
        var root = (h - sqrtd) / a;
        if (!ray_t.surrounds(root)) {
            root = (h + sqrtd) / a;
            if (!ray_t.surrounds(root))
                return false;
        }

        rec.*.t = root;
        rec.*.p = ray.at(rec.t);
        rec.*.material = self.material;
        const outward_normal = rec.p.sub(self.center).div(self.radius);
        rec.set_face_normal(ray, outward_normal);

        return true;
    }
};
