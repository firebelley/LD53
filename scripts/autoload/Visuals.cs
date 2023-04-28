using Godot;

namespace Game.Autoload
{
    public partial class Visuals : Node
    {
        [Export]
        private Color clearColor;

        public override void _EnterTree()
        {
            RenderingServer.SetDefaultClearColor(clearColor);
        }
    }
}
