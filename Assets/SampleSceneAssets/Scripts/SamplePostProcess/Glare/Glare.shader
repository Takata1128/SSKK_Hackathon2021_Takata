Shader "Hidden/Shader/Glare"
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
        float2 uvOffset   : TEXCOORD1;
        float pathfactor  : TEXCOORD2;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    struct v2f
    {
        float4 positionCS : SV_POSITION;
        float2 texcoord   : TEXCOORD0;
        UNITY_VERTEX_OUTPUT_STEREO
    };

    // List of properties to control your post process effect
    float _Intensity;
    float _Threshold;
    float _Attenuation;
    float4 _InputTexture_ST;
    float4 _InputTexture_TexelSize;
    int3 _Params;
    TEXTURE2D_X(_InputTexture);


    v2f VertBrightness(Attributes input)
    {
        v2f output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord   = GetFullScreenTriangleTexCoord(input.vertexID);

        return output;
    }

    float4 FragBrightness(v2f input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 positionSS    = input.texcoord * _ScreenSize.xy;
        float4 col          = LOAD_TEXTURE2D_X(_InputTexture, positionSS);
        float brightness    = max(col.r, max(col.g, col.b));
        float contribution  = max(0, brightness - _Threshold);
        contribution       /= max(brightness, 0.00001);

        return col * contribution;
    }

    Varyings VertStar(Attributes input)
    {
        Varyings output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS  = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord    = GetFullScreenTriangleTexCoord(input.vertexID);
        output.pathfactor  = pow(4, _Params.z);
        output.uvOffset    = float2(_Params.x, _Params.y) * _InputTexture_TexelSize.xy * output.pathfactor;

        return output;
    }

    float4 FragStar(Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 positionSS        = input.texcoord * _ScreenSize.xy;
        float2 positionSSOffset = input.uvOffset * _ScreenSize.xy;
        float4 col              = float4(0,0,0,1);

        // uvをずらしてぼかしていく
        for (int i = 0; i < 4; i++)
        {
            col.rgb     += LOAD_TEXTURE2D_X(_InputTexture, positionSS).rgb * pow(abs(_Attenuation),i * input.pathfactor);
            positionSS  += positionSSOffset;
        }
        return col;
    }

    v2f VertCompose(Attributes input)
    {
        v2f output;
        UNITY_SETUP_INSTANCE_ID(input);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

        output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
        output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);

        return output;
    }

    float4 FragCompose(v2f input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 positionSS = input.texcoord * _ScreenSize.xy;
        float4 outColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS);

        return outColor * _Intensity;
    }
    ENDHLSL

    SubShader
    {
        ZWrite Off
        ZTest Always
        Cull Off

        // 明度抽出パス
        Pass
        {
            Name "Brightness"

            HLSLPROGRAM
                #pragma fragment FragBrightness
                #pragma vertex VertBrightness
            ENDHLSL
        }
        // スターを作るパス
        Pass
        {
            Name "Star"

            HLSLPROGRAM
                #pragma fragment FragStar
                #pragma vertex VertStar
            ENDHLSL
        }
        // 加算合成パス
        Pass
        {
            Name "Compose"

            Blend One One
            ColorMask RGB

            HLSLPROGRAM
                #pragma fragment FragCompose
                #pragma vertex VertCompose
            ENDHLSL
        }
    }
    Fallback Off
}
