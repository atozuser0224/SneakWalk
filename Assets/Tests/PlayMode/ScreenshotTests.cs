using System.Collections;
using System.IO;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.TestTools;
using UnityEngine.UI;

namespace SneakWalk.Tests
{
    /// <summary>
    /// Explicit visual capture of the real Main scene. The project does not include
    /// the ScreenCapture module and WaitForEndOfFrame does not fire in batchmode, so
    /// the frame is rendered through the game camera into a RenderTexture with the UI
    /// canvas switched to Screen Space - Camera for the capture.
    /// Run with: -runTests -testPlatform PlayMode -testFilter SneakWalk.Tests.ScreenshotTests
    /// </summary>
    public class ScreenshotTests
    {
        static string OutDir
        {
            get { return Path.GetFullPath(Path.Combine(Application.dataPath, "../Previews")); }
        }

        [UnityTest, Explicit("Writes screenshots; run on demand.")]
        public IEnumerator CaptureMenuAndGameplay()
        {
            Directory.CreateDirectory(OutDir);
            SceneManager.LoadScene("Main");
            yield return null;
            yield return new WaitForSeconds(0.8f);

            var cam = Camera.main;
            var director = Object.FindFirstObjectByType<GameDirector>();
            Assert.IsNotNull(cam, "no main camera");
            Assert.IsNotNull(director, "no GameDirector");

            var canvases = Object.FindObjectsByType<Canvas>(FindObjectsSortMode.None);
            Debug.Log("[SneakWalk][Shot] screen=" + Screen.width + "x" + Screen.height + " canvases=" + canvases.Length);
            foreach (var c in canvases)
            {
                var rt = c.GetComponent<RectTransform>();
                Debug.Log("[SneakWalk][Shot] canvas mode=" + c.renderMode + " scale=" + c.scaleFactor +
                          " rect=" + (rt != null ? rt.rect.size.ToString() : "none") +
                          " children=" + c.transform.childCount);
                foreach (var img in c.GetComponentsInChildren<Image>(true))
                {
                    Debug.Log("[SneakWalk][Shot] image " + img.name + " sprite=" + (img.sprite != null ? img.sprite.name : "NULL") +
                              " color=" + img.color + " active=" + img.gameObject.activeInHierarchy);
                }
                foreach (var txt in c.GetComponentsInChildren<Text>(true))
                {
                    Debug.Log("[SneakWalk][Shot] text " + txt.name + " font=" + (txt.font != null ? txt.font.name : "NULL") +
                              " '" + txt.text + "' active=" + txt.gameObject.activeInHierarchy);
                }
            }

            yield return Shot(cam, "10_game_menu");

            director.StartRun();
            yield return new WaitForSeconds(1.4f);
            yield return Shot(cam, "11_game_myroom");

            yield return new WaitForSeconds(7.0f);
            yield return Shot(cam, "12_game_later");

            Debug.Log("[SneakWalk][Shot] room=" + director.CurrentRoom +
                      " x=" + director.PlayerX.ToString("0.0") +
                      " noise=" + director.Noise.ToString("0.0") +
                      " phase=" + director.Phase);
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

            var path = Path.Combine(OutDir, fileName + ".png");
            File.WriteAllBytes(path, tex.EncodeToPNG());

            cam.targetTexture = null;
            rt.Release();
            Object.Destroy(rt);
            Object.Destroy(tex);

            Debug.Log("[SneakWalk][Shot] wrote " + path + " exists=" + File.Exists(path));
        }
    }
}
