using NUnit.Framework;
using UnityEngine;
using SneakWalk;

namespace SneakWalk.Tests
{
    public class RhythmConfigTests
    {
        [Test]
        public void RestPattern_MarksThirdBeatOfFirstBar()
        {
            Assert.IsTrue(GameConfig.IsRestBeat(2), "beat 2 (bar1 beat3) must be a stop beat");
        }

        [Test]
        public void RestPattern_RepeatsEverySixteenBeats()
        {
            Assert.AreEqual(GameConfig.IsRestBeat(2), GameConfig.IsRestBeat(2 + 16));
            Assert.IsTrue(GameConfig.IsRestBeat(2 + 16 * 5));
        }

        [Test]
        public void RestPattern_SoundingBeatsAreNotStopBeats()
        {
            Assert.IsFalse(GameConfig.IsRestBeat(0));
            Assert.IsFalse(GameConfig.IsRestBeat(1));
            Assert.IsFalse(GameConfig.IsRestBeat(3));
        }

        [Test]
        public void NoiseFactor_RisesFromBedroomToKitchen()
        {
            float bedroom = GameConfig.RoomNoiseFactor(RoomId.MyRoom);
            float living = GameConfig.RoomNoiseFactor(RoomId.LivingRoom);
            float kitchen = GameConfig.RoomNoiseFactor(RoomId.Kitchen);
            Assert.Less(bedroom, living);
            Assert.Less(living, kitchen);
            Assert.AreEqual(1f, living, 0.0001f);
        }

        [Test]
        public void TimeLimitIsSeventyFiveSeconds()
        {
            Assert.AreEqual(75f, GameConfig.TimeLimitSeconds, 0.001f);
        }
    }

    public class RhythmClockTests
    {
        GameObject go;
        RhythmClock clock;

        [SetUp]
        public void SetUp()
        {
            go = new GameObject("clock");
            clock = go.AddComponent<RhythmClock>();
            clock.Begin();
        }

        [TearDown]
        public void TearDown()
        {
            Object.DestroyImmediate(go);
        }

        [Test]
        public void PressExactlyOnRestBeat_IsPerfect()
        {
            long beat;
            double delta;
            StopGrade grade;
            Assert.IsTrue(clock.TryFindStopBeat(clock.BeatTime(2), out beat, out delta, out grade));
            Assert.AreEqual(2, beat);
            Assert.AreEqual(StopGrade.Perfect, grade);
        }

        [Test]
        public void PressInsideGoodWindow_IsGood()
        {
            long beat;
            double delta;
            StopGrade grade;
            Assert.IsTrue(clock.TryFindStopBeat(clock.BeatTime(2) + 0.10, out beat, out delta, out grade));
            Assert.AreEqual(StopGrade.Good, grade);
        }

        [Test]
        public void PressOutsideWindow_IsRejected()
        {
            long beat;
            double delta;
            StopGrade grade;
            Assert.IsFalse(clock.TryFindStopBeat(clock.BeatTime(2) + 0.20, out beat, out delta, out grade));
        }

        [Test]
        public void PressOnSoundingBeat_IsRejected()
        {
            long beat;
            double delta;
            StopGrade grade;
            Assert.IsFalse(clock.TryFindStopBeat(clock.BeatTime(3), out beat, out delta, out grade));
        }

        [Test]
        public void BeatDurationMatchesBpm()
        {
            Assert.AreEqual(0.75, GameConfig.SecondsPerBeat, 0.0001);
            Assert.AreEqual(1.5, clock.BeatTime(2) - clock.StartDsp, 0.0001);
        }
    }
}
