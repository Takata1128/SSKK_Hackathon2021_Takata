Shader "Hidden/Shader/Outline"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
	#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/PostProcessing/Shaders/FXAA.hlsl"
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

    Varyings Vert(Attributes input)
    {
        Varyings output;

        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);

        return output;
    }

    float _Intensity;
    float _DepthThreshold;
    float _NormalThreshold;
    float4 _EdgeColor;
    TEXTURE2D_X(_InputTexture);

    float3 GetViewSpaceNormal(float2 positionSS)
    {
        NormalData normal;
        DecodeFromNormalBuffer(positionSS, normal);
        float3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V, normal.normalWS));
        return normalVS;
    }

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 positionSS = input.texcoord * _ScreenSize.xy;
        const float3 vInputColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS).xyz;
        
        float fEdge = 0.0f;

        // Sobel Filter
        // https://blog.siliconstudio.co.jp/2021/05/960/

        // depth edge
        float fViewZ;
        {
            const float unityDepth00 = LoadCameraDepth(positionSS + float2(-1.0f, -1.0f));
            const float unityDepth10 = LoadCameraDepth(positionSS + float2(0.0f, -1.0f));
            const float unityDepth20 = LoadCameraDepth(positionSS + float2(1.0f, -1.0f));
            const float unityDepth01 = LoadCameraDepth(positionSS + float2(-1.0f, 0.0f));
            const float unityDepth11 = LoadCameraDepth(positionSS + float2(0.0f, 0.0f));
            const float unityDepth21 = LoadCameraDepth(positionSS + float2(1.0f, 0.0f));
            const float unityDepth02 = LoadCameraDepth(positionSS + float2(-1.0f, 1.0f));
            const float unityDepth12 = LoadCameraDepth(positionSS + float2(0.0f, 1.0f));
            const float unityDepth22 = LoadCameraDepth(positionSS + float2(1.0f, 1.0f));
            const float logZ00 = log2(LinearEyeDepth(unityDepth00, _ZBufferParams));
            const float logZ10 = log2(LinearEyeDepth(unityDepth10, _ZBufferParams));
            const float logZ20 = log2(LinearEyeDepth(unityDepth20, _ZBufferParams));
            const float logZ01 = log2(LinearEyeDepth(unityDepth01, _ZBufferParams));
            fViewZ = LinearEyeDepth(unityDepth11, _ZBufferParams);
            const float logZ11 = log2(fViewZ);
            const float logZ21 = log2(LinearEyeDepth(unityDepth21, _ZBufferParams));
            const float logZ02 = log2(LinearEyeDepth(unityDepth02, _ZBufferParams));
            const float logZ12 = log2(LinearEyeDepth(unityDepth12, _ZBufferParams));
            const float logZ22 = log2(LinearEyeDepth(unityDepth22, _ZBufferParams));
            const float fSobelX = logZ00 + 2.0f * logZ01 + logZ02 - logZ20 - 2.0f * logZ21 - logZ22;
            const float fSobelY = logZ00 + 2.0f * logZ10 + logZ20 - logZ02 - 2.0f * logZ12 - logZ22;
            const float fSobel = sqrt(fSobelX * fSobelX + fSobelY * fSobelY);
            if (fSobel > _DepthThreshold) fEdge = 1.0f;
        }

        // normal edge
        {
            const float3 normal00 = GetViewSpaceNormal(positionSS + float2(-1.0f, -1.0f));
            const float3 normal10 = GetViewSpaceNormal(positionSS + float2(0.0f, -1.0f));
            const float3 normal20 = GetViewSpaceNormal(positionSS + float2(1.0f, -1.0f));
            const float3 normal01 = GetViewSpaceNormal(positionSS + float2(-1.0f, 0.0f));
            const float3 normal11 = GetViewSpaceNormal(positionSS + float2(0.0f, 0.0f));
            const float3 normal21 = GetViewSpaceNormal(positionSS + float2(1.0f, 0.0f));
            const float3 normal02 = GetViewSpaceNormal(positionSS + float2(-1.0f, 1.0f));
            const float3 normal12 = GetViewSpaceNormal(positionSS + float2(0.0f, 1.0f));
            const float3 normal22 = GetViewSpaceNormal(positionSS + float2(1.0f, 1.0f));
            const float3 vSobelX = normal00 + 2.0f * normal01 + normal02 - normal20 - 2.0f * normal21 - normal22;
            const float3 vSobelY = normal00 + 2.0f * normal10 + normal20 - normal02 - 2.0f * normal12 - normal22;
            const float3 vSobel = sqrt(vSobelX * vSobelX + vSobelY * vSobelY);
            if (max(vSobel.x,max(vSobel.y, vSobel.z)) > _NormalThreshold) fEdge = 1.0f;
        }

        // Render Edge
        fEdge *= _Intensity;
        float4 vOutColor = float4(vInputColor.rgb, 1.0f);
        vOutColor.rgb = lerp(vOutColor.rgb, _EdgeColor.rgb, fEdge);
        return vOutColor;
    }

        ENDHLSL

        SubShader
    {
        Pass
        {
            Name "Outline"

            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            HLSLPROGRAM
                #pragma fragment CustomPostProcess
                #pragma vertex Vert
            ENDHLSL
        }
    }

    Fallback Off
}