Shader "Explosion"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			ZWrite On
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            struct VertexInput 
            {
                float4 pos : POSITION;
            };

            struct VertexOutput 
            {
                float4 clipPos : SV_POSITION;
                float3 localPos : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float distort : TEXCOORD2;
            };


            float4x4 unity_MatrixVP;
            float _ElapsedTime;

            float4 _Color;
            float3 _VortexAxis0;
            float3 _VortexAxis1;
            float3 _VortexAxis2;
            float4x4 unity_ObjectToWorld;

            Texture2D<float4> _NoiseLUT;
            SamplerState sampler_NoiseLUT;

            // based on work done by Inigo Quilez https://www.shadertoy.com/view/4sfGzS
            float ValueNoise3D( in float3 x )
            {
                float3 i = floor(x); // integer
                float3 f = frac(x); // fractional

                f = f*f*(3.0-2.0*f); // smooth step
                float2 uv = (i.xy + i.z * float2(37.0, 17.0)) + f.xy;
                float2 rg = _NoiseLUT.SampleLevel(sampler_NoiseLUT, (uv + 0.5)/256.0, 0.0).rg;
                return lerp(rg.y, rg.x, f.z );
            }

            float3x3 AxisAngleRotation(float3 axis, float angle)
            {
                float s, c;
                
                sincos(angle, s, c);

                float t = 1 - c;

                float3x3 rot = {
                    t*axis.x*axis.x + c,        t*axis.x*axis.y - axis.z*s, t*axis.x*axis.z + axis.y*s,
                    t*axis.x*axis.y + axis.z*s, t*axis.y*axis.y + c, 	    t*axis.y*axis.z - axis.x*s,
                    t*axis.x*axis.z - axis.y*s, t*axis.y*axis.z + axis.x*s, t*axis.z*axis.z + c,
                };

                return rot;
            }

            VertexOutput vert(VertexInput input)
			{
                VertexOutput output;

                // input.pos.xyz *= 2;

                output.localPos = input.pos.xyz;

                output.distort = pow(1.0+input.pos.y,3)*0.25*_ElapsedTime*ValueNoise3D(_VortexAxis0 + 2*input.pos.xyz);

                input.pos.xyz += output.distort*input.pos.xyz;
                
#if defined(UNITY_INSTANCING_ENABLED)
                output.worldPos = (float3)mul(UNITY_MATRIX_M, float4(input.pos.xyz, 1.0));
#else
                output.worldPos = (float3)mul(unity_ObjectToWorld, float4(input.pos.xyz, 1.0));
#endif
	            output.clipPos = mul(unity_MatrixVP, float4(output.worldPos, 1.0));

			    return output;
            }

            float AxisDistance(float3 pos, float3 axis)
            {
                return length(pos - dot(pos, axis)*axis);
            }

            float3 ApplyVortex(float3 axis, float3 pos)
            {
                float l = smoothstep(0.2, 1.0, AxisDistance(pos, axis));

                return mul(AxisAngleRotation(axis, 0.2*l*( 11.5 + 4*_ElapsedTime.x )), pos);
            }

            float4 frag(VertexOutput input) : SV_TARGET 
			{
                float3 color = _Color.xyz;

                float shade = 0.3 + 0.7*input.distort;

                input.localPos.xyz = ApplyVortex(_VortexAxis0, input.localPos.xyz);
                input.localPos.xyz = ApplyVortex(_VortexAxis1, input.localPos.xyz);
                input.localPos.xyz = ApplyVortex(_VortexAxis2, input.localPos.xyz);

                float height = 0.3*ValueNoise3D(2*input.localPos.xyz + _VortexAxis0);
                height += 0.3*ValueNoise3D(4*input.localPos.xyz + _VortexAxis0);
                height += 0.3*ValueNoise3D(6*input.localPos.xyz + _VortexAxis0);

                clip(0.15 + height - _ElapsedTime);

                color *= shade;

                return float4(color, 1);
			}
            ENDHLSL
        }
    }
}
