using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteAlways]
public class AutoLoadPipelineAsset : MonoBehaviour
{
    public UniversalRenderPipelineAsset pipelineAsset;

    // Start is called before the first frame update
    void OnEnable()
    {
        if (pipelineAsset)
        {
            GraphicsSettings.defaultRenderPipeline = pipelineAsset;
            GraphicsSettings.defaultRenderPipeline = pipelineAsset;
            QualitySettings.renderPipeline = pipelineAsset;
        }   
    }
}
