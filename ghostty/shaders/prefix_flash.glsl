// prefix_flash.glsl — pulsing glow + ripples while the tmux prefix is active.
//
// HOW IT'S TRIGGERED: tmux can't talk to a GPU shader directly, so the prefix
// keypress smuggles a signal through the one channel a shader CAN read — the
// cursor color. While the prefix is held, tmux sets the cursor to a super light
// orange sentinel (OSC 12, see scripts/prefix-flash.sh), then resets it. This
// shader watches iCurrentCursorColor: when it's that orange, it paints a soft
// radial glow centered on the cursor that PULSES (breathes via iTime), with
// concentric rings rippling outward. Gated on the color, so it fires ONLY on
// prefix — never on cursor movement or vim modes. All animation is driven by
// iTime, so it needs no cursor-change timestamp.

// ---- tunables ----
const vec3  TINT         = vec3(1.00, 0.70, 0.40); // glow color (warm orange)
const float GLOW_MAX     = 0.24;  // peak background glow strength
const float PULSE_SPEED  = 7.0;   // glow breathing rate (higher = faster pulse)
const float PULSE_DEPTH  = 0.45;  // how deep the pulse dips (0 = steady glow)
const float RIPPLE_MAX   = 0.28;  // peak ring brightness
const float RIPPLE_FREQ  = 22.0;  // ring spacing (higher = more rings)
const float RIPPLE_SPEED = 6.0;   // outward ring speed
const float REACH        = 1.10;  // how far glow/ripples spread (screen-heights)

// sentinel = super light orange cursor: R near max AND clearly warmer than the
// normal cursor color (R well above B). The default cursor is cool/lavender
// (B highest), so this never matches outside the prefix flash.
float isPrefix(vec3 c) {
    return step(0.92, c.r) * step(c.b + 0.18, c.r);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);
    fragColor = base;

    float active = isPrefix(iCurrentCursorColor.rgb);
    if (active < 0.5) return;   // not in prefix → no effect, no cost

    // aspect-correct coords centered on the cursor
    float aspect = iResolution.x / iResolution.y;
    vec2 p   = uv;                          p.x   *= aspect;
    vec2 cur = iCurrentCursor.xy / iResolution.xy; cur.x *= aspect;
    float d  = distance(p, cur);

    float falloff = 1.0 - smoothstep(0.0, REACH, d); // strong near cursor, fades out

    // pulsing background glow — breathes while the prefix is held
    float pulse = 1.0 - PULSE_DEPTH * (0.5 + 0.5 * sin(iTime * PULSE_SPEED));
    float glow = falloff * GLOW_MAX * pulse;

    // concentric ripples expanding from the cursor, animated by iTime
    float rings = sin(d * RIPPLE_FREQ - iTime * RIPPLE_SPEED);
    rings = smoothstep(0.6, 1.0, rings);             // keep only thin bright crests
    float ripple = rings * falloff * RIPPLE_MAX;

    float amt = (glow + ripple) * active;
    fragColor = vec4(base.rgb + TINT * amt, base.a);
}
