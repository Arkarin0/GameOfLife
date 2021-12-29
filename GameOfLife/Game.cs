using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife
{
    public class Game
    {
        object _lockIteration = new object();

        public int Width { get; }

        public int Height { get; }

        public bool[,] Map { get; private set; }

        public Ruleset CurrentRules { get; set; }


        public Game(int width, int height)
        {
            this.Map = new bool[width, height];
            this.Width = width;
            this.Height = height;
        }

        public void NetxtIteration()
        {
            if (this.CurrentRules == null) throw new ArgumentNullException(nameof(this.CurrentRules));

            int width = this.Width, height = this.Height;
            var mapNew = new bool[width, height];
            lock (this._lockIteration)
            {
                var temp = (bool[,])Map.Clone();

                mapNew = this.CurrentRules.ApplyRules(temp, width, height);
            }
            this.Map = mapNew;
        }

        public void SetSettlement(bool[,] settlement, Location location)
        {
            if (settlement == null) throw new ArgumentNullException(nameof(settlement));

            int width = settlement.GetLength(0), height = settlement.GetLength(1);

            int destinationX = 0, destinationY = 0;


            lock (this._lockIteration)
            {
                var map = this.Map;

                map.ForXYAt(location, width, height, result =>
                {
                    map[result.arrayX, result.arrayY] = settlement[result.x, result.y];
                });

            }
        }

        public void Genozid()
        {
            lock (this._lockIteration)
            {
                this.Map = new bool[Width, Height];

            }
        }

        public static void GeneratePopulation(Game game, int count = -1, params bool[][,] templates)
        {
            
            Random rdm = new Random();

            int templatecount = templates?.Count() ?? -1;

            var settlements = count < 0 ? rdm.Next(3, 10) : count;

            for (int i = 0; i < settlements; i++)
            {
                var template = templatecount > 0 ? templates.ElementAt(rdm.Next(templatecount)) : Settlement.Ring3x3;

                Location location = new Location(rdm.Next(game.Width), rdm.Next(game.Height));

                game.SetSettlement(template, location);
            }
        }

    }
}
