#include "./noiseSimplex.hlsl"

//Uses 3D texture and lighting 
void clouds_float( float3 rayOrigin, float3 rayDirection, float numSteps, float stepSize,
    float densityScale, float noiseScale,
    float3 offset, float numLightSteps, float lightStepSize, float3 lightDir,
    float lightAbsorb, float darknessThreshold, float transmittance, out float3 result )
{
float density = 0;
float transmission = 0;
float lightAccumulation = 0;
float finalLight = 0;


for(int i =0; i< numSteps; i++){
    rayOrigin += (rayDirection*stepSize);

    //The blue dot position
    float3 samplePos = rayOrigin+offset;
    float sampledDensity = snoise(samplePos * noiseScale);
    density += sampledDensity*densityScale;

    //light loop
    float3 lightRayOrigin = samplePos;

    for(int j = 0; j < numLightSteps; j++){
        //The red dot position
        lightRayOrigin += -lightDir*lightStepSize;
        float lightDensity = snoise(lightRayOrigin * noiseScale);
        //The accumulated density from samplePos to the light - the higher this value the less light reaches samplePos
        lightAccumulation += lightDensity;
    }

    //The amount of light received along the ray from param rayOrigin in the direction rayDirection
    float lightTransmission = exp(-lightAccumulation);
    //shadow tends to the darkness threshold as lightAccumulation rises
    float shadow = darknessThreshold + lightTransmission * (1.0 -darknessThreshold);
    //The final light value is accumulated based on the current density, transmittance value and the calculated shadow value 
    finalLight += density*transmittance*shadow;
    //Initially a param its value is updated at each step by lightAbsorb, this sets the light lost by scattering
    transmittance *= exp(-density*lightAbsorb);
    
    }

    transmission = exp(-density);

    result = float3(finalLight, transmission, transmittance);
}