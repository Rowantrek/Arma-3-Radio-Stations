#!/bin/sh
# Synthesizes the placeholder demo music as WAV, one subfolder per station, ready for import_music.ps1.
# Needs ffmpeg. Usage: sh tools/make_demo_audio.sh <output folder>, then import each subfolder:
#   mission -> Arma3RadioStations/.hemtt/missions/a3r_test.VR, addon -> AddonTemplate/addons/main
set -e
OUT=${1:?usage: make_demo_audio.sh <output folder>}

# Plucked pentatonic arpeggio over a I-IV-V-IV bass with a soft kick.
arp() { # file seconds basefreq notesPerSecond step
  N="floor(t*$4)"; D="mod($N*$5,5)"; P="mod(t,1/$4)"
  R="(5*eq(mod(floor(t/4),4),1)+7*eq(mod(floor(t/4),4),2)+5*eq(mod(floor(t/4),4),3))"
  F="$3*pow(2,(2*$D+gte($D,3)+12*mod(floor($N/5),2)+$R)/12)"
  LEAD="0.3*exp(-9*$P*$4/4)*sin(2*PI*$F*t)"
  BASS="0.2*sin(2*PI*$3/4*pow(2,$R/12)*t)"
  KICK="0.35*exp(-14*mod(t,0.5))*sin(2*PI*(45+90*exp(-30*mod(t,0.5)))*mod(t,0.5))"
  mkdir -p "$(dirname "$1")"
  ffmpeg -y -loglevel error -f lavfi -i "aevalsrc='$LEAD+$BASS+$KICK':s=44100:d=$2" \
    -af "afade=t=in:d=1,afade=t=out:st=$(($2-2)):d=2" -ac 1 "$1"
}

# Swelling chord pad; each chord fades to silence at the change so there are no clicks.
pad() { # file seconds basefreq secondsPerChord chordA chordB chordC chordD (semitone roots)
  C="floor(t/$4)"; E="pow(sin(PI*mod(t,$4)/$4),2)"
  R="($5*eq(mod($C,4),0)+$6*eq(mod($C,4),1)+$7*eq(mod($C,4),2)+$8*eq(mod($C,4),3))"
  F="$3*pow(2,$R/12)"
  CHORD="0.22*sin(2*PI*$F*t)+0.15*sin(2*PI*$F*1.4983*t)+0.12*sin(2*PI*$F*2.002*t)+0.07*sin(2*PI*$F*2.52*t)*(0.5+0.5*sin(2*PI*0.3*t))"
  mkdir -p "$(dirname "$1")"
  ffmpeg -y -loglevel error -f lavfi -i "aevalsrc='$E*($CHORD)':s=44100:d=$2" -ac 1 "$1"
}

# Example mission (Arma3RadioStations/.hemtt/missions/a3r_test.VR)
pad "$OUT/mission/Drift Radio/01 Slow Tide.wav" 64 110 8 0 5 -3 -5
pad "$OUT/mission/Drift Radio/02 Low Cloud.wav" 60 98 10 0 -2 3 5
# Add-on template (AddonTemplate/addons/main)
arp "$OUT/addon/Example FM/01 Example One.wav" 36 196 5 3
arp "$OUT/addon/Example FM/02 Example Two.wav" 36 247 4 2
echo "Wrote demo music to $OUT"
