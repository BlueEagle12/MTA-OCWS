local scx, scy = guiGetScreenSize()
local shader = dxCreateShader("fx/water.fx", 999, 0, false, "world")
local shader2 = dxCreateShader("fx/water.fx", 999, 0, false, "world")

local textureWater = dxCreateTexture("images/water.jpg", "dxt5")
local normalTex = dxCreateTexture("images/water_normal.png")
dxSetShaderValue(shader, "sWaterNormal", normalTex)
dxSetShaderValue(shader2, "sWaterNormal", normalTex)

local reflectionTexture = dxCreateScreenSource(scx/5, scy/5)

applyListNormal = {'waterclear256'}
applyListBlended = {'*water*','pol'}

if shader then
    dxSetShaderValue(shader, "sWater", textureWater)
    dxSetShaderValue(shader2, "sWater", textureWater)

-- Apply 'shader' to all textures in both lists

    for _, tex in ipairs(applyListBlended) do
        engineApplyShaderToWorldTexture(shader, tex)
    end

    for _, tex in ipairs(applyListNormal) do
        engineApplyShaderToWorldTexture(shader2, tex)
        engineRemoveShaderFromWorldTexture(shader2, tex)
    end

else
    outputChatBox("Shader creation failed!", 255, 0, 0)
    return
end


local params = {
    gDeepWater              = {0.05, 0.2, 0.05},
    gShallowWater           = {0.2, 0.9, 0.6},
    gRefractionStrength     = 0.5,
    gMaxWaterTransparency   = 0.7,
    gFresnelPower           = 2.5,
    gFresnelScale           = 0.7,
    gFresnelBias            = 0.3,
    gSpecularPower          = 5,
    gSpecularIntensity      = 50.0,
    gWaveSpeed1             = {0.01, 0.008},
    gNormalScale            = 0.35,
    gReflectionScale        = 0.3,
    gUVScale                = 0.03,
    gNearPlane              = getNearClipDistance(),
    gFarPlane               = getFarClipDistance(),
}

for k, v in pairs(params) do
    if type(v) == "table" then
        dxSetShaderValue(shader, k, unpack(v))
        dxSetShaderValue(shader2, k, unpack(v))
    else
        dxSetShaderValue(shader, k, v)
        dxSetShaderValue(shader2, k, v)
    end
end


dxSetShaderValue(shader2, 'useDepth', false)

dxSetShaderValue(shader, "sPixelSize", {1/scx, 1/scy})
dxSetShaderValue(shader2, "sPixelSize", {1/scx, 1/scy})

addEventHandler("onClientHUDRender", root, function()
    if not shader then return end

    local perFrame = {
    gNearPlane           = getNearClipDistance(),
    gFarPlane            = getFarClipDistance(),
    }

    for k, v in pairs(perFrame) do
        if type(v) == "table" then
            dxSetShaderValue(shader, k, unpack(v))
            dxSetShaderValue(shader2, k, unpack(v))
        else
            dxSetShaderValue(shader, k, v)
            dxSetShaderValue(shader2, k, v)
        end
    end

    dxUpdateScreenSource(reflectionTexture, true)
    dxSetShaderValue(shader, "sReflection", reflectionTexture)
    dxSetShaderValue(shader2, "sReflection", reflectionTexture)
    -- Camera values
    local cx, cy, cz, tx, ty, tz, roll, fov = getCameraMatrix()
    dxSetShaderValue(shader, "gCameraPosition", cx, cy, cz)
    dxSetShaderValue(shader, "gTime", getTickCount() / 1000)

    dxSetShaderValue(shader2, "gCameraPosition", cx, cy, cz)
    dxSetShaderValue(shader2, "gTime", getTickCount() / 1000)
    -- Sky color (bottom gradient)
    local topR, topG, topB, botR, botG, botB = getSkyGradient()
    local avgR = (topR + botR) / 2 / 255
    local avgG = (topG + botG) / 2 / 255
    local avgB = (topB + botB) / 2 / 255
    dxSetShaderValue(shader, "gSkyColor", avgR, avgG, avgB)
    dxSetShaderValue(shader2, "gSkyColor", avgR, avgG, avgB)
end)
