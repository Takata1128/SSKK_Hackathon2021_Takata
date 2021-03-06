Shader "Hidden/Shader/Glitch"
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
	float _Threshold;
	float _Intensity;
	float _Param;
	float _Param1;
	float _Param2;
	float _Param3;
	float _Param4;

	float4 _OverrayColor;
	TEXTURE2D_X(_InputTexture);

	float4 CustomPostProcess(Varyings input) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

		float2 uv = input.texcoord.xy;
		uint2 positionSS = uv * _ScreenSize.xy;
		float4 outColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS);

		// ノイズ(y座標ごと)
		float n = sin(uv.y * _Param1 + _Time.y * _Param2) * sin(uv.y * _Param3 + _Time.y * _Param4);

		// ずらす
		uv.x = frac(uv.x + n * _Intensity);
		uv.y = frac(uv.y + n * _Intensity);
		uv.y *= frac(_Param * uv.y + n * _Param);
		float4 glitchColor = LOAD_TEXTURE2D_X(_InputTexture, uv * _ScreenSize.xy);

		outColor = lerp(outColor, glitchColor, step(frac(n * 170.), _Threshold));
		return outColor;
	}

		ENDHLSL

		SubShader
	{
		Pass
		{
			Name "Glitch"

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
