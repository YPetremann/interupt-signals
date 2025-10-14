## Description

This add a auto-managed logistic section for constant combinators that contain all signals used in train station names, whenever a station is added, renamed, mined or destroyed, it got updated.

This help setting smart interrupts based on signals when items are not in the train
without setting each signal manually, 

Instead you only need to add a constant combinator with this logistic section to relevant train stations and add items or fluid icons to train stops to automatically get them in the logistic section

Multiple forces are supported: a combinator will only display signals used in the force train stops

## Experimental

This mod have not been extensively tested, so please report any issue

**Known bugs:**
- It's not possible to prevent removing or renaming the logistic section globally, 
it will be recreated automatically with correct naming but removing logistic section has the side effect of unlinking every constant combinator to it

## License

MIT NON-AI License