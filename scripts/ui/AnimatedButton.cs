using Godot;
using GodotUtilities;

namespace Game.UI
{
    [Scene]
    public partial class AnimatedButton : Button
    {
        [Node]
        private AnimationPlayer animationPlayer;

        public override void _Notification(int what)
        {
            if (what == NotificationSceneInstantiated)
            {
                WireNodes();
            }
        }

        public override void _Ready()
        {
            Connect("pressed", new Callable(this, nameof(OnPressed)));
        }

        public override void _Process(double delta)
        {
            PivotOffset = Size / 2f;
        }

        private void OnPressed()
        {
            if (animationPlayer.IsPlaying())
            {
                animationPlayer.Seek(0f, true);
                animationPlayer.Stop();
            }
            animationPlayer.Play("default");
        }
    }
}
