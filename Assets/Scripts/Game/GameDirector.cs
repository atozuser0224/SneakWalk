using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

namespace SneakWalk
{
    /// <summary>
    /// Chapter 1: 내 방 → 거실 → 부엌 → 물 마시기 → 거실 → 내 방.
    /// The character walks by itself; the metronome marks stop beats and the player
    /// has to click on them to halt. Missing one creaks the floorboard, clicking on
    /// a sounding beat is a stray footstep. Noise above 100, or running out of time,
    /// ends the run.
    /// </summary>
    public class GameDirector : MonoBehaviour
    {
        public SpriteLibrary sprites;
        public GameUI ui;

        public RunPhase Phase { get { return phase; } }
        public float Noise { get { return noise; } }
        public float TimeLeft { get { return Mathf.Max(0f, GameConfig.TimeLimitSeconds - runTime); } }
        public RoomId CurrentRoom { get { return room; } }
        public int SinkCombo { get { return sinkCombo; } }
        public bool Drank { get { return drank; } }
        public float PlayerX { get { return playerX; } }
        public bool SinkRitual { get { return sinkRitual; } }
        public double StopUntilDsp { get { return stopUntilDsp; } }
        public bool Succeeded { get; private set; }
        public string ResultReason { get; private set; }

        /// <summary>Time on the rhythm clock's timeline (falls back to DSP audio time).</summary>
        public double NowDsp { get { return clock != null ? clock.Now : AudioSettings.dspTime; } }

        RhythmClock clock;
        Camera cam;

        RunPhase phase = RunPhase.Menu;
        RoomId room = RoomId.MyRoom;
        float playerX = PropCatalog.BedX;
        int dir = 1;
        float speed = GameConfig.WalkSpeed;

        float noise;
        float runTime;
        bool drank;
        bool sinkRitual;
        int sinkCombo;

        double stopUntilDsp;
        long stoppedRestBeat = -1;
        float stumbleUntil;

        readonly List<GameObject> roomRoots = new List<GameObject>();
        GameObject playerGo;
        SpriteRenderer playerSr;
        bool booted;

        void Start()
        {
            if (cam == null) cam = Camera.main;
            if (clock == null) clock = GetComponent<RhythmClock>();
            if (clock != null && !booted)
            {
                booted = true;
                Boot(cam, clock);
            }
            EnterMenu();
        }

        public void Boot(Camera camera, RhythmClock rhythm)
        {
            cam = camera;
            clock = rhythm;
            if (clock != null) clock.Beat += OnBeat;
            booted = true;
        }

        void OnDestroy()
        {
            if (clock != null) clock.Beat -= OnBeat;
        }

        // ------------------------------------------------------------------ flow

        public void EnterMenu()
        {
            phase = RunPhase.Menu;
            if (clock != null) clock.Halt();
            ClearWorld();
            ShowMenuUI();
        }

        public void StartRun()
        {
            phase = RunPhase.Playing;
            room = RoomId.MyRoom;
            playerX = PropCatalog.BedX;
            dir = 1;
            speed = GameConfig.WalkSpeed;
            noise = 0f;
            runTime = 0f;
            drank = false;
            sinkRitual = false;
            sinkCombo = 0;
            stopUntilDsp = 0;
            stoppedRestBeat = -1;
            stumbleUntil = 0f;

            BuildWorld();
            ShowHudUI();
            if (clock != null) clock.Begin();
        }

        void Finish(bool success, string reason)
        {
            phase = RunPhase.Result;
            Succeeded = success;
            ResultReason = reason;
            if (clock != null) clock.Halt();
            // The result panel is text over a dimmed scene; hiding the room keeps it readable.
            SetWorldVisible(false);
            ShowResultUI(success, reason);
        }

        void SetWorldVisible(bool visible)
        {
            foreach (var go in roomRoots) if (go != null) go.SetActive(visible);
            if (playerGo != null) playerGo.SetActive(visible);
        }

        // ------------------------------------------------------------------ world

        void ClearWorld()
        {
            foreach (var go in roomRoots) if (go != null) Destroy(go);
            roomRoots.Clear();
            if (playerGo != null) Destroy(playerGo);
            playerGo = null;
            playerSr = null;
        }

        void BuildWorld()
        {
            ClearWorld();
            foreach (RoomId id in new[] { RoomId.MyRoom, RoomId.LivingRoom, RoomId.Kitchen })
            {
                var root = new GameObject("Room_" + id);
                root.transform.position = new Vector3(RoomBase(id), 0f, 0f);

                var bg = new GameObject("Background");
                bg.transform.SetParent(root.transform, false);
                var bgSr = bg.AddComponent<SpriteRenderer>();
                bgSr.sprite = sprites != null ? sprites.Get(PropCatalog.BackgroundKey(id)) : null;
                bgSr.sortingOrder = 0;
                bg.transform.localPosition = new Vector3(GameConfig.RoomWidth * 0.5f, GameConfig.BackgroundBottomY, 0f);

                foreach (var p in PropCatalog.ForRoom(id))
                {
                    var sprite = sprites != null ? sprites.Get(p.Key) : null;
                    if (sprite == null) { Debug.LogWarning("[SneakWalk] missing prop sprite " + p.Key); continue; }
                    var go = new GameObject(p.Key);
                    go.transform.SetParent(root.transform, false);
                    var sr = go.AddComponent<SpriteRenderer>();
                    sr.sprite = sprite;
                    sr.sortingOrder = p.Order;
                    go.transform.localScale = new Vector3(p.Scale, p.Scale, 1f);
                    go.transform.localPosition = new Vector3(p.X, GameConfig.FloorY + p.FloorOffset, 0f);
                }

                roomRoots.Add(root);
            }

            playerGo = new GameObject("Player");
            playerSr = playerGo.AddComponent<SpriteRenderer>();
            playerSr.sortingOrder = 30;
            playerSr.sprite = sprites != null ? sprites.Frame(0) : null;
            UpdatePlayerTransform();
        }

        static float RoomBase(RoomId id)
        {
            return (int)id * GameConfig.RoomWidth;
        }

        void UpdatePlayerTransform()
        {
            if (playerGo == null) return;
            playerGo.transform.position = new Vector3(RoomBase(room) + playerX, GameConfig.FloorY, 0f);
            playerSr.flipX = dir < 0;
        }

        // ------------------------------------------------------------------ beats

        void OnBeat(long beat)
        {
            if (phase != RunPhase.Playing) return;

            if (playerSr != null && sprites != null && sprites.FrameCount > 0)
                playerSr.sprite = sprites.Frame((int)(beat % sprites.FrameCount));

            if (sinkRitual) return;

            if (GameConfig.IsRestBeat(beat) && beat != stoppedRestBeat)
            {
                AddNoise(GameConfig.NoiseMissedStop);
                stumbleUntil = Time.time + 0.12f;
                Flash("삐걱", new Color(1f, 0.45f, 0.35f));
            }
        }

        // ------------------------------------------------------------------ update

        void Update()
        {
            if (phase == RunPhase.Menu) { HandleMenuInput(); return; }
            if (phase == RunPhase.Result) { HandleResultInput(); return; }

            runTime += Time.deltaTime;
            if (runTime >= GameConfig.TimeLimitSeconds)
            {
                Finish(false, "시간 초과\n어머니가 불을 켰다");
                return;
            }

            bool stopped = NowDsp < stopUntilDsp || sinkRitual;
            float decay = stopped ? GameConfig.DecayWhileStopped : GameConfig.DecayWhileWalking;
            noise = Mathf.Clamp(noise - decay * Time.deltaTime, 0f, GameConfig.MaxNoise);

            if (noise >= GameConfig.MaxNoise) { Finish(false, "어머니가 들켰다"); return; }

            if (!sinkRitual) Advance();

            float camX = RoomBase(room) + Mathf.Clamp(playerX, 9.6f, GameConfig.RoomWidth - 9.6f);
            if (cam != null) cam.transform.position = new Vector3(camX, 0f, -10f);

            HandlePlayInput();
            UpdatePlayerTransform();
            if (ui != null) ui.UpdateHud(this);
        }

        void Advance()
        {
            if (NowDsp < stopUntilDsp) return;
            if (Time.time < stumbleUntil) return;

            playerX += dir * speed * Time.deltaTime;

            if (dir > 0 && !drank && room == RoomId.Kitchen && playerX >= PropCatalog.SinkX)
            {
                playerX = PropCatalog.SinkX;
                sinkRitual = true;
                sinkCombo = 0;
                return;
            }

            if (drank && room == RoomId.MyRoom && playerX <= PropCatalog.BedX)
            {
                Finish(true, "물을 마시고 돌아왔다");
                return;
            }

            if (dir < 0 && playerX < 1f)
            {
                if ((int)room == 0) { playerX = 1f; return; }
                room = (RoomId)((int)room - 1);
                playerX = GameConfig.RoomWidth - 1f;
            }
            else if (dir > 0 && playerX > GameConfig.RoomWidth - 1f)
            {
                if ((int)room == 2) { playerX = GameConfig.RoomWidth - 1f; return; }
                room = (RoomId)((int)room + 1);
                playerX = 1f;
            }
        }

        // ------------------------------------------------------------------ input

        void HandlePlayInput()
        {
            if (!PressedThisFrame()) return;
            PressAt(NowDsp);
        }

        /// <summary>
        /// Judgement entry point. Public and time-explicit so tests can drive it
        /// without a real mouse.
        /// </summary>
        public void PressAt(double pressDsp)
        {
            if (phase != RunPhase.Playing || clock == null) return;

            long beat;
            double delta;
            StopGrade grade;

            if (!clock.TryFindStopBeat(pressDsp, out beat, out delta, out grade))
            {
                AddNoise(GameConfig.NoiseStrayTap);
                if (sinkRitual) sinkCombo = 0;
                Flash("헛발", new Color(1f, 0.78f, 0.3f));
                return;
            }

            if (sinkRitual)
            {
                if (grade == StopGrade.Perfect)
                {
                    sinkCombo++;
                    AddNoise(GameConfig.NoiseCleanStop);
                    Flash("조용히 " + sinkCombo + "/" + GameConfig.SinkStopsRequired, new Color(0.55f, 0.95f, 0.65f));
                    if (sinkCombo >= GameConfig.SinkStopsRequired) Drink();
                }
                else
                {
                    sinkCombo = 0;
                    AddNoise(GameConfig.NoiseSloppyStop);
                    Flash("연속 끊김", new Color(1f, 0.78f, 0.3f));
                }
                return;
            }

            stoppedRestBeat = beat;
            stopUntilDsp = clock.BeatTime(beat) + GameConfig.SecondsPerBeat * GameConfig.StopHoldBeats;
            AddNoise(grade == StopGrade.Perfect ? GameConfig.NoiseCleanStop : GameConfig.NoiseSloppyStop);
            if (grade == StopGrade.Perfect) Flash("정지", new Color(0.55f, 0.95f, 0.65f));
            else Flash("간신히 정지", new Color(1f, 0.85f, 0.4f));
        }

        void Drink()
        {
            drank = true;
            sinkRitual = false;
            sinkCombo = 0;
            dir = -1;
            speed = GameConfig.WalkSpeedAfterDrink;
            Flash("물을 마셨다. 돌아가자", new Color(0.6f, 0.85f, 1f));
        }

        static bool PressedThisFrame()
        {
            var mouse = Mouse.current;
            if (mouse != null && mouse.leftButton.wasPressedThisFrame) return true;
            var kb = Keyboard.current;
            if (kb != null && (kb.spaceKey.wasPressedThisFrame || kb.enterKey.wasPressedThisFrame)) return true;
            return false;
        }

        void HandleMenuInput()
        {
            var kb = Keyboard.current;
            var mouse = Mouse.current;
            if (kb != null && (kb.spaceKey.wasPressedThisFrame || kb.enterKey.wasPressedThisFrame)) { StartRun(); return; }
            if (mouse != null && mouse.leftButton.wasPressedThisFrame && ui != null)
            {
                var hit = ui.MenuHitTest(mouse.position.ReadValue());
                if (hit == GameUI.MenuAction.Start) StartRun();
                else if (hit == GameUI.MenuAction.Settings) ui.ToggleSettings();
                else if (hit == GameUI.MenuAction.Exit) QuitGame();
            }
        }

        void HandleResultInput()
        {
            var kb = Keyboard.current;
            if (kb == null) return;
            if (kb.rKey.wasPressedThisFrame || kb.spaceKey.wasPressedThisFrame) StartRun();
            if (kb.escapeKey.wasPressedThisFrame || kb.mKey.wasPressedThisFrame) EnterMenu();
        }

        void QuitGame()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }

        // ------------------------------------------------------------------ noise

        public void AddNoise(float amount)
        {
            noise = Mathf.Clamp(noise + amount * GameConfig.RoomNoiseFactor(room), 0f, GameConfig.MaxNoise);
        }

        // ------------------------------------------------------------- ui glue

        void ShowMenuUI() { if (ui != null) ui.ShowMenu(); }
        void ShowHudUI() { if (ui != null) ui.ShowHud(); }
        void ShowResultUI(bool success, string reason) { if (ui != null) ui.ShowResult(success, reason, runTime, noise); }
        void Flash(string text, Color color) { if (ui != null) ui.FlashJudgement(text, color); }
    }
}
