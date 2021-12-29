using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GameOfLife
{
    public static class Extensions
    {
        public static bool TryGetAt<T>(this T[,] array, Location location, out T value)
        {
            if (array == null) throw new ArgumentNullException(nameof(array));

            int width = array.GetLength(0), height = array.GetLength(1);

            int destinationX = location.X,
                destinationY = location.Y ; ;

            bool result = destinationX > 0 && destinationX <= width && destinationY > 0 && destinationY <= height;

            value = result ? array[destinationX, destinationY] : default(T);

            return result;
        }

        public static void ForXYAt<T>(this T[,] array, Location location, int width, int height, Action<(int x,int y, int arrayX, int arrayY)> action)
        {
            if (array == null) throw new ArgumentNullException(nameof(array));

            int srcWidth = array.GetLength(0), srcHeight = array.GetLength(1);

            int destinationX = 0, destinationY = 0;

            for (int y = 0; y < height; y++)
            {
                destinationY = location.Y + y;
                if (destinationY < 0 || destinationY>= srcHeight) continue;

                for (int x = 0; x < width; x++)
                {
                    destinationX = location.X + x;
                    if (destinationX < 0 || destinationX >= srcWidth) continue;

                    action?.Invoke((x, y, destinationX, destinationY));
                }
            }
        }

        public static void ForXY<T>(this T[,] array, Action<(int x, int y)> action)
        {
            if (array == null) throw new ArgumentNullException(nameof(array));

            int srcWidth = array.GetLength(0), srcHeight = array.GetLength(1);

            for (int y = 0; y < srcHeight; y++)
            {
                for (int x = 0; x < srcWidth; x++)
                {
                    action?.Invoke((x, y));
                }
            }
        }
    }
}
