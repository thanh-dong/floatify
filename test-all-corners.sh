#!/bin/bash

# Test all corner positions simultaneously
# Note: Some positions may overlap on screen

echo "Testing all corner positions..."

floatify --message 'Bottom Left!' --position bottomLeft --duration 8 &
floatify --message 'Bottom Right!' --position bottomRight --duration 8 &
floatify --message 'Top Left!' --position topLeft --duration 8 &
floatify --message 'Top Right!' --position topRight --duration 8 &
floatify --message 'Centered!' --position center --duration 8 &
floatify --message 'Below menu bar!' --position menubar --duration 8 &
floatify --message 'Horizontal!' --position horizontal --duration 8 &
floatify --message 'Following cursor!' --position cursorFollow --duration 8 &

echo "All notifications triggered!"
