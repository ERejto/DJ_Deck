echo "COMPILING"
rm *.vcd  *.o
iverilog -o test.o -g 2012 ../tb/*  ../src/* 

vvp test.o 

gtkwave test.vcd &

echo "CLEANING UP"
