using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace SneakWalk.EditorTools
{
    /// <summary>
    /// Rebuilds Assets/Scenes/Main.unity from code so the scene stays reproducible:
    /// one camera, one Game object holding the runtime systems, and a sprite table
    /// filled from Assets/Art. Run it after adding art.
    /// </summary>
    public static class SneakWalkSceneBuilder
    {
        const string ScenePath = "Assets/Scenes/Main.unity";
        const string PlayerSheet = "Assets/Art/Characters/me/player.png";

        [MenuItem("SneakWalk/Scene/Rebuild Main Scene")]
        public static void Build()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var camGo = new GameObject("Main Camera");
            camGo.tag = "MainCamera";
            var cam = camGo.AddComponent<Camera>();
            cam.orthographic = true;
            cam.orthographicSize = GameConfig.CameraSize;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.06f, 0.06f, 0.08f, 1f);
            cam.transform.position = new Vector3(0f, 0f, -10f);
            cam.nearClipPlane = 0.3f;
            cam.farClipPlane = 100f;
            camGo.AddComponent<AudioListener>();

            var game = new GameObject("Game");

            var library = game.AddComponent<SpriteLibrary>();
            library.entries = BuildEntries().ToArray();
            library.playerFrames = BuildPlayerFrames().ToArray();

            game.AddComponent<RhythmClock>();
            game.AddComponent<Metronome>();

            var ui = game.AddComponent<GameUI>();
            var director = game.AddComponent<GameDirector>();
            ui.sprites = library;
            director.sprites = library;
            director.ui = ui;

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);

            var scenes = EditorBuildSettings.scenes.ToList();
            if (!scenes.Any(s => s.path == ScenePath))
            {
                scenes.Add(new EditorBuildSettingsScene(ScenePath, true));
                EditorBuildSettings.scenes = scenes.ToArray();
            }

            Debug.Log("[SneakWalk][SceneBuilder] wrote " + ScenePath +
                      " sprites=" + library.entries.Length +
                      " playerFrames=" + library.playerFrames.Length);
        }

        static IEnumerable<SpriteLibrary.Entry> BuildEntries()
        {
            foreach (var guid in AssetDatabase.FindAssets("t:Sprite", new[] { "Assets/Art" }))
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (path == PlayerSheet) continue; // the sheet is exposed as frames instead
                var sprite = AssetDatabase.LoadAssetAtPath<Sprite>(path);
                if (sprite == null) continue;
                yield return new SpriteLibrary.Entry { key = KeyFromPath(path), sprite = sprite };
            }
        }

        static IEnumerable<SpriteLibrary.Entry> BuildPlayerFrames()
        {
            var sprites = AssetDatabase.LoadAllAssetsAtPath(PlayerSheet)
                .OfType<Sprite>()
                .OrderBy(s => s.name)
                .ToList();
            for (int i = 0; i < sprites.Count; i++)
            {
                yield return new SpriteLibrary.Entry { key = "frame" + i, sprite = sprites[i] };
            }
        }

        public static string KeyFromPath(string assetPath)
        {
            var key = assetPath.StartsWith("Assets/") ? assetPath.Substring("Assets/".Length) : assetPath;
            int dot = key.LastIndexOf('.');
            return dot >= 0 ? key.Substring(0, dot) : key;
        }
    }
}
