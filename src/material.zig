const vectors = @import("vectors.zig");
const colors = @import("color.zig");
const rays = @import("ray.zig");
const shapes = @import("shapes.zig");

const Vec3 = vectors.Vec3;
const Color = colors.Color;
const Ray = rays.Ray;
const HitRecord = shapes.HitRecord;

pub const Material = union(enum) {
    Lambertian: Lambertian,
    Metal: Metal,
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn init(albedo: Color) Lambertian {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: Lambertian, r_in: Ray, hit_record: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = r_in;

        var scatter_direction = hit_record.normal.add(Vec3.random_unit_vector());

        // Catch degenerate scatter direction
        if (scatter_direction.near_zero())
            scatter_direction = hit_record.normal;

        scattered.* = Ray.init(hit_record.p, scatter_direction);
        attenuation.* = self.albedo;

        return true;
    }
};

pub const Metal = struct {
    albedo: Color,
    fuzz: f64,

    pub fn init(albedo: Color, fuzz: f64) Metal {
        return .{ .albedo = albedo, .fuzz = if (fuzz < 1) fuzz else 1 };
    }

    pub fn scatter(self: Metal, r_in: Ray, hit_record: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        var reflected = Vec3.reflect(r_in.direction, hit_record.normal);
        reflected = reflected.unit_vector().add(Vec3.random_unit_vector().scale(self.fuzz));
        scattered.* = Ray.init(hit_record.p, reflected);
        attenuation.* = self.albedo;

        return scattered.direction.dotProd(hit_record.normal) > 0;
    }
};
