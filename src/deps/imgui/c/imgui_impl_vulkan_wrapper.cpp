#include "imgui_impl_vulkan.h"

#ifdef __cplusplus
extern "C" {
#endif

bool _ImGui_ImplVulkan_LoadFunctions(PFN_vkVoidFunction(*loader_func)(const char* function_name, void* user_data))
{
  return ImGui_ImplVulkan_LoadFunctions(loader_func);
}

bool _ImGui_ImplVulkan_Init(
    ImGui_ImplVulkan_InitInfo* info,
    VkRenderPass render_pass)
{
  return ImGui_ImplVulkan_Init(info, render_pass);
}

void _ImGui_ImplVulkan_Shutdown()
{
  ImGui_ImplVulkan_Shutdown();
}

void _ImGui_ImplVulkan_NewFrame()
{
  ImGui_ImplVulkan_NewFrame();
}

void _ImGui_ImplVulkan_RenderDrawData(
    ImDrawData* draw_data,
    VkCommandBuffer command_buffer)
{
  ImGui_ImplVulkan_RenderDrawData(draw_data, command_buffer);
}

#ifdef __cplusplus
}
#endif
