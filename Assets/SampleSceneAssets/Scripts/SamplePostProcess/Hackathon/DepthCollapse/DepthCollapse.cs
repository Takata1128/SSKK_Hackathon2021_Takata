using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;
using System;

[Serializable, VolumeComponentMenu("Post-processing/Custom/DepthCollapse")]
public sealed class DepthCollapse : CustomPostProcessVolumeComponent, IPostProcessComponent
{
    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0f, 0f, 1f);

    [Tooltip("Controls the distortion intensity of the effect.")]
    public ClampedFloatParameter distort_intensity = new ClampedFloatParameter(0f, 0f, 1f);


    [Tooltip("Controls the pixel_x of the effect.")]
    public IntParameter pixel_x = new IntParameter(10);

    [Tooltip("Controls the pixel_y of the effect.")]
    public IntParameter pixel_y = new IntParameter(10);

    [Tooltip("Controls the noise speed of the effect.")]
    public FloatParameter noise_speed = new FloatParameter(10f);

    [Tooltip("Controls the noise ratio of the effect.")]
    public ClampedFloatParameter noise_ratio = new ClampedFloatParameter(0.5f, 0f, 1f);

    [Tooltip("Controls the noise min of the effect.")]
    public ClampedFloatParameter noise_min = new ClampedFloatParameter(0.001f, 0f, 0.01f);

    [Tooltip("Controls the noise max of the effect.")]
    public ClampedFloatParameter noise_max = new ClampedFloatParameter(0.002f, 0f, 0.01f);

    [Tooltip("noise color")]
    public ColorParameter noise_color = new ColorParameter(new Color(0, 0, 0, 0), false, true, true);


    Material m_Material;

    public bool IsActive() => m_Material != null && intensity.value > 0f;

    // Do not forget to add this post process in the Custom Post Process Orders list (Project Settings > HDRP Default Settings).
    public override CustomPostProcessInjectionPoint injectionPoint => CustomPostProcessInjectionPoint.AfterPostProcess;

    const string kShaderName = "Hidden/Shader/DepthCollapse";

    public override void Setup()
    {
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume DepthCollapse is unable to load.");
    }

    public override void Render(CommandBuffer cmd, HDCamera camera, RTHandle source, RTHandle destination)
    {
        if (m_Material == null)
            return;

        m_Material.SetFloat("_Intensity", intensity.value);
        m_Material.SetFloat("_DistortIntensity", distort_intensity.value);
        m_Material.SetInt("_PixelX", pixel_x.value);
        m_Material.SetInt("_PixelY", pixel_y.value);
        m_Material.SetFloat("_NoiseSpeed", noise_speed.value);
        m_Material.SetFloat("_NoiseRatio", noise_ratio.value);
        m_Material.SetFloat("_NoiseMin", noise_min.value);
        m_Material.SetFloat("_NoiseMax", noise_max.value);
        m_Material.SetVector("_NoiseColor", noise_color.value);




        m_Material.SetTexture("_InputTexture", source);
        HDUtils.DrawFullScreen(cmd, m_Material, destination);
    }

    public override void Cleanup()
    {
        CoreUtils.Destroy(m_Material);
    }
}
