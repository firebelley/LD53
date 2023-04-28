using Godot;

namespace Game
{
    public partial class Main : Node
    {
        public override void _EnterTree()
        {
            GD.Print("hello");
        }
    }
}
