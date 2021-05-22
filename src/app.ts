// Menro is a toy instrument application.
// Copyright (C) 2021  Shota Fuji
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import { Elm } from "./Menro/App.elm";

import "./app.css?runtime";

declare global {
  interface Window {
    webkitAudioContext: typeof AudioContext;
  }
}

/**
 * Entry point function.
 */
export async function main() {
  const app = Elm.Menro.App.init<{
    repositoryUrl?: string;
  }>({
    node: document.getElementById("app")!,
    flags: {
      // @ts-ignore
      repositoryUrl: process.env.REPOSITORY_URL,
    },
  });

  const audioCtx = new (AudioContext || window.webkitAudioContext)();
  audioCtx.suspend();

  const sources = new Map<string, [OscillatorNode, GainNode]>();

  app.ports.updateSoundState?.subscribe<
    [
      {
        id: string;
        level: number;
        freq: number;
        waveType: OscillatorType;
      }
    ]
  >((values) => {
    const existingIDs = [...sources.keys()];
    const currentIDs = [];

    for (const value of values) {
      currentIDs.push(value.id);

      const nodes = sources.get(value.id);
      if (!nodes) {
        const oscillator = audioCtx.createOscillator();
        oscillator.type = value.waveType;
        oscillator.frequency.setValueAtTime(0, audioCtx.currentTime);

        const gain = audioCtx.createGain();
        gain.gain.setValueAtTime(0, audioCtx.currentTime);

        oscillator.connect(gain);
        gain.connect(audioCtx.destination);

        oscillator.start();

        oscillator.frequency.setValueAtTime(value.freq, audioCtx.currentTime);
        gain.gain.setValueAtTime(value.level, audioCtx.currentTime);

        sources.set(value.id, [oscillator, gain]);
      } else {
        const [oscillator, gain] = nodes;

        if (oscillator.type !== value.waveType) {
          oscillator.type = value.waveType;
        }

        oscillator.frequency.setValueAtTime(value.freq, audioCtx.currentTime);
        gain.gain.setValueAtTime(value.level, audioCtx.currentTime);
      }
    }

    for (const id of existingIDs) {
      if (currentIDs.indexOf(id) < 0) {
        const nodes = sources.get(id);
        if (!nodes) {
          continue;
        }

        nodes[0].disconnect();
        nodes[1].disconnect();
        sources.delete(id);
      }
    }
  });

  document.addEventListener("mouseup", () => {
    app.ports.pointerUpOutsideOfTheApp?.send(null);
  });

  const enableAudioPlayback = () => {
    audioCtx.resume();
    document.removeEventListener("mousedown", enableAudioPlayback);
    document.removeEventListener("touchstart", enableAudioPlayback);
  };

  document.addEventListener("mousedown", enableAudioPlayback);
  document.addEventListener("touchstart", enableAudioPlayback);
}
