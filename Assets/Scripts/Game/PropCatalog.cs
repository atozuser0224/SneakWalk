namespace SneakWalk
{
    public struct PropPlacement
    {
        public string Key;        // SpriteLibrary key
        public float X;           // room-local x, 0..GameConfig.RoomWidth
        public float FloorOffset; // units above the floor line (wall items use > 1)
        public float Scale;       // runtime correction, source PNGs are not edited
        public int Order;

        public PropPlacement(string key, float x, float floorOffset, float scale, int order = 10)
        {
            Key = key;
            X = x;
            FloorOffset = floorOffset;
            Scale = scale;
            Order = order;
        }
    }

    /// <summary>
    /// Chapter 1 layout. Scales compensate for prop art drawn at inconsistent sizes
    /// (sofa is 19.3 units wide, sink is 18.0 at 1:1). Source PNGs stay untouched:
    /// when the artist redraws a prop, the scale here drops back to 1.
    /// </summary>
    public static class PropCatalog
    {
        public const string PlayerPrefix = "Art/Characters/me/player";

        public static string BackgroundKey(RoomId room)
        {
            switch (room)
            {
                case RoomId.MyRoom: return "Art/Backgrounds/myRoom_background";
                case RoomId.LivingRoom: return "Art/Backgrounds/livingroom_background";
                case RoomId.Kitchen: return "Art/Backgrounds/kitchen_background";
                default: return "Art/Backgrounds/myRoom_background";
            }
        }

        public static string RoomLabel(RoomId room)
        {
            switch (room)
            {
                case RoomId.MyRoom: return "내 방";
                case RoomId.LivingRoom: return "거실";
                case RoomId.Kitchen: return "부엌";
                default: return "?";
            }
        }

        public static PropPlacement[] ForRoom(RoomId room)
        {
            switch (room)
            {
                case RoomId.MyRoom:
                    return new[]
                    {
                        new PropPlacement("Art/Props/myRoom/bed", 6.5f, 0f, 0.38f),
                        new PropPlacement("Art/Props/myRoom/desk", 12.5f, 0f, 0.51f),
                        new PropPlacement("Art/Props/myRoom/dresser", 17.0f, 0f, 0.62f),
                        new PropPlacement("Art/Props/myRoom/mirror", 20.5f, 0f, 0.77f),
                        new PropPlacement("Art/Props/myRoom/pictures", 25.0f, 2.4f, 0.45f),
                        new PropPlacement("Art/Props/myRoom/calendar", 30.0f, 2.5f, 0.42f)
                    };
                case RoomId.LivingRoom:
                    return new[]
                    {
                        new PropPlacement("Art/Props/livingroom/clock", 3.0f, 2.7f, 0.30f),
                        new PropPlacement("Art/Props/livingroom/sofa", 8.5f, 0f, 0.39f),
                        new PropPlacement("Art/Props/livingroom/coffeeTable", 14.0f, 0f, 0.22f),
                        new PropPlacement("Art/Props/livingroom/tv", 19.5f, 0f, 0.44f),
                        new PropPlacement("Art/Props/livingroom/shelf", 25.5f, 0f, 0.55f),
                        new PropPlacement("Art/Props/livingroom/plants", 30.5f, 0f, 0.40f),
                        new PropPlacement("Art/Props/livingroom/picture", 34.5f, 2.6f, 0.45f)
                    };
                case RoomId.Kitchen:
                    return new[]
                    {
                        new PropPlacement("Art/Props/kitchen/fridge", 5.5f, 0f, 0.83f),
                        new PropPlacement("Art/Props/kitchen/cabinet2", 12.0f, 0f, 0.54f),
                        new PropPlacement("Art/Props/kitchen/sink", 20.0f, 0f, 0.39f),
                        new PropPlacement("Art/Props/kitchen/hood", 20.0f, 3.3f, 0.55f),
                        new PropPlacement("Art/Props/kitchen/long_cabinet", 27.0f, 0f, 0.52f)
                    };
                default:
                    return new PropPlacement[0];
            }
        }

        /// <summary>Room-local x where the kitchen sink interaction starts.</summary>
        public const float SinkX = 20f;

        /// <summary>Room-local x of the bed the chapter starts and ends at.</summary>
        public const float BedX = 6.5f;
    }
}
