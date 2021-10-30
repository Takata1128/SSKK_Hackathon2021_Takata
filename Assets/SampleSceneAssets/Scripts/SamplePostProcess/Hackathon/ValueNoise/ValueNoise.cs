using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/ValueNoise")]
public sealed class ValueNoise : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the threshold of the effect.")]
    public ClampedFloatParameter threshold = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the threshold of the effect.")]
    public ClampedFloatParameter scale_x = new ClampedFloatParameter(2f, 0f, 10f);

    [Tooltip("Controls the threshold of the effect.")]
    public ClampedFloatParameter scale_y = new ClampedFloatParameter(2f, 0f, 10f);



    Material m_Material;

    public bool IsActive() => m_Material != null && intensity.value > 0f;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > HDRP Default Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/ValueNoise";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume ValueNoise is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Intensity", intensity.value);
        m_Material.SetFloat("_Threshold", threshold.value);
        m_Material.SetFloat("_ScaleX", scale_x.value);
        m_Material.SetFloat("_ScaleY", scale_y.value);

        m_Material.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
