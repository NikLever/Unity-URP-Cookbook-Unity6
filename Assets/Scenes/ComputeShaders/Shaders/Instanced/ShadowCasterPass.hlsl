#ifndef UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED
#define UNIVERSAL_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;

struct BoidData
{
    float3 velocity; // 速度
    float3 position; // 位置
};

StructuredBuffer<BoidData> _BoidDataBuffer;
float _Freq;
float3 _ObjectScale; // Boidオブジェクトのスケール

float4x4 eulerAnglesToRotationMatrix(float3 angles)
{
    float ch = cos(angles.y); float sh = sin(angles.y); // heading
    float ca = cos(angles.z); float sa = sin(angles.z); // attitude
    float cb = cos(angles.x); float sb = sin(angles.x); // bank

    // Ry-Rx-Rz (Yaw Pitch Roll)
    return float4x4(
        ch * ca + sh * sb * sa, -ch * sa + sh * sb * ca, sh * cb, 0,
        cb * sa, cb * ca, -sb, 0,
        -sh * ca + ch * sb * sa, sh * sa + ch * sb * ca, ch * cb, 0,
        0, 0, 0, 1
    );
}

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    uint instanceID : SV_InstanceID;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
};

float4 GetShadowPositionHClip(Attributes input, uint instanceID)
{

    // 位置計算
    BoidData boidData = _BoidDataBuffer[input.instanceID];

    float3 pos = boidData.position.xyz; // Boidの位置を取得

    float3 scl = _ObjectScale;
    float4x4 object2world = (float4x4)0;
    object2world._11_22_33_44 = float4(scl.xyz, 1.0);
    float rotY = atan2(boidData.velocity.x, boidData.velocity.z);
    float rotX = -asin(boidData.velocity.y / (length(boidData.velocity.xyz) + 1e-8));
    float4x4 rotMatrix = eulerAnglesToRotationMatrix(float3(rotX, rotY, 0));
    // 行列に回転を適用
    object2world = mul(rotMatrix, object2world);
    // 行列に位置（平行移動）を適用
    object2world._14_24_34 += pos.xyz;

    input.positionOS.x += 0.01/_Freq*sin(input.positionOS.z*30+_Time.z*2*_Freq + input.instanceID);

    
    float3 positionWS = TransformObjectToWorld(mul(object2world, input.positionOS));


    
    float3 normalWS = TransformObjectToWorldNormal(mul(object2world, input.normalOS));

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = GetShadowPositionHClip(input, input.instanceID);
    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}

#endif
