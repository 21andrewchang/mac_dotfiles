// prefix_flash.glsl — sonic_boom_cursor.glsl copied VERBATIM, with only the
// TRIGGER changed from a cursor WIDTH change to a cursor COLOR change, and COLOR
// set to the cursor_blaze amber. On the tmux prefix, tmux sets the cursor to the
// blaze amber (scripts/prefix-flash.sh); that color change bumps iTimeCursorChange,
// so the real sonic-boom animation plays. Everything else is the original shader.

// CONFIGURATION
const float DURATION = 0.3;               // How long the ripple animates (seconds)
const float MAX_RADIUS = 0.2;             // Max radius in normalized coords (0.5 = 1/4 screen height)
const float ANIMATION_START_OFFSET = 0.0;        // Start the ripple slightly progressed (0.0 - 1.0)
vec4 COLOR = vec4(0.35, 0.36, 0.44, 1.0); // change to iCurrentCursorColor for your cursor's color
const float COLOR_CHANGE_THRESHOLD = 0.10; // Triggers boom if cursor color changes by this much
const float BLUR = 2.0;                    // Blur level in pixels

// pulsing cyan glow around the cursor while prefix is active (sparks-style bloom)
const vec3  GLOW_COLOR     = vec3(0.502, 0.98, 1.0); // cyan, matches the boom
const float GLOW_INTENSITY = 0.9;  // peak glow brightness
const float GLOW_FADE      = 0.003; // higher = smaller/tighter glow
const float PULSE_MIN      = 0.5;   // glow never dims below this fraction (stays on; 1.0 = no pulse)
const float PULSE_SPEED    = 5.0;   // pulse rate

// black screen tint while prefix is active, faded in over TINT_FADE seconds
const float TINT_STRENGTH  = 0.5;   // darkness at full fade (0 = none, 1 = black)
const float TINT_FADE      = 0.1;   // seconds to fade in

// Prefix detection: tmux dims the cursor to a darker shade of the normal
// (cool/lavender #c0caf5) cursor. We detect "cool AND dimmer than DIM_MAX" —
// the normal cursor is brighter than this, so it never matches. (Works whether
// the color uniform is sRGB or linear: ordering + a brightness threshold.)
const float DIM_MAX = 0.9;


// Easing functions
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
}
float easeInOutQuad(float t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}
float easeOutCubic(float t) {
    return 1.0 - pow(1.0 - t, 3.0);
}
float easeOutQuart(float t) {
    return 1.0 - pow(1.0 - t, 4.0);
}
float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0);
}
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}
float easeOutCirc(float t) {
    return sqrt(1.0 - pow(t - 1.0, 2.0));
}
float easeOutSine(float t) {
    return sin((t * 3.1415916) / 2.0);
}
float easeOutElastic(float t) {
    const float c4 = (2.0 * 3.1415916) / 3.0;
    return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}
float easeOutBounce(float t) {
    const float n1 = 7.5625;
    const float d1 = 2.75;
    if (t < 1.0 / d1) {
        return n1 * t * t;
    } else if (t < 2.0 / d1) {
        return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
        return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
        return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
}
float easeOutBack(float t) {
    const float c1 = 1.70158;
    const float c3 = c1 + 1.0;
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0);
}

// Pulse fade functions
float smoothstepPulse(float t) {
    return 4.0 * t * (1.0 - t);
}
float easeOutPulse(float t) {
    return t * (2.0 - t);
}
float powerCurvePulse(float t) {
    float x = t * 2.0 - 1.0;
    return 1.0 - x * x;
}
float doubleSmoothstepPulse(float t) {
    return smoothstep(0.0, 0.5, t) * (1.0 - smoothstep(0.5, 1.0, t));
}
float exponentialDecayPulse(float t) {
    return exp(-3.0 * t) * sin(t * 3.1415916);
}
float sinPulse(float t) {
    return sin(t * 3.1415916);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // Normalization & setup (-1 to 1 coords)
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);

    // check for significant COLOR change (was: cursor width change). The tmux
    // prefix dims the cursor, so we fire when the cursor color jumps AND is
    // currently the dim cool shade — never on the normal (bright) cursor or on
    // vim's width-only changes.
    vec3 curCol = iCurrentCursorColor.rgb;
    float colorChange = length(curCol - iPreviousCursorColor.rgb);
    float isCool = step(curCol.r, curCol.b) * step(curCol.g, curCol.b); // b is the max channel
    float isDim  = 1.0 - step(DIM_MAX, max(curCol.r, max(curCol.g, curCol.b)));
    float isPrefix = isCool * isDim;
    float isModeChange = step(COLOR_CHANGE_THRESHOLD, colorChange) * isPrefix;

    // Black tint: darken the whole screen while the prefix is active, faded in
    // from when the prefix was pressed. Boom + glow render bright over it.
    float tintAmt = TINT_STRENGTH * clamp((iTime - iTimeCursorChange) / TINT_FADE, 0.0, 1.0) * isPrefix;
    fragColor.rgb = mix(fragColor.rgb, vec3(0.0), tintAmt);


    // ANIMATION
    float rippleProgress = (iTime - iTimeCursorChange) / DURATION + ANIMATION_START_OFFSET;
    // don't clamp yet; we need to know if it's > 1.0 (finished)
     float isAnimating = 1.0 - step(1.0, rippleProgress); // progress < 1.0 ? 1.0: 0.0

     if (isModeChange > 0.0 && isAnimating > 0.0) {
        // float easedProgress = rippleProgress;
        // float easedProgress = easeOutQuad(rippleProgress);
        // float easedProgress = easeInOutQuad(rippleProgress);
        // float easedProgress = easeOutCubic(rippleProgress);
        // float easedProgress = easeOutQuart(rippleProgress);
        // float easedProgress = easeOutQuint(rippleProgress);
        // float easedProgress = easeOutExpo(rippleProgress);
        float easedProgress = easeOutCirc(rippleProgress);
        // float easedProgress = easeOutSine(rippleProgress);
        // float easedProgress = easeOutBack(rippleProgress);

        // easedProgress = clamp(easedProgress, 0.0, 1.0);

        // RIPPLE CALCULATION
        float rippleRadius = easedProgress * MAX_RADIUS;

        // float fade = 1.0; // no fade
        // float fade = 1.0 - easedProgress; // linear fade
        // float fade = 1.0 - smoothstepPulse(rippleProgress);
        float fade = 1.0 - easeOutPulse(rippleProgress);
        // float fade = 1.0 - powerCurvePulse(rippleProgress);
        // float fade = doubleSmoothstepPulse(rippleProgress);
        // float fade = exponentialDecayPulse(rippleProgress);
        // float fade = sinPulse(rippleProgress);

        // Calculate distance from frag to cursor center
        float dist = distance(vu, centerCC);

        float sdfCircle = dist - rippleRadius;

        // Antialias (1-pixel width in normalized coords)
        float antiAliasSize = normalize(vec2(BLUR, BLUR), 0.0).x;
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfCircle)) * fade;

        // Apply ripple effect
        fragColor = mix(fragColor, COLOR, ripple * COLOR.a);
    }

    // Small pulsing cyan glow around the cursor while the prefix is active —
    // sparks-style soft bloom: intensity / (1 + k * r^2), breathing via iTime.
    vec2 cpix = vec2(iCurrentCursor.x + iCurrentCursor.z * 0.5,
                     iCurrentCursor.y - iCurrentCursor.w * 0.5);
    vec2 gp = fragCoord - cpix;
    float bloom = GLOW_INTENSITY / (1.0 + GLOW_FADE * dot(gp, gp));
    float gpulse = mix(PULSE_MIN, 1.0, 0.5 + 0.5 * sin(iTime * PULSE_SPEED));
    fragColor.rgb += GLOW_COLOR * (isPrefix * bloom * gpulse);
}
