using System.Collections;
using System.IO;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;

namespace SneakWalk.Tests
{
    /// <summary>
    /// Plays the whole chapter with synthetic on-beat presses and captures the result
    /// screen. This is the end-to-end check: it proves the chapter can actually be
    /// finished inside the 75 s limit and that the result panel appears.
    /// Run with: -runTests -testPlatform PlayMode -testFilter SneakWalk.Tests.AutoPlayTests
    /// </summary>
    public class AutoPlayTests
    {
        static string OutDir
        {
            get { return Path.GetFullPath(Path.Combine(Application.dataPath, "../Previews")); }
        }

        [UnityTest, Explicit("Takes about a minute of real time.")]
        public IEnumerator CompleteChapterWithPerfectStops()
        {
            Directory.CreateDirectory(OutDir);
            SceneManager.LoadScene("Main");
            yield return null;
            yield return new WaitForSeconds(0.6f);

            var director = Object.FindFirstObjectByType<GameDirector>();
            var clock = Object.FindFirstObjectByType<RhythmClock>();
            Assert.IsNotNull(director, "no GameDirector");
            Assert.IsNotNull(clock, "no RhythmClock");

            director.StartRun();
            yield return null;

            var cam = Camera.main;
            float deadline = Time.realtimeSinceStartup + 95f;
            bool shotKitchen = false;
            int pressed = 0;

            while (director.Phase == RunPhase.Playing && Time.realtimeSinceStartup < deadline)
            {
                double now = clock.Now;

                // Press exactly on the next rest beat.
                for (long b = clock.CurrentBeat + 1; b <= clock.CurrentBeat + 3; b++)
                {
                    if (!GameConfig.IsRestBeat(b)) continue;
                    double when = clock.BeatTime(b);
                    double diff = when - now;
                    if (diff <= 0.030 && diff >= -0.030)
                    {
                        director.PressAt(now);
                        pressed++;
                        break;
                    }
                }

                if (!shotKitchen && director.SinkRitual)
                {
                    shotKitchen = true;
                    yield return Shot(cam, "13_game_kitchen");
                }

                yield return null;
            }

            Debug.Log("[SneakWalk][AutoPlay] phase=" + director.Phase +
                      " success=" + director.Succeeded +
                      " reason=" + director.ResultReason +
                      " timeLeft=" + director.TimeLeft.ToString("0.0") +
                      " noise=" + director.Noise.ToString("0.0") +
                      " presses=" + pressed);

            yield return new WaitForSeconds(0.3f);
            yield return Shot(cam, "14_game_result");

            Assert.AreEqual(RunPhase.Result, director.Phase, "chapter did not finish");
            Assert.IsTrue(director.Succeeded, "clean play should succeed: " + director.ResultReason);
        }

        static IEnumerator Shot(Camera cam, string fileName)
        {
            foreach (var canvas in Object.FindObjectsByType<Canvas>(FindObjectsSortMode.None))
            {
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.worldCamera = cam;
                canvas.planeDistance = 1f;
            }
            Canvas.ForceUpdateCanvases();
            yield return null;
            Canvas.ForceUpdateCanvases();

            const int w = 1920, h = 1080;
            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32);
            rt.Create();
            cam.targetTexture = rt;
            cam.Render();

            var previous = RenderTexture.active;
            RenderTexture.active = rt;
            var tex = new Texture2D(w, h, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, w, h), 0, 0);
            tex.Apply();
            RenderTexture.active = previous;

            File.WriteAllBytes(Path.Combine(OutDir, fileName + ".png"), tex.EncodeToPNG());

            cam.targetTexture = null;
            rt.Release();
            Object.Destroy(rt);
            Object.Destroy(tex);
            Debug.Log("[SneakWalk][Shot] wrote " + fileName);
        }
    }
}
