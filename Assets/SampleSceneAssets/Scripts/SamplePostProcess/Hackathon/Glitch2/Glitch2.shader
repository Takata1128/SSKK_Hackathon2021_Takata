Shader "Hidden/Shader/Glitch2"
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
	float _FrameRate;
	float _GlitchProb;
	float _GlitchSize;
	float _ShiftX;
	float _ShiftY;
	float _GrayProb;
	TEXTURE2D_X(_InputTexture);

	float rand(float2 seed) {
		return frac(sin(dot(seed.xy, float2(12.9888, 78.233))) * 43758.5453);
	}

	float perlinNoise(float2 st) {
		float2 p = floor(st);
		float2 f = frac(st);
		float2 u = f * f * (3.0 - 2.0 * f);

		float v00 = rand(p + float2(0, 0));
		float v01 = rand(p + float2(1, 0));
		float v10 = rand(p + float2(0, 1));
		float v11 = rand(p + float2(1, 1));

		return lerp(
			lerp(dot(v00, float2(0, 0)), dot(v01, float2(0, 1)), u.x),
			lerp(dot(v10, float2(1, 0)), dot(v11, float2(1, 1)), u.x),
			u.y) + 0.5f;
	}

	float4 CustomPostProcess(Varyings input) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

		float2 uv = input.texcoord;
		uint2 positionSS = uv * _ScreenSize.xy;
		float3 outColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS).xyz;

		// ポスタライズタイム
		float posterize1 = floor(frac(perlinNoise(_SinTime.y) * 10.) / (1 / _FrameRate)) * (1 / _FrameRate);
		float posterize2 = floor(frac(perlinNoise(_SinTime.y) * 5.) / (1 / _FrameRate)) * (1 / _FrameRate);
		float posterize3 = floor(frac(perlinNoise(_SinTime.y) * 17.) / (1 / _FrameRate)) * (1 / _FrameRate);


		// グリッチ発生フラグ
		float flag = step(rand(posterize2), _GlitchProb);

		// グリッチのずれ幅
		float distort = ((2.0 * rand(posterize1) - 0.5) * 0.1) * flag;
		// グリッチの高さ
		float height = rand(2.0 * rand(posterize1) - 0.5);

		// グリッチ生成
		float glitchLine1 = step(uv.y, height);
		float glitchLine2 = step(uv.y, height + _GlitchSize);
		float glitch = saturate(glitchLine2 - glitchLine1);
		uv.x = lerp(uv.x, uv.x + distort, glitch);

		// RGBずらし
		outColor.r = LOAD_TEXTURE2D_X(_InputTexture, (uv + float2(_ShiftX, _ShiftY) * flag) * _ScreenSize.xy).r;
		outColor.b = LOAD_TEXTURE2D_X(_InputTexture, (uv - float2(_ShiftX, _ShiftY) * flag) * _ScreenSize.xy).b;

		// グリッチ時確率でグレースケール化
		float3 grayScale = Luminance(outColor).xxx;
		outColor = lerp(outColor,grayScale, step(rand(posterize3),flag * _GrayProb));

		return float4(outColor,1);
	}

		ENDHLSL

		SubShader
	{
		Pass
		{
			Name "Glitch2"

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
