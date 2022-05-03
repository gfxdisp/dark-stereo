using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Valve.VR;

public class StereoConstancyToggle : MonoBehaviour
{
    public SteamVR_Action_Boolean grabPinch; //Grab Pinch is the trigger, select from inspecter
    public SteamVR_Input_Sources inputSource = SteamVR_Input_Sources.Any;
    public StereoConstancy stereoConstancyScript;

    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (SteamVR_Input.GetStateDown("InteractUI", inputSource))
        {
            Debug.Log("Trigger was pressed");
            stereoConstancyScript.toggle = !stereoConstancyScript.toggle;
        }
    }
}
