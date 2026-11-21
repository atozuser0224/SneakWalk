using UnityEngine;
using UnityEngine.UI;

namespace SneakWalk
{
    /// <summary>
    /// Runtime UI: title menu, chapter HUD and result panel. Everything is built in
    /// code so the scene file stays small and reviewable. Korean text uses the OS
    /// font (Malgun Gothic) because the project ships no font asset.
    /// </summary>
    public class GameUI : MonoBehaviour
    {
        public enum MenuAction { None, Start, Settings, Exit }

        public SpriteLibrary sprites;

        Font font;
        Canvas canvas;
        GameObject menuRoot;
        GameObject hudRoot;
        GameObject resultRoot;
        GameObject settingsPanel;

        RectTransform startButton;
        RectTransform settingButton;
        RectTransform exitButton;

        Image noiseFill;
        Text noiseLabel;
        Text timeLabel;
        Text roomLabel;
        Text objectiveLabel;
        Text judgementLabel;
        Text sinkLabel;
        Text resultTitle;
        Text resultBody;
        Text hintLabel;

        float judgementTimer;
        float hintTimer;

        static readonly Color Panel = new Color(0f, 0f, 0f, 0.45f);
        static readonly Color Good = new Color(0.55f, 0.95f, 0.65f);
        static readonly Color Warn = new Color(1f, 0.78f, 0.3f);
        static readonly Color Bad = new Color(1f, 0.45f, 0.35f);

        void Awake()
        {
            font = Font.CreateDynamicFontFromOSFont(new[] { "Malgun Gothic", "맑은 고딕", "Gulim", "Arial" }, 42);
            BuildCanvas();
            BuildMenu();
            BuildHud();
            BuildResult();
        }

        // ------------------------------------------------------------------ build

        void BuildCanvas()
        {
            var go = new GameObject("Canvas");
            go.transform.SetParent(transform, false);
            canvas = go.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            // Sprites use sorting orders up to 30; keep the UI above every one of them.
            canvas.sortingOrder = 100;
            var scaler = go.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;
            go.AddComponent<GraphicRaycaster>();
        }

        RectTransform NewRect(string name, Transform parent)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);
            return go.AddComponent<RectTransform>();
        }

        void Stretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
        }

        Text MakeText(Transform parent, string name, int size, TextAnchor anchor, Color color, Vector2 pos, Vector2 box)
        {
            var rt = NewRect(name, parent);
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.anchoredPosition = pos;
            rt.sizeDelta = box;
            var text = rt.gameObject.AddComponent<Text>();
            text.font = font;
            text.fontSize = size;
            text.alignment = anchor;
            text.color = color;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Overflow;
            return text;
        }

        void BuildMenu()
        {
            menuRoot = NewRect("Menu", canvas.transform).gameObject;
            Stretch((RectTransform)menuRoot.transform);

            var bgRt = NewRect("Title", menuRoot.transform);
            Stretch(bgRt);
            var bg = bgRt.gameObject.AddComponent<Image>();
            bg.sprite = sprites.Get("Art/Backgrounds/menu");
            bg.color = Color.white;

            startButton = NewButton(menuRoot.transform, "StartButton", "Art/Props/buttons/menu_start_button", new Vector2(0f, -250f), new Vector2(417f, 92f));
            settingButton = NewButton(menuRoot.transform, "SettingButton", "Art/Props/buttons/menu_setting_button", new Vector2(0f, -370f), new Vector2(416f, 89f));
            exitButton = NewButton(menuRoot.transform, "ExitButton", "Art/Props/buttons/menu_exit_button", new Vector2(760f, -460f), new Vector2(134f, 55f));

            var tip = MakeText(menuRoot.transform, "Tip", 26, TextAnchor.LowerCenter,
                new Color(1f, 1f, 1f, 0.75f), new Vector2(0f, 36f), new Vector2(1400f, 60f));
            var tipRt = (RectTransform)tip.transform;
            tipRt.anchorMin = new Vector2(0.5f, 0f);
            tipRt.anchorMax = new Vector2(0.5f, 0f);
            tipRt.pivot = new Vector2(0.5f, 0f);
            tip.text = "박자에 맞춰 클릭하면 조용히 멈춘다.  Space / Enter 로 시작";

            settingsPanel = NewRect("Settings", menuRoot.transform).gameObject;
            var spRt = (RectTransform)settingsPanel.transform;
            spRt.anchorMin = new Vector2(0.5f, 0.5f);
            spRt.anchorMax = new Vector2(0.5f, 0.5f);
            spRt.sizeDelta = new Vector2(900f, 420f);
            var spImg = settingsPanel.AddComponent<Image>();
            spImg.color = new Color(0.05f, 0.05f, 0.09f, 0.94f);
            var spText = MakeText(settingsPanel.transform, "SettingsText", 34, TextAnchor.MiddleCenter, Color.white, Vector2.zero, new Vector2(820f, 360f));
            spText.text = "설정\n\n음량은 시스템 볼륨을 사용한다.\n박자 표시는 넣지 않았다. 소리만 듣고 맞춘다.\n\n(닫기: 다시 클릭)";
            settingsPanel.SetActive(false);

            menuRoot.SetActive(false);
        }

        RectTransform NewButton(Transform parent, string name, string spriteKey, Vector2 pos, Vector2 size)
        {
            var rt = NewRect(name, parent);
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = sprites.Get(spriteKey);
            img.raycastTarget = false;
            return rt;
        }

        void BuildHud()
        {
            hudRoot = NewRect("Hud", canvas.transform).gameObject;
            Stretch((RectTransform)hudRoot.transform);

            var barBgRt = NewRect("NoiseBarBg", hudRoot.transform);
            barBgRt.anchorMin = new Vector2(0f, 1f);
            barBgRt.anchorMax = new Vector2(0f, 1f);
            barBgRt.pivot = new Vector2(0f, 1f);
            barBgRt.anchoredPosition = new Vector2(48f, -48f);
            barBgRt.sizeDelta = new Vector2(460f, 30f);
            var barBg = barBgRt.gameObject.AddComponent<Image>();
            barBg.color = new Color(0f, 0f, 0f, 0.6f);

            var fillRt = NewRect("NoiseFill", barBgRt);
            Stretch(fillRt);
            noiseFill = fillRt.gameObject.AddComponent<Image>();
            noiseFill.type = Image.Type.Filled;
            noiseFill.fillMethod = Image.FillMethod.Horizontal;
            noiseFill.fillOrigin = 0;
            noiseFill.fillAmount = 0f;
            noiseFill.color = Good;

            noiseLabel = MakeText(hudRoot.transform, "NoiseLabel", 30, TextAnchor.UpperLeft, Color.white,
                new Vector2(0f, 0f), new Vector2(460f, 40f));
            var nlRt = (RectTransform)noiseLabel.transform;
            nlRt.anchorMin = new Vector2(0f, 1f);
            nlRt.anchorMax = new Vector2(0f, 1f);
            nlRt.pivot = new Vector2(0f, 1f);
            nlRt.anchoredPosition = new Vector2(48f, -86f);

            timeLabel = MakeText(hudRoot.transform, "TimeLabel", 34, TextAnchor.UpperRight, Color.white,
                Vector2.zero, new Vector2(300f, 50f));
            var tRt = (RectTransform)timeLabel.transform;
            tRt.anchorMin = new Vector2(1f, 1f);
            tRt.anchorMax = new Vector2(1f, 1f);
            tRt.pivot = new Vector2(1f, 1f);
            tRt.anchoredPosition = new Vector2(-48f, -44f);

            roomLabel = MakeText(hudRoot.transform, "RoomLabel", 30, TextAnchor.UpperCenter, new Color(1f, 1f, 1f, 0.8f),
                Vector2.zero, new Vector2(500f, 40f));
            var rRt = (RectTransform)roomLabel.transform;
            rRt.anchorMin = new Vector2(0.5f, 1f);
            rRt.anchorMax = new Vector2(0.5f, 1f);
            rRt.pivot = new Vector2(0.5f, 1f);
            rRt.anchoredPosition = new Vector2(0f, -44f);

            objectiveLabel = MakeText(hudRoot.transform, "Objective", 34, TextAnchor.LowerCenter, Color.white,
                Vector2.zero, new Vector2(1500f, 60f));
            var oRt = (RectTransform)objectiveLabel.transform;
            oRt.anchorMin = new Vector2(0.5f, 0f);
            oRt.anchorMax = new Vector2(0.5f, 0f);
            oRt.pivot = new Vector2(0.5f, 0f);
            oRt.anchoredPosition = new Vector2(0f, 64f);

            sinkLabel = MakeText(hudRoot.transform, "SinkLabel", 30, TextAnchor.LowerCenter, Good,
                Vector2.zero, new Vector2(1200f, 50f));
            var sRt = (RectTransform)sinkLabel.transform;
            sRt.anchorMin = new Vector2(0.5f, 0f);
            sRt.anchorMax = new Vector2(0.5f, 0f);
            sRt.pivot = new Vector2(0.5f, 0f);
            sRt.anchoredPosition = new Vector2(0f, 124f);
            sinkLabel.text = string.Empty;

            judgementLabel = MakeText(hudRoot.transform, "Judgement", 44, TextAnchor.MiddleCenter, Good,
                new Vector2(0f, 150f), new Vector2(1200f, 70f));
            judgementLabel.text = string.Empty;

            hintLabel = MakeText(hudRoot.transform, "Hint", 28, TextAnchor.LowerCenter, new Color(1f, 1f, 1f, 0.7f),
                Vector2.zero, new Vector2(1400f, 50f));
            var hRt = (RectTransform)hintLabel.transform;
            hRt.anchorMin = new Vector2(0.5f, 0f);
            hRt.anchorMax = new Vector2(0.5f, 0f);
            hRt.pivot = new Vector2(0.5f, 0f);
            hRt.anchoredPosition = new Vector2(0f, 12f);
            hintLabel.text = "박자에 맞춰 클릭: 조용히 멈춘다";

            hudRoot.SetActive(false);
        }

        void BuildResult()
        {
            resultRoot = NewRect("Result", canvas.transform).gameObject;
            Stretch((RectTransform)resultRoot.transform);

            var bg = resultRoot.AddComponent<Image>();
            bg.color = new Color(0f, 0f, 0f, 0.78f);

            resultTitle = MakeText(resultRoot.transform, "Title", 84, TextAnchor.MiddleCenter, Color.white,
                new Vector2(0f, 120f), new Vector2(1400f, 120f));
            resultBody = MakeText(resultRoot.transform, "Body", 38, TextAnchor.MiddleCenter, new Color(0.9f, 0.9f, 0.95f),
                new Vector2(0f, -60f), new Vector2(1400f, 260f));

            resultRoot.SetActive(false);
        }

        // ------------------------------------------------------------------ api

        public void ShowMenu()
        {
            menuRoot.SetActive(true);
            hudRoot.SetActive(false);
            resultRoot.SetActive(false);
            settingsPanel.SetActive(false);
        }

        public void ShowHud()
        {
            menuRoot.SetActive(false);
            resultRoot.SetActive(false);
            hudRoot.SetActive(true);
            judgementLabel.text = string.Empty;
            sinkLabel.text = string.Empty;
            hintTimer = 4f;
            hintLabel.gameObject.SetActive(true);
        }

        public void ShowResult(bool success, string reason, float seconds, float noise)
        {
            hudRoot.SetActive(false);
            menuRoot.SetActive(false);
            resultRoot.SetActive(true);
            resultTitle.text = success ? "챕터 1 클리어" : "실패";
            resultTitle.color = success ? Good : Bad;
            resultBody.text = string.Format("{0}\n\n기록: {1:0.0}초   최종 소음: {2:0} / 100\n\nR 또는 Space: 다시 하기\nM 또는 Esc: 메뉴로", reason, seconds, noise);
        }

        public void FlashJudgement(string text, Color color)
        {
            judgementLabel.text = text;
            judgementLabel.color = color;
            judgementTimer = 0.7f;
        }

        public void ToggleSettings()
        {
            if (settingsPanel == null) return;
            settingsPanel.SetActive(!settingsPanel.activeSelf);
        }

        public MenuAction MenuHitTest(Vector2 screenPosition)
        {
            if (!menuRoot.activeSelf || settingsPanel.activeSelf) return MenuAction.None;
            if (Contains(startButton, screenPosition)) return MenuAction.Start;
            if (Contains(settingButton, screenPosition)) return MenuAction.Settings;
            if (Contains(exitButton, screenPosition)) return MenuAction.Exit;
            return MenuAction.None;
        }

        static bool Contains(RectTransform rt, Vector2 screenPosition)
        {
            return rt != null && RectTransformUtility.RectangleContainsScreenPoint(rt, screenPosition, null);
        }

        public void UpdateHud(GameDirector director)
        {
            float ratio = Mathf.Clamp01(director.Noise / GameConfig.MaxNoise);
            noiseFill.fillAmount = ratio;
            noiseFill.color = ratio < 0.4f ? Good : (ratio < 0.75f ? Warn : Bad);
            noiseLabel.text = "소음 " + Mathf.RoundToInt(director.Noise) + " / 100";
            timeLabel.text = Mathf.CeilToInt(director.TimeLeft) + "초";
            roomLabel.text = PropCatalog.RoomLabel(director.CurrentRoom);

            if (director.SinkCombo > 0)
                sinkLabel.text = "물 마시기: " + director.SinkCombo + " / " + GameConfig.SinkStopsRequired + " (Perfect 연속)";
            else
                sinkLabel.text = string.Empty;

            if (director.Drank)
                objectiveLabel.text = "내 방 침대로 돌아가라";
            else if (director.CurrentRoom == RoomId.Kitchen)
                objectiveLabel.text = "싱크대 앞에서 박자에 맞춰 3연속 멈추기";
            else
                objectiveLabel.text = "부엌으로 가서 물을 마셔라";
        }

        void Update()
        {
            if (judgementTimer > 0f)
            {
                judgementTimer -= Time.deltaTime;
                if (judgementTimer <= 0f) judgementLabel.text = string.Empty;
            }
            if (hintTimer > 0f)
            {
                hintTimer -= Time.deltaTime;
                if (hintTimer <= 0f) hintLabel.gameObject.SetActive(false);
            }
        }
    }
}
