#include "noiseSimplex.hlsl"

struct Params{
    float3 wind;
    float cloudScale;
    float detailNoiseScale;
    float3 detailWind;
    float containerEdgeFadeDst;
    float cloudSmooth;
    float detailNoiseWeight;
    float densityMultiplier;
    float densityThreshold;
    UnityTexture3D shapeNoise;
    UnityTexture3D detailNoise;
    UnitySamplerState _sampler;
    float3 boundsMin;
    float3 boundsMax;
};

float scaledNoise( float3 pos ){
    return (snoise( pos ) + 1.0)/2.0;
}

bool inBounds( float3 boundsMin, float3 boundsMax, float3 pos ){
    bool x = (pos.x > boundsMin.x) && (pos.x < boundsMax.x);
    bool y = (pos.y > boundsMin.y) && (pos.y < boundsMax.y);
    bool z = (pos.z > boundsMin.z) && (pos.z < boundsMax.z);
    return x && y && z;
}

float sampleDensity( float3 pos, Params params ){
    float3 uvw = pos * params.cloudScale * 0.001 + params.wind.xyz * 0.1 * _Time.y * params.cloudScale;
    float3 size = params.boundsMax - params.boundsMin;
    float3 boundsCentre = (params.boundsMin+params.boundsMax) * 0.5f;

    float3 duvw = pos * params.detailNoiseScale * 0.001 + params.detailWind.xyz * 0.1 * _Time.y * params.detailNoiseScale;

    float dstFromEdgeX = min(params.containerEdgeFadeDst, min(pos.x - params.boundsMin.x, params.boundsMax.x - pos.x));
    float dstFromEdgeY = min(params.cloudSmooth, min(pos.y - params.boundsMin.y, params.boundsMax.y - pos.y));
    float dstFromEdgeZ = min(params.containerEdgeFadeDst, min(pos.z - params.boundsMin.z,params.boundsMax.z - pos.z));
    float edgeWeight = min(dstFromEdgeZ,dstFromEdgeX)/params.containerEdgeFadeDst;

    float4 shape = params.shapeNoise.SampleLevel(params._sampler, uvw.xyz, 0);
    float4 detail = params.detailNoise.SampleLevel(params._sampler, duvw, 0);
    float density = max(0, lerp(shape.x, detail.x, params.detailNoiseWeight) - params.densityThreshold) * params.densityMultiplier;
    return density * edgeWeight * (dstFromEdgeY/params.cloudSmooth);
}

void clouds_float( float3 rayOrigin, float3 rayDirection, float numSteps, float stepSize,
    float densityScale, float noiseScale, float3 boundsMin, float3 boundsMax,
    UnityTexture3D shapeNoise, UnityTexture3D detailNoise, UnitySamplerState _sampler,
    float3 offset, float numLightSteps, float lightStepSize, float3 lightDir,
    float lightAbsorb, float darknessThreshold, float transmittance, out float3 result )
{
    float density = 0;
    float transmission = 0;
    float lightAccumulation = 0;
    float finalLight = 0;

    float3 samplePos = rayOrigin;
    float3 pos;

    Params params;
    /*float3 wind;
    float cloudScale;
    float detailNoiseScale;
    float3 detailWind;
    float containerEdgeFadeDst;
    float cloudSmooth;
    float detailNoiseWeight;
    float densityMultiplier;
    float densityThreshold;
    UnityTexture3D shapeNoise;
    UnityTexture3D detailNoise;
    UnitySamplerState _sampler;
    float3 boundsMin;
    float3 boundsMax;*/
    params.wind = float3( 0.1, 0, 0.1 );
    params.cloudScale = noiseScale;
    params.detailNoiseScale = noiseScale * 0.1;
    params.detailWind = float3( 0.2, 0, 0.2 );
    params.containerEdgeFadeDst = 50;
    params.cloudSmooth = 50;
    params.detailNoiseWeight = 0.4;
    params.densityMultiplier = densityScale;
    params.densityThreshold = 0.5;
    params.shapeNoise = shapeNoise;
    params.detailNoise = detailNoise;
    params._sampler = _sampler;
    params.boundsMin = boundsMin;
    params.boundsMax = boundsMax;

    do{
        samplePos += (rayDirection*stepSize);
        //The blue dot position
        float sampledDensity = sampleDensity( samplePos, params );
    
        density += sampledDensity;

        //light loop
        float3 lightSamplePos = samplePos;

        for(int j = 0; j < numLightSteps; j++){
            //The red dot position
            lightSamplePos += -lightDir*lightStepSize;
            float lightDensity = snoise(lightSamplePos * noiseScale);
            //The accumulated density from samplePos to the light - the higher this value the less light reaches samplePos
            lightAccumulation += lightDensity;
        }

        //The amount of light received along the ray from param rayOrigin in the direction rayDirection
        float lightTransmission = exp(-lightAccumulation);
        //shadow tends to the darkness threshold as lightAccumulation rises
        float shadow = darknessThreshold + lightTransmission * (1.0 - darknessThreshold);
        //The final light value is accumulated based on the current density, transmittance value and the calculated shadow value 
        finalLight += density;//*transmittance*shadow;
        //Initially a param its value is updated at each step by lightAbsorb, this sets the light lost by scattering
        transmittance *= exp(-density*lightAbsorb);
    
    }while( inBounds( boundsMin, boundsMax, samplePos ) );

    transmission = exp(-density);

    result = float3(finalLight, transmission, transmittance);
}