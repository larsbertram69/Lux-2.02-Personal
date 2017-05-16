# Lux-2.02-Personal - pbr Shader Framework for Unity 5.6

Lux is a (mostly...) open source shader framework built upon unity’s rendering and shading pipeline. It adds advanced lighting features such as area lights, translucent and skin lighting and allows you to easily use effects like dynamic weather, mix mapping or parallax occlusion mapping.

Lux has been built having deferred rendering in mind. So you will have to face some limitations as far as you material definitions are concerned as lux aims to be efficient rather than make everything possible.

Lux ships with a standard shader which will allow you to use and adjust most features simply using the material editor. However getting most out of it you may consider writing your own surface shaders. In order to make this as easy as possible the framework ships with a bunch of includes and shader macro definitions which should do most of the work that is needed to make everything work.

Lighting Features
- Area and diffuse fill lights
- Standard, translucent, skin and anisotropic Lighting
- Diffuse scattering

Surface Feature
- Dynamic Weather including water/wetness and snow
- Mix Mapping: Unlike unity’s built in detail mapping mix mapping allows you to blend between 2 different texture sets either controlled using vertex colors or texture input and takes the height per pixel into account if present to calculate the final blending result.
- Parallax Mapping and Parallax Occlusion Mapping

Full documentation:
https://docs.google.com/document/d/19LM0qbnUSrdgR_Eb5eWTBLbPfiEAoM2jijPV_-7GZKg/edit?usp=sharing
