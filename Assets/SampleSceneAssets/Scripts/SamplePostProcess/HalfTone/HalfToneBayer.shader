Shader "Hidden/Shader/HalfToneBayer"
{
    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 playstation xboxone xboxseries vulkan metal switch

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
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

    // List of properties to control your post process effect
    float _Intensity;
    TEXTURE2D_X(_InputTexture);

    // http://hooktail.org/computer/index.php?%A5%CF%A1%BC%A5%D5%A5%C8%A1%BC%A5%F3%BD%E8%CD%FD%28%A5%C7%A5%A3%A5%B6%CB%A1%29
    #define FROM_BYTE(x) ((1.0f / 255.f) * (x * 16.f + 8))
    static const float bayerpattern[] = {
        FROM_BYTE(0.f), FROM_BYTE(8.f), FROM_BYTE(2.f), FROM_BYTE(10.f),
        FROM_BYTE(12.f), FROM_BYTE(4.f), FROM_BYTE(14.f), FROM_BYTE(6.f),
        FROM_BYTE(3.f), FROM_BYTE(11.f), FROM_BYTE(1.f), FROM_BYTE(9.f),
        FROM_BYTE(15.f), FROM_BYTE(7.f), FROM_BYTE(13.f), FROM_BYTE(5.f)
    };

    float4 CustomPostProcess(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 positionSS = input.texcoord * _ScreenSize.xy;
        float3 inputColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS).xyz;
        float3 outColor = float3(0.f,0.f,0.f);

        float bayer = bayerpattern[(positionSS.y % 4) * 4 + (positionSS.x % 4)];

        // グレースケール化(NTSC 系加重平均法)
        float g = inputColor.r * 0.298912 + inputColor.g * 0.586611 + inputColor.b + 0.114478;

        if (bayer <= g)
        {
            outColor = float3(1.f,1.f,1.f);
        }
        else
        {
            outColor = float3(0.f,0.f,0.f);
        }

        return float4(outColor, 1.f);
    }

    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "HalfToneBayer"

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
