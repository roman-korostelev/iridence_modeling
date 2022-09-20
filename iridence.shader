Shader "Custom/FirstShader"
{
       Properties
  {
 _Color ("Color", Color) = (1,1,1,1) // Цвет
 _MainTex ("Albedo (RGB)", 2D) = "white" {} // Текстура
 _Glossiness ("Smoothness", Range(0,1)) = 0.5
 _Metallic ("Metallic", Range(0,1)) = 0.0
 _Distance ("Grating distance", Range(0,10000)) = 1600 // Дистанция между волнам
}
        Subshader
{
    Tags { "RenderType"="Opaque" }
    CGPROGRAM
    #pragma surface surf Diffraction fullforwardshadows
    #include "UnityPBSLighting.cginc"
    float _Distance;
    sampler2D _MainTex, _Normal;
    fixed4 _Color;
    float3 worldTangent;

    void LightingDiffraction_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)  
    {
        LightingStandard_GI(s, data, gi); 
    } 
    
    struct Input
     {
         float2 uv_Maintex;
         float2 uv_Normal;
     };

     void surf(Input IN, inout SurfaceOutputStandard o)
     {
         fixed4 c = tex2D(_MainTex, IN.uv_Maintex) * _Color;
         o.Albedo = c.rgb;
         o.Normal = UnpackNormal(tex2D(_Normal, IN.uv_Normal));
         fixed2 uv = IN.uv_Maintex * 2 -1;
         fixed2 uv_orthogonal = normalize(uv);
         fixed3 uv_tangent = fixed3(-uv_orthogonal.y, 0, uv_orthogonal.x);
         worldTangent = normalize( mul(unity_ObjectToWorld, float4(uv_tangent, 0)) );
     }

    inline fixed3 bump3y (fixed3 x, fixed3 yoffset)
     {
     float3 y = 1 - x * x;
     y = saturate(y-yoffset);
     return y;
     }
     
     fixed3 spectral_zucconi6 (float w) // переводим длину волны в цвета, приближенные к реальному спектру
     {
     // w: [400, 700]
     // x: [0,   1]
     fixed x = saturate((w - 400.0)/ 300.0);

     const float3 c1 = float3(3.54585104, 2.93225262, 2.41593945);
     const float3 x1 = float3(0.69549072, 0.49228336, 0.27699880);
     const float3 y1 = float3(0.02312639, 0.15225084, 0.52607955);

     const float3 c2 = float3(3.90307140, 3.21182957, 3.96587128);
     const float3 x2 = float3(0.11748627, 0.86755042, 0.66077860);
     const float3 y2 = float3(0.84897130, 0.88445281, 0.73949448);

     return
     bump3y(c1 * (x - x1), y1) +
     bump3y(c2 * (x - x2), y2) ;
     }
     inline fixed4 LightingDiffraction(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
     {
      // Исходный цвет
      fixed4 pbr = LightingStandard(s, viewDir, gi);
      
      // --- Эффект дифракционной решётки ---
      float3 L = gi.light.dir;
      float3 V = viewDir;
      float3 T = worldTangent;
      
      float d = _Distance;
      float cos_ThetaL = dot(L, T);
      float cos_ThetaV = dot(V, T);
      float u = abs(cos_ThetaL - cos_ThetaV);
      
      if (u == 0)
      return pbr;
      
      // Цвет отражения
      fixed3 color = 0;
      for (int n = 1; n <= 8; n++)
      {
      float wavelength = u * d / n;
      color += spectral_zucconi6(wavelength);
      }
      color = saturate(color);
      
      // Прибавляет отражение к цвету материала
      pbr.rgb += color;
      return pbr;
     }

     
     ENDCG
}
}
      