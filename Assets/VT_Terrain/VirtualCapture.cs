﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VirtualCapture : MonoBehaviour {
	private Material captureMat;
	public Shader captureShader;
	public TerrainData terrainData;

	public Texture2DArray albedoAtlas;
	public Texture2DArray normalAtlas;
	public Texture2DArray maskAtlas;

	public RenderTexture[] clipRTs;
	private RenderBuffer[] mrtRB = new RenderBuffer[2];
	public int mipmapCount;
	public const int virtualTextArraySize = 512;

	public Texture2D defaultMask;

	// Use this for initialization
	void Awake () {
		
		mipmapCount = (int)Mathf.Log(virtualTextArraySize, 2);
		clipRTs = new RenderTexture[3];// 
		for (int i = 0; i < clipRTs.Length; i++)
		{

			clipRTs[i] = new RenderTexture(virtualTextArraySize, virtualTextArraySize, 16, i == 0 ? RenderTextureFormat.ARGB32 : RenderTextureFormat.ARGB32, i == 0 ? RenderTextureReadWrite.sRGB : RenderTextureReadWrite.Linear);
			clipRTs[i].useMipMap = true;
			clipRTs[i].autoGenerateMips = false;
			clipRTs[i].Create();

		}








		captureMat = new Material(captureShader);
            for (int k = 0; k < terrainData.alphamapTextures.Length; k++)
            {
			captureMat.SetTexture("_Control"+k, terrainData.alphamapTextures[k]);
			}
			
 

		 

		var tileData = new Vector4[terrainData.splatPrototypes.Length];
		for (int i = 0; i < tileData.Length; i++)
		{
			tileData[i] = new Vector4(terrainData.size.x / terrainData.splatPrototypes[i].tileSize.x, terrainData.size.z / terrainData.splatPrototypes[i].tileSize.y, 0, 0);


		}
 
		Shader.SetGlobalTexture("albedoAtlas", albedoAtlas);
		Shader.SetGlobalTexture("normalAtlas", normalAtlas);
        Shader.SetGlobalTexture("maskAtlas", maskAtlas);
        Shader.SetGlobalVectorArray("tileData", tileData);
		Shader.SetGlobalInt("virtualTextArraySize", virtualTextArraySize);

		//mrt mode
		mrtRB = new RenderBuffer[] { clipRTs[0].colorBuffer, clipRTs[1].colorBuffer, clipRTs[2].colorBuffer };
		 

	}
	void OnDestroy()
	{
		if (clipRTs != null)
		{
			for (int i = 0; i < clipRTs.Length; i++)
			{

				clipRTs[i].Release();


			}
		}

	}
 
 
	public void  virtualCapture_MRT(Vector2 center, float size, out RenderTexture albedoRT,out RenderTexture normalRT,out RenderTexture maskRT)
	{

		int terrainSize = (int)terrainData.size.x;

		Shader.SetGlobalVector("blitOffsetScale", new Vector4((center.x - size / 2) / terrainSize, (center.y - size / 2) / terrainSize, (size) / terrainSize, (size) / terrainSize));

		RenderTexture oldRT = RenderTexture.active;

		Graphics.SetRenderTarget(mrtRB,clipRTs[0].depthBuffer);

		GL.Clear(false, true, Color.clear);

		GL.PushMatrix();
		GL.LoadOrtho();

		captureMat.SetPass(0);     //Pass 0 outputs 2 render textures.

		//Render the full screen quad manually.
		GL.Begin(GL.QUADS);
		GL.TexCoord2(0.0f, 0.0f); GL.Vertex3(0.0f, 0.0f, 0.1f);
		GL.TexCoord2(1.0f, 0.0f); GL.Vertex3(1.0f, 0.0f, 0.1f);
		GL.TexCoord2(1.0f, 1.0f); GL.Vertex3(1.0f, 1.0f, 0.1f);
		GL.TexCoord2(0.0f, 1.0f); GL.Vertex3(0.0f, 1.0f, 0.1f);
		GL.End();

		GL.PopMatrix();

		RenderTexture.active = oldRT;
		albedoRT = clipRTs[0];
		normalRT = clipRTs[1];
		maskRT = clipRTs[2];
		albedoRT.GenerateMips();
		normalRT.GenerateMips();
		maskRT.GenerateMips();
	}

#if UNITY_EDITOR
	[ContextMenu("MakeAlbedoAtlas")]
	// Update is called once per frame
	void MakeAlbedoAtlas()
	{
		var arrayLen= terrainData.terrainLayers.Length;
	 
		int wid = terrainData.terrainLayers[0].diffuseTexture.width;
		int hei = terrainData.terrainLayers[0].diffuseTexture.height;

		int widNormal = terrainData.terrainLayers[0].normalMapTexture.width;
		int heiNormal = terrainData.terrainLayers[0].normalMapTexture.height;

		int widMask = terrainData.terrainLayers[0].diffuseTexture.width;
		int heiMask = terrainData.terrainLayers[0].diffuseTexture.height;

		albedoAtlas = new Texture2DArray(wid, hei, arrayLen, terrainData.terrainLayers[0].diffuseTexture.format, true, false);
		normalAtlas = new Texture2DArray(widNormal, heiNormal, arrayLen, terrainData.terrainLayers[0].normalMapTexture.format, true, true);
		maskAtlas = new Texture2DArray(widMask, heiMask, arrayLen, terrainData.terrainLayers[0].diffuseTexture.format, true, false);

		for (int index = 0; index < arrayLen; index++)
		{
			if (index >= terrainData.terrainLayers.Length) break;
			print(index);
			for (int k = 0; k < terrainData.terrainLayers[index].diffuseTexture.mipmapCount; k++)
			{
				Graphics.CopyTexture(terrainData.terrainLayers[index].diffuseTexture, 0, k, albedoAtlas, index, k);

			}
			for (int k = 0; k < terrainData.terrainLayers[index].normalMapTexture.mipmapCount; k++)
			{
				Graphics.CopyTexture(terrainData.terrainLayers[index].normalMapTexture, 0, k, normalAtlas, index, k);

			}
			if (terrainData.terrainLayers[index].maskMapTexture)
			{
				for (int k = 0; k < terrainData.terrainLayers[index].maskMapTexture.mipmapCount; k++)
				{
					Graphics.CopyTexture(terrainData.terrainLayers[index].maskMapTexture, 0, k, maskAtlas, index, k);
				}
			}
			else
            {
                for (int k = 0; k < terrainData.terrainLayers[index].normalMapTexture.mipmapCount; k++)
                {
                    Graphics.CopyTexture(defaultMask, 0, k, maskAtlas, index, k);
                }
            }
		}
	}
#endif
}
