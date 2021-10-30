using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/Glitch2")]
public sealed class Glitch2 : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the framerate of the effect.")]
    public ClampedFloatParameter framerate = new ClampedFloatParameter(0f, 0f, 60f);

    [Tooltip("Controls the glitch prob of the effect.")]
    public ClampedFloatParameter glitch_prob = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the glitch size of the effect.")]
    public ClampedFloatParameter glitch_size = new ClampedFloatParameter(0f, 0f, 0.5f);

    [Tooltip("Controls the rgb shift X of the effect.")]
    public ClampedFloatParameter shift_x = new ClampedFloatParameter(0f, 0f, 0.1f);

    [Tooltip("Controls the rgb shift Y of the effect.")]
    public ClampedFloatParameter shift_y = new ClampedFloatParameter(0f, 0f, 0.1f);

    [Tooltip("Controls the gray scale prob of the effect.")]
    public ClampedFloatParameter gray_prob = new ClampedFloatParameter(0f, 0f, 1f);


    Material m_Material;

    public bool IsActive() => m_Material != null && intensity.value > 0f;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > HDRP Default Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/Glitch2";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume Glitch2 is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Intensity", intensity.value);
        m_Material.SetFloat("_GlitchProb", glitch_prob.value);
        m_Material.SetFloat("_FrameRate", framerate.value);
        m_Material.SetFloat("_GlitchSize", glitch_size.value);
        m_Material.SetFloat("_ShiftX", shift_x.value);
        m_Material.SetFloat("_ShiftY", shift_y.value);
        m_Material.SetFloat("_GrayProb", gray_prob.value);


        m_Material.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
