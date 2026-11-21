// SneakWalk 2D import canonicalization.
//
// Unity defaults are wrong for this project: 4000x1080 backgrounds get clamped to
// 2048 wide, sprites are auto-trimmed to their alpha bbox, and every pivot lands on
// the canvas center. Both facts are measured in analysis/02-art-pipeline.md.
//
// Run from CLI:
//   Unity.exe -batchmode -quit -projectPath <repo> \
//     -executeMethod SneakWalk.EditorTools.AssetSetup.ApplyImportSettings
//
// Or from the Editor menu: SneakWalk/Assets/Apply Import Settings.

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace SneakWalk.EditorTools
{
    public static class AssetSetup
    {
        const string BackgroundsDir = "Assets/Art/Backgrounds";
        const string CharactersDir = "Assets/Art/Characters/me";
        const string PropsDir = "Assets/Art/Props";
        const string UiDir = "Assets/Art/UI";

        const int Ppu = 100;
        const int BackgroundMaxSize = 4096; // source is 4000px wide
        const int DefaultMaxSize = 2048;
        const float AlphaThreshold = 0.02f;

        // Wall-mounted props are not floor aligned: keep a centered pivot.
        static readonly HashSet<string> WallProps = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "clock", "picture", "map", "calendar", "switch", "intercom", "hood", "pictures"
        };

        [MenuItem("SneakWalk/Assets/Apply Import Settings")]
        public static void ApplyImportSettings()
        {
            var report = new List<string>();
            int ok = 0, failed = 0;

            foreach (var path in AllPngUnder(BackgroundsDir))
            {
                bool isMenu = Path.GetFileNameWithoutExtension(path).Equals("menu", StringComparison.OrdinalIgnoreCase);
                if (isMenu)
                {
                    // Full-screen title art: a UI sprite, used at native 1960x1080.
                    ok += Configure(path, SpriteImportMode.Single, DefaultMaxSize, TextureImporterCompression.Uncompressed,
                            new Vector2(0.5f, 0.5f), false, report);
                }
                else
                {
                    // Wide room strip: bottom-center pivot so the sprite bottom can sit
                    // on the camera edge and the painted floor line lands where planned.
                    ok += Configure(path, SpriteImportMode.Single, BackgroundMaxSize, TextureImporterCompression.CompressedHQ,
                            new Vector2(0.5f, 0f), false, report);
                }
            }

            // player.png is a 4-frame horizontal sheet of 325x584 cells (1300x584).
            const int cellW = 325, cellH = 584;
            var playerPath = CharactersDir + "/player.png";
            if (File.Exists(playerPath))
            {
                var pivot = new Vector2(0.5f, AlphaBottomGap(playerPath) / (float)cellH);
                ok += ConfigureSheet(playerPath, cellW, cellH, pivot, report);
            }
            else
            {
                report.Add("MISSING " + playerPath);
                failed++;
            }

            foreach (var path in AllPngUnder(CharactersDir).Where(p => !p.EndsWith("/player.png", StringComparison.Ordinal)))
            {
                var pivot = new Vector2(0.5f, AlphaBottomGap(path) / (float)ImageHeight(path));
                ok += Configure(path, SpriteImportMode.Single, DefaultMaxSize, TextureImporterCompression.Uncompressed,
                        pivot, false, report);
            }

            foreach (var path in AllPngUnder(PropsDir))
            {
                bool isButton = path.StartsWith(PropsDir + "/buttons", StringComparison.OrdinalIgnoreCase);
                bool isWall = WallProps.Contains(Path.GetFileNameWithoutExtension(path));
                var pivot = isWall || isButton
                        ? new Vector2(0.5f, 0.5f)
                        : new Vector2(0.5f, AlphaBottomGap(path) / (float)ImageHeight(path));
                var compression = isButton ? TextureImporterCompression.Uncompressed : TextureImporterCompression.CompressedHQ;
                ok += Configure(path, SpriteImportMode.Single, DefaultMaxSize, compression, pivot, false, report);
            }

            foreach (var path in AllPngUnder(UiDir))
            {
                ok += Configure(path, SpriteImportMode.Single, DefaultMaxSize, TextureImporterCompression.Uncompressed,
                        new Vector2(0.5f, 0.5f), false, report);
            }

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            Debug.Log("[SneakWalk][AssetSetup] configured=" + ok + " failed=" + failed);
            foreach (var line in report) Debug.Log("[SneakWalk][AssetSetup] " + line);
            if (failed > 0) throw new Exception("AssetSetup failed for " + failed + " asset(s)");
        }

        // ---------------------------------------------------------------- helpers

        static IEnumerable<string> AllPngUnder(string dir)
        {
            if (!Directory.Exists(dir)) yield break;
            foreach (var f in Directory.GetFiles(dir, "*.png", SearchOption.AllDirectories).OrderBy(x => x, StringComparer.Ordinal))
                yield return f.Replace('\\', '/');
        }

        static int Configure(string path, SpriteImportMode mode, int maxSize, TextureImporterCompression compression,
                             Vector2 pivot, bool readable, List<string> report)
        {
            var imp = AssetImporter.GetAtPath(path) as TextureImporter;
            if (imp == null)
            {
                report.Add("MISSING importer " + path);
                return 0;
            }

            imp.textureType = TextureImporterType.Sprite;
            imp.spriteImportMode = mode;
            imp.spritePixelsPerUnit = Ppu;
            imp.maxTextureSize = maxSize;
            imp.textureCompression = compression;
            imp.compressionQuality = 100;
            imp.filterMode = FilterMode.Bilinear;
            imp.mipmapEnabled = false;
            imp.wrapMode = TextureWrapMode.Clamp;
            imp.npotScale = TextureImporterNPOTScale.None;
            imp.alphaIsTransparency = true;
            imp.isReadable = readable;
            imp.crunchedCompression = false;

            var s = new TextureImporterSettings();
            imp.ReadTextureSettings(s);
            s.spriteMeshType = SpriteMeshType.FullRect;
            s.spriteExtrude = 1;
            s.spriteGenerateFallbackPhysicsShape = false;
            s.spriteAlignment = (int)SpriteAlignment.Custom;
            s.spritePivot = pivot;
            imp.SetTextureSettings(s);
            imp.SaveAndReimport();

            report.Add(string.Format("OK {0} ppu={1} max={2} pivot=({3:0.###},{4:0.###})", path, Ppu, maxSize, pivot.x, pivot.y));
            return 1;
        }

        static int ConfigureSheet(string path, int cellW, int cellH, Vector2 pivot, List<string> report)
        {
            var imp = AssetImporter.GetAtPath(path) as TextureImporter;
            if (imp == null)
            {
                report.Add("MISSING importer " + path);
                return 0;
            }

            var tex = new Texture2D(2, 2);
            if (!ImageConversion.LoadImage(tex, File.ReadAllBytes(path), false))
            {
                report.Add("UNREADABLE " + path);
                return 0;
            }
            int frames = Mathf.Max(1, tex.width / cellW);
            UnityEngine.Object.DestroyImmediate(tex);

            imp.textureType = TextureImporterType.Sprite;
            imp.spriteImportMode = SpriteImportMode.Multiple;
            imp.spritePixelsPerUnit = Ppu;
            imp.maxTextureSize = DefaultMaxSize;
            imp.textureCompression = TextureImporterCompression.Uncompressed;
            imp.compressionQuality = 100;
            imp.filterMode = FilterMode.Bilinear;
            imp.mipmapEnabled = false;
            imp.wrapMode = TextureWrapMode.Clamp;
            imp.npotScale = TextureImporterNPOTScale.None;
            imp.alphaIsTransparency = true;

            var s = new TextureImporterSettings();
            imp.ReadTextureSettings(s);
            s.spriteMode = (int)SpriteImportMode.Multiple;
            s.spriteMeshType = SpriteMeshType.FullRect;
            s.spriteExtrude = 1;
            s.spriteGenerateFallbackPhysicsShape = false;
            imp.SetTextureSettings(s);

            // Uniform cells keep the animation from jittering; the pivot is identical
            // for every frame so the feet stay on the floor line.
#pragma warning disable 618
            var metas = new SpriteMetaData[frames];
            for (int i = 0; i < frames; i++)
            {
                metas[i] = new SpriteMetaData
                {
                    name = Path.GetFileNameWithoutExtension(path) + "_" + i,
                    rect = new Rect(i * cellW, 0, cellW, cellH),
                    alignment = (int)SpriteAlignment.Custom,
                    pivot = pivot,
                    border = Vector4.zero
                };
            }
            imp.spritesheet = metas;
#pragma warning restore 618
            imp.SaveAndReimport();

            report.Add(string.Format("OK {0} frames={1} cell={2}x{3} pivot=({4:0.###},{5:0.###})", path, frames, cellW, cellH, pivot.x, pivot.y));
            return 1;
        }

        /// <summary>Height, in pixels, of the fully transparent band at the bottom of a PNG.</summary>
        static int AlphaBottomGap(string path)
        {
            var tex = new Texture2D(2, 2);
            if (!ImageConversion.LoadImage(tex, File.ReadAllBytes(path), false))
            {
                UnityEngine.Object.DestroyImmediate(tex);
                return 0;
            }
            var px = tex.GetPixels32();
            int w = tex.width, h = tex.height;
            UnityEngine.Object.DestroyImmediate(tex);

            for (int y = 0; y < h; y++)
            {
                int row = y * w;
                for (int x = 0; x < w; x++)
                {
                    if (px[row + x].a / 255f > AlphaThreshold) return y;
                }
            }
            return 0;
        }

        static int ImageHeight(string path)
        {
            var bytes = File.ReadAllBytes(path);
            var tex = new Texture2D(2, 2);
            bool loaded = ImageConversion.LoadImage(tex, bytes, false);
            int h = loaded ? tex.height : 1;
            UnityEngine.Object.DestroyImmediate(tex);
            return h;
        }
    }
}
