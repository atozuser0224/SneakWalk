using UnityEngine;

namespace SneakWalk
{
    /// <summary>
    /// Generates the metronome in code (the repository ships no audio files) and
    /// plays each click scheduled on the DSP clock. Rest beats get a lower, softer
    /// tone: that tone is the only cue to stop, because the HUD has no beat line.
    /// </summary>
    public class Metronome : MonoBehaviour
    {
        public const int SampleRate = 44100;

        AudioSource tickSource;
        AudioSource restSource;
        AudioClip tickClip;
        AudioClip restClip;

        void Start()
        {
            // RhythmClock sets its singleton in Awake; Start runs after every Awake.
            if (tickSource == null && RhythmClock.Instance != null) Setup(RhythmClock.Instance);
        }

        public void Setup(RhythmClock clock)
        {
            if (tickSource != null) return;
            tickSource = gameObject.AddComponent<AudioSource>();
            restSource = gameObject.AddComponent<AudioSource>();
            foreach (var src in new[] { tickSource, restSource })
            {
                src.playOnAwake = false;
                src.spatialBlend = 0f;
                src.volume = 0.55f;
            }

            tickClip = MakeClick("tick", 1200f, 0.045f, 0.55f);
            restClip = MakeClick("rest", 620f, 0.11f, 0.42f);

            clock.Beat += OnBeat;
        }

        void OnDestroy()
        {
            if (RhythmClock.Instance != null) RhythmClock.Instance.Beat -= OnBeat;
        }

        void OnBeat(long beat)
        {
            var clock = RhythmClock.Instance;
            if (clock == null) return;

            bool rest = GameConfig.IsRestBeat(beat);
            var clip = rest ? restClip : tickClip;
            var source = rest ? restSource : tickSource;
            double when = clock.BeatTime(beat);
            double now = clock.Now;

            if (when > now + 0.02)
            {
                source.clip = clip;
                source.PlayScheduled(when);
            }
            else
            {
                source.PlayOneShot(clip, rest ? 0.9f : 1f);
            }
        }

        static AudioClip MakeClick(string name, float frequency, float duration, float amplitude)
        {
            int samples = Mathf.CeilToInt(SampleRate * duration);
            var data = new float[samples];
            for (int i = 0; i < samples; i++)
            {
                float t = i / (float)SampleRate;
                float env = Mathf.Exp(-t * (6f / duration));      // fast decay
                float attack = Mathf.Clamp01(t / 0.004f);
                data[i] = Mathf.Sin(2f * Mathf.PI * frequency * t) * env * attack * amplitude;
            }
            var clip = AudioClip.Create(name, samples, 1, SampleRate, false);
            clip.SetData(data, 0);
            return clip;
        }
    }
}
