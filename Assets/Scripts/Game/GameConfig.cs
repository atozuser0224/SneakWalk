// Rhythm and risk tuning for chapter 1. Every number a designer will want to
// touch lives here so nothing has to be dug out of gameplay code.
//
// Mechanic (decided with the project owner):
//   The character walks forward on its own. The music defines "stop beats" (rests).
//   The player clicks exactly on a stop beat to halt, otherwise the floorboard
//   creaks. There is no note lane and no visual beat indicator; the metronome is
//   the only cue.

namespace SneakWalk
{
    public static class GameConfig
    {
        // --- rhythm -------------------------------------------------------
        public const float Bpm = 80f;
        public const float SecondsPerBeat = 60f / Bpm;      // 0.75 s
        public const double PerfectWindow = 0.060;          // +/- 60 ms
        public const double GoodWindow = 0.120;             // +/- 120 ms
        public const double LeadInSeconds = 1.6;            // silence before beat 0

        // 16-beat loop. true = a rest the player must stop on.
        // Bar 1: beat 3 | Bar 3: beat 1 and beat 4
        static readonly bool[] RestPattern =
        {
            false, false, true,  false,
            false, false, false, false,
            true,  false, false, true,
            false, false, false, false
        };

        public static bool IsRestBeat(long beatIndex)
        {
            if (beatIndex < 0) return false;
            return RestPattern[(int)(beatIndex % RestPattern.Length)];
        }

        public static float NextRestBeatAfter(long beatIndex)
        {
            for (int i = 1; i <= RestPattern.Length; i++)
            {
                long b = beatIndex + i;
                if (IsRestBeat(b)) return b * SecondsPerBeat;
            }
            return (beatIndex + 4) * SecondsPerBeat;
        }

        // --- noise --------------------------------------------------------
        public const float MaxNoise = 100f;
        public const float NoiseCleanStop = 0f;     // perfect
        public const float NoiseSloppyStop = 1f;    // good
        public const float NoiseStrayTap = 3f;      // clicked on a sounding beat
        public const float NoiseMissedStop = 7f;    // walked through a rest
        public const float DecayWhileStopped = 1.5f; // per second
        public const float DecayWhileWalking = 0.4f; // per second

        // Multiplied into every noise source. The kitchen carries furthest.
        public static float RoomNoiseFactor(RoomId room)
        {
            switch (room)
            {
                case RoomId.MyRoom: return 0.6f;
                case RoomId.LivingRoom: return 1.0f;
                case RoomId.Kitchen: return 1.3f;
                default: return 1f;
            }
        }

        // --- movement -----------------------------------------------------
        public const float WalkSpeed = 5.0f;              // world units / s
        public const float WalkSpeedAfterDrink = 6.5f;    // the return trip speeds up
        public const float RoomWidth = 40f;               // 4000 px at 100 PPU
        public const float StopHoldBeats = 1f;            // a clean stop lasts one beat

        // --- chapter ------------------------------------------------------
        public const float TimeLimitSeconds = 75f;
        public const int SinkStopsRequired = 3;

        // --- presentation -------------------------------------------------
        public const float PPU = 100f;
        public const float CameraSize = 5.4f;
        public const float FloorY = -3.62f;
        public const float BackgroundBottomY = -5.4f;
    }
}
