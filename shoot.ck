GWindow.title("Shoot Loop");
GWindow.fullscreen();
GG.scene().backgroundColor(@(0.0, 0.0, 0.0));
GG.camera().posZ(7);

GG.bloom(true);
GG.bloomPass().threshold(0.5);
GG.bloomPass().intensity(0.8);
GG.bloomPass().radius(0.7);

// Loop settings
1 => int metronomeOn;
72 => float bpm;
4 => int beatsPerBar;
4 => int bars;
4 => int subdivisions;

(60.0 / bpm)::second => dur beatDuration;
beatDuration * beatsPerBar * bars => dur loopDuration;

UI_Int bpmUI(72);
UI_Int beatsUI(4);
UI_Int barsUI(4);

0 => int started;
0 => int recording;

4 => int selectedInstrument;
["A", "B", "C", "D", "E", "F", "G"] @=> string noteNames[];
[9, 11, 0, 2, 4, 5, 7] @=> int notePitches[];

int recordedInstruments[0];
int recordedPitches[0];
float recordedTimes[0];

time loopStart;

// Targets and cannon
GText statusText --> GG.scene();
statusText.text("READY");
statusText.size(0.35);
statusText.pos(-2.5, 2.6, 0.2);
statusText.color(@(1.0, 1.0, 1.0));

TextureLoadDesc options;
1 => options.flip_y;

Texture.load(me.dir() + "images/drum.png", options) @=> Texture drumTexture;
Texture.load(me.dir() + "images/hiHat.png", options) @=> Texture hihatTexture;

GPlane kick --> GG.scene();
kick.colorMap(drumTexture);
kick.color(@(1.0, 1.0, 1.0));
kick.sca(1.3);
kick.pos(-2.5, 1.2, 0.0);

GPlane snare --> GG.scene();
snare.colorMap(drumTexture);
snare.color(@(1.0, 1.0, 1.0));
snare.sca(0.95);
snare.pos(0.0, 1.2, 0.0);

GPlane hihat --> GG.scene();
hihat.colorMap(hihatTexture);
hihat.color(@(1.0, 1.0, 1.0));
hihat.sca(1.0);
hihat.pos(2.5, 1.2, 0.0);

GCircle cannon --> GG.scene();
cannon.color(@(0.2, 0.2, 0.3));
cannon.sca(0.55);
cannon.pos(0.0, -2.0, 0.0);

GCircle core --> cannon;
core.color(@(0.0, 1.0, 2.0));
core.sca(0.5);
core.pos(0.0, 0.0, 0.02);

GPlane barrel --> cannon;
barrel.color(@(0.0, 1.0, 2.0));
barrel.sca(@(0.38, 0.65, 1.0));
barrel.pos(0.0, 0.48, -0.01);

[kick, snare, hihat] @=> GGen targets[];

GText letters[7];
GLines rings[28];

vec3 colors[7];

@(0.0, 0.9, 1.0)   => colors[0];
@(1.0, 0.1, 0.6)  => colors[1];
@(0.6, 0.3, 1.0)  => colors[2];
@(0.1, 1.0, 0.4)  => colors[3];
@(1.0, 0.8, 0.1)  => colors[4];
@(1.0, 0.3, 0.1)  => colors[5];
@(0.1, 0.4, 1.0)  => colors[6];

0.6 => float radius;

0.12 => float gap;

// generating alphabets and rings
for (0 => int i; i < 7; i++) {

    letters[i] --> GG.scene();
    letters[i].text(noteNames[i]);
    letters[i].sca(0.9);
    letters[i].color(colors[i]);
    letters[i].pos(-2.4 + (i % 4) * 1.6, -0.1 - (i / 4) * 1.2, 0);

    for (0 => int arc; arc < 4; arc++) {

        vec2 arcPoints[0];

        arc * Math.PI / 2.0 + Math.PI => float start;

        for (0 => int j; j < 24; j++) {

            start + gap / 2.0 + (Math.PI / 2.0 - gap) * j / 23 => float angle;

            arcPoints << @(radius * Math.cos(angle), radius * Math.sin(angle));
        }

        i * 4 + arc => int index;

        rings[index] --> letters[i];
        rings[index].positions(arcPoints);
        rings[index].width(0.05);
        rings[index].pos(0, 0, -0.03);
        rings[index].color(colors[i]);
    }

    targets << letters[i];
}

for (0 => int i; i < targets.size(); i++) {
    targets[i].posZ(i * 0.02);
}

// Target movement
vec2 targetVelocity[targets.size()];
float turnRemaining[targets.size()];

for (0 => int i; i < targets.size(); i++) {
    Math.random2f(0, 2 * Math.PI) => float angle;
    Math.random2f(0.3, 0.6) => float speed;

    @(Math.cos(angle) * speed, Math.sin(angle) * speed) => targetVelocity[i];
    Math.random2f(2, 4) => turnRemaining[i];
}

fun void updateTargets() {
    Math.min(GG.dt(), 0.05) => float dt;

    for (0 => int i; i < targets.size(); i++) {
        dt -=> turnRemaining[i];

        if (turnRemaining[i] <= 0) {
            Math.random2f(-0.5, 0.5) => float turn;
            targetVelocity[i] => vec2 oldVelocity;

            @(oldVelocity.x * Math.cos(turn) - oldVelocity.y * Math.sin(turn), oldVelocity.x * Math.sin(turn) + oldVelocity.y * Math.cos(turn)) => targetVelocity[i];
            Math.random2f(2, 4) => turnRemaining[i];
        }

        targets[i].pos() => vec3 p;

        targetVelocity[i].x * dt +=> p.x;
        targetVelocity[i].y * dt +=> p.y;

        if (p.x < -4.4) {
            -4.4 => p.x;
            Math.fabs(targetVelocity[i].x) => targetVelocity[i].x;
        }
        else if (p.x > 4.4) {
            4.4 => p.x;
            -Math.fabs(targetVelocity[i].x) => targetVelocity[i].x;
        }
        if (p.y < -1.1) {
            -1.1 => p.y;
            Math.fabs(targetVelocity[i].y) => targetVelocity[i].y;
        }
        else if (p.y > 2.4) {
            2.4 => p.y;
            -Math.fabs(targetVelocity[i].y) => targetVelocity[i].y;
        }

        targets[i].pos(p);
    }
}

fun void checkCollisions() {

    for (0 => int i; i < targets.size(); i++) {
        for (i + 1 => int j; j < targets.size(); j++) {

            targets[i].pos() => vec3 p1;
            targets[j].pos() => vec3 p2;

            0.5 => float factor1;
            0.5 => float factor2;

            if (i >= 3) 0.65 => factor1;
            if (j >= 3) 0.65 => factor2;

            targets[i].scaX() * factor1 => float r1;
            targets[j].scaX() * factor2 => float r2;

            p2.x - p1.x => float dx;
            p2.y - p1.y => float dy;

            Math.sqrt(dx*dx + dy*dy) => float dist;

            r1 + r2 => float minDist;

            if (dist < minDist) {

                if (dist < 0.0001) {
                    0.0001 => dist;
                    0.0001 => dx;
                    0.0 => dy;
                }

                dx / dist => float nx;
                dy / dist => float ny;

                (minDist - dist) * 0.5 => float overlap;

                overlap * nx -=> p1.x;
                overlap * ny -=> p1.y;
                overlap * nx +=> p2.x;
                overlap * ny +=> p2.y;

                targets[i].pos(p1);
                targets[j].pos(p2);
                targetVelocity[i].x - targetVelocity[j].x=> float rvx;
                targetVelocity[i].y - targetVelocity[j].y=> float rvy;

                rvx * nx + rvy * ny => float approach;

                if (approach > 0) {
                    approach * nx -=> targetVelocity[i].x;
                    approach * ny -=> targetVelocity[i].y;
                    approach * nx +=> targetVelocity[j].x;
                    approach * ny +=> targetVelocity[j].y;
                }
            }
        }
    }
}

// Metronome
fun void playClick(int accent) {
    SinOsc osc => ADSR env => dac;

    if (accent == 1) {
        1200 => osc.freq;
        0.5 => osc.gain;
    }
    else {
        800 => osc.freq;
        0.3 => osc.gain;
    }

    env.set(1::ms, 10::ms, 0.0, 1::ms);
    env.keyOn();

    15::ms => now;
    env.keyOff();
    2::ms => now;
}

fun void metronome() {
    0 => int beat;

    while (true) {
        if (metronomeOn == 1) {
            if (beat % beatsPerBar == 0) spork ~ playClick(1);
            else spork ~ playClick(0);
        }

        (beat + 1) % (beatsPerBar * bars) => beat;
        beatDuration => now;
    }
}

// Instrument sounds
fun void playKick(){
    SinOsc osc => ADSR env => dac;
    1.3 => osc.gain;
    env.set(0::ms, 200::ms, 0.0, 1::ms);

    50 => osc.freq;
    env.keyOn();

    for (0 => int i; i < 100; i++){
        30 + 100 * Math.exp(-i / 15.0) => osc.freq;
        1::ms => now;
    }

    100::ms => now;
    env.keyOff();
    2::ms => now;
}

fun void playSnare(){
    SinOsc osc => ADSR oscEnv => dac;
    Noise noise => HPF hpf => ADSR noiseEnv => dac;

    0.5 => noise.gain;
    2000 => hpf.freq;
    noiseEnv.set(0::ms, 150::ms, 0.0, 1::ms);

    0.15 => osc.gain;
    180 => osc.freq;
    oscEnv.set(0::ms, 80::ms, 0.0, 1::ms);

    noiseEnv.keyOn();
    oscEnv.keyOn();

    150::ms => now;

    noiseEnv.keyOff();
    oscEnv.keyOff();
    2::ms => now;
}

fun void playHiHat(){
    Noise noise => HPF hpf => LPF lpf => ADSR env => dac;

    0.7 => noise.gain;
    6000 => hpf.freq;
    12000 => lpf.freq;
    env.set(0::ms, 50::ms, 0.0, 1::ms);

    env.keyOn();
    50::ms => now;

    env.keyOff();
    2::ms => now;
}

fun void playMelody(int midiNote){
    SawOsc osc => LPF lpf => ADSR env => dac;

    0.4 => osc.gain;
    Std.mtof(midiNote) => osc.freq;
    800 => lpf.freq;
    env.set(10::ms, 100::ms, 0.4, 200::ms);

    env.keyOn();
    300::ms => now;

    env.keyOff();
    250::ms => now;
}

fun void playBass(int midiNote) {
    SawOsc osc => LPF lpf => ADSR env => dac;

    0.5 => osc.gain;
    Std.mtof(midiNote - 12) => osc.freq;
    600 => lpf.freq;
    env.set(15::ms, 100::ms, 0.6, 150::ms);

    env.keyOn();
    250::ms => now;

    env.keyOff();
    160::ms => now;
}

fun void playChord(int midiNote) {
    SinOsc osc[3];
    ADSR env[3];

    int intervals[3];

    midiNote % 12 => int pitchClass;

    // minor chords
    if (pitchClass == 2 || pitchClass == 4 || pitchClass == 9) {
        [0, 3, 7] @=> intervals;
    }
    // diminished chords
    else if (pitchClass == 11) {
        [0, 3, 6] @=> intervals;
    }
    // major chords
    else {
        [0, 4, 7] @=> intervals;
    }

    for (0 => int i; i < 3; i++) {
        osc[i] => env[i] => dac;

        0.16 => osc[i].gain;

        Std.mtof(midiNote + intervals[i]) => osc[i].freq;

        env[i].set(10::ms, 80::ms, 0.5, 180::ms);
        env[i].keyOn();
    }

    350::ms => now;

    for (0 => int i; i < 3; i++) {
        env[i].keyOff();
    }

    200::ms => now;
}

fun void playInstrument(int instrument, int midiNote) {
    if (instrument == 1) playKick();
    else if (instrument == 2) playSnare();
    else if (instrument == 3) playHiHat();
    else if (instrument == 4) playMelody(midiNote);
    else if (instrument == 5) playBass(midiNote);
    else if (instrument == 6) playChord(midiNote);
}

// Settings and timeline
fun void updateSettings() {
    bpmUI.val() => bpm;
    beatsUI.val() => beatsPerBar;
    barsUI.val() => bars;

    (60.0 / bpm)::second => beatDuration;
    beatDuration * beatsPerBar * bars => loopDuration;
}

GPlane boxes[0];

-4.0 => float timelineX;
-1.9 => float timelineY;
5.8 => float timelineWidth;

0.16 => float rowSpacing;
0.11 => float boxHeight;

vec3 trackColors[6];

@(0.65, 0.40, 1.0) => trackColors[0];
@(1.0, 0.30, 0.50) => trackColors[1];
@(0.20, 0.85, 1.0) => trackColors[2];
@(0.0, 0.96, 1.0)  => trackColors[3];
@(1.0, 0.20, 0.60) => trackColors[4];
@(1.0, 0.85, 0.10) => trackColors[5];

// create boxes indicating beats
fun void createBoxes() {

    for (0 => int i; i < boxes.size(); i++) {
        boxes[i].detach();
    }
    boxes.clear();

    beatsPerBar * bars => int totalSteps;

    0.10 => float groupGap;

    (timelineWidth - (bars - 1) * groupGap) / totalSteps => float spacing;

    for (0 => int row; row < 6; row++) {
        for (0 => int step; step < totalSteps; step++) {
            GPlane box --> GG.scene();

            box.sca(@(spacing * 0.85, boxHeight, 1.0));
            step / beatsPerBar => int group;

            box.pos(timelineX + spacing * (step + 0.5) + group * groupGap, timelineY - row * rowSpacing, 0.2);
            box.color(@(0.12, 0.16, 0.24));
            boxes << box;
        }
    }
}

["KICK", "SNARE", "HI-HAT", "MELODY", "BASS", "CHORD"] @=> string trackNames[];

GText trackLabels[6];

for (0 => int i; i < 6; i++) {
    trackLabels[i] --> GG.scene();
    trackLabels[i].text(trackNames[i]);
    trackLabels[i].size(0.12);
    trackLabels[i].color(@(0.65, 0.75, 0.85));
    trackLabels[i].pos(timelineX - 0.65, timelineY - i * rowSpacing, 0.2);
}

fun void updateBeats() {
    beatsPerBar * bars => int totalSteps;
    beatDuration / second => float grid;

    (now - loopStart) % loopDuration => dur elapsed;
    (elapsed / second / grid) $ int => int currentStep;

    int occupied[0];

    for (0 => int i; i < 6 * totalSteps; i++) {
        occupied << 0;
    }

    for (0 => int i; i < recordedTimes.size(); i++) {
        recordedInstruments[i] - 1 => int row;
        Math.floor(recordedTimes[i] / grid) $ int => int step;
        step % totalSteps => step;

        if (row >= 0 && row < 6) {
            1 => occupied[row * totalSteps + step];
        }
    }

    for (0 => int row; row < 6; row++) {
        for (0 => int step; step < totalSteps; step++) {
            row * totalSteps + step => int index;

            if (occupied[index] == 1) {
                if (step == currentStep) {
                    boxes[index].color(trackColors[row] * 1.6);
                }
                else {
                    boxes[index].color(trackColors[row]);
                }
            }
            else {
                if (step == currentStep) {
                    boxes[index].color(@(0.45, 0.55, 0.7));
                }
                else {
                    boxes[index].color(@(0.12, 0.16, 0.24));
                }
            }
        }
    }
}

// Recording and playback
fun void updateStatus() {
    if (recording == 1) {
        statusText.text("WAIT");
        statusText.color(@(1.0, 0.8, 0.2));
    }
    else if (recording == 2) {
        statusText.text("REC");
        statusText.color(@(1.0, 0.2, 0.2));
    }
    else {
        statusText.text("PLAY");
        statusText.color(@(0.2, 1.0, 0.5));
    }
}

fun void recordNote(int instrument, int midiNote) {
    if (recording != 2 || instrument == 0) return;

    (now - loopStart) % loopDuration => dur offset;
    offset / second => float noteTime;

    (beatDuration / second) / subdivisions => float grid;

    Math.floor(noteTime / grid + 0.5) * grid => noteTime;

    loopDuration / second => float loopSeconds;

    if (noteTime >= loopSeconds) {
        noteTime - loopSeconds => noteTime;
    }

    recordedInstruments << instrument;
    recordedPitches << midiNote;
    recordedTimes << noteTime;
}

fun void playRecordedNote(int instrument, int midiNote, float noteTime) {
    noteTime::second => now;
    playInstrument(instrument, midiNote);
}

fun void playLoop() {
    loopStart + loopDuration => time nextLoop;

    while (true) {
        nextLoop => now;

        if (recording == 1) {
            2 => recording;
        }

        if (recordedInstruments.size() > 0) {
            for (0 => int i; i < recordedInstruments.size(); i++) {
                spork ~ playRecordedNote(recordedInstruments[i], recordedPitches[i], recordedTimes[i]);
            }
        }
        nextLoop + loopDuration => nextLoop;
    }
}

// Mouse and aiming
fun vec3 mousePos(float z) {
    GWindow.mousePos() => vec2 mouse;
    GG.camera().screenCoordToWorldPos(mouse, 1.0) => vec3 a;
    GG.camera().screenCoordToWorldPos(mouse, 2.0) => vec3 b;
    return a + (b - a) * ((z - a.z) / (b.z - a.z));
}

fun void updateCannon() {
    mousePos(cannon.posZ()) => vec3 mouse;
    cannon.pos() => vec3 center;

    mouse.x - center.x => float dx;
    mouse.y - center.y => float dy;

    Math.atan2(dy, dx) - Math.PI / 2.0 => float angle;
    cannon.rotZ(angle);
}

// Mode buttons
GPlane modeButtons[3];
GText modeLabels[3];

GPlane resetButton --> GG.scene();
resetButton.sca(@(0.7, 0.20, 1.0));
resetButton.pos(4.2, -2.65, 0.3);
resetButton.color(@(0.8, 0.1, 0.2));

GText resetLabel --> GG.scene();
resetLabel.text("RESET");
resetLabel.size(0.12);
resetLabel.color(@(1.0, 1.0, 1.0));
resetLabel.pos(4.2, -2.65, 0.31);

["MELODY", "BASS", "CHORD"] @=> string modeNames[];

vec3 modeColors[3];
@(0.0, 0.96, 1.0) => modeColors[0];
@(1.0, 0.20, 0.60) => modeColors[1];
@(1.0, 0.85, 0.10) => modeColors[2];

for (0 => int i; i < 3; i++) {
    modeButtons[i] --> GG.scene();
    modeButtons[i].sca(@(0.7, 0.20, 1.0));
    modeButtons[i].pos(2.6 + i * 0.8, -2.3, 0.3);

    modeLabels[i] --> GG.scene();
    modeLabels[i].text(modeNames[i]);
    modeLabels[i].size(0.12);
    modeLabels[i].color(@(1.0, 1.0, 1.0));
    modeLabels[i].pos(2.6 + i * 0.8, -2.3, 0.31);
}

fun void updateModeButtons() {
    for (0 => int i; i < 3; i++) {
        if (selectedInstrument == i + 4) {
            modeButtons[i].color(modeColors[i]);
        }
        else {
            modeButtons[i].color(@(0.08, 0.12, 0.20));
        }
    }
}

fun int checkModeButton() {
    mousePos(0.3) => vec3 p;
    for (0 => int i; i < 3; i++) {
        modeButtons[i].pos() => vec3 center;

        if (Math.fabs(p.x - center.x) <= 0.35 && Math.fabs(p.y - center.y) <= 0.10) {
            i + 4 => selectedInstrument;
            return 1;
        }
    }
    return 0;
}

fun int checkResetButton() {
    mousePos(0.3) => vec3 p;
    resetButton.pos() => vec3 center;

    if (Math.fabs(p.x - center.x) <= 0.35 && Math.fabs(p.y - center.y) <= 0.10) {
        recordedInstruments.clear();
        recordedPitches.clear();
        recordedTimes.clear();

        0 => recording;
        return 1;
    }
    return 0;
}

// Crosshair and hits
GLines crosshair[4];

0.05 => float crossGap;
0.17 => float crossSize;

for (0 => int i; i < 4; i++) {
    crosshair[i] --> GG.scene();
    crosshair[i].width(0.035);
    crosshair[i].color(@(0.83, 1.0, 0.30));
}

crosshair[0].positions([@(0, crossGap), @(0, crossSize)]);
crosshair[1].positions([@(0, -crossGap), @(0, -crossSize)]);
crosshair[2].positions([@(-crossGap, 0), @(-crossSize, 0)]);
crosshair[3].positions([@(crossGap, 0), @(crossSize, 0)]);

fun void updateCrosshair() {
    mousePos(0.5) => vec3 p;

    for (0 => int i; i < 4; i++) {
        crosshair[i].pos(p);
    }
}

fun int checkHit(GGen target) {
    mousePos(target.posZ()) => vec3 worldPos;
    target.pos() => vec3 center;

    worldPos.x - center.x => float dx;
    worldPos.y - center.y => float dy;

    if (dx*dx + dy*dy <= radius * radius * target.scaX() * target.scaX()) {
        return 1;
    }
    return 0;
}

// Paint and shooting
Texture paintTextures[3];
Texture.load(me.dir() + "images/paint1.png") @=> paintTextures[0];
Texture.load(me.dir() + "images/paint2.png") @=> paintTextures[1];
Texture.load(me.dir() + "images/paint3.png") @=> paintTextures[2];

fun void paintSplash(vec3 pos, vec3 paintColor, GGen target) {
    GPlane paint;

    if (target != null) {
        paint --> target;
        paint.sca(0.7 / target.scaX());
        paint.pos(pos.x, pos.y, 0.003 / target.scaZ());
    }
    else {
        paint --> GG.scene();
        paint.sca(0.7);
        paint.pos(pos.x, pos.y, 0.5);
    }

    paint.colorMap(paintTextures[Math.random2(0, 2)]);
    paint.color(paintColor);
    paint.rotZ(Math.random2f(0, 6.28));
    5::second => now;
    paint.detach();
}

fun void shoot(vec3 endPos, GGen target) {
    endPos => vec3 paintPos;

    if (target == null) {
        mousePos(0.5) => paintPos;
    }
    if (target != null) {
        target.pos() => vec3 center;

        @((endPos.x - center.x) / target.scaX(), (endPos.y - center.y) / target.scaY(), 0) => paintPos;
    }

    GCircle bullet --> GG.scene();
    bullet.sca(0.2);

    colors[Math.random2(0, 6)] * 2.0 => vec3 paintColor;
    bullet.color(paintColor);

    cannon.pos() => vec3 startPos;
    bullet.pos(startPos.x, startPos.y, 0.1);

    12 => int steps;

    for (0 => int i; i <= steps; i++) {
        if (target != null) {
            target.posLocalToWorld(paintPos) => endPos;
        }

        i / (steps $ float) => float t;

        bullet.pos(startPos.x + (endPos.x - startPos.x) * t, startPos.y + (endPos.y - startPos.y) * t, 0.1 + (endPos.z - 0.1) * t);

        GG.nextFrame() => now;
    }
    bullet.detach();
    GG.unregisterShred();
    paintSplash(paintPos, paintColor, target);
}

// Start menu
fun void drawUI() {
    if (started == 0) {
        UI.begin("Loop Settings");
        UI.slider("BPM", bpmUI, 60, 200);
        UI.slider("Beats per Bar", beatsUI, 2, 7);
        UI.slider("Bars", barsUI, 1, 8);

        if (UI.button("START")) {
            updateSettings();
            createBoxes();

            now => loopStart;
            1 => started;

            spork ~ metronome();
            spork ~ playLoop();
        }
        UI.end();
    }
}

while (true) {
    GG.nextFrame() => now;
    GWindow.mouseMode(GWindow.MOUSE_HIDDEN);

    drawUI();
    updateTargets();
    checkCollisions();
    updateModeButtons();
    updateCrosshair();
    updateCannon();

    if (started == 1) {
        updateBeats();
        updateStatus();
    }

    if (started && GWindow.keyDown(GWindow.KEY_R)) {
        if (recording == 0) {
            1 => recording;
        }
        else if (recording == 1) {
            0 => recording;
        }
        else if (recording == 2) {
            0 => recording;
        }
    }

    if (GWindow.keyDown(GWindow.KEY_M)) {
        1 - metronomeOn => metronomeOn;
    }

    if (GWindow.mouseLeftDown() && !UI.wantCaptureMouse()) {
        checkModeButton();
        checkResetButton();
        mousePos(0.0) => vec3 endPos;

        0 => int instrument;
        0 => int midiNote;
        GGen @ hitTarget;

        for (targets.size() - 1 => int i; i >= 0; i--) {
            if (checkHit(targets[i])) {
                targets[i] @=> hitTarget;
                if (i < 3) i + 1 => instrument;
                else {
                    selectedInstrument => instrument;
                    60 => int baseNote;
                    if (instrument == 5) 36 => baseNote;
                    baseNote + notePitches[i - 3] => midiNote;
                }
                break;
            }
        }

        if (hitTarget != null) {
            mousePos(hitTarget.posZ()) => endPos;
        }

        if (instrument != 0) {
            recordNote(instrument, midiNote);
            spork ~ playInstrument(instrument, midiNote);
        }
        spork ~ shoot(endPos, hitTarget);
    }
}
