install.packages('RCurl')
install.packages('devtools')

library(devtools)

install_github('rgbkrk/rzmq', ref='c++11')
install_github('takluyver/IRdisplay')
install_github('takluyver/IRkernel')

IRkernel::installspec()
