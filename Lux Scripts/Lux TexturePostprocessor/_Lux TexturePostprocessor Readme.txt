- - - - - - - - - - - - - - - -
LUX TEXTUREPOSTPROCESSOR

The Lux Texturepostprocessor lets you prefilter your smoothness textures so aliasing on very smooth surfaces becomes (at least a little bit) less noticeable. 
The script acts as AssetPostprocessor and will automatically look for textures that fit the naming conventions mentioned below and postprocess them whenever they are updated.

In order to be able to postprocess your smoothness texture – or better: the alpha channel of the "Specular Color (RGB) Smoothness (A)" or "Metallic (R) Smoothness (A)" texture the script needs the corresponding normal texture as well.
For this reason
- both texture have to be placed in the same folder.
- both textures have to have the same size.
- both textures have to marked as "readable" ( Import settings --> "Texture Type: Advanced" --> "Read/Write Enabled").
- both texture have to have the same file extension (e.g. ".tga" or ".psd").
- both texture have to be named properly:
  - Spec/Smoothness map: "YourtextureName_LuxSPEC"
  - Normal map: "YourtextureName_LuxNRM"