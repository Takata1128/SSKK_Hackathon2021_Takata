using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/Glitch")]
public sealed class Glitch : CustomPostProcessVolumeComponent, IPostProcessComponent
{


    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the threshold of the effect.")]
    public ClampedFloatParameter threshold = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the random param of the effect.")]
    public ClampedFloatParameter param = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the random param of the effect.")]
    public ClampedFloatParameter param1 = new ClampedFloatParameter(0f, 0f, 30f);

    [Tooltip("Controls the random param of the effect.")]
    public ClampedFloatParameter param2 = new ClampedFloatParameter(0f, 0f, 30f);

    [Tooltip("Controls the random param of the effect.")]
    public ClampedFloatParameter param3 = new ClampedFloatParameter(0f, 0f, 30f);

    [Tooltip("Controls the random param of the effect.")]
    public ClampedFloatParameter param4 = new ClampedFloatParameter(0f, 0f, 30f);

    Material m_Material;

    public bool IsActive() => m_Material != null && intensity.value > 0f;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > HDRP Default Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/Glitch";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume Glitch is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Intensity", intensity.value);
        m_Material.SetFloat("_Threshold", threshold.value);
        m_Material.SetFloat("_Param", param.value);
        m_Material.SetFloat("_Param1", param1.value);
        m_Material.SetFloat("_Param2", param2.value);
        m_Material.SetFloat("_Param3", param3.value);
        m_Material.SetFloat("_Param4", param4.value);
        m_Material.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
