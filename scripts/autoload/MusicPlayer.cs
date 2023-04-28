using Godot;
using GodotUtilities;

namespace Game.Autoload
{
    [Scene]
    public partial class MusicPlayer : Node
    {
        [Node]
        private AudioStreamPlayer audioStreamPlayer;
        [Node]
        private Timer timer;

        public override void _Notification(int what)
        {
            if (what == NotificationSceneInstantiated)
            {
                WireNodes();
            }
        }

        public override void _Ready()
        {
            audioStreamPlayer.Connect("finished", new Callable(this, nameof(OnFinished)));
            timer.Connect("timeout", new Callable(this, nameof(OnTimeout)));
        }

        private void OnTimeout()
        {
            audioStreamPlayer.Play();
        }

        private void OnFinished()
        {
            timer.Start();
        }
    }
}
