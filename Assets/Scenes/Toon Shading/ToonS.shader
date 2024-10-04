Shader "Custom/ToonS" {

    Properties {
        [NoScaleOffset] _BaseMap ("Texture", 2D) = "white" {}
        _Shades ("Shades", Integer) = 3
    }

    Subshader {

        Tags {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass{
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Stencil
             {
                 Ref 2
                 Comp Always
                 Pass Replace
             } 

            ZWrite On

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            CBUFFER_START(UnityPerMaterial)

            sampler2D _BaseMap;
            int _Shades;

            CBUFFER_END

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 texcoord         : TEXCOORD0;
                float3 normal           : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS      : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float3 normal           : NORMAL;
            };
     
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.texcoord;
                OUT.normal = TransformObjectToWorld(IN.normal);
                return OUT;
            }

            float remap(float In, float2 InMinMax, float2 OutMinMax)
            {
                return OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
            }

            half4 frag(Varyings IN) : SV_Target {
                Light light = GetMainLight();
                float dotLN = dot( IN.normal, light.direction );//n, IN.normal );
                float lightLevel = remap( dotLN, float2(-1, 1), float2(0, 1));
                float oneOverShades = 1.0 / float(_Shades);
                lightLevel = round( lightLevel / oneOverShades );
                float ramp = remap( lightLevel, float2(0, _Shades), float2(0, 1) );
                //half3 lightingColor = LightingLambert(light.color, light.direction, IN.normal);
                half3 texel = tex2D(_BaseMap, IN.uv).rgb;
                
                half3 color = texel * saturate(ramp);

	            return half4(color, 1.0);
            }           

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            LOD 80
            Cull [_Culling]
            Offset [_Offset], [_Offset]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
           
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster

            //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS       : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS      : SV_POSITION;
            };
     
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target {
	            return half4(0.0, 0.0, 0.0, 1.0);
            } 

            ENDHLSL
        }
    }

}