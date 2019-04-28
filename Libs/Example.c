
/*----------------------------------------------------------------------+
 |                                                                      |
 |      DemoLib.c -- Demonstrate ideas for standard library             |
 |                                                                      |
 +----------------------------------------------------------------------*/

#include <Gigatron.h>
#include <stdio.h>

/*----------------------------------------------------------------------+
 |      main                                                            |
 +----------------------------------------------------------------------*/

int main(void)
{
  byte color = 0;
  while (1) {
    BgColor = color++;
    ClearScreen();
    puts("Hello Gigatron! How are you today?");
  }
  return 0;
}

/*----------------------------------------------------------------------+
 |                                                                      |
 +----------------------------------------------------------------------*/

