using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;
using SneakWalk;

namespace SneakWalk.Tests
{
    /// <summary>
    /// Drives the real director through the judgement path with time-explicit
    /// presses, so the noise model and the stop rule are verified without a mouse.
    /// </summary>
    public class ChapterOnePlayTests
    {
        GameObject root;
        GameObject cameraGo;
        GameDirector director;
        RhythmClock clock;

        [SetUp]
        public void SetUp()
        {
            // Headless runs have no audio device, so dspTime is frozen: use the
            // realtime clock instead so beat events actually fire.
            RhythmClock.TimeSource = () => Time.realtimeSinceStartup;

            root = new GameObject("game");
            root.AddComponent<SpriteLibrary>();
            clock = root.AddComponent<RhythmClock>();
            director = root.AddComponent<GameDirector>();
            cameraGo = new GameObject("cam");
            var cam = cameraGo.AddComponent<Camera>();
            cameraGo.tag = "MainCamera";
            director.Boot(cam, clock);
        }

        [TearDown]
        public void TearDown()
        {
            Object.Destroy(root);
            Object.Destroy(cameraGo);
            RhythmClock.TimeSource = null;
        }

        [UnityTest]
        public IEnumerator StrayPressOnSoundingBeat_RaisesNoise()
        {
            director.StartRun();
            yield return null;
            float before = director.Noise;
            director.PressAt(clock.BeatTime(3)); // beat 3 sounds, no stop allowed
            Assert.Greater(director.Noise, before + 1f, "a stray footstep must add noise");
        }

        [UnityTest]
        public IEnumerator PerfectStop_HaltsTheCharacterForOneBeat()
        {
            director.StartRun();
            yield return null;
            director.PressAt(clock.BeatTime(2));
            yield return new WaitForSeconds(0.05f);
            float x = director.PlayerX;
            yield return new WaitForSeconds(0.20f);
            Assert.AreEqual(x, director.PlayerX, 0.0005f, "character must not move while stopped");
        }

        [UnityTest]
        public IEnumerator MissingARestBeat_RaisesNoise()
        {
            director.StartRun();
            // Beat 2 is the first rest (lead-in 1.6 s + 2 beats). Wait past it untouched.
            double restTime = clock.BeatTime(2);
            yield return new WaitForSeconds((float)(restTime - clock.Now) + 0.3f);
            Assert.Greater(director.Noise, 2f, "walking through a rest must creak");
        }

        [UnityTest]
        public IEnumerator StoppingOnEveryRest_KeepsNoiseLow()
        {
            director.StartRun();
            float end = Time.time + 6f;
            while (Time.time < end)
            {
                long next = clock.CurrentBeat + 1;
                for (long b = next; b <= next + 3; b++)
                {
                    if (!GameConfig.IsRestBeat(b)) continue;
                    double when = clock.BeatTime(b);
                    if (when > clock.Now)
                    {
                        yield return new WaitForSeconds(Mathf.Max(0f, (float)(when - clock.Now) - 0.005f));
                        director.PressAt(clock.Now);
                    }
                }
                yield return null;
            }
            Assert.Less(director.Noise, 3f, "clean stops must keep the gauge low");
        }
    }
}
