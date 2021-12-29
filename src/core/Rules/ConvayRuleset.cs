using GameOfLife.Graphics2D;
using GameOfLife.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife.Rules
{
    public class ConvayRuleset : Ruleset
    {
        public override bool[,] ApplyRules(bool[,] map, int width, int height)
        {
            var result = new bool[width, height];

            map.ForXY((location) => 
            {
                int neightbors = this.Count(map, new Location(location.x, location.y));

                bool isAlive = map[location.x, location.y];

                //rules
                if (!isAlive && neightbors == 3) isAlive = true;
                else if (isAlive && neightbors >= 2 && neightbors <= 3) isAlive = isAlive;
                else isAlive = false;



                result[location.x, location.y] = isAlive;
            });

            return result;
        }


    }
}
