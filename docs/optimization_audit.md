# ⚙️ GPU Optimization Audit: V10 Low-Draw Strategy

This document outlines the high-impact areas for GPU optimization to support "Low-Draw Mode" in Verasso V10.

## 1. Cognitive Dashboard (3D Mind-map) 🧠

The dashboard currently uses a heavy particle system and real-time lighting for the mind-map nodes.

- **Current Draw:** 1500+ draw calls for a complex mind-map.
- **Optimization Target:** < 300 draw calls in "Normal" mode, < 50 in "Low-Draw".
- **Proposed Fixes:**
  - **Instanced Rendering**: Use mesh instancing for nodes instead of individual widget/mesh objects.
  - **Static Baking**: Pre-bake lighting for non-interactive mind-map sections.
  - **Billboard Sprites**: Replace 3D spheres with billboarded 2D sprites when the camera is distant.

## 2. Liquid Glass 2.0 (UI Engine) 🧪

The "Liquid Glass" effect uses heavy Gaussian blur and dynamic transparency (withValues / withOpacity).

- **Current Draw:** High fill-rate cost due to multiple translucent layers.
- **Optimization Target:** Minimize overdraw on budget Android devices.
- **Proposed Fixes:**
  - **Simplified Shadows**: Replace real-time dynamic shadows with static PNG masks in Low-Draw mode.
  - **Static Backdrop**: Flatten multi-layered glass backgrounds into a single pre-rendered texture.
  - **Reduced Sampling**: Decrease the blur radius and sample count for `BackdropFilter` when performance dips.

## 3. High-Fidelity Simulations 🔬

Specific labs (e.g., pH Lab, Cell Biology) use complex geometry and physics.

- **Current Draw:** Varied; some labs peak at 60 FPS only on high-end hardware.
- **Proposed Fixes:**
  - **Geometry Decimation**: Provide simplified meshes for all Lab assets.
  - **Frame-Rate Cap**: Option to lock simulations to 30 FPS to save power on older devices.
  - **Shader Simplification**: Create a "Lite" version of the PBR (Physically Based Rendering) shaders used in labs.

## 4. Next Steps for V10 🚀

1. **Profiling**: Perform a deep trace using Flutter DevTools to identify specific shader bottlenecks.
2. **LOD Prototyping**: Implement the first Level of Detail (LOD) system for the Cognitive Dashboard.
3. **Low-Draw Toggle**: Add the "Low-Draw" configuration to the `SettingsController`.
