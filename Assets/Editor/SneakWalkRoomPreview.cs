// Renders room compositions off-screen so the scale/pivot decisions in
// analysis/02-art-pipeline.md can be checked without opening the Editor by hand.
//
// Run from CLI (needs a graphics device, so no -nographics):
//   Unity.exe -batchmode -quit -projectPath <repo> \
//     -executeMethod SneakWalk.EditorTools.RoomPreview.RenderAll -logFile <log>
//
// Output: <repo>/Previews/*.png (outside Assets, so Unity never imports them).
// The open scene is replaced in memory and never saved.

using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace SneakWalk.EditorTools
{
    public static class RoomPreview
    {
        // PPU 100 + orthographic 5.4 => 1080 source pixels map 1:1 onto a 1080p view.
        const float OrthoSize = 5.4f;
        const int ShotW = 1920;
        const int ShotH = 1080;

        // Background sprites use a bottom-center pivot, so their bottom sits at
        // cameraY - OrthoSize = -5.4. The painted floor line is 178px above the sprite
        // bottom (901..902 from the top of a 1080px image) => -3.62 world units.
        const float BackgroundBottomY = -5.4f;
        const float FloorY = -3.62f;

        // The room strip is 4000px at PPU 100 = 40 units wide and its pivot is centered,
        // so place the sprite centre at +20 to make room-local x run 0..40.
        const float RoomWidthUnits = 40f;
        const float BackgroundCenterX = RoomWidthUnits * 0.5f;

        static string OutDir { get { return Path.GetFullPath(Path.Combine(Application.dataPath, "../Previews")); } }

        [MenuItem("SneakWalk/Render/Room Previews")]
        public static void RenderAll()
        {
            Directory.CreateDirectory(OutDir);

            RenderRoom("myRoom_background", "01_myRoom_left", 9.6f, new[]
            {
                P("myRoom/bed", 4.0f, 0f), P("myRoom/desk", 11.0f, 0f),
                P("myRoom/dresser", 14.5f, 0f), P("myRoom/mirror", 17.3f, 0f)
            });

            RenderRoom("myRoom_background", "02_myRoom_right", 28.0f, new[]
            {
                P("myRoom/pictures", 22.0f, 2.2f), P("myRoom/calendar", 26.0f, 2.4f)
            });

            RenderRoom("kitchen_background", "03_kitchen_left", 9.6f, new[]
            {
                P("kitchen/fridge", 4.0f, 0f), P("kitchen/cabinet2", 9.5f, 0f),
                P("kitchen/sink", 15.0f, 0f)
            });

            RenderRoom("livingroom_background", "04_livingroom_left", 9.6f, new[]
            {
                P("livingroom/sofa", 6.0f, 0f), P("livingroom/coffeeTable", 12.0f, 0f),
                P("livingroom/tv", 16.5f, 0f), P("livingroom/clock", 2.5f, 2.6f)
            });

            RenderPlayerFrames();

            Debug.Log("[SneakWalk][Preview] wrote PNGs to " + OutDir);
        }

        struct PropDef
        {
            public string SpritePath;
            public float X;
            public float YOffset;
            public PropDef(string p, float x, float y) { SpritePath = "Assets/Art/Props/" + p + ".png"; X = x; YOffset = y; }
        }

        static PropDef P(string relative, float x, float yOffset) { return new PropDef(relative, x, yOffset); }

        static void RenderRoom(string backgroundName, string fileName, float cameraX, PropDef[] props)
        {
            NewEmptyScene();
            var cam = NewCamera(cameraX);

            AddSprite(LoadSprite("Assets/Art/Backgrounds/" + backgroundName + ".png"), BackgroundCenterX, BackgroundBottomY, 0, "Background");
            foreach (var p in props)
                AddSprite(LoadSprite(p.SpritePath), p.X, FloorY + p.YOffset, 10, Path.GetFileNameWithoutExtension(p.SpritePath));

            // Player standing on the floor line, to the right of the props.
            AddSprite(LoadSprite("Assets/Art/Characters/me/player.png"), cameraX + 4.0f, FloorY, 30, "Player");

            Save(cam, fileName);
            Finish(cam);
        }

        static void RenderPlayerFrames()
        {
            NewEmptyScene();
            var cam = NewCamera(9.6f);
            AddSprite(LoadSprite("Assets/Art/Backgrounds/myRoom_background.png"), BackgroundCenterX, BackgroundBottomY, 0, "Background");
            for (int i = 0; i < 4; i++)
                AddSprite(LoadSheetSprite(i), 4.0f + i * 4.2f, FloorY, 30, "PlayerFrame" + i);
            Save(cam, "05_player_frames");
            Finish(cam);
        }

        static void NewEmptyScene()
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        }

        static void Finish(Camera cam)
        {
            Object.DestroyImmediate(cam.gameObject);
            NewEmptyScene(); // leave an unsaved empty scene behind, Main.unity is never touched
        }

        static Camera NewCamera(float x)
        {
            var go = new GameObject("PreviewCamera");
            var cam = go.AddComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = OrthoSize;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.06f, 0.06f, 0.08f, 1f);
            cam.transform.position = new Vector3(x, 0f, -10f);
            cam.nearClipPlane = 0.3f;
            cam.farClipPlane = 100f;
            return cam;
        }

        static Sprite LoadSprite(string path)
        {
            var s = AssetDatabase.LoadAssetAtPath<Sprite>(path);
            if (s == null) Debug.LogWarning("[SneakWalk][Preview] missing sprite " + path);
            return s;
        }

        static Sprite LoadSheetSprite(int index)
        {
            var all = AssetDatabase.LoadAllAssetsAtPath("Assets/Art/Characters/me/player.png");
            int seen = 0;
            foreach (var a in all)
            {
                var s = a as Sprite;
                if (s == null) continue;
                if (seen == index) return s;
                seen++;
            }
            Debug.LogWarning("[SneakWalk][Preview] missing sheet frame " + index);
            return null;
        }

        static GameObject AddSprite(Sprite sprite, float x, float y, int order, string name)
        {
            var go = new GameObject(name);
            if (sprite == null) return go;
            var sr = go.AddComponent<SpriteRenderer>();
            sr.sprite = sprite;
            sr.sortingOrder = order;
            go.transform.position = new Vector3(x, y, 0f);
            return go;
        }

        static void Save(Camera cam, string fileName)
        {
            var rt = new RenderTexture(ShotW, ShotH, 24, RenderTextureFormat.ARGB32);
            rt.Create();
            cam.targetTexture = rt;
            cam.Render();

            var prev = RenderTexture.active;
            RenderTexture.active = rt;
            var tex = new Texture2D(ShotW, ShotH, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, ShotW, ShotH), 0, 0);
            tex.Apply();
            RenderTexture.active = prev;

            var outPath = Path.Combine(OutDir, fileName + ".png");
            File.WriteAllBytes(outPath, tex.EncodeToPNG());

            cam.targetTexture = null;
            rt.Release();
            Object.DestroyImmediate(rt);
            Object.DestroyImmediate(tex);
            Debug.Log("[SneakWalk][Preview] wrote " + outPath);
        }
    }
}
