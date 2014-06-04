LFprintsample
=============

Sample code on how to print to a large format printer with roll from iOS. 

The sample is considering the source PDF as a blueprint. It tries to minimize the amount of waste paper by rotating the drawing and in case scaling is needed, it tries to scale to 50% first.

There is a sample Arch D size blueprint PDF and two different methods to print it.

First one is using UIPrintInteractionController and printingItem. The control in this case is limited but the integration is easy.

Second one is using a UIPrintPageRenderer, so you have a full control on how the PDF will be printed on the paper. I recommend to use this method. 

On this case when printing a D size 24x36inches, the result will be like:

* Printing on a 36inches roll: Printed landscape and no scaling.
* Printing on a 24inches roll: Printed portrait and no scaling.
* Printing to a 17inches roll: Printed in portrait at 50% scale and with a "Halfsize" watermark.
* Printing on a B size sheet: Printed in portrait at 50% scale with a "halfsize" watermark.
* Printing on a A size sheet: will be printed scale to sheet.









