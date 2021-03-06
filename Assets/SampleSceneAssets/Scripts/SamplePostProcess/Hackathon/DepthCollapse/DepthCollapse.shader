Shader "Hidden/Shader/DepthCollapse"
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
	int _PixelX;
	int _PixelY;
	float _NoiseSpeed;
	float _NoiseRatio;
	float _NoiseMin;
	float _NoiseMax;
	float3 _NoiseColor;
	float _DistortIntensity;
	TEXTURE2D_X(_InputTexture);

	float rand(float2 seed) {
		return frac(sin(dot(seed.xy, float2(12.9888, 78.233))) * 43758.5453);
	}

	float4 CustomPostProcess(Varyings input) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

		float2 uv = input.texcoord;
		uint2 positionSS = input.texcoord * _ScreenSize.xy;
		float3 outColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS).xyz;


		// ピクセルノイズ
		float ratioX = 1 / (float)_PixelX;
		float ratioY = 1 / (float)_PixelY;
		float2 coord = float2((int)(uv.x / ratioX) * ratioX, (int)(uv.y / ratioY) * ratioY);
		float c = step(_NoiseRatio, rand(coord * floor(_Time.y * _NoiseSpeed)));

		// 歪み
		float dis1 = sin(_Time * 100.0) + uv.y;
		float dis2 = sin(_Time * 50.0) + uv.y * 2.;
		uv.x += (dis1 * dis1 + dis2 * dis2 - 1) * _DistortIntensity / 10.;

		float3 collapsedColor = lerp(outColor,LOAD_TEXTURE2D_X(_InputTexture, uv * _ScreenSize.xy),c);


		// 深度で効果
		float depth = Linear01Depth(LoadCameraDepth(positionSS),_ZBufferParams);
		outColor = lerp(collapsedColor, outColor, smoothstep(_NoiseMin,_NoiseMax,depth));

		return float4(outColor, 1);
	}

		ENDHLSL

		SubShader
	{
		Pass
		{
			Name "DepthCollapse"

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
