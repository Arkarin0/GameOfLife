using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife.Graphics2D
{
    public static class Settlement
    {
        public static bool[,] Corss3x3
        { get; }
        = new bool[,]
        {
            { false, true, false } ,
            { true,  true, true },
            { false, true, false } ,
        };

        public static bool[,] Ring3x3
        { get; }
= new bool[,]
{
            { true, true, true } ,
            { true,  false, true },
            { true, true, true } ,
};

        public static bool[,] R_Pentomino
        { get; }
= new bool[,]
{
            { false, true, false } ,
            { true,  true, true },
            { false, false, true } ,
};

    }
}
