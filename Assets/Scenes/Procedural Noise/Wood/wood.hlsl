// Adapted to Unity HLSL custom function by Nik Lever
// 'Procedural Wood texture' dean_the_coder (Twitter: @deanthecoder)
// https://www.shadertoy.com/view/mdy3R1
//
// Processed by 'GLSL Shader Shrinker'
// (https://github.com/deanthecoder/GLSLShaderShrinker)
//
// I spent some time working on some noise functions and then
// used them to make a wood texture. I'd never used musgrave
// noise before - Looks very useful!
//
// Thanks to Evvvvil, Flopine, Nusan, BigWings, Iq, Shane,
// totetmatt, Blackle, Dave Hoskins, byt3_m3chanic, tater,
// and a bunch of others for sharing their time and knowledge!
//
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

//#define R	iResolution
#define sat(x)	clamp(x, 0., 1.)
#define S(a, b, c)	smoothstep(a, b, c)
#define S01(a)	S(0., 1., a)

float sum2(float2 v) { return dot(v, float2(1.0, 1.0)); }

///////////////////////////////////////////////////////////////////////////////

float h31(float3 p3) {
	p3 = frac(p3 * 0.1031);
	p3 += dot(p3, p3.yzx + 333.3456);
	return frac(sum2(p3.xy) * p3.z);
}

float h21(float2 p) { return h31(p.xyx); }

float n31(float3 p) {
	const float3 s = float3(7, 157, 113);

	// Thanks Shane - https://www.shadertoy.com/view/lstGRB
	float3 ip = floor(p);
	p = frac(p);
	p = p * p * (3. - 2. * p);
	float4 h = float4(0, s.yz, sum2(s.yz)) + dot(ip, s);
	h = lerp(frac(sin(h) * 43758.545), frac(sin(h + s.x) * 43758.545), p.x);
	h.xy = lerp(h.xz, h.yw, p.y);
	return lerp(h.x, h.y, p.z);
}

// roughness: (0.0, 1.0], default: 0.5
// Returns unsigned noise [0.0, 1.0]
float fbm(float3 p, int octaves, float roughness) {
	float sum = 0.,
	      amp = 1.,
	      tot = 0.;
	roughness = sat(roughness);
	for (int i = 0; i < octaves; i++) {
		sum += amp * n31(p);
		tot += amp;
		amp *= roughness;
		p *= 2.;
	}
	return sum / tot;
}

float3 randomPos(float seed) {
	float4 s = float4(seed, 0, 1, 2);
	return float3(h21(s.xy), h21(s.xz), h21(s.xw)) * 1e2 + 1e2;
}

// Returns unsigned noise [0.0, 1.0]
float fbmDistorted(float3 p) {
	p += (float3(n31(p + randomPos(0.)), n31(p + randomPos(1.)), n31(p + randomPos(2.))) * 2. - 1.) * 1.12;
	return fbm(p, 8, .5);
}

// float3: detail(/octaves), dimension(/inverse contrast), lacunarity
// Returns signed noise.
float musgraveFbm(float3 p, float octaves, float dimension, float lacunarity) {
	float sum = 0.,
	      amp = 1.,
	      m = pow(lacunarity, -dimension);
	for (float i = 0.; i < octaves; i++) {
		float n = n31(p) * 2. - 1.;
		sum += n * amp;
		amp *= m;
		p *= lacunarity;
	}
	return sum;
}

// Wave noise along X axis.
float3 waveFbmX(float3 p) {
	float n = p.x * 20.;
	n += .4 * fbm(p * 3., 3, 3.);
	return float3(sin(n) * .5 + .5, p.yz);
}

///////////////////////////////////////////////////////////////////////////////
// Math
float remap01(float f, float in1, float in2) { return sat((f - in1) / (in2 - in1)); }

///////////////////////////////////////////////////////////////////////////////
// Wood material.
float3 matWood(float3 p, float3 colA, float3 colB ) {
	float n1 = fbmDistorted(p * float3(7.8, 1.17, 1.17));
	n1 = lerp(n1, 1.0, 0.2);
	float n2 = lerp(musgraveFbm(float3(n1, n1, n1) * 4.6, 8.0, 0.0, 2.5), n1, 0.85);
	float dirt = 1. - musgraveFbm(waveFbmX(p * float3(.01, .15, .15)), 15., .26, 2.4) * .4;
	float grain = 1. - S(.2, 1., musgraveFbm(p * float3(500, 6, 1), 2., 2., 2.5)) * .2;
	n2 *= dirt * grain;
    
    // The three float3 values are the RGB wood colors - Tweak to suit.
	return lerp(lerp(colA, colB, remap01(n2, .19, .56)), float3(.52, .32, .19), remap01(n2, .56, 1.));
}

void wood_float( float3 pos, out float4 result){
    float3 colA = float3(.03, .012, .003);
    float3 colB = float3(.25, .11, .04);
    result = float4(pow(matWood(pos, colA, colB), float3(1,1,1) * 0.4545), 0);
}

void wood_float( float3 pos, float3 colA, float3 colB, out float4 result){
    result = float4(pow(matWood(pos, colA, colB ), float3(1,1,1) * 0.4545), 0);
}