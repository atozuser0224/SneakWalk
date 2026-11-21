using System.Collections.Generic;
using UnityEngine;

namespace SneakWalk
{
    /// <summary>
    /// Filled by the editor scene builder so runtime code never calls AssetDatabase.
    /// Keys are asset-relative paths without the extension, e.g. "Art/Props/myRoom/bed".
    /// </summary>
    public class SpriteLibrary : MonoBehaviour
    {
        [System.Serializable]
        public class Entry
        {
            public string key;
            public Sprite sprite;
        }

        public Entry[] entries = new Entry[0];
        public Entry[] playerFrames = new Entry[0];

        Dictionary<string, Sprite> map;
        Sprite[] frames;

        void Build()
        {
            if (map != null) return;
            map = new Dictionary<string, Sprite>();
            foreach (var e in entries)
            {
                if (e != null && !string.IsNullOrEmpty(e.key) && e.sprite != null) map[e.key] = e.sprite;
            }
            frames = new Sprite[playerFrames.Length];
            for (int i = 0; i < playerFrames.Length; i++)
            {
                frames[i] = playerFrames[i] != null ? playerFrames[i].sprite : null;
            }
        }

        public Sprite Get(string key)
        {
            Build();
            Sprite s;
            return map.TryGetValue(key, out s) ? s : null;
        }

        public Sprite Frame(int index)
        {
            Build();
            if (frames.Length == 0) return null;
            return frames[((index % frames.Length) + frames.Length) % frames.Length];
        }

        public int FrameCount
        {
            get { Build(); return frames.Length; }
        }
    }
}
