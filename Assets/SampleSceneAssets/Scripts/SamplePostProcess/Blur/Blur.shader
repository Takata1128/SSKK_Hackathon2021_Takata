Shader "Hidden/Shader/Blur"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/RTUpscale.hlsl"

    struct Attributes
    {
        uint vertexID : SV_VertexID;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    
    float _Intensity;
    const int _SamplingCount = 21;
    float _GaussianWeight[21];
    TEXTURE2D_X(_InputTexture);
    TEXTURE2D_X(_BlurTexture);

    Varyings Vert(Attributes input)
    {
        Varyings output;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);

        return output;
    }

    float4 HorizontalBlurFragment(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);        

        const uint2 positionS = input.texcoord * _ScreenSize.xy;

        float3 col = 0.0f;        
        uint2 position = positionS;
        position.x -= _SamplingCount / 2u;
        
        for (int j = 0; j < _SamplingCount; j++)
        {
            col += LOAD_TEXTURE2D_X(_InputTexture, position).xyz * _GaussianWeight[j];
            position.x++;
        }
        return float4(saturate(col), 1.0f);
    }
    
    float4 VerticalBlurFragment(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        const uint2 positionS = input.texcoord * _ScreenSize.xy;

        float3 col = 0.0f;        
        uint2 position = positionS;
        position.y -= _SamplingCount / 2u;
        for (int j = 0; j < _SamplingCount; j++)
        {
            col += LOAD_TEXTURE2D_X(_InputTexture, position).xyz * _GaussianWeight[j];
            position.y++;   
        }
        return float4(saturate(col), 1.0f);
    }

        ENDHLSL

    SubShader
    {
        ZWrite Off
        ZTest Always
        Blend Off
        Cull Off
        Pass
        {
            Name "HorizontalBlur"
            
            HLSLPROGRAM
                #pragma fragment HorizontalBlurFragment
                #pragma vertex Vert
            ENDHLSL
        }
        Pass
        {
            Name "VerticalBlur"
            
            HLSLPROGRAM
                #pragma fragment VerticalBlurFragment
                #pragma vertex Vert
            ENDHLSL
        }
    }

    Fallback Off
}