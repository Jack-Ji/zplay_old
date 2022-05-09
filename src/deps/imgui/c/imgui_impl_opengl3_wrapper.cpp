#include "imgui_impl_opengl3.h"

#ifdef __cplusplus
extern "C" {
#endif

bool _ImGui_ImplOpenGL3_Init(const char* glsl_version)
{
  return ImGui_ImplOpenGL3_Init(glsl_version);
}

void _ImGui_ImplOpenGL3_Shutdown()
{
  ImGui_ImplOpenGL3_Shutdown();
}

void _ImGui_ImplOpenGL3_NewFrame()
{
  ImGui_ImplOpenGL3_NewFrame();
}

void _ImGui_ImplOpenGL3_RenderDrawData(ImDrawData* draw_data)
{
  ImGui_ImplOpenGL3_RenderDrawData(draw_data);
}

#ifdef __cplusplus
}
#endif
