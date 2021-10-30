using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;
using UnityEngine.Experimental.Rendering;

[Serializable, VolumeComponentMenu("Post-processing/Custom/Blur")]
public sealed class Blur : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the dispersion of Gaussian blur of the effect.")]
    public ClampedFloatParameter dispersion = new ClampedFloatParameter(3.0f, 0.00f, 30.0f);

    Material m_Material;

    public bool IsActive() => m_Material != null && dispersion.value > 0; 

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    MaterialPropertyBlock propertyBlock;
    private RTHandle pBuffer;

    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/Blur") != null)
            m_Material = new Material(Shader.Find("Hidden/Shader/Blur"));

        RTHandle AllocBuffer()
        {
            return RTHandles.Alloc(Vector2.one, TextureXR.slices, dimension: TextureXR.dimension,
                colorFormat: GraphicsFormat.B10G11R11_UFloatPack32,
                useDynamicScale: true, name: name);
        }
        
        propertyBlock = new MaterialPropertyBlock();
        
        pBuffer = AllocBuffer();
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        const int samplingCount = 21;
        propertyBlock.SetInt("_SamplingCount", samplingCount);
        
        // calc blur weight
        var sum = 0.0f;
        var weight = new float[samplingCount];
        for (var x = 0; x < samplingCount; x++)
        {
            var correctedDispersion = 2 * dispersion.value;
            weight[x] =
                (float) (Math.Exp(-(x - samplingCount / 2) * (x - samplingCount / 2) / correctedDispersion) /
                         Math.Sqrt(Math.PI * correctedDispersion));
            sum += weight[x];
        }
        for (var x = 0; x < samplingCount; x++) weight[x] /= sum;
    
        // blur common
        propertyBlock.SetFloatArray("_GaussianWeight", weight);

        // horizontal blur
        propertyBlock.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, pBuffer, propertyBlock, 0);

        // vertical blur
        propertyBlock.SetTexture("_InputTexture", pBuffer);
        HDUtils.DrawFullScreen(cmd, m_Material, destination, propertyBlock, 1);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
        pBuffer.Release();
    }
}