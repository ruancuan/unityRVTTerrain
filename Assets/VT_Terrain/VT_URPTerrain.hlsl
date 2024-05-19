#ifndef UNIVERSAL_TERRAIN_LIT_URPRVT
#define UNIVERSAL_TERRAIN_LIT_URPRVT

CBUFFER_START(_Terrain)
    float _Metallic;
    float _Smoothness;
    float _Occlusion;
CBUFFER_END


struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 uvMainAndLM              : TEXCOORD0; // xy: control, zw: lightmap
    half3 normal                    : TEXCOORD3;    // xyz: normal, w: viewDir.x
    half4 tangent                   : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    half4 bitangent                 : TEXCOORD5;    // xyz: bitangent, w: viewDir.z

    half3 vertexSH                  : TEXCOORD2; // SH
    half  fogFactor                 : TEXCOORD6;
    float3 positionWS               : TEXCOORD7;
#if defined(DYNAMICLIGHTMAP_ON)
    float2 dynamicLightmapUV        : TEXCOORD9;
#endif

    float4 clipPos                  : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};

    sampler2D _VT_IndexTex;
    int VT_RootSize;
    TEXTURE2D_ARRAY(_VT_AlbedoTex);  
    SAMPLER(sampler_VT_AlbedoTex);

    TEXTURE2D_ARRAY(_VT_NormalTex);
    SAMPLER(sampler_VT_NormalTex);  


    
    
    float3 mainCamPos;
    int virtualTextArraySize;

    // Used in Standard Terrain shader
    Varyings SplatmapVert2(Attributes v)
    {
        Varyings o = (Varyings)0;

        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        TerrainInstancing(v.positionOS, v.normalOS, v.texcoord);

        VertexPositionInputs Attributes = GetVertexPositionInputs(v.positionOS.xyz);


        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(Attributes.positionWS);
        float4 vertexTangent = float4(cross(float3(0, 0, 1), v.normalOS), 1.0);
        VertexNormalInputs normalInput = GetVertexNormalInputs(v.normalOS, vertexTangent);

        o.positionWS = Attributes.positionWS;
        o.clipPos = Attributes.positionCS;
        o.normal=v.normalOS.xyz;
        o.tangent = half4(normalInput.tangentWS, viewDirWS.y);
        o.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);
        
        o.uvMainAndLM.xy = TRANSFORM_TEX(v.texcoord, _Control);  // Need to manually transform uv here, as we choose not to use 'uv' prefix for this texcoord.
        o.uvMainAndLM.zw = v.texcoord * unity_LightmapST.xy + unity_LightmapST.zw;
    half fogFactor = 0;
    #if !defined(_FOG_FRAGMENT)
        fogFactor = ComputeFogFactor(Attributes.positionCS.z);
    #endif
        o.fogFactor = fogFactor;

        return o;
    }

    void InitializeInputData2(Varyings IN, half3 normalTS, out InputData inputData)
    {
        inputData = (InputData)0;

        inputData.positionWS = IN.positionWS;
        inputData.positionCS = IN.clipPos;

        half3 viewDirWS = GetWorldSpaceNormalizeViewDir(IN.positionWS);
        inputData.tangentToWorld = half3x3(-IN.tangent.xyz, IN.bitangent.xyz, IN.normal.xyz);
        // inputData.normalWS = TransformTangentToWorld(normalTS, inputData.tangentToWorld);
        // no need for vertex SH when _NORMALMAP is defined as we will evaluate SH per pixel
        half3 SH = IN.vertexSH;
        inputData.normalWS = IN.normal;

        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #if defined(DYNAMICLIGHTMAP_ON)
        inputData.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, IN.dynamicLightmapUV, SH, inputData.normalWS);
    #else
        inputData.bakedGI = SAMPLE_GI(IN.uvMainAndLM.zw, SH, inputData.normalWS);
    #endif
        inputData.normalWS = TransformTangentToWorld(normalTS,inputData.tangentToWorld);
        inputData.viewDirectionWS = viewDirWS;
        inputData.fogCoord = InitializeInputDataFog(float4(IN.positionWS, 1.0), IN.fogFactor);
        
    }


    void SplatmapFinalColor(inout half4 color, half fogCoord)
    {
        color.rgb *= color.a;
        #ifdef TERRAIN_SPLAT_ADDPASS
            color.rgb = MixFogColor(color.rgb, half3(0,0,0), fogCoord);
        #else
            color.rgb = MixFog(color.rgb, fogCoord);
        #endif

    }

    half4 SplatmapFragment2(Varyings IN) : SV_TARGET
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
    #ifdef _ALPHATEST_ON
        ClipHoles(IN.uvMainAndLM.xy);
    #endif
        
        half weight;
        half4 mixedDiffuse;
        float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
        half4 splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);

        float4 indexData = tex2D(_VT_IndexTex,  (IN.uvMainAndLM.xy));
        float2 wpos = IN.uvMainAndLM.xy * VT_RootSize;
        int lod = (int)(log2(indexData.w) + 0.5);
        float2 localUV =saturate( (wpos - indexData.yz) / indexData.w);

        // float lodBias = 0.5;
        // float2 dx_vtc = ddx(wpos* virtualTextArraySize * lodBias);
        // float2 dy_vtc = ddy(wpos* virtualTextArraySize * lodBias);
        float lodBias  =-0.65;
        float2 dx_vtc = ddx(wpos* virtualTextArraySize);
        float2 dy_vtc = ddy(wpos* virtualTextArraySize);
        float md = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
        float mipmap= clamp( 0.5 * log2(md)-lod+ lodBias,0,3);
        

        float4 albedo = SAMPLE_TEXTURE2D_X_LOD(_VT_AlbedoTex,sampler_VT_AlbedoTex, float3(localUV, indexData.r), mipmap);
        float3 normalTS = SAMPLE_TEXTURE2D_X_LOD(_VT_NormalTex,sampler_VT_NormalTex, float3(localUV, indexData.r), mipmap);
        //normal = normalize(normal * 2 - 1);

        InputData inputData;
        InitializeInputData2(IN, normalTS, inputData);
        // inputData.normalWS = normal;
        
        half4 color = UniversalFragmentPBR(inputData, albedo, _Metallic, /* specular */ half3(0.0h, 0.0h, 0.0h), _Smoothness, _Occlusion, /* emission */ half3(0, 0, 0), 1.0);

        SplatmapFinalColor(color, inputData.fogCoord);

        // return half4(inputData.normalWS.xyz,1.0);
        // return half4(normal.rgb, 1.0h);
        return float4(color.xyz, 1.0);
    }

    half4 ShadowPassFragment(Varyings IN) : SV_TARGET
    {
        return 0;
    }


    half4 DepthOnlyFragment(Varyings IN) : SV_TARGET
    {
        return 0;
    }

#endif