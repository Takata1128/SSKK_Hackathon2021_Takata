using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

class Glare : CustomPass
{
    // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
    // When empty this render pass will render to the active camera render target.
    // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
    // The render pipeline will ensure target setup and clearing happens in an performance manner.

    public LayerMask GlareLayer = 0;

    [Tooltip("Controls the intensity of the effect.")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0.1f, 0f, 1f);
    [Tooltip("Controls the threshold of the effect.")]
    public ClampedFloatParameter threshold = new ClampedFloatParameter(0.6f, 0f, 1f);
    [Tooltip("Controls the attenuation of the effect.")]
    public ClampedFloatParameter attenuation = new ClampedFloatParameter(0.95f, 0f, 1f);


    const string kShaderName = "Hidden/Shader/Glare";

    Material m_Material;
    RTHandle RTBuffer1;
    RTHandle RTBuffer2;
    RTHandle RTDestBuffer;

    protected override void Setup(ScriptableRenderContext renderContext, CommandBuffer cmd)
    {
        // Setup code here
        if (Shader.Find(kShaderName) != null)
            m_Material = new Material(Shader.Find(kShaderName));
        else
            Debug.LogError($"Unable to find shader '{kShaderName}'. Post Process Volume Glare is unable to load.");

        Alloc(ref RTBuffer1,    "RTBuffer1");
        Alloc(ref RTBuffer2,    "RTBuffer2");
        Alloc(ref RTDestBuffer, "RTDestBuffer");
    }

    protected override void Execute(CustomPassContext ctx)
    {
        // Executed every frame for all the camera inside the pass volume.
        // The context contains the command buffer to use to enqueue graphics commands.

        ctx.propertyBlock.SetFloat("_Intensity",    intensity.value);
        ctx.propertyBlock.SetFloat("_Threshold",    threshold.value);
        ctx.propertyBlock.SetFloat("_Attenuation",  attenuation.value);

        var paramsID = Shader.PropertyToID("_Params");

        CustomPassUtils.Copy(ctx, ctx.cameraColorBuffer, RTDestBuffer);
        
        // 4方向にスター作成
        for (int i = 0; i < 4; i++)
        {
            // 明度抽出
            ctx.propertyBlock.SetTexture("_InputTexture", ctx.cameraColorBuffer);
            CoreUtils.SetRenderTarget(ctx.cmd, RTBuffer1);
            CoreUtils.DrawFullScreen(ctx.cmd, m_Material, ctx.propertyBlock, shaderPassId: 0);

            var parameters = Vector3.zero;

            // UV オフセットの設定
            parameters.x = i == 0 || i == 1 ? -1 : 1;
            parameters.y = i == 0 || i == 2 ? -1 : 1;

            // 1方向にぼかしを伸ばす
            for (int j = 0; j < 4; j++)
            {
                parameters.z = j;
                ctx.propertyBlock.SetVector("_Params", parameters);
                ctx.propertyBlock.SetTexture("_InputTexture", RTBuffer1);
                CoreUtils.SetRenderTarget(ctx.cmd, RTBuffer2);
                CoreUtils.DrawFullScreen(ctx.cmd, m_Material, ctx.propertyBlock, shaderPassId: 1);

                var tmp = RTBuffer1;
                RTBuffer1 = RTBuffer2;
                RTBuffer2 = tmp;
            }

            // 加算合成
            ctx.propertyBlock.SetTexture("_InputTexture", RTBuffer1);
            CoreUtils.SetRenderTarget(ctx.cmd, RTDestBuffer);
            CoreUtils.DrawFullScreen(ctx.cmd, m_Material, ctx.propertyBlock, shaderPassId: 2);

        }
        // cameraColorBuffer　に 加算合成
        ctx.propertyBlock.SetTexture("_InputTexture", RTDestBuffer);
        CoreUtils.SetRenderTarget(ctx.cmd, ctx.cameraColorBuffer);
        CoreUtils.DrawFullScreen(ctx.cmd, m_Material, ctx.propertyBlock, shaderPassId: 2);
    }

    protected override void Cleanup()
    {
        // Cleanup code
        RTBuffer1.Release();
        RTBuffer2.Release();
        RTDestBuffer.Release();
        CoreUtils.Destroy(m_Material);
    }

    protected void Alloc(ref RTHandle rtHandle, string name)
    {
        rtHandle = RTHandles.Alloc(Vector2.one, TextureXR.slices, dimension: TextureXR.dimension,
            colorFormat: GraphicsFormat.B10G11R11_UFloatPack32,
            useDynamicScale: true, name: name);
    }
}