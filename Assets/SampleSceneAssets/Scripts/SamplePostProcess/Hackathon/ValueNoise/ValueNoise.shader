Shader "Hidden/Shader/ValueNoise"
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
	float _ScaleX;
	float _ScaleY;
	TEXTURE2D_X(_InputTexture);

	float random(float2 p) {
		return frac(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
	}

	float noise(float2 st)
	{
		float2 p = floor(st);
		return random(p);
	}

	float4 CustomPostProcess(Varyings input) : SV_Target
	{
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

		float2 uv = input.texcoord;

		uint2 positionSS = input.texcoord * _ScreenSize.xy;
		float3 outColor = LOAD_TEXTURE2D_X(_InputTexture, positionSS).xyz;

		float sizeX = (random(floor(_Time.x)) + 1.) * _ScaleX;
		float sizeY = (random(floor(_Time.y)) + 1.) * _ScaleY;

		float2 coord = uv * float2(sizeX, sizeY);

		coord.x += random(floor(_Time)) * sizeX;
		float n = random(random(floor(coord)) * floor(_Time));

		float3 pixColor = lerp(0.8,1.0,LOAD_TEXTURE2D_X(_InputTexture, floor(coord)).xyz);

		outColor = lerp(outColor * pixColor, outColor, step(n, _Threshold));
		return float4(outColor , 1);
	}

		ENDHLSL

		SubShader
	{
		Pass
		{
			Name "ValueNoise"

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
