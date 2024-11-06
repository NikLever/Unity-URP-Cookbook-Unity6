using Unity.VisualScripting;
using UnityEngine;

[ExecuteInEditMode]
public class ProceduralHeight : MonoBehaviour
{
    public int depth = 20; // The max height of the terrain
    public float scale = 20f; // Controls how “stretched” the noise appears

    private int width = 256; // Width of the terrain
    private int height = 256; // Height of the terrain
    private float offsetX = 100f; // Offset for X coordinate (randomized at start)
    private float offsetY = 100f; // Offset for Y coordinate (randomized at start)

    private int _depth;
    private float _scale;

    private Terrain terrain;

    void Start()
    {
        // Randomize offsets for a unique terrain each time
        offsetX = Random.Range(0f, 9999f);
        offsetY = Random.Range(0f, 9999f);

        _depth = depth;
        _scale = scale;

        terrain = GetComponent<Terrain>();
        terrain.terrainData = GenerateTerrain(terrain.terrainData);
    }

    TerrainData GenerateTerrain(TerrainData terrainData)
    {
        terrainData.heightmapResolution = width + 1;
        terrainData.size = new Vector3(width, depth, height);
        terrainData.SetHeights(0, 0, GenerateHeights());
        return terrainData;
    }

    float[,] GenerateHeights()
    {
        float[,] heights = new float[width, height];
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
                float xCoord = (float)x / width * scale + offsetX;
                float yCoord = (float)y / height * scale + offsetY;
                heights[x, y] = Mathf.PerlinNoise(xCoord, yCoord);
            }
        }
        return heights;
    }

    void Update(){
        if ( depth != _depth || scale != _scale ){
            terrain.terrainData = GenerateTerrain(terrain.terrainData);
             _depth = depth;
             _scale = scale;
        }
    }
}
