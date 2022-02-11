#version 330 core
layout (location = 0) in vec3 a_pos;
layout (location = 2) in vec3 a_normal;
layout (location = 4) in vec2 a_tex1;

out vec3 v_pos;
out vec3 v_normal;
out vec2 v_tex;

uniform mat4 u_model = mat4(1.0);
uniform mat4 u_normal = mat4(1.0);
uniform mat4 u_view = mat4(1.0);
uniform mat4 u_project = mat4(1.0);

void main()
{
    gl_Position = u_project * u_view * u_model * vec4(a_pos, 1.0);
    v_pos = vec3(u_model * vec4(a_pos, 1.0));
    v_normal = mat3(u_normal) * a_normal;
    v_tex = a_tex1;
}
