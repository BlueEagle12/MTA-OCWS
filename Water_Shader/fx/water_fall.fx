// Water Reflection Shader (MTA:SA) - Cleaned

#include "mta-helper.fx"

texture sReflection;
texture sWater;
texture sWaterNormal;

// Parameters
float3 gSkyColor         = float3(0.2, 0.4, 0.6);
float3 gWaterColor         = float3(0.1, 0.4, 0.1);
float   gRefractionStrength = 0.015;
float   gWaterTransparency  = 0.75;
float   gFresnelPower       = 2.5;
float   gFresnelScale       = 0.7;
float   gFresnelBias        = 0.3;
float   gSpecularPower      = 50.0;
float   gSpecularIntensity  = 0.05;
float2  gWaveSpeed1         = float2(0.01, 0.008);
float   gNormalScale        = 0.6;
float   gReflectionScale    = 0.5;
float   gNormalUVScale      = 0.8;

float4x4 gWorldViewProj : WORLDVIEWPROJECTION;

// Samplers
sampler2D SamplerReflection = sampler_state {
    Texture   = (sReflection);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

sampler2D SamplerWater = sampler_state {
    Texture   = (sWater);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
};

sampler2D SamplerWaterNormal = sampler_state {
    Texture   = (sWaterNormal);
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU  = Wrap;
    AddressV  = Wrap;
};

// Vertex Shader Inputs/Outputs
struct VSInput {
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct PSInput {
    float4 Position : POSITION0;
    float2 MeshUV   : TEXCOORD0;
    float4 WorldPos : TEXCOORD1;
};

PSInput VS(VSInput input) {
    PSInput output;
    output.Position = mul(input.Position, gWorldViewProj);
    output.MeshUV   = input.TexCoord;
    output.WorldPos = mul(input.Position, gWorld);
    return output;
}

float4 PS(PSInput input) : COLOR0 {
    float3 fragPos = input.WorldPos.xyz;
    float3 viewDir = normalize(gCameraPosition - fragPos);

    // Normal map (animated/scaled UV)
    float2 animUV = input.MeshUV * gNormalUVScale + gWaveSpeed1 * gTime;
    float3 normal = normalize(tex2D(SamplerWaterNormal, animUV).rgb * 2.0 - 1.0) * gNormalScale;

    // Refraction offset for fake distortion
    float2 refractionOffset = normal.xy * gRefractionStrength;

    // Reflection direction and screen projection
    float3 reflectDir = reflect(-viewDir, normal);
    float3 reflPos    = fragPos + reflectDir * 1000.0;
    float4 projPos    = mul(mul(float4(reflPos, 1.0), gView), gProjection);
    float2 screenUV   = projPos.xy / projPos.w * 0.5 + 0.5;
    screenUV.y        = 1.0 - screenUV.y;

    // Edge fade for borders
    float2 uvDist   = saturate(1.0 - abs(screenUV * 2.0 - 1.0));
    float  edgeFade = uvDist.x * uvDist.y;

    // Fresnel for view-dependent reflection strength
    float viewDot = saturate(dot(normal, -viewDir));
    float fresnel = max(gFresnelBias + gFresnelScale * pow(1.0 - viewDot, gFresnelPower), 0.2);

    // Reflection & water textures
    float4 reflection = tex2D(SamplerReflection, saturate(screenUV + refractionOffset)) * gReflectionScale;
    float4 waterTex   = tex2D(SamplerWater, animUV);

    // Specular (sun) highlight
    float3 sunDir = normalize(float3(0.5, -0.5, 0.6));
    float3 halfVec = normalize(-viewDir + sunDir);
    float  spec = pow(saturate(dot(normal, halfVec)), gSpecularPower) * gSpecularIntensity;


    float sceneDepth = tex2D(SceneDepthSampler, screenUV).r;
    float myDepth = input.WorldPos.z; // or however you get water depth
    float distToObject = abs(sceneDepth - myDepth);
    float fade = saturate(distToObject / someFadeDistance); // 0 = close, 1 = far

    // Final blending
    float4 reflBlend = lerp(waterTex, reflection, fresnel);
    reflBlend.rgb = lerp(reflBlend.rgb, gSkyColor*gWaterColor, (1.0 - edgeFade) * 0.2);
    reflBlend.rgb = saturate(reflBlend.rgb * 0.9 + spec);
    reflBlend.a   = gWaterTransparency*fade;


    return reflBlend;
}

technique WaterPlanarReflection {
    pass P0 {
        AlphaBlendEnable = TRUE;
        AlphaRef = 1;
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS();
    }
}
