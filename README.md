# Water Reflection Shader | MTA\:SA

A high-quality, real-time water shader for Multi Theft Auto: San Andreas.
Features realistic planar reflections, animated waves, per-pixel depth and refraction, and is fully customizable for both visuals and performance.

Developed by Blue Eagle.

![image](https://github.com/user-attachments/assets/2ad0cdd2-8f6b-4e33-8eaa-79bc0fdb95a4)

---

## Features


* [x] Real-time planar reflections
* [x] Animated water normals and waves
* [x] Depth-based refraction and color blending
* [x] Customizable shallow and deep water color
* [x] Adjustable Fresnel edge reflections
* [x] Physically-based specular highlights
* [x] Efficient and optimized

---

## Usage

1. [Download](https://github.com/BlueEagle12/MTA-SA-Water-Shader) or clone this repository.
2. Place the shader resource folder in your MTA\:SA resources directory.
3. Start the resource in your server (`start <shader-resource-name>`).
4. The shader will automatically apply to water surfaces.
5. Adjust parameters via Lua or in the `.fx` file for visual fine-tuning.

---

## Parameters

Most shader effects are controlled through exposed parameters (settable via Lua):

* **gShallowWater** / **gDeepWater**: Shallow/deep water blend colors.
* **gRefractionStrength**: Controls refraction distortion.
* **gMaxWaterTransparency**: Maximum alpha/transparency of water.
* **gFresnelPower / gFresnelScale / gFresnelBias**: Controls edge reflection strength.
* **gSpecularPower / gSpecularIntensity**: Controls size and brightness of specular highlights.
* **gWaveSpeed1**: Controls wave animation speed and direction.
* **gNormalScale / gReflectionScale / gUVScale**: Advanced control over normal and reflection strength.

*Parameters can be adjusted at runtime using dxSetShaderValue and related Lua functions.*

## Credits

* Some code sniplets orginally from Ren712 to sample plannar depth.
  
## Links

* [Discord](https://discord.gg/q8ZTfGqRXj)
* [More resources and tools by Blue Eagle](https://github.com/BlueEagle12)

---
