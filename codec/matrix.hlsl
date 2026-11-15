// Falling-digits "rain" behind terminal text. Windows Terminal pixel shader.
// Remove "experimental.pixelShaderPath" from Windows Terminal settings to turn it off.

Texture2D shaderTexture;
SamplerState samplerState;

cbuffer PixelShaderSettings
{
    float  Time;
    float  Scale;
    float2 Resolution;
    float4 Background;
};

// 3x5 digit glyphs, row-major, top-left bit first.
static const uint GLYPHS[10] = { 31599, 11415, 29671, 29647, 23497, 31183, 31215, 29257, 31727, 31695 };

float hash1(float n) { return frac(sin(n) * 43758.5453); }
float hash2(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

float4 main(float4 pos : SV_POSITION, float2 tex : TEXCOORD) : SV_TARGET
{
    float4 text = shaderTexture.Sample(samplerState, tex);

    float cell = 16.0 * Scale;                       // size of one falling digit
    float2 p = pos.xy / cell;
    float col = floor(p.x);
    float row = floor(p.y);
    float2 local = frac(p);

    float rows   = Resolution.y / cell;
    float speed  = 3.0 + hash1(col * 1.37) * 7.0;    // rows per second
    float trail  = 8.0 + hash1(col * 7.91) * 16.0;   // trail length in rows
    float period = rows + trail + 6.0;
    float head   = fmod(Time * speed + hash1(col * 3.17) * period, period);
    float dist   = head - row;

    float rain = 0.0;
    float isHead = 0.0;
    if (dist >= 0.0 && dist < trail)
    {
        // pick a digit for this cell; it flickers to a new one now and then
        float tick  = floor(Time * (1.5 + hash1(col * 5.3) * 3.0) + hash2(float2(col, row)) * 10.0);
        uint  digit = (uint)(hash2(float2(col * 13.0 + tick, row * 7.0)) * 10.0) % 10;

        // draw the 3x5 glyph inside a 4x6 cell (one column/row of padding)
        int gx = (int)floor(local.x * 4.0);
        int gy = (int)floor(local.y * 6.0);
        if (gx < 3 && gy < 5)
        {
            uint bit = (GLYPHS[digit] >> (14 - (gy * 3 + gx))) & 1;
            rain   = (float)bit * (1.0 - dist / trail);
            isHead = (dist < 1.0) ? (float)bit : 0.0;
        }
    }

    // only paint rain where there is no text (pixel matches the background color)
    float isBg = 1.0 - step(0.20, max(text.r, max(text.g, text.b)));

    float3 trailColor = float3(0.22, 0.75, 0.42);
    float3 headColor  = float3(0.75, 1.00, 0.82);
    float3 rainColor  = lerp(trailColor * rain, headColor, isHead) * 0.18;   // 0.18 = brightness

    // ---- faint digital Jolly Roger (skull & crossbones), made of glowing pixel blocks ----
    float  blk = 7.0 * Scale;                                    // size of one "pixel" block
    float2 bc  = (floor(pos.xy / blk) + 0.5) * blk;              // center of this block
    float2 uv  = (bc - Resolution * 0.5) / Resolution.y;         // centered, height = 1 (y grows downward)

    // skull: round cranium + jaw
    float cranium = length(uv - float2(0.0, -0.07)) - 0.17;
    float2 jq     = abs(uv - float2(0.0, 0.10)) - float2(0.095, 0.055);
    float jaw     = length(max(jq, 0.0)) + min(max(jq.x, jq.y), 0.0) - 0.02;
    float skull   = min(cranium, jaw);

    // holes: eye sockets, nose, gaps between teeth
    float eyes  = min(length(uv - float2(-0.065, -0.05)), length(uv - float2(0.065, -0.05))) - 0.045;
    float nose  = length((uv - float2(0.0, 0.035)) * float2(1.0, 0.8)) - 0.022;
    float teeth = (uv.y > 0.105 && uv.y < 0.165) ? (min(min(abs(uv.x + 0.05), abs(uv.x)), abs(uv.x - 0.05)) - 0.007) : 1.0;
    float holes = min(min(eyes, nose), teeth);

    // crossbones: two capsules with knobby ends, passing behind the skull
    float2 a1 = float2(-0.30, -0.15), b1 = float2(0.30, 0.33);
    float2 a2 = float2( 0.30, -0.15), b2 = float2(-0.30, 0.33);
    float2 pa1 = uv - a1, ba1 = b1 - a1; float h1 = saturate(dot(pa1, ba1) / dot(ba1, ba1));
    float2 pa2 = uv - a2, ba2 = b2 - a2; float h2 = saturate(dot(pa2, ba2) / dot(ba2, ba2));
    float bones = min(length(pa1 - ba1 * h1), length(pa2 - ba2 * h2)) - 0.022;
    float2 n1 = normalize(float2(-ba1.y, ba1.x)) * 0.03;
    float2 n2 = normalize(float2(-ba2.y, ba2.x)) * 0.03;
    float knobs = min(min(min(length(uv - a1 - n1), length(uv - a1 + n1)), min(length(uv - b1 - n1), length(uv - b1 + n1))),
                      min(min(length(uv - a2 - n2), length(uv - a2 + n2)), min(length(uv - b2 - n2), length(uv - b2 + n2)))) - 0.032;
    bones = min(bones, knobs);

    float skullFill = step(skull, 0.0) * step(0.0, holes);       // skull minus its holes
    float boneFill  = step(bones, 0.0) * step(0.0, skull);       // bones only where the skull isn't
    float fill = max(skullFill, boneFill);

    float2 inBlk = frac(pos.xy / blk);
    float  led   = step(0.15, inBlk.x) * step(inBlk.x, 0.85) * step(0.15, inBlk.y) * step(inBlk.y, 0.85);
    float  pulse = 0.8 + 0.2 * sin(Time * 1.2);
    float  scan  = 0.85 + 0.15 * sin(pos.y * 1.3);
    float3 flagColor = float3(0.30, 0.90, 0.55) * fill * 0.11 * led * pulse * scan;   // 0.11 = faintness

    float3 behind = max(flagColor, rainColor);                   // digits fall in front of the Jolly Roger
    return float4(text.rgb + behind * isBg, text.a);
}
