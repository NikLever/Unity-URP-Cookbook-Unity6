using UnityEngine;

public class RotateY : MonoBehaviour
{
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        transform.Rotate( 0.0f, 0.01f, 0.0f );
    }
}
