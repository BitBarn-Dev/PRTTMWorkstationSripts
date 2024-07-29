#!/bin/bash
/usr/bin/x0vncserver -display :0 -rfbauth /etc/tigervnc.pass -rfbport 5900 -forever -bg
