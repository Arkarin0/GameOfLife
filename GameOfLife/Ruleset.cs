using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife
{
    public abstract class Ruleset
    {

        public abstract bool[,] ApplyRules(bool[,] map, int width, int height);

        protected virtual private int Count(bool[,] map, Location location)
        {
            int counter = 0;
            var filterPos = new Location(location.X - 1, location.Y - 1);
            map.ForXYAt(filterPos, 3, 3, (result) =>
            {
                if (result.arrayX == location.X && result.arrayY == location.Y) return;
                if (map[result.arrayX, result.arrayY]) counter++;
            });

            return counter;
        }
    }
}
