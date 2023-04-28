using Godot;
using GodotUtilities;

namespace Game
{
    [Scene]
    public partial class OptionsMenu : CanvasLayer
    {
        [Node]
        private HSlider SFXSlider;
        [Node]
        private HSlider musicSlider;
        [Node]
        private Button backButton;
        [Node]
        private Button windowButton;
        [Node]
        private Control windowContainer;

        public override void _Notification(int what)
        {
            if (what == NotificationSceneInstantiated)
            {
                WireNodes();
            }
        }

        public override void _Ready()
        {
            SFXSlider.Value = GetBusVolume("sfx");
            musicSlider.Value = GetBusVolume("music");

            SFXSlider.Connect("value_changed", new Callable(this, nameof(OnSfxChanged)));
            musicSlider.Connect("value_changed", new Callable(this, nameof(OnMusicChanged)));
            backButton.Connect("pressed", new Callable(this, nameof(OnBackButtonPressed)));
            windowButton.Connect("pressed", new Callable(this, nameof(OnWindowButtonPressed)));

            UpdateText();

            if (OS.HasFeature("HTML5"))
            {
                windowContainer.QueueFree();
            }
        }

        private void UpdateText()
        {
            // windowButton.Text = OS. ? "Fullscreen" : "Windowed";
        }

        private float GetBusVolume(string busName)
        {
            var busIdx = AudioServer.GetBusIndex(busName);
            var dbVol = AudioServer.GetBusVolumeDb(busIdx);
            var percent = Mathf.DbToLinear(dbVol);
            return percent;
        }

        private void SetBusVolume(string busName, float percent)
        {
            var busIdx = AudioServer.GetBusIndex(busName);
            var db = Mathf.LinearToDb(percent);
            AudioServer.SetBusVolumeDb(busIdx, db);
        }

        private void OnSfxChanged(float val)
        {
            SetBusVolume("sfx", val);
        }

        private void OnMusicChanged(float val)
        {
            SetBusVolume("music", val);
        }

        private async void OnBackButtonPressed()
        {
            GetNode("/root/ScreenTransition").Call("transition");
            await ToSignal(GetNode("/root/ScreenTransition"), "transitioned_halfway");
            QueueFree();
        }

        private void OnWindowButtonPressed()
        {
            // OS.WindowFullscreen = !OS.WindowFullscreen;
            UpdateText();
        }
    }
}
