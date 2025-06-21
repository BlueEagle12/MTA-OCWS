// Water Reflection Shader (MTA:SA) Blue Eagle

#include "mta-helper.fx"

float4 gFogColor                    < string renderState="FOGCOLOR"; >;
int gFogEnable                      < string renderState="FOGENABLE"; >;
int gCapsMaxAnisotropy              < string deviceCaps="MaxAnisotropy"; >;

float gFogStart                     < string renderState="FogStart"; >;
float gFogDensity                   < string renderState="FogDensity"; >;


texture sReflection;
texture sWater;
texture sWaterNormal;
texture gDepthBuffer : DEPTHBUFFER;

// Exposed parameters (set from Lua)
float3 gSkyColor;
float3 gShallowWater;
float3 gDeepWater;
float  gRefractionStrength;
float  gMaxWaterTransparency;
float  gFresnelPower;
float  gFresnelScale;
float  gFresnelBias;
float  gSpecularPower;
float  gSpecularIntensity;
float2 gWaveSpeed1;
float  gNormalScale;
float  gReflectionScale;
float  gUVScale;
float  gNearPlane;
float  gFarPlane;
float  gFogDistance;
float2 sPixelSize = float2(0,0);
bool useDepth = true;

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
sampler2D SamplerDepth = sampler_state {
    Texture   = (gDepthBuffer);
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

// Vertex structures
struct VSInput {
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};
struct PSInput {
    float4 Position  : POSITION0;
    float2 MeshUV    : TEXCOORD0;
    float4 WorldPos  : TEXCOORD1;
    float4 ScreenPos : TEXCOORD2;
};

// Vertex Shader
PSInput VS(VSInput input) {
    PSInput output;
    output.Position  = mul(input.Position, gWorldViewProjection);
    output.MeshUV    = input.TexCoord;
    output.WorldPos  = mul(input.Position, gWorld);
    output.ScreenPos = output.Position;
    return output;
}

// Depth Sampler
float SampleSceneDepth(float2 uv) {
    float4 texel = tex2D(SamplerDepth, uv);
#if IS_DEPTHBUFFER_RAWZ
    float3 rawval = floor(255.0 * texel.rgb + 0.5);
    float3 valueScaler = float3(
        0.9960938093718177,
        0.0038909914428587,
        1.519918532366665e-5
    );
    float rawDepth = dot(rawval, valueScaler / 255.0);
    return rawDepth;
#else
    float z = texel.r;
    return z;
#endif
}

// Convert screen-space to UV
float2 ScreenUV(float4 projPos) {
    float2 uv = projPos.xy / projPos.w * 0.5 + 0.5;
    uv.y = 1.0 - uv.y;
    return uv;
}

// Blur Reflection Helper
float3 BlurReflection(float2 uv, float strength) {
    float2 offsets[4] = {
        float2( strength,  0.0),
        float2(-strength,  0.0),
        float2( 0.0,  strength),
        float2( 0.0, -strength)
    };
    float3 col = tex2D(SamplerReflection, uv).rgb;
    for (int i = 0; i < 4; i++) {
        col += tex2D(SamplerReflection, uv + offsets[i]).rgb;
    }
    return col / 5.0;
}

// Pixel Shader
float4 PS(PSInput input) : COLOR0 {
    float3 worldPos      = input.WorldPos.xyz;
    float3 toCamera      = normalize(gCameraPosition - worldPos);
    float  cameraDistance = length(gCameraPosition - worldPos);

    // Compute animated/scaled UV for normal map
    float2 worldUV       = worldPos.xy * gUVScale + gWaveSpeed1 * gTime;
    float3 normalMap     = tex2D(SamplerWaterNormal, worldUV).rgb * 2.0 - 1.0;
    float3 waterNormal   = normalize(normalMap) * gNormalScale;

    float2 refractionOffset = waterNormal.xy * gRefractionStrength;

    // Projected UV
    float2 screenUV          = ScreenUV(input.ScreenPos);
    screenUV += 0.5 * sPixelSize;
    
    // Depths

    float waterPixelDepth   = 0.9;

    if (useDepth) {
        float sampledSceneDepth  = saturate(max(0.915, SampleSceneDepth(screenUV)));
        float projectedDepth     = input.ScreenPos.z / input.ScreenPos.w;
        float linearDepth        = 1.0 / (1.0 - projectedDepth);
        float linearSceneDepth   = (1.0 / (1.0 - sampledSceneDepth));

        // Water depth
        float waterHeightOffset  = worldPos.z / 20.0;
        waterPixelDepth    = min(10.0, (linearSceneDepth - linearDepth) + waterHeightOffset);
    } else {
        waterPixelDepth   = 1;
    }
    // Edge and depth blends
    float edgeFade           = smoothstep(0.0, 1.0, waterPixelDepth);
    float depthBlend         = smoothstep(0.0, 15.0, waterPixelDepth);

    // Water color blending

    float3 waterColorBlended = lerp(gShallowWater, gDeepWater, depthBlend);

    // How much are we looking down?
    float cameraDownFactor   = saturate(dot(-toCamera, float3(0, 0, -1)));

    // Reflection
    float3 reflectionDir     = reflect(-toCamera, waterNormal);
    float3 reflectionPos     = worldPos + reflectionDir * 1500.0;
    float4 reflectedProjPos  = mul(mul(float4(reflectionPos, 1.0), gView), gProjection);
    float2 reflectionUV      = ScreenUV(reflectedProjPos) + refractionOffset;

    float reflectionFade     = saturate(1.0 - smoothstep(100.0, 250.0, cameraDistance));

    float fogFade = saturate(smoothstep(gFogStart, gFarPlane, cameraDistance))*gFogDensity;

    float blurStrength       = lerp(0.01, 0.001, reflectionFade);
    float3 blurredReflection = BlurReflection(saturate(reflectionUV), blurStrength) * gReflectionScale;
    float4 reflectionColor   = float4(blurredReflection, 1.0);

    // Wavy sky color based on view angle to normal
    float normalFacing       = saturate(dot(waterNormal, -toCamera));
    float skyWaveIntensity   = pow(normalFacing, 4.0);
    float3 wavySkyColor      = gSkyColor * skyWaveIntensity;
    float4 skyColorWavy      = float4(wavySkyColor, 1.0);

    // Final reflection (SSR + wavy sky blend)
    float4 finalReflection   = lerp(reflectionColor, skyColorWavy, cameraDownFactor);

    // Edge fade based on screen-space distance from center
    float2 uvDistFromCenter  = saturate(1.0 - abs(screenUV * 2.0 - 1.0));
    float  screenEdgeFade    = uvDistFromCenter.x * uvDistFromCenter.y;

    // Specular highlight
    float3 sunDirection      = normalize(float3(0.2, -1.0, 0.2));
    float3 halfVector        = normalize(toCamera + sunDirection);
    float  normalSpecAngle   = saturate(dot(waterNormal, halfVector));
    float  specularStrength  = pow(normalSpecAngle, gSpecularPower) * gSpecularIntensity;
    float4 specularColor     = float4(lerp(float3(0,0,0), gSkyColor * gReflectionScale, specularStrength), 1.0);

    // Fresnel factor
    float normalViewDot      = saturate(dot(waterNormal, -toCamera));
    float fresnelFactor      = max(gFresnelBias + gFresnelScale * pow(1.0 - normalViewDot, gFresnelPower), 0.2);

    // Combine: base water, reflection, fresnel
    float4 blendedBaseColor  = lerp(float4(gSkyColor, 1.0), finalReflection, fresnelFactor);
    blendedBaseColor.rgb     = lerp(blendedBaseColor.rgb,gSkyColor * waterColorBlended,((1.0 - edgeFade * screenEdgeFade) * 0.2));
    blendedBaseColor.rgb     = saturate(blendedBaseColor.rgb + specularColor.rgb);

    // Alpha: fade out at edges and with water depth
    float alphaDepthFade     = lerp(1.0, 1.01, waterPixelDepth);
    blendedBaseColor.a       = gMaxWaterTransparency * edgeFade * alphaDepthFade;

    if (gFogEnable) blendedBaseColor.rgb = lerp(blendedBaseColor.rgb,gFogColor.rgb,fogFade);

    return blendedBaseColor;
}


technique WaterPlanarReflection {
    pass P0 {
        AlphaBlendEnable = TRUE;
        AlphaRef = 1;
        VertexShader = compile vs_3_0 VS();
        PixelShader  = compile ps_3_0 PS();
    }
}
