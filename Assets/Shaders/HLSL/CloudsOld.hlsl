#include "./noiseSimplex.hlsl"

// Used to scale the blue-noise to fit the view
/*float2 scaleUV(float2 uv, float scale) {
    float x = uv.x * _ScreenParams.x;
    float y = uv.y * _ScreenParams.y;
    return float2 (x,y)/scale;
}

float maxComponent(float3 vec) {
    return max(max(vec.x, vec.y), vec.z);
}
float minComponent(float3 vec) {
    return min(min(vec.x, vec.y), vec.z);
}

// Returns min and max t distances
float2 slabs(float3 p1, float3 p2, float3 rayPos, float3 invRayDir) {
    float3 t1 = (p1 - rayPos) * invRayDir;
    float3 t2 = (p2 - rayPos) * invRayDir;
    return float2(maxComponent(min(t1, t2)), minComponent(max(t1, t2)));
}

// Returns the distance to cloud box (x) and distance inside cloud box (y)
float2 rayBox(float3 boundsMin, float3 boundsMax, float3 rayPos, float3 invRayDir) {
    float2 slabD = slabs(boundsMin, boundsMax, rayPos, invRayDir);
    float toBox = max(0, slabD.x);
    return float2(toBox, max(0, slabD.y - toBox));
}

float lerp(float a, float b, float t) {
    return a * (1 - t) + b * t;
}

float henyeyGreenstein(float g, float angle) {
    return (1.0f - pow(g,2)) / (4.0f * 3.14159 * pow(1 + pow(g, 2) - 2.0f * g * angle, 1.5f));
}

float hgScatter(float angle, float forwardScatter, float backwardScatter, Light light) {
    float scatterAverage = (henyeyGreenstein(forwardScatter, angle) + henyeyGreenstein(-backwardScatter, angle)) / 2.0f;
    // Scale the brightness by sun position
    float sunPosModifier = 1.0f;
    if (light.position.y < 0) {
        sunPosModifier = pow(light.position.y + 1,3);
    }
    return brightness * sunPosModifier + scatterAverage * scatterMultiplier;
}

float beer(float d) {
    return exp(-d);
}

float heightMap(float h) {
    return lerp(1,(1 - beer(1 * h)) * beer(4 * h), heightMapFactor);
}

float densityAtPosition(float3 rayPos) {
    float time = _Time.x * timeScale;
    float3 uvw = ((boundsMax - boundsMin) / 2.0f + rayPos) * scale / 1000.0;
    float3 cloudPosition = uvw  + cloudSpeed * time;	
    float width = min(rayPos.x - boundsMin.x, boundsMax.x - rayPos.x);
    float height = (rayPos.y - boundsMin.y) / (boundsMax.y - boundsMin.y);
    float depth = min( rayPos.z - boundsMin.z, boundsMax.z - rayPos.z);
    float edgeDistance = minComponent(float3(100, width, depth)) / 100;
    float heightMapValue = heightMap(height);
    // Density at point 
    float4 noise = NoiseTex.SampleLevel(samplerNoiseTex, cloudPosition, 0);
    float FBM = dot(noise, normalize(noiseWeights)) * volumeOffset * edgeDistance * heightMapValue; 
    float cloudDensity = FBM + densityOffset * 0.05;

    if (cloudDensity <= 0) {
        return 0;
    }

    float3 detailPosition = uvw * detailNoiseScale +  detailSpeed * time;
    float4 detailNoise = DetailNoiseTex.SampleLevel(samplerDetailNoiseTex, detailPosition, 0);
    float detailFBM = dot(detailNoise, normalize(detailWeights)) * (1-heightMapValue);

    // Combine the normal and detail
    float density = cloudDensity - detailFBM * pow(1- FBM, 3) * detailNoiseMultiplier;

    return density * densityMultiplier * 0.1 ;
}

// Calculate proportion of light that reaches the given point from the lightsource
float lightmarch(float3 position) {
    float3 L = _WorldSpaceLightPos0.xyz;
    float stepSize = rayBox(boundsMin, boundsMax, position, 1 / L).y / marchSteps;

    float density = 0;

    for (int i = 0; i < marchSteps; i++) {
        position += L * stepSize;
        density += max(0, densityAtPosition(position) * stepSize);
    }

    float transmit = beer(density * (1 - outScatterMultiplier));
    return lerp(transmit, 1, transmitThreshold);
} 

//Uses 3D texture and lighting 
void clouds_float( float3 rayOrigin, float3 rayDirection, float numSteps, float stepSize,
    float densityScale, float noiseScale, float2 uv,
    float3 offset, float numLightSteps, float lightStepSize, float3 lightDir,
    float lightAbsorb, float darknessThreshold, float transmittance, out float3 result )
{
    float density = 0;
    float transmission = 0;
    float lightAccumulation = 0;
    float finalLight = 0;
    float forwardScatter = 0.6;
    float backwardScatter = 0.4;

    Light light = GetMainLight();

    // Ray-cast
    float3 E = rayOrigin;
    float3 D = rayDirection;
    float3 boundsMin = float3( -500, -250, -500 );
    float3 boundsMax = float3( 500, 250, 500 );	

    // Ray-box intersection
    float depthTex = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(uv));
    float depth = LinearEyeDepth(depthTex) * length(rayDirection);
    float2 rayToBox = rayBox(boundsMin, boundsMax, E, 1.0f / D);
    
    // Break early if ray-box intersection is   false 
    if (rayToBox.y == 0) {
        return float4( 0, 0, 0, 0);
    }
    float3 boxHit = E + D * rayToBox.x;

    // Henyey-Greenstein scatter
    float scatter = hgScatter(dot(D, lightDir), forwardScatter, backwardScatter);

    // Blue Noise
    float randomOffset = BlueNoise.SampleLevel(samplerBlueNoise, scaleUV(i.uv, 72), 0);
    float offset = randomOffset * rayOffset;

    float stepLimit = min(depth - rayToBox.x, rayToBox.y);
    float stepSize = 12; 
    float transmit = 1;

    float3 I = 0; // Illumination
    for(int steps = offset; steps < stepLimit; steps+=stepSize) {
        float3 pos = boxHit + D * steps;
        float density = densityAtPosition(pos);

        if (density > 0) {
            I += density * transmit * lightmarch(pos) * scatter;
            transmit *= beer(density  * (1 - inScatterMultiplier));
        }
    }
    float3 color = (I * _LightColor0) + transmit;
    return float4(color, 0);
}*/

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
        sampledDensity += snoise(samplePos * noiseScale * 0.1);
        sampledDensity += snoise(samplePos * noiseScale * 0.01);
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