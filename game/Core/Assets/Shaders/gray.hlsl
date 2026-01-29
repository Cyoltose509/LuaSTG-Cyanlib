
SamplerState screen_texture_sampler : register(s0);
Texture2D screen_texture            : register(t0);

cbuffer g_buffer : register(b0)
{
    float alpha;
};

struct PS_Input
{
	float4 sxy : SV_Position;
	float2 uv  : TEXCOORD0;
	float4 col : COLOR0;
};
struct PS_Output
{
	float4 col : SV_Target;
};

PS_Output main(PS_Input input)
{
    float4 texColor = screen_texture.Sample(screen_texture_sampler, input.uv);

    float h = dot(texColor.rgb, float3(0.299f, 0.587f, 0.114f));

    float a = saturate(alpha);

    float3 rgb = lerp(texColor.rgb, h.xxx, a);

    PS_Output output;
    output.col = float4(rgb, texColor.a);
	return output;
}
