﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
 

public class Test : MonoBehaviour {

	public float startZ;
	public float endZ;
	public float speed = 1;
	public float hight = 1;
	public  GameObject[] switchItem;
	public Terrain terrain;
	private float startTime = 0;
	[SerializeField]
	private bool moving = true;
 
	
	// Update is called once per frame
	void Update () {
		float lerp = 0.1f;
		if (Input.GetKeyDown(KeyCode.R))
		{
			lerp = 1;
			startTime = Time.time;
		 
			//UnityEditor.EditorApplication.isPaused = true;
		}
		if (Input.GetKeyDown(KeyCode.P)) {
			
			switchItem[0].SetActive(!switchItem[0].activeSelf);
			switchItem[1].SetActive(!switchItem[1].activeSelf);
		}
		if (Input.GetKeyDown(KeyCode.Q))
		{
			 
				moving = !moving;
			 
		
		}
	}

 
	void Start() {
 

	}
 
}
