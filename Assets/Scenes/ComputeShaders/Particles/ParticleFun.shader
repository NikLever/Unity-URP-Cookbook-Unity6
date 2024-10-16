Shader "Custom/ParticleFun"
{
    Properties
    {
        _PointSize("Point size", Float) = 5.0
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            struct Particle{
                float3 position;
                float3 velocity;
                float life;
            };

            StructuredBuffer<Particle> particleBuffer;

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float _PointSize;

            CBUFFER_END


            struct Attributes
            {
                float4 positionOS   : POSITION;
                uint instanceID : SV_InstanceID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float4 color : COLOR;
                float size: PSIZE;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Color
			    float life = particleBuffer[IN.instanceID].life;
			    float lerpVal = life * 0.25f;
			    OUT.color = half4(1.0f - lerpVal+0.1, lerpVal+0.1, 1.0f, lerpVal);

			    // Position
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                OUT.size = _PointSize;

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                return IN.color;
            }
            ENDHLSL
        }
    }
}
