using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife
{
    public struct Location
    {
        public int X { get; }
        public int Y { get; }

        public Location(int x, int y)
        {
            this.X = x;
            this.Y = y;
        }
    }
}
