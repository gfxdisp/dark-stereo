# dark-stereo
The code and data related to the paper *Dark Stereo: Improving Depth Perception Under Low Luminance*

# Unity Implementation of the Stereo Constancy Model
Unity implementation can be found in directory *stereo_constancy_model/unity_implementation*.
To use the model in your unity project please follow the steps below:
1. Copy *stereo_constancy_model/unity_implementation/StereoConstancy* directory to the *Assets* directory of your project.
2. Add *StereoConstancy* component to the camera of your choice.

# Sample Unity Project
In the repository you can also find a sample Unity project that uses the Stereo Constancy Model. To try out the sample project, please follow the steps below:
1. Start Unity Hub application and add *stereo_constancy_model/unity_sample_project* as a project.
2. After opening the project import SteamVR plugin from the Unity Asset Store (https://assetstore.unity.com/packages/tools/integration/steamvr-plugin-32647).
3. During the import of SteamVR plugin you might be asked which API version shall be used. Please pick the *Legacy VR* option.
4. Import following asset pack from the Unity Asset Store: https://assetstore.unity.com/packages/3d/environments/landscapes/rpg-poly-pack-lite-148410 .
5. Project is ready to run.
6. **Note:** Project tested with Unity 2019.3.8f1.
