TODO
===
* Find a way to make it so that signals can propagate at the same rate regardless of update order
  * Double Buffer all values? or double-buffer outputs of gates maybe
  * could be tied into the "transistors" concept where each transistor adds the same mount of delay
  * need to mke pass-thru component that passes thru without a delay, so routing with them is zero-cost
* Menu system, with which I can:
  * Add, tweak, and delete circuit boards
  * Add and tweak components
  * Delete components without necessarily having a dedicated button
* Properly support arbitrary number of circuit boards, and wiring between them
* Save and undo system(s)
* With all of the above, I can support "Component-izing" boards
* Wire routing (visual)
* Wire bundles/connectors

idea:  what if the basic components were actually all made of "transistors," which would then be the only component you can't open up to edit? That would require that any variable number of inputs results in a variable transistor arrangement, hmm

note: each wire effectively already has a diode, so transistor-diode logic might only require transistors (or might not work)

transistors don't work tho, but something that is functionally complete, like a NAND gate, works
