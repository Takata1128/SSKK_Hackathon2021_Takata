using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/Sepia")]
public sealed class Sepia : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the R ratio of the effect.")]
    public ClampedFloatParameter r_ratio = new ClampedFloatParameter(1f, 0f, 1f);

    [Tooltip("Controls the G ratio of the effect.")]
    public ClampedFloatParameter g_ratio = new ClampedFloatParameter(1f, 0f, 1f);

    [Tooltip("Controls the Bratio of the effect.")]
    public ClampedFloatParameter b_ratio = new ClampedFloatParameter(1f, 0f, 1f);

    Material m_Material;

    public bool IsActive() => m_Material != null;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > HDRP Default Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/Sepia";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume Sepia is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Rratio", r_ratio.value);
        m_Material.SetFloat("_Gratio", g_ratio.value);
        m_Material.SetFloat("_Bratio", b_ratio.value);
        m_Material.SetTexture("_InputTexture", source);

        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
