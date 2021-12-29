using GameOfLife.Graphics2D;
using GameOfLife.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife.Rules
{
    public class CopyRuleset : Ruleset
    {
        public override bool[,] ApplyRules(bool[,] map, int width, int height)
        {
            var result = new bool[width, height];

            map.ForXY((location) =>
            {
                int neightbors = this.Count(map, new Location(location.x, location.y));

                bool isAlive = map[location.x, location.y];

                //rules
                isAlive = neightbors % 2 != 0;
                //at 0,2,4,6,8 dying/death
                //at 1,3,5,7,9 stay alive / born



                result[location.x, location.y] = isAlive;
            });

            return result;
        }
    }
}

