Shader "Hidden/Shader/Distance"
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
	float _Intensity2;

	TEXTURE2D_X(_InputTexture);

	float4 CustomPostProcess(Varyings input) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

		float2 uv = input.texcoord;
		uint2 positionSS = input.texcoord * _ScreenSize.xy;
		float3 outColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS).xyz;

		// è„â∫ç∂âE
		float m = max(abs(uv.x - 0.5), abs(uv.y - 0.5)) * 2;
		float c1 = 1 - smoothstep(_Intensity, 1.0, m) * 0.9;

		// Ç©Ç«
		float d = distance(float2(0.5, 0.5), uv);
		float c2 = 1 - smoothstep(0.5, _Intensity2, d) * 0.9;

		outColor *= c1 * c2;

		return float4(outColor, 1);
	}

		ENDHLSL

		SubShader
	{
		Pass
		{
			Name "Distance"

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
