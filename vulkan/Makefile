
vulkan: vulkan.cpp shader.vert shader.frag
	g++ vulkan.cpp -lvulkan -lglfw -o $@
	mkdir -p shaders
	glslc  shader.vert  -o shaders/vert.spv
	glslc  shader.frag  -o shaders/frag.spv
