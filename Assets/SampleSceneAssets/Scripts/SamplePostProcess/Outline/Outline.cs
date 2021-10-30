using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/Outline")]
public sealed class Outline : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(1.0f, 0f, 1f);
    [Tooltip("Controls the DepthThreshold of the effect.")]
    public ClampedFloatParameter depthThreshold = new ClampedFloatParameter(0.1f, 0f, 0.5f);
    [Tooltip("Controls the NormalThreshold of the effect.")]
    public ClampedFloatParameter normalThreshold = new ClampedFloatParameter(1.0f, 0f, 4.0f);
    [Tooltip("Controls the EdgeColor of the effect.")]
    public ColorParameter edgeColor = new ColorParameter(Color.black);

    Material m_Material;

    public bool IsActive() => m_Material != null && intensity.value > 0; 

    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    public override void Setup()
    {
        if (Shader.Find("Hidden/Shader/Outline") != null)
            m_Material = new Material(Shader.Find("Hidden/Shader/Outline"));
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        m_Material.SetFloat("_Intensity", intensity.value);
        m_Material.SetFloat("_DepthThreshold", depthThreshold.value);
        m_Material.SetFloat("_NormalThreshold", normalThreshold.value);
        m_Material.SetColor("_EdgeColor", edgeColor.value);
        m_Material.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup() => CoreUtils.Destroy(m_Material);

}