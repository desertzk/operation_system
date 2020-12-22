#include "types.h"
#include "stat.h"
#include "user.h"

void periodic();

int
main(int argc, char *argv[])
{
  int i;
  printf(1, "alarmtest starting\n");
  alarm(10, periodic);//The program calls alarm(10, periodic) to ask the kernel to force a call to periodic() every 10 ticks, and then spins for a while.
  for(i = 0; i < 25*500000*10; i++){
    if((i % 250000) == 0)
      write(2, ".", 1);
  }
  exit();
}

void
periodic()
{
  printf(1, "alarm!\n");
}