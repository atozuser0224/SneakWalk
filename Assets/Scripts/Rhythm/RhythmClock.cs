using System;
using UnityEngine;

namespace SneakWalk
{
    /// <summary>
    /// Beat source driven by the audio DSP clock so judgement lines up with what
    /// the player hears, not with the render frame rate.
    /// </summary>
    public class RhythmClock : MonoBehaviour
    {
        public static RhythmClock Instance { get; private set; }

        /// <summary>
        /// Time source override for tests and CI. Headless (-nographics) runs have no
        /// audio device, so AudioSettings.dspTime never advances there. Set this to
        /// () => Time.realtimeSinceStartup in a test fixture.
        /// </summary>
        public static System.Func<double> TimeSource;

        public event Action<long> Beat;

        double startDsp;
        long lastBeat = -1;
        bool running;

        public bool Running { get { return running; } }
        public double StartDsp { get { return startDsp; } }

        /// <summary>Current time on the clock's own timeline.</summary>
        public double Now
        {
            get { return TimeSource != null ? TimeSource() : AudioSettings.dspTime; }
        }


        void Awake()
        {
            Instance = this;
        }

        public void Begin()
        {
            startDsp = Now + GameConfig.LeadInSeconds;
            lastBeat = -1;
            running = true;
        }

        public void Halt()
        {
            running = false;
        }

        public double BeatTime(long beatIndex)
        {
            return startDsp + beatIndex * GameConfig.SecondsPerBeat;
        }

        public long CurrentBeat
        {
            get
            {
                if (!running) return -1;
                return (long)Math.Floor((Now - startDsp) / GameConfig.SecondsPerBeat);
            }
        }

        /// <summary>Seconds until the next beat starts. Used by the HUD and tests.</summary>
        public double SecondsToNextBeat
        {
            get
            {
                long b = CurrentBeat;
                return Math.Max(0.0, BeatTime(b + 1) - Now);
            }
        }

        void Update()
        {
            if (!running) return;
            long current = CurrentBeat;
            while (lastBeat < current)
            {
                lastBeat++;
                if (lastBeat >= 0 && Beat != null) Beat(lastBeat);
            }
        }

        /// <summary>
        /// Nearest rest beat to a press timestamp, if the press is inside the
        /// good window. Returns false for presses that are not on a stop beat.
        /// </summary>
        public bool TryFindStopBeat(double pressDsp, out long beatIndex, out double delta, out StopGrade grade)
        {
            beatIndex = -1;
            delta = 0;
            grade = StopGrade.None;
            if (!running) return false;

            long probe = (long)Math.Floor((pressDsp - startDsp) / GameConfig.SecondsPerBeat);
            double best = double.MaxValue;

            for (long k = probe - 1; k <= probe + 1; k++)
            {
                if (!GameConfig.IsRestBeat(k)) continue;
                double d = BeatTime(k) - pressDsp;
                if (Math.Abs(d) < best)
                {
                    best = Math.Abs(d);
                    beatIndex = k;
                    delta = d;
                }
            }

            if (beatIndex < 0 || Math.Abs(delta) > GameConfig.GoodWindow) return false;

            grade = Math.Abs(delta) <= GameConfig.PerfectWindow ? StopGrade.Perfect : StopGrade.Good;
            return true;
        }
    }
}
