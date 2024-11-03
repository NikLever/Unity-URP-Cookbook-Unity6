float remap(float x, float a, float b, float c, float d)
{
    return (((x - a) / (b - a)) * (d - c)) + c;
}

void worley_float( float4 fragCoord, UnityTexture3D worleyNoise, UnitySamplerState ss, out float4 result ){
    //float2 resolution = fragCoord.zw;
    float3 st = float3( fragCoord.xy, 0.0 );
    float3 uv = float3( fragCoord.xy, 0.0 );

    st.x *= 5.0; // 5 columns for different noises
    uv -= .02 * _Time.y;

    float3 col = float3(0, 0, 0);

    float perlinWorley = SAMPLE_TEXTURE3D( worleyNoise, ss, uv ).x;

    // worley fbms with different frequencies
    float3 worley = SAMPLE_TEXTURE3D( worleyNoise, ss, uv ).yzw;
    float wfbm = worley.x * 0.625 +
                    worley.y * 0.125 +
                    worley.z * 0.25; 

    // cloud shape modeled after the GPU Pro 7 chapter
    float cloud = remap(perlinWorley, wfbm - 1.0, 1.0, 0.0, 1.0);
    cloud = remap(cloud, 0.85, 1.0, 0.0, 1.0); // fake cloud coverage

    if (st.x < 1.)
        col += perlinWorley;
    else if(st.x < 2.)
        col += worley.x;
    else if(st.x < 3.)
        col += worley.y;
    else if(st.x < 4.)
        col += worley.z;
    else if(st.x < 5.)
        col += cloud;
            
    // column dividers
    float div = smoothstep(.01, 0., abs(st.x - 1.));
    div += smoothstep(.01, 0., abs(st.x - 2.));
    div += smoothstep(.01, 0., abs(st.x - 3.));
    div += smoothstep(.01, 0., abs(st.x - 4.));
        
    col = lerp(col, float3(0.0, 0.0, 0.866), div);

    //col = float3( fragCoord.xy, 0.0);
        
    result = float4(col, 1.0);
}