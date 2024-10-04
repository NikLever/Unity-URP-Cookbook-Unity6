using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering.RenderGraphModule;
using System.Collections.Generic;

/*public class DepthNormalsRendererFeature : ScriptableRendererFeature
{
    public class DepthNormalPass : ScriptableRenderPass {
        private const string normalTextureName = "_CameraDepthNormalTexture";
        private readonly List<ShaderTagId> m_shaderTagIds;
        private readonly Material m_material;

        public DepthNormalPass(Material _material) {
            m_material = _material;
            m_shaderTagIds = new List<ShaderTagId> { new ShaderTagId("UniversalForward"), new ShaderTagId("UniversalForwardOnly"), new ShaderTagId("SRPDefaultUnlit") };
        }

        private class PassData {
            internal Material material;
            internal RendererListHandle rendererListHandle;
            internal TextureHandle normalTexture;
            internal TextureHandle activeColorTexture;
            internal TextureHandle activeDepthTexture;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameContext) {
            const string passName = "Depth Normals Texture";
            
            UniversalResourceData resourceData = frameContext.Get<UniversalResourceData>();
            UniversalRenderingData renderingData = frameContext.Get<UniversalRenderingData>();
            UniversalCameraData cameraData = frameContext.Get<UniversalCameraData>();
            UniversalLightData lightData = frameContext.Get<UniversalLightData>();
            
            if (cameraData.camera.cameraType != CameraType.Game) return;
            
            using (IRasterRenderGraphBuilder builder = renderGraph.AddRasterRenderPass<PassData>(passName, out var passData)) {
                SortingCriteria sortFlags = cameraData.defaultOpaqueSortFlags;
                RenderQueueRange renderQueueRange = RenderQueueRange.opaque;
                FilteringSettings filterSettings = new FilteringSettings(renderQueueRange, ~0);
                DrawingSettings drawSettings = RenderingUtils.CreateDrawingSettings(m_shaderTagIds, renderingData, cameraData, lightData, sortFlags);
                drawSettings.overrideMaterial = m_material;
                RendererListParams rendererListParameters = new RendererListParams(renderingData.cullResults, drawSettings, filterSettings);
                RenderTextureDescriptor cameraTextureDescriptor = cameraData.cameraTargetDescriptor;
                RenderTextureDescriptor renderTextureDescriptor = new RenderTextureDescriptor(cameraTextureDescriptor.width, cameraTextureDescriptor.height, cameraTextureDescriptor.colorFormat, 0, cameraTextureDescriptor.mipCount, RenderTextureReadWrite.Default);
                TextureHandle normalTexture = UniversalRenderer.CreateRenderGraphTexture(renderGraph, renderTextureDescriptor, normalTextureName, false);
                
                passData.material = m_material;
                passData.rendererListHandle = renderGraph.CreateRendererList(rendererListParameters);
                passData.normalTexture = normalTexture;
                passData.activeColorTexture = resourceData.activeColorTexture;
                passData.activeDepthTexture = resourceData.activeDepthTexture;
                
                builder.UseRendererList(passData.rendererListHandle);
                builder.SetRenderAttachment(normalTexture, 0);
                builder.SetRenderAttachmentDepth(resourceData.activeDepthTexture, AccessFlags.Read);
                builder.SetRenderFunc((PassData data, RasterGraphContext context) => {
                    context.cmd.ClearRenderTarget(true, true, Color.black);
                    context.cmd.DrawRendererList(data.rendererListHandle);
                });
                
                builder.SetGlobalTextureAfterPass(normalTexture, Shader.PropertyToID(normalTextureName));
            }
        }

    }

    DepthNormalPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create( )
    {
        m_ScriptablePass = new DepthNormalPass( material );

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}*/


