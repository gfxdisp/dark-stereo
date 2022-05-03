Shader "Custom/StereoConstancy"
{
	Properties{
		_MainTex("Texture", 2D) = "white" {}
		_YuvlTex("YUVL Texture", 2D) = "white" {}
		_CSFLut("CSFLut", 2D) = "white" {}

		_LumSource("Source Lum", Range(0.001, 300)) = 80
		_LumTarget("Terget Lum", Range(0.001, 300)) = 8

		_Sensitivity("Sensitivity", Range(0.1,20)) = 8.6

		_pixelSizeFactorMultiplier("Pixel Size Factor", Range(0.1,10)) = 1.0

		_blackLevel("Black Level", Float) = 0.001
	}

		CGINCLUDE
#include "UnityCG.cginc"

		sampler2D _MainTex;
		sampler2D _CSFLut;
		sampler2D _CameraDepthTexture;
		sampler2D _RGBTexture;
		float4 _MainTex_TexelSize;

		sampler2D _G1;
		sampler2D _G2;

		float _kernel5[5];
		float _kernel9[9];
		float _Z9;
		float _Z5;

		float _Sensitivity = 8.6;
		float _pixelSizeFactorMultiplier = 1.0;

		float _jump;

		float _blackLevel;

		struct VertexData {
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct Interpolators {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		Interpolators VertexProgram(VertexData v) {
			Interpolators i;
			i.pos = UnityObjectToClipPos(v.vertex);
			i.uv = v.uv;
			return i;
		}

		float Gauss2Dk9c1_Opt(float2 uv)
		{
			//declare parameters
			const int mSize = 9;
			float2 o = _MainTex_TexelSize.xy * _pixelSizeFactorMultiplier;
			const int kSize = (mSize - 1) / 2;
			float final_colour = 0;

			//read out the texels
			for (int i = -kSize; i <= kSize; ++i)
			{
				for (int j = -kSize; j <= kSize; ++j)
				{
					final_colour += _kernel9[kSize + j] * _kernel9[kSize + i] * tex2D(_MainTex, uv + float2(i, j) * o);
				}
			}
			return final_colour / (_Z9 * _Z9);
		}

		float2 Gauss2Dk9c2_Opt(float2 uv)
		{
			//declare parameters
			const int mSize = 9;
			float2 o = _MainTex_TexelSize.xy * _pixelSizeFactorMultiplier;
			const int kSize = (mSize - 1) / 2;
			float2 final_colour = float2(0, 0);

			//read out the texels
			for (int i = -kSize; i <= kSize; ++i)
			{
				for (int j = -kSize; j <= kSize; ++j)
				{
					final_colour += _kernel9[kSize + j] * _kernel9[kSize + i] * tex2D(_MainTex, uv + float2(i, j) * o);
				}
			}
			return final_colour / (_Z9 * _Z9);
		}

		float Gauss2Dk5c1_Opt(float2 uv)
		{
			//declare parameters
			const int mSize = 5;
			float2 o = _MainTex_TexelSize.xy * _pixelSizeFactorMultiplier;
			const int kSize = (mSize - 1) / 2;
			float final_colour = 0;

			//read out the texels
			for (int i = -kSize; i <= kSize; ++i)
			{
				for (int j = -kSize; j <= kSize; ++j)
				{
					final_colour += _kernel5[kSize + j] * _kernel5[kSize + i] * tex2D(_MainTex, uv + float2(i, j) * o);
				}
			}
			return final_colour / (_Z5 * _Z5);
		}

		float2 Gauss2Dk5c2_Opt(float2 uv)
		{
			//declare parameters
			const int mSize = 5;
			float2 o = _MainTex_TexelSize.xy * _pixelSizeFactorMultiplier;
			const int kSize = (mSize - 1) / 2;
			float2 final_colour = float2(0, 0);

			//read out the texels
			for (int i = -kSize; i <= kSize; ++i)
			{
				for (int j = -kSize; j <= kSize; ++j)
				{
					final_colour += _kernel5[kSize + j] * _kernel5[kSize + i] * tex2D(_MainTex, uv + float2(i, j) * o);
				}
			}
			return final_colour / (_Z5 * _Z5);
		}

		float2 Gauss2Dk5DiscreteForG1(float2 uv, float jump)
		{
			//declare parameters
			const int mSize = 5;
			float kernel[5] = { 0.05f, 0.25f, 0.4f, 0.25f, 0.05f };
			float2 o = _MainTex_TexelSize.xy;
			const int kSize = (mSize - 1) / 2;
			float2 final_colour = float2(0, 0);

			//read out the texels
			for (int i = -kSize; i <= kSize; ++i)
			{
				for (int j = -kSize; j <= kSize; ++j)
				{
					final_colour += kernel[kSize + j] * kernel[kSize + i] * tex2D(_MainTex, uv + float2(i, j) * o * float2(jump, jump));
				}
			}
			return final_colour;
		}

		float logc(float x)
		{
			return pow(10, x);
		}

		float GetLuminance(float3 rgb)
		{
			return rgb.r * 0.212656 + rgb.g * 0.715158 + rgb.b * 0.072186;
		}

		float3 RemoveGamma(float3 rgb)
		{
			return pow(rgb, 2.2);
		}

		float3 RestoreGamma(float3 rgb)
		{
			return pow(rgb, 1 / 2.2);
		}

		float Remap01(float x, float minIn, float maxIn)
		{
			return (x - minIn) / (maxIn - minIn);
		}

		float2 RhoAndLogLumToCSFCoordinates(float rho, float logLum)
		{
			float x = Remap01(rho, 1, 32); // values in the LUT are generated for frequencies 1:32
			float y = 1 - Remap01(logLum, -5, 3); // values in the LUT are generated for range -5:3
			return float2(x, y);
		}

		float SampleCSF(float rho, float logLum)
		{
			float2 uv = RhoAndLogLumToCSFCoordinates(rho, logLum);
			float sensitivity = tex2D(_CSFLut, uv).r;
			return sensitivity * _Sensitivity;
		}


		float Michelson2Log(float C)
		{
			return 0.5 * log10((C + 1) / (1 - C));
		}

		float log2michelson(float G)
		{
			return (pow(10, (2 * G)) - 1) / (pow(10, (2 * G)) + 1);
		}

		float michelson2log(float C)
		{
			return 0.5*log10((C + 1) / (1 - C));
		}

		float beta_function(float Y, float C)
		{
			return  (0.00964028930664063*log10(Y) + 0.00110626220703125*C + (-0.0015)*(pow(log10(Y), 2)) + 0.0271167755126953);
		}

		float beta_function_new(float Y, float C)
		{
			float pars1 = 0.00952911376953125;
			float pars2 = 0.467311859;
			float pars3 = -0.00193869;
			float pars4 = 0.399483489990234;
			float pars5 = 0.0279922485351562;

			return  (pars1*log10(Y) + pars2 * C + pars3 * (pow(log10(Y), 2)) + pars4 * pow(C, 2) + pars5);
		}

		float contrast_function(float Y, float beta)
		{
			return ((0.00964028930664063*log10(Y) + (-0.0015)*(pow(log10(Y), 2)) + 0.0271167755126953 - beta) / (-0.00110626220703125));
		}

		float contrast_function_new(float Y, float beta)
		{
			float pars1 = 0.00952911376953125;
			float pars2 = 0.467311859;
			float pars3 = -0.00193869;
			float pars4 = 0.399483489990234;
			float pars5 = 0.0279922485351562;

			float A = pars4;
			float B = pars2;
			float K = pars1 * log10(Y) + pars3 * (pow(log10(Y), 2)) + pars5 - beta;

			return (-B + sqrt(pow(B, 2) - 4 * A*K)) / (2 * A);
		}

		float betaBoostG(float Y_in, float Y_out, float G_est)
		{
			float C_in = G_est;
			float y_in = max(Y_in, 0.3);
			float y_out = max(Y_out, 0.001);
			float beta = beta_function_new(y_in, C_in);
			float C_out = contrast_function_new(y_out, beta);

			float G_est_out = C_out;
			float m = G_est_out / max(0.0001, G_est);

			return m;
		}

		float KulikowskiBoostG(float l_in, float G_in, float l_out, float rho)
		{
			float S_s = max(SampleCSF(rho, l_in), 1.0202);
			float S_d = max(SampleCSF(rho, l_out), 1.2222);
			float t_s = 1 / S_s;
			float t_d = 1 / S_d;
			float G_ts = Michelson2Log(t_s);
			float G_td = Michelson2Log(t_d);
			return max(G_in - G_ts + G_td, 0.00000001f) / G_in;
		}


		ENDCG


			SubShader
		{
			Cull Off
			ZTest Always
			ZWrite Off

			Pass  // Main pass 0
			{
				CGPROGRAM
					#pragma vertex VertexProgram
					#pragma fragment FragmentProgram

					float _LumSource, _LumTarget;
					sampler2D _YuvlTex;

					float4 FragmentProgram(Interpolators i) : SV_Target
					{
						float ret;
						
						float2 g0composite = tex2D(_MainTex, i.uv);
						float2 g1composite = tex2D(_G1, i.uv);
						float2 g2composite = tex2D(_G2, i.uv);
						float2 g1compositeOld = Gauss2Dk5c2_Opt(i.uv);
						float2 g2compositeOld = Gauss2Dk9c2_Opt(i.uv);


						float g0 = g0composite.r;
						float g1 = g1composite.r;
						float g2 = g2composite.r;


						float P_in[3];
						P_in[0] = g0 - g1;
						P_in[1] = g1 - g2;
						P_in[2] = g2;

						float2 LL2Composites[2];
						LL2Composites[0] = g1compositeOld;
						LL2Composites[1] = g2compositeOld;

						float l_in = g2;
						float l_out = g2;

						for (int iter = 1; iter >= 0; iter--)
						{
							float C_in = P_in[iter];

							float l_source = l_in + log10(_LumSource);
							float l_target = l_out + log10(_LumTarget);

							float G_est = sqrt(max(0, LL2Composites[iter].g - LL2Composites[iter].r * LL2Composites[iter].r));

							float m = min(betaBoostG(l_source, l_target, G_est), 2);
							
							float C_out = C_in * m;

							l_out = l_out + C_out;
							l_in = l_in + P_in[iter];
						}

						float y_out = clamp(logc(l_out),0,1);
						float3 rgb_in = tex2D(_RGBTexture, i.uv).rgb;
						float y_in = GetLuminance(rgb_in);

						float maxFactor = 1 / max(max(rgb_in.r, rgb_in.g), rgb_in.b);

						float multiplier = min((y_out / max(y_in, 0.0001f)), maxFactor);

						float3 rgb_out = rgb_in * multiplier;
						rgb_out = max(rgb_out - _blackLevel, 0) * (1 / (1 - _blackLevel));

						return float4(rgb_out, 1);

					}
				ENDCG
			}

			Pass // RGB to LL2
			{
				CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float2 FragmentProgram(Interpolators i) : SV_Target {

					//Acquiring color from input
					float3 rgb = tex2D(_MainTex,i.uv).rgb;

					//Acquiring luminance
					float y = GetLuminance(rgb);

					//Adding black level
					y = y * (1 - _blackLevel) + _blackLevel;

					//Converting luminance to log-luminance
					float l = log10(y);
					float l2 = l * l;

					//Returning values
					float2 output = float2(l, l2);
					return output;
				}
			ENDCG
			}

		Pass // DepthPass
		{
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float4 FragmentProgram(Interpolators i) : SV_Target {
					//get depth from depth texture
					float depth = tex2D(_CameraDepthTexture, i.uv).r;

					return depth;
				}
			ENDCG
		}

		Pass // GaussBlur to L 2
		{
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float2 FragmentProgram(Interpolators i) : SV_Target {
					float2 g1composite = Gauss2Dk5DiscreteForG1(i.uv, _jump);
					return g1composite;
				}
			ENDCG
		}

		Pass // DebugShader
		{
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float4 FragmentProgram(Interpolators i) : SV_Target {
					float3 rgbClamped = clamp(tex2D(_MainTex,i.uv).rgb, 0.001f, 1);
					rgbClamped = RemoveGamma(rgbClamped);
					rgbClamped = clamp(rgbClamped, 0.001f, 1);

					float y = GetLuminance(rgbClamped);
					float l = log10(y);
					float l2 = l * l;

					float3 ret = RestoreGamma(float3(y, y, y));

					return float4(ret,1);
				}
			ENDCG
		}

		Pass // PrintOut
		{
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float4 FragmentProgram(Interpolators i) : SV_Target {
					float ret;
					float2 input = tex2D(_MainTex, i.uv).rg;
					ret = logc(input.r);
					float4 output = float4(ret, ret, ret, 1);
					return output;
				}
			ENDCG
		}
	}
}