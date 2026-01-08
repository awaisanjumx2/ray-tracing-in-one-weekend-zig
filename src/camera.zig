const std = @import("std");
const utils = @import("utils.zig");
const rays = @import("ray.zig");
const shapes = @import("shapes.zig");
const colors = @import("color.zig");
const interval = @import("interval.zig");
const vectors = @import("vectors.zig");

const math = std.math;

const Vec3 = vectors.Vec3;
const Point3 = vectors.Point3;
const Color = colors.Color;
const Ray = rays.Ray;
const HitRecord = shapes.HitRecord;
const HittableList = shapes.HittableList;
const Interval = interval.Interval;

pub const Camera = struct {
    aspect_ratio: f64, // Ratio of image width over height
    image_width: u32, // Rendered image width in pixel count
    samples_per_pixel: u32, // Count of random samples for each pixel
    image_height: u32, // Rendered image height
    center: Point3, // Camera center
    pixel00_loc: Vec3, // Location of pixel 0, 0
    pixel_delta_u: Vec3, // Offset to pixel to the right
    pixel_delta_v: Vec3, // Offset to pixel below
    pixel_samples_scale: f64, // Color scale factor for a sum of pixel samples
    max_depth: u32, // Maximum number of ray bounces into scene
    vfov: f64, // Vertical view angle (field of view)
    lookfrom: Point3, // Point camera is looking from
    lookat: Point3, // Point camera is looking at
    vup: Vec3, // Camera-relative "up" direction
    defocus_angle: f64, // Variation angle of rays through each pixel
    focus_dist: f64, // Distance from camera lookfrom point to plane of perfect focus
    defocus_disk_u: Vec3, // Defocus disk horizontal radius
    defocus_disk_v: Vec3, // Defocus disk vertical radius

    pub fn init(
        aspect_ratio: f64,
        image_width: u32,
        samples_per_pixel: u32,
        max_depth: u32,
        vfov: f64,
        lookfrom: Point3,
        lookat: Point3,
        vup: Vec3,
        defocus_angle: f64,
        focus_dist: f64,
    ) Camera {
        var image_height: u32 = @intFromFloat(@as(f64, @floatFromInt(image_width)) / aspect_ratio);
        image_height = if (image_height < 1) 1 else image_height;

        const pixel_samples_scale = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));

        const center = lookfrom;

        // Determine viewport dimensions.
        const theta = utils.degrees_to_radians(vfov);
        const h = math.tan(theta / 2);
        const viewport_height = 2 * h * focus_dist;

        const viewport_width = viewport_height * @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));

        // Calculate the u,v,w unit basis vectors for the camera coordinate frame.
        const w = lookfrom.sub(lookat).unit_vector();
        const u = vup.crossProd(w).unit_vector();
        const v = w.crossProd(u);

        // Calculate the vectors across the horizontal and down the vertical viewport edges.
        const viewport_u = u.scale(viewport_width); // Vector across viewport horizontal edge
        const viewport_v = v.negate().scale(viewport_height); // Vector down viewport vertical edge

        // Calculate the horizontal and vertical delta vectors from pixel to pixel.
        const pixel_delta_u = viewport_u.div(@floatFromInt(image_width));
        const pixel_delta_v = viewport_v.div(@floatFromInt(image_height));

        // Calculate the location of the upper left pixel.
        const viewport_upper_left = center
            .sub(w.scale(focus_dist))
            .sub(viewport_u.div(2))
            .sub(viewport_v.div(2));

        const pixel00_loc = viewport_upper_left
            .add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

        // Calculate the camera defocus disk basis vectors.
        const defocus_radius = focus_dist * math.tan(utils.degrees_to_radians(defocus_angle / 2));
        const defocus_disk_u = u.scale(defocus_radius);
        const defocus_disk_v = v.scale(defocus_radius);

        return .{
            .aspect_ratio = aspect_ratio,
            .image_width = image_width,
            .image_height = image_height,
            .center = center,
            .pixel00_loc = pixel00_loc,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .samples_per_pixel = samples_per_pixel,
            .pixel_samples_scale = pixel_samples_scale,
            .max_depth = max_depth,
            .vfov = vfov,
            .lookfrom = lookfrom,
            .lookat = lookat,
            .vup = vup,
            .defocus_angle = defocus_angle,
            .focus_dist = focus_dist,
            .defocus_disk_u = defocus_disk_u,
            .defocus_disk_v = defocus_disk_v,
        };
    }

    pub fn render(self: *Camera, world: *HittableList, stdout: *std.Io.Writer, stderr: *std.Io.Writer) !void {
        try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height });

        for (0..self.image_height) |j| {
            try utils.bufferedPrint(stderr, "\rScanlines remaining: {d} \n", .{self.image_height - j});
            for (0..self.image_width) |i| {
                var pixel_color = Color.zero();
                var sample: i32 = 0;
                while (sample < self.samples_per_pixel) : (sample += 1) {
                    const ray = get_ray(self, i, j);
                    pixel_color = pixel_color.add(ray_color(ray, self.max_depth, world));
                }

                try colors.write_color(stdout, pixel_color.scale(self.pixel_samples_scale));
            }
        }
    }

    fn get_ray(self: *Camera, i: usize, j: usize) Ray {
        // Construct a camera ray originating from the defocus disk and directed at a randomly
        // sampled point around the pixel location i, j.

        const offset = sample_square();
        const pixel_sample = self.pixel00_loc.add(
            self.pixel_delta_u.scale(@as(f64, @floatFromInt(i)) + offset.x()),
        ).add(
            self.pixel_delta_v.scale(@as(f64, @floatFromInt(j)) + offset.y()),
        );

        const ray_origin = if (self.defocus_angle <= 0) self.center else self.defocus_disk_sample();
        const ray_direction = pixel_sample.sub(ray_origin);

        return Ray.init(ray_origin, ray_direction);
    }

    fn sample_square() Vec3 {
        // Returns the vector to a random point in the [-.5,-.5]-[+.5,+.5] unit square.
        return Vec3.init(utils.random_float() - 0.5, utils.random_float() - 0.5, 0);
    }

    fn defocus_disk_sample(self: Camera) Point3 {
        // Returns a random point in the camera defocus disk.
        const p = Vec3.random_in_unit_disk();
        return self.center.add(self.defocus_disk_u.scale(p.e[0])).add(self.defocus_disk_v.scale(p.e[1]));
    }

    fn ray_color(ray: Ray, depth: u32, world: *HittableList) Color {
        // If we've exceeded the ray bounce limit, no more light is gathered.
        if (depth <= 0)
            return Color.zero();

        var hit_record: HitRecord = undefined;
        if (world.hit(ray, Interval.init(0.001, utils.infinity), &hit_record)) {
            var scattered: Ray = undefined;
            var attenuation: Color = undefined;

            const did_scatter = switch (hit_record.material) {
                .Metal => |metal| metal.scatter(ray, hit_record, &attenuation, &scattered),
                .Lambertian => |lambertian| lambertian.scatter(ray, hit_record, &attenuation, &scattered),
                .Dielectric => |dielectric| dielectric.scatter(ray, hit_record, &attenuation, &scattered),
            };
            if (did_scatter) {
                return ray_color(scattered, depth - 1, world).mul(attenuation);
            }
            return Color.zero();
        }

        const unit_direction = ray.direction.unit_vector();
        const a = 0.5 * (unit_direction.y() + 1.0);
        return Color.init(1.0, 1.0, 1.0).scale(1.0 - a).add(
            Color.init(0.5, 0.7, 1.0).scale(a),
        );
    }
};
