#version 330

in vec3 fragPosition;
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragNormal;

out vec4 finalColor;

void main() {
    // Basic diffuse lighting so spheres look 3D
    vec3 lightDir = normalize(vec3(0.5, 1.0, 0.5));
    float light = max(dot(fragNormal, lightDir), 0.2);
    finalColor = vec4(1.0, 1.0, 1.0, 1.0);
}
