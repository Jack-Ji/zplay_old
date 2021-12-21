pub const cgltf_size = usize;
pub const cgltf_float = f32;
pub const cgltf_int = c_int;
pub const cgltf_uint = c_uint;
pub const cgltf_bool = c_int;
pub const cgltf_file_type_invalid: c_int = 0;
pub const cgltf_file_type_gltf: c_int = 1;
pub const cgltf_file_type_glb: c_int = 2;
pub const enum_cgltf_file_type = c_uint;
pub const cgltf_file_type = enum_cgltf_file_type;
pub const cgltf_result_success: c_int = 0;
pub const cgltf_result_data_too_short: c_int = 1;
pub const cgltf_result_unknown_format: c_int = 2;
pub const cgltf_result_invalid_json: c_int = 3;
pub const cgltf_result_invalid_gltf: c_int = 4;
pub const cgltf_result_invalid_options: c_int = 5;
pub const cgltf_result_file_not_found: c_int = 6;
pub const cgltf_result_io_error: c_int = 7;
pub const cgltf_result_out_of_memory: c_int = 8;
pub const cgltf_result_legacy_gltf: c_int = 9;
pub const enum_cgltf_result = c_uint;
pub const cgltf_result = enum_cgltf_result;
pub const struct_cgltf_memory_options = extern struct {
    alloc: ?fn (?*anyopaque, cgltf_size) callconv(.C) ?*anyopaque,
    free: ?fn (?*anyopaque, ?*anyopaque) callconv(.C) void,
    user_data: ?*anyopaque,
};
pub const cgltf_memory_options = struct_cgltf_memory_options;
pub const struct_cgltf_file_options = extern struct {
    read: ?fn ([*c]const struct_cgltf_memory_options, [*c]const struct_cgltf_file_options, [*c]const u8, [*c]cgltf_size, [*c]?*anyopaque) callconv(.C) cgltf_result,
    release: ?fn ([*c]const struct_cgltf_memory_options, [*c]const struct_cgltf_file_options, ?*anyopaque) callconv(.C) void,
    user_data: ?*anyopaque,
};
pub const cgltf_file_options = struct_cgltf_file_options;
pub const struct_cgltf_options = extern struct {
    type: cgltf_file_type,
    json_token_count: cgltf_size,
    memory: cgltf_memory_options,
    file: cgltf_file_options,
};
pub const cgltf_options = struct_cgltf_options;
pub const cgltf_buffer_view_type_invalid: c_int = 0;
pub const cgltf_buffer_view_type_indices: c_int = 1;
pub const cgltf_buffer_view_type_vertices: c_int = 2;
pub const enum_cgltf_buffer_view_type = c_uint;
pub const cgltf_buffer_view_type = enum_cgltf_buffer_view_type;
pub const cgltf_attribute_type_invalid: c_int = 0;
pub const cgltf_attribute_type_position: c_int = 1;
pub const cgltf_attribute_type_normal: c_int = 2;
pub const cgltf_attribute_type_tangent: c_int = 3;
pub const cgltf_attribute_type_texcoord: c_int = 4;
pub const cgltf_attribute_type_color: c_int = 5;
pub const cgltf_attribute_type_joints: c_int = 6;
pub const cgltf_attribute_type_weights: c_int = 7;
pub const enum_cgltf_attribute_type = c_uint;
pub const cgltf_attribute_type = enum_cgltf_attribute_type;
pub const cgltf_component_type_invalid: c_int = 0;
pub const cgltf_component_type_r_8: c_int = 1;
pub const cgltf_component_type_r_8u: c_int = 2;
pub const cgltf_component_type_r_16: c_int = 3;
pub const cgltf_component_type_r_16u: c_int = 4;
pub const cgltf_component_type_r_32u: c_int = 5;
pub const cgltf_component_type_r_32f: c_int = 6;
pub const enum_cgltf_component_type = c_uint;
pub const cgltf_component_type = enum_cgltf_component_type;
pub const cgltf_type_invalid: c_int = 0;
pub const cgltf_type_scalar: c_int = 1;
pub const cgltf_type_vec2: c_int = 2;
pub const cgltf_type_vec3: c_int = 3;
pub const cgltf_type_vec4: c_int = 4;
pub const cgltf_type_mat2: c_int = 5;
pub const cgltf_type_mat3: c_int = 6;
pub const cgltf_type_mat4: c_int = 7;
pub const enum_cgltf_type = c_uint;
pub const cgltf_type = enum_cgltf_type;
pub const cgltf_primitive_type_points: c_int = 0;
pub const cgltf_primitive_type_lines: c_int = 1;
pub const cgltf_primitive_type_line_loop: c_int = 2;
pub const cgltf_primitive_type_line_strip: c_int = 3;
pub const cgltf_primitive_type_triangles: c_int = 4;
pub const cgltf_primitive_type_triangle_strip: c_int = 5;
pub const cgltf_primitive_type_triangle_fan: c_int = 6;
pub const enum_cgltf_primitive_type = c_uint;
pub const cgltf_primitive_type = enum_cgltf_primitive_type;
pub const cgltf_alpha_mode_opaque: c_int = 0;
pub const cgltf_alpha_mode_mask: c_int = 1;
pub const cgltf_alpha_mode_blend: c_int = 2;
pub const enum_cgltf_alpha_mode = c_uint;
pub const cgltf_alpha_mode = enum_cgltf_alpha_mode;
pub const cgltf_animation_path_type_invalid: c_int = 0;
pub const cgltf_animation_path_type_translation: c_int = 1;
pub const cgltf_animation_path_type_rotation: c_int = 2;
pub const cgltf_animation_path_type_scale: c_int = 3;
pub const cgltf_animation_path_type_weights: c_int = 4;
pub const enum_cgltf_animation_path_type = c_uint;
pub const cgltf_animation_path_type = enum_cgltf_animation_path_type;
pub const cgltf_interpolation_type_linear: c_int = 0;
pub const cgltf_interpolation_type_step: c_int = 1;
pub const cgltf_interpolation_type_cubic_spline: c_int = 2;
pub const enum_cgltf_interpolation_type = c_uint;
pub const cgltf_interpolation_type = enum_cgltf_interpolation_type;
pub const cgltf_camera_type_invalid: c_int = 0;
pub const cgltf_camera_type_perspective: c_int = 1;
pub const cgltf_camera_type_orthographic: c_int = 2;
pub const enum_cgltf_camera_type = c_uint;
pub const cgltf_camera_type = enum_cgltf_camera_type;
pub const cgltf_light_type_invalid: c_int = 0;
pub const cgltf_light_type_directional: c_int = 1;
pub const cgltf_light_type_point: c_int = 2;
pub const cgltf_light_type_spot: c_int = 3;
pub const enum_cgltf_light_type = c_uint;
pub const cgltf_light_type = enum_cgltf_light_type;
pub const cgltf_data_free_method_none: c_int = 0;
pub const cgltf_data_free_method_file_release: c_int = 1;
pub const cgltf_data_free_method_memory_free: c_int = 2;
pub const enum_cgltf_data_free_method = c_uint;
pub const cgltf_data_free_method = enum_cgltf_data_free_method;
pub const struct_cgltf_extras = extern struct {
    start_offset: cgltf_size,
    end_offset: cgltf_size,
};
pub const cgltf_extras = struct_cgltf_extras;
pub const struct_cgltf_extension = extern struct {
    name: [*c]u8,
    data: [*c]u8,
};
pub const cgltf_extension = struct_cgltf_extension;
pub const struct_cgltf_buffer = extern struct {
    name: [*c]u8,
    size: cgltf_size,
    uri: [*c]u8,
    data: ?*anyopaque,
    data_free_method: cgltf_data_free_method,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_buffer = struct_cgltf_buffer;
pub const cgltf_meshopt_compression_mode_invalid: c_int = 0;
pub const cgltf_meshopt_compression_mode_attributes: c_int = 1;
pub const cgltf_meshopt_compression_mode_triangles: c_int = 2;
pub const cgltf_meshopt_compression_mode_indices: c_int = 3;
pub const enum_cgltf_meshopt_compression_mode = c_uint;
pub const cgltf_meshopt_compression_mode = enum_cgltf_meshopt_compression_mode;
pub const cgltf_meshopt_compression_filter_none: c_int = 0;
pub const cgltf_meshopt_compression_filter_octahedral: c_int = 1;
pub const cgltf_meshopt_compression_filter_quaternion: c_int = 2;
pub const cgltf_meshopt_compression_filter_exponential: c_int = 3;
pub const enum_cgltf_meshopt_compression_filter = c_uint;
pub const cgltf_meshopt_compression_filter = enum_cgltf_meshopt_compression_filter;
pub const struct_cgltf_meshopt_compression = extern struct {
    buffer: [*c]cgltf_buffer,
    offset: cgltf_size,
    size: cgltf_size,
    stride: cgltf_size,
    count: cgltf_size,
    mode: cgltf_meshopt_compression_mode,
    filter: cgltf_meshopt_compression_filter,
};
pub const cgltf_meshopt_compression = struct_cgltf_meshopt_compression;
pub const struct_cgltf_buffer_view = extern struct {
    name: [*c]u8,
    buffer: [*c]cgltf_buffer,
    offset: cgltf_size,
    size: cgltf_size,
    stride: cgltf_size,
    type: cgltf_buffer_view_type,
    data: ?*anyopaque,
    has_meshopt_compression: cgltf_bool,
    meshopt_compression: cgltf_meshopt_compression,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_buffer_view = struct_cgltf_buffer_view;
pub const struct_cgltf_accessor_sparse = extern struct {
    count: cgltf_size,
    indices_buffer_view: [*c]cgltf_buffer_view,
    indices_byte_offset: cgltf_size,
    indices_component_type: cgltf_component_type,
    values_buffer_view: [*c]cgltf_buffer_view,
    values_byte_offset: cgltf_size,
    extras: cgltf_extras,
    indices_extras: cgltf_extras,
    values_extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
    indices_extensions_count: cgltf_size,
    indices_extensions: [*c]cgltf_extension,
    values_extensions_count: cgltf_size,
    values_extensions: [*c]cgltf_extension,
};
pub const cgltf_accessor_sparse = struct_cgltf_accessor_sparse;
pub const struct_cgltf_accessor = extern struct {
    name: [*c]u8,
    component_type: cgltf_component_type,
    normalized: cgltf_bool,
    type: cgltf_type,
    offset: cgltf_size,
    count: cgltf_size,
    stride: cgltf_size,
    buffer_view: [*c]cgltf_buffer_view,
    has_min: cgltf_bool,
    min: [16]cgltf_float,
    has_max: cgltf_bool,
    max: [16]cgltf_float,
    is_sparse: cgltf_bool,
    sparse: cgltf_accessor_sparse,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_accessor = struct_cgltf_accessor;
pub const struct_cgltf_attribute = extern struct {
    name: [*c]u8,
    type: cgltf_attribute_type,
    index: cgltf_int,
    data: [*c]cgltf_accessor,
};
pub const cgltf_attribute = struct_cgltf_attribute;
pub const struct_cgltf_image = extern struct {
    name: [*c]u8,
    uri: [*c]u8,
    buffer_view: [*c]cgltf_buffer_view,
    mime_type: [*c]u8,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_image = struct_cgltf_image;
pub const struct_cgltf_sampler = extern struct {
    name: [*c]u8,
    mag_filter: cgltf_int,
    min_filter: cgltf_int,
    wrap_s: cgltf_int,
    wrap_t: cgltf_int,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_sampler = struct_cgltf_sampler;
pub const struct_cgltf_texture = extern struct {
    name: [*c]u8,
    image: [*c]cgltf_image,
    sampler: [*c]cgltf_sampler,
    has_basisu: cgltf_bool,
    basisu_image: [*c]cgltf_image,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_texture = struct_cgltf_texture;
pub const struct_cgltf_texture_transform = extern struct {
    offset: [2]cgltf_float,
    rotation: cgltf_float,
    scale: [2]cgltf_float,
    has_texcoord: cgltf_bool,
    texcoord: cgltf_int,
};
pub const cgltf_texture_transform = struct_cgltf_texture_transform;
pub const struct_cgltf_texture_view = extern struct {
    texture: [*c]cgltf_texture,
    texcoord: cgltf_int,
    scale: cgltf_float,
    has_transform: cgltf_bool,
    transform: cgltf_texture_transform,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_texture_view = struct_cgltf_texture_view;
pub const struct_cgltf_pbr_metallic_roughness = extern struct {
    base_color_texture: cgltf_texture_view,
    metallic_roughness_texture: cgltf_texture_view,
    base_color_factor: [4]cgltf_float,
    metallic_factor: cgltf_float,
    roughness_factor: cgltf_float,
    extras: cgltf_extras,
};
pub const cgltf_pbr_metallic_roughness = struct_cgltf_pbr_metallic_roughness;
pub const struct_cgltf_pbr_specular_glossiness = extern struct {
    diffuse_texture: cgltf_texture_view,
    specular_glossiness_texture: cgltf_texture_view,
    diffuse_factor: [4]cgltf_float,
    specular_factor: [3]cgltf_float,
    glossiness_factor: cgltf_float,
};
pub const cgltf_pbr_specular_glossiness = struct_cgltf_pbr_specular_glossiness;
pub const struct_cgltf_clearcoat = extern struct {
    clearcoat_texture: cgltf_texture_view,
    clearcoat_roughness_texture: cgltf_texture_view,
    clearcoat_normal_texture: cgltf_texture_view,
    clearcoat_factor: cgltf_float,
    clearcoat_roughness_factor: cgltf_float,
};
pub const cgltf_clearcoat = struct_cgltf_clearcoat;
pub const struct_cgltf_transmission = extern struct {
    transmission_texture: cgltf_texture_view,
    transmission_factor: cgltf_float,
};
pub const cgltf_transmission = struct_cgltf_transmission;
pub const struct_cgltf_ior = extern struct {
    ior: cgltf_float,
};
pub const cgltf_ior = struct_cgltf_ior;
pub const struct_cgltf_specular = extern struct {
    specular_texture: cgltf_texture_view,
    specular_color_texture: cgltf_texture_view,
    specular_color_factor: [3]cgltf_float,
    specular_factor: cgltf_float,
};
pub const cgltf_specular = struct_cgltf_specular;
pub const struct_cgltf_volume = extern struct {
    thickness_texture: cgltf_texture_view,
    thickness_factor: cgltf_float,
    attenuation_color: [3]cgltf_float,
    attenuation_distance: cgltf_float,
};
pub const cgltf_volume = struct_cgltf_volume;
pub const struct_cgltf_sheen = extern struct {
    sheen_color_texture: cgltf_texture_view,
    sheen_color_factor: [3]cgltf_float,
    sheen_roughness_texture: cgltf_texture_view,
    sheen_roughness_factor: cgltf_float,
};
pub const cgltf_sheen = struct_cgltf_sheen;
pub const struct_cgltf_material = extern struct {
    name: [*c]u8,
    has_pbr_metallic_roughness: cgltf_bool,
    has_pbr_specular_glossiness: cgltf_bool,
    has_clearcoat: cgltf_bool,
    has_transmission: cgltf_bool,
    has_volume: cgltf_bool,
    has_ior: cgltf_bool,
    has_specular: cgltf_bool,
    has_sheen: cgltf_bool,
    pbr_metallic_roughness: cgltf_pbr_metallic_roughness,
    pbr_specular_glossiness: cgltf_pbr_specular_glossiness,
    clearcoat: cgltf_clearcoat,
    ior: cgltf_ior,
    specular: cgltf_specular,
    sheen: cgltf_sheen,
    transmission: cgltf_transmission,
    volume: cgltf_volume,
    normal_texture: cgltf_texture_view,
    occlusion_texture: cgltf_texture_view,
    emissive_texture: cgltf_texture_view,
    emissive_factor: [3]cgltf_float,
    alpha_mode: cgltf_alpha_mode,
    alpha_cutoff: cgltf_float,
    double_sided: cgltf_bool,
    unlit: cgltf_bool,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_material = struct_cgltf_material;
pub const struct_cgltf_material_mapping = extern struct {
    variant: cgltf_size,
    material: [*c]cgltf_material,
    extras: cgltf_extras,
};
pub const cgltf_material_mapping = struct_cgltf_material_mapping;
pub const struct_cgltf_morph_target = extern struct {
    attributes: [*c]cgltf_attribute,
    attributes_count: cgltf_size,
};
pub const cgltf_morph_target = struct_cgltf_morph_target;
pub const struct_cgltf_draco_mesh_compression = extern struct {
    buffer_view: [*c]cgltf_buffer_view,
    attributes: [*c]cgltf_attribute,
    attributes_count: cgltf_size,
};
pub const cgltf_draco_mesh_compression = struct_cgltf_draco_mesh_compression;
pub const struct_cgltf_primitive = extern struct {
    type: cgltf_primitive_type,
    indices: [*c]cgltf_accessor,
    material: [*c]cgltf_material,
    attributes: [*c]cgltf_attribute,
    attributes_count: cgltf_size,
    targets: [*c]cgltf_morph_target,
    targets_count: cgltf_size,
    extras: cgltf_extras,
    has_draco_mesh_compression: cgltf_bool,
    draco_mesh_compression: cgltf_draco_mesh_compression,
    mappings: [*c]cgltf_material_mapping,
    mappings_count: cgltf_size,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_primitive = struct_cgltf_primitive;
pub const struct_cgltf_mesh = extern struct {
    name: [*c]u8,
    primitives: [*c]cgltf_primitive,
    primitives_count: cgltf_size,
    weights: [*c]cgltf_float,
    weights_count: cgltf_size,
    target_names: [*c][*c]u8,
    target_names_count: cgltf_size,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_mesh = struct_cgltf_mesh;
pub const cgltf_node = struct_cgltf_node;
pub const struct_cgltf_skin = extern struct {
    name: [*c]u8,
    joints: [*c][*c]cgltf_node,
    joints_count: cgltf_size,
    skeleton: [*c]cgltf_node,
    inverse_bind_matrices: [*c]cgltf_accessor,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_skin = struct_cgltf_skin;
pub const struct_cgltf_camera_perspective = extern struct {
    has_aspect_ratio: cgltf_bool,
    aspect_ratio: cgltf_float,
    yfov: cgltf_float,
    has_zfar: cgltf_bool,
    zfar: cgltf_float,
    znear: cgltf_float,
    extras: cgltf_extras,
};
pub const cgltf_camera_perspective = struct_cgltf_camera_perspective;
pub const struct_cgltf_camera_orthographic = extern struct {
    xmag: cgltf_float,
    ymag: cgltf_float,
    zfar: cgltf_float,
    znear: cgltf_float,
    extras: cgltf_extras,
};
pub const cgltf_camera_orthographic = struct_cgltf_camera_orthographic;
const union_unnamed_1 = extern union {
    perspective: cgltf_camera_perspective,
    orthographic: cgltf_camera_orthographic,
};
pub const struct_cgltf_camera = extern struct {
    name: [*c]u8,
    type: cgltf_camera_type,
    data: union_unnamed_1,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_camera = struct_cgltf_camera;
pub const struct_cgltf_light = extern struct {
    name: [*c]u8,
    color: [3]cgltf_float,
    intensity: cgltf_float,
    type: cgltf_light_type,
    range: cgltf_float,
    spot_inner_cone_angle: cgltf_float,
    spot_outer_cone_angle: cgltf_float,
    extras: cgltf_extras,
};
pub const cgltf_light = struct_cgltf_light;
pub const struct_cgltf_node = extern struct {
    name: [*c]u8,
    parent: [*c]cgltf_node,
    children: [*c][*c]cgltf_node,
    children_count: cgltf_size,
    skin: [*c]cgltf_skin,
    mesh: [*c]cgltf_mesh,
    camera: [*c]cgltf_camera,
    light: [*c]cgltf_light,
    weights: [*c]cgltf_float,
    weights_count: cgltf_size,
    has_translation: cgltf_bool,
    has_rotation: cgltf_bool,
    has_scale: cgltf_bool,
    has_matrix: cgltf_bool,
    translation: [3]cgltf_float,
    rotation: [4]cgltf_float,
    scale: [3]cgltf_float,
    matrix: [16]cgltf_float,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const struct_cgltf_scene = extern struct {
    name: [*c]u8,
    nodes: [*c][*c]cgltf_node,
    nodes_count: cgltf_size,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_scene = struct_cgltf_scene;
pub const struct_cgltf_animation_sampler = extern struct {
    input: [*c]cgltf_accessor,
    output: [*c]cgltf_accessor,
    interpolation: cgltf_interpolation_type,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_animation_sampler = struct_cgltf_animation_sampler;
pub const struct_cgltf_animation_channel = extern struct {
    sampler: [*c]cgltf_animation_sampler,
    target_node: [*c]cgltf_node,
    target_path: cgltf_animation_path_type,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_animation_channel = struct_cgltf_animation_channel;
pub const struct_cgltf_animation = extern struct {
    name: [*c]u8,
    samplers: [*c]cgltf_animation_sampler,
    samplers_count: cgltf_size,
    channels: [*c]cgltf_animation_channel,
    channels_count: cgltf_size,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_animation = struct_cgltf_animation;
pub const struct_cgltf_material_variant = extern struct {
    name: [*c]u8,
    extras: cgltf_extras,
};
pub const cgltf_material_variant = struct_cgltf_material_variant;
pub const struct_cgltf_asset = extern struct {
    copyright: [*c]u8,
    generator: [*c]u8,
    version: [*c]u8,
    min_version: [*c]u8,
    extras: cgltf_extras,
    extensions_count: cgltf_size,
    extensions: [*c]cgltf_extension,
};
pub const cgltf_asset = struct_cgltf_asset;
pub const struct_cgltf_data = extern struct {
    file_type: cgltf_file_type,
    file_data: ?*anyopaque,
    asset: cgltf_asset,
    meshes: [*c]cgltf_mesh,
    meshes_count: cgltf_size,
    materials: [*c]cgltf_material,
    materials_count: cgltf_size,
    accessors: [*c]cgltf_accessor,
    accessors_count: cgltf_size,
    buffer_views: [*c]cgltf_buffer_view,
    buffer_views_count: cgltf_size,
    buffers: [*c]cgltf_buffer,
    buffers_count: cgltf_size,
    images: [*c]cgltf_image,
    images_count: cgltf_size,
    textures: [*c]cgltf_texture,
    textures_count: cgltf_size,
    samplers: [*c]cgltf_sampler,
    samplers_count: cgltf_size,
    skins: [*c]cgltf_skin,
    skins_count: cgltf_size,
    cameras: [*c]cgltf_camera,
    cameras_count: cgltf_size,
    lights: [*c]cgltf_light,
    lights_count: cgltf_size,
    nodes: [*c]cgltf_node,
    nodes_count: cgltf_size,
    scenes: [*c]cgltf_scene,
    scenes_count: cgltf_size,
    scene: [*c]cgltf_scene,
    animations: [*c]cgltf_animation,
    animations_count: cgltf_size,
    variants: [*c]cgltf_material_variant,
    variants_count: cgltf_size,
    extras: cgltf_extras,
    data_extensions_count: cgltf_size,
    data_extensions: [*c]cgltf_extension,
    extensions_used: [*c][*c]u8,
    extensions_used_count: cgltf_size,
    extensions_required: [*c][*c]u8,
    extensions_required_count: cgltf_size,
    json: [*c]const u8,
    json_size: cgltf_size,
    bin: ?*const anyopaque,
    bin_size: cgltf_size,
    memory: cgltf_memory_options,
    file: cgltf_file_options,
};
pub const cgltf_data = struct_cgltf_data;
pub extern fn cgltf_parse(options: [*c]const cgltf_options, data: ?*const anyopaque, size: cgltf_size, out_data: [*c][*c]cgltf_data) cgltf_result;
pub extern fn cgltf_parse_file(options: [*c]const cgltf_options, path: [*c]const u8, out_data: [*c][*c]cgltf_data) cgltf_result;
pub extern fn cgltf_free(data: [*c]cgltf_data) void;
pub extern fn cgltf_load_buffers(options: [*c]const cgltf_options, data: [*c]cgltf_data, gltf_path: [*c]const u8) cgltf_result;
pub extern fn cgltf_load_buffer_base64(options: [*c]const cgltf_options, size: cgltf_size, base64: [*c]const u8, out_data: [*c]?*anyopaque) cgltf_result;
pub extern fn cgltf_decode_string(string: [*c]u8) cgltf_size;
pub extern fn cgltf_decode_uri(uri: [*c]u8) cgltf_size;
pub extern fn cgltf_validate(data: [*c]cgltf_data) cgltf_result;
pub extern fn cgltf_node_transform_local(node: [*c]const cgltf_node, out_matrix: [*c]cgltf_float) void;
pub extern fn cgltf_node_transform_world(node: [*c]const cgltf_node, out_matrix: [*c]cgltf_float) void;
pub extern fn cgltf_accessor_read_float(accessor: [*c]const cgltf_accessor, index: cgltf_size, out: [*c]cgltf_float, element_size: cgltf_size) cgltf_bool;
pub extern fn cgltf_accessor_read_uint(accessor: [*c]const cgltf_accessor, index: cgltf_size, out: [*c]cgltf_uint, element_size: cgltf_size) cgltf_bool;
pub extern fn cgltf_accessor_read_index(accessor: [*c]const cgltf_accessor, index: cgltf_size) cgltf_size;
pub extern fn cgltf_num_components(@"type": cgltf_type) cgltf_size;
pub extern fn cgltf_accessor_unpack_floats(accessor: [*c]const cgltf_accessor, out: [*c]cgltf_float, float_count: cgltf_size) cgltf_size;
pub extern fn cgltf_copy_extras_json(data: [*c]const cgltf_data, extras: [*c]const cgltf_extras, dest: [*c]u8, dest_size: [*c]cgltf_size) cgltf_result;
