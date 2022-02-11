#version 330 core
out vec4 frag_color;

in vec3 v_pos;
in vec3 v_normal;
in vec2 v_tex;

uniform vec3 u_view_pos;

struct DirectionalLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 direction;
};
uniform DirectionalLight u_directional_light;

struct PointLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 position;
    float constant;
    float linear;
    float quadratic;
};
#define NR_POINT_LIGHTS 16
uniform int u_point_light_count;
uniform PointLight u_point_lights[NR_POINT_LIGHTS];

struct SpotLight {
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
    vec3 position;
    vec3 direction;
    float constant;
    float linear;
    float quadratic;
    float cutoff;
    float outer_cutoff;
};
#define NR_SPOT_LIGHTS 16
uniform int u_spot_light_count;
uniform SpotLight u_spot_lights[NR_SPOT_LIGHTS];

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shiness;
};
uniform Material u_material;

vec3 ambientColor(vec3 light_color,
                  vec3 material_ambient)
{
    return light_color * material_ambient;
}

vec3 diffuseColor(vec3 light_dir,
                  vec3 light_color,
                  vec3 vertex_normal,
                  vec3 material_diffuse)
{
    vec3 norm = normalize(vertex_normal);
    float diff = max(dot(norm, light_dir), 0.0);
    return light_color * (diff * material_diffuse);
}

vec3 specularColor(vec3 light_dir,
                   vec3 light_color,
                   vec3 view_dir,
                   vec3 vertex_normal,
                   vec3 material_specular,
                   float material_shiness)
{
    vec3 norm = normalize(vertex_normal);
    vec3 halfway_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(norm, halfway_dir), 0.0), material_shiness);
    return light_color * (spec * material_specular);
}

vec3 applyDirectionalLight(DirectionalLight light, vec3 material_diffuse, vec3 material_specular, float shiness)
{
    vec3 light_dir = normalize(-light.direction);
    vec3 view_dir = normalize(u_view_pos - v_pos);
    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
                                        v_normal, material_specular, shiness);
    vec3 result = ambient_color + diffuse_color + specular_color;
    return result;
}

vec3 applyPointLight(PointLight light, vec3 material_diffuse, vec3 material_specular, float shiness)
{
    vec3 light_dir = normalize(light.position - v_pos);
    vec3 view_dir = normalize(u_view_pos - v_pos);
    float distance = length(light.position - v_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance +
              light.quadratic * distance * distance);

    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
                                        v_normal, material_specular, shiness);
    vec3 result = (ambient_color + diffuse_color + specular_color) * attenuation;
    return result;
}

vec3 applySpotLight(SpotLight light, vec3 material_diffuse, vec3 material_specular, float shiness)
{
    vec3 light_dir = normalize(light.position - v_pos);
    vec3 view_dir = normalize(u_view_pos - v_pos);
    float distance = length(light.position - v_pos);
    float attenuation = 1.0 / (light.constant + light.linear * distance +
              light.quadratic * distance * distance);
    float theta = dot(light_dir, normalize(-light.direction));
    float epsilon = light.cutoff - light.outer_cutoff;
    float intensity = clamp((theta - light.outer_cutoff) / epsilon, 0.0, 1.0);

    vec3 ambient_color = ambientColor(light.ambient, material_diffuse);
    vec3 diffuse_color = diffuseColor(light_dir, light.diffuse, v_normal, material_diffuse);
    vec3 specular_color = specularColor(light_dir, light.specular, view_dir,
                                        v_normal, material_specular, shiness);
    vec3 result = ambient_color + (diffuse_color + specular_color) * intensity;

    return result * attenuation;
}

void main()
{
    vec3 material_diffuse = vec3(texture(u_material.diffuse, v_tex));
    vec3 material_specular = vec3(texture(u_material.specular, v_tex));
    float shiness = u_material.shiness;
    vec3 result = applyDirectionalLight(u_directional_light, material_diffuse, material_specular, shiness);
    for (int i = 0; i < u_point_light_count; i++) {
      result += applyPointLight(u_point_lights[i], material_diffuse, material_specular, shiness);
    }
    for (int i = 0; i < u_spot_light_count; i++) {
      result += applySpotLight(u_spot_lights[i], material_diffuse, material_specular, shiness);
    }
    frag_color = vec4(result, 1.0);
}

