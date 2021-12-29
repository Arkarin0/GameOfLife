using GameOfLife.Graphics2D;
using GameOfLife.Rules;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace GameOfLife
{
    class Program
    {
        static Location CursorStartLocation;
        static object printLock = new object();

        static void Main(string[] args)
        {
            int width = 50, height = 50;
            bool pause = false;


            var game = new Game(width, height);
            game.CurrentRules = new ConvayRuleset();
            //game.CurrentRules = new CopyRuleset();

            Game.GeneratePopulation(game, 3);

            Console.Write("Iterration: ");
            var IterationPos = new Location(Console.CursorLeft, Console.CursorTop);
            var itereration = 0;
            void PrintIteration()
            {
                lock (printLock)
                {
                    SetCursor(IterationPos);
                    Console.WriteLine("{0,10:##########}", itereration);
                }
            }
            PrintIteration();

            void Iterate()
            {
                game.NetxtIteration();
                itereration++;
                Print(game);
                PrintIteration();
            }

            Console.Write("Speed (ms): ");
            var speedPos = new Location(Console.CursorLeft, Console.CursorTop);
            int speed = 200;
            void PrintSpeed()
            {
                lock (printLock)
                {
                    SetCursor(speedPos);
                    Console.WriteLine("{0,10:##########}", speed);
                }
            }
            PrintSpeed();
            Console.WriteLine();
            Console.WriteLine();

            CursorStartLocation = new Location(Console.CursorLeft, Console.CursorTop);
            PrepareConsoleforGameField(game.Width + 10, game.Height + speedPos.Y + 10);

            CancellationTokenSource source = new CancellationTokenSource();
            CancellationToken cancellationToken = source.Token;

            //game
            Task.Factory.StartNew(() =>
            {
                while (!cancellationToken.IsCancellationRequested)
                {
                    if (!pause)
                    {
                        Iterate();
                    }
                    Thread.Sleep(speed);
                }
            }, cancellationToken);


            //user interface
            ConsoleKeyInfo lastKey = new ConsoleKeyInfo();
            do
            {
                bool pausestate = pause;
                switch (lastKey.Key)
                {
                    case ConsoleKey.Spacebar: pause = !pause; break;
                    case ConsoleKey.Q: source.Cancel(); break;
                    case ConsoleKey.N:
                        pause = true;
                        {
                            game.Genozid();
                            Game.GeneratePopulation(game, count: -1, Settlement.R_Pentomino, Settlement.Corss3x3, Settlement.Ring3x3);
                            Print(game);
                            itereration = 0;
                            PrintIteration();
                        }
                        pause = pausestate;
                        break;

                    case ConsoleKey.F:
                        pause = true;
                        {
                            game.Genozid();
                            Game.GeneratePopulation(game, count: 1, Settlement.R_Pentomino);
                            Print(game);
                            itereration = 0;
                            PrintIteration();
                        }
                        pause = pausestate;
                        break;
                    case ConsoleKey.RightArrow:
                        if (pause)
                        {
                            Iterate();
                        }
                        break;
                    case ConsoleKey.UpArrow:
                        speed = (int)((double)speed * 0.75);
                        if (speed <= 0) speed = 1;
                        PrintSpeed(); break;//faster=> reduce sleep
                    case ConsoleKey.DownArrow:
                        var oldspeed = speed;
                        speed = (int)((double)speed * 1.25);
                        if (speed == oldspeed) speed++;
                        PrintSpeed(); break;//slower => increase sleep
                    default: break;
                }

                lastKey = Console.ReadKey();
            } while (lastKey.Key != ConsoleKey.Q);



        }



        static void Print(Game game)
        {
            lock (printLock)
            {
                var foreground = Console.ForegroundColor;
                var background = Console.BackgroundColor;

                Console.ForegroundColor = ConsoleColor.Black;
                Console.BackgroundColor = ConsoleColor.Gray;
                for (int y = 0; y < game.Height; y++)
                    for (int x = 0; x < game.Width; x++)
                    {
                        Console.SetCursorPosition(CursorStartLocation.X + x, CursorStartLocation.Y + y);
                        Console.Write(game.Map[x, y] ? "#" : " ");
                    }

                Console.ForegroundColor = foreground;
                Console.BackgroundColor = background;
            }
        }

        static void PrepareConsoleforGameField(int width, int height)
        {
            //Console.WindowHeight = height;
            //Console.WindowWidth = width;
            Console.SetWindowSize(width, height);
            Console.CursorVisible = false;

            //char[] empty = new char[width];
            //for (int y = 0; y < height; y++)
            //{
            //    Console.WriteLine(empty);
            //}

        }

        public static void SetCursor(Location location)
        {
            Console.SetCursorPosition(location.X, location.Y);
        }
    }
}
