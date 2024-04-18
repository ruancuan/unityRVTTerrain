Shader "Universal Render Pipeline/Terrain/RVT Lit"
{
    Properties
    {
        [HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _Occlusion("Occlusion",Range(0.0,1.0))=1.0
    }

    HLSLINCLUDE

    #pragma multi_compile_fragment __ _ALPHATEST_ON

    
    ENDHLSL

    SubShader
    {
        Tags { "Queue" = "Geometry-100"
                "RenderType" = "Opaque"
                "RenderPipeline" = "UniversalPipeline"
                "UniversalMaterialType" = "Lit"
                "IgnoreProjector" = "False"
                "TerrainCompatible" = "True"
            }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma target 3.0

            #pragma vertex SplatmapVert2
            #pragma fragment SplatmapFragment2

            #define _METALLICSPECGLOSSMAP 1
            #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ _CLUSTERED_RENDERING

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY
            #pragma multi_compile_instancing
            #pragma instancing_options norenderinglayer assumeuniformscaling nomatrices nolightprobe nolightmap

            #pragma shader_feature_local_fragment _TERRAIN_BLEND_HEIGHT
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local_fragment _MASKMAP
            // Sample normal in pixel shader when doing instancing
            #pragma shader_feature_local _TERRAIN_INSTANCED_PERPIXEL_NORMAL

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
            #include "VT_URPTerrain.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma target 2.0

            #pragma vertex SplatmapVert2
            #pragma fragment ShadowPassFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "VT_URPTerrain.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name"DepthOnly"
            Tags
            {"LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0


            HLSLPROGRAM
            #pragma target 3.0

            #pragma vertex SplatmapVert2
            #pragma fragment DepthOnlyFragment

            #pragma multi_compile_instancing
            #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

            #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "VT_URPTerrain.hlsl"
            ENDHLSL
        }

        // Pass
        // {
        //     Name"DepthNormals"
        //     Tags
        //     {"LightMode" = "DepthNormals"
        //     }

        //     ZWrite On

        //     HLSLPROGRAM
        //     #pragma target 2.0
        //     #pragma vertex SplatmapVert2
        //     #pragma fragment DepthNormalOnlyFragment

        //     #pragma shader_feature_local _NORMALMAP
        //     #pragma multi_compile_instancing
        //     #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
        //     #include "VT_URPTerrain.hlsl"
        //     ENDHLSL
        //  }

        // Pass
        // {
        //     Name "SceneSelectionPass"
        //     Tags { "LightMode" = "SceneSelectionPass" }

        //     HLSLPROGRAM
        //     #pragma target 2.0

        //     #pragma vertex DepthOnlyVertex
        //     #pragma fragment DepthOnlyFragment

        //     #pragma multi_compile_instancing
        //     #pragma instancing_options assumeuniformscaling nomatrices nolightprobe nolightmap

        //     #define SCENESELECTIONPASS
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/Terrain/TerrainLitPasses.hlsl"
        //     ENDHLSL
        // }


        UsePass "Hidden/Nature/Terrain/Utilities/PICKING"
    }
    
}
