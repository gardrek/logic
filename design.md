# High-level design
## Components

The basic unit of logic is a component. Components can be described as a variable number of inputs, a variable number of outputs, an optional internal state, and a function which may:
  * read any number of the inputs
  * write to any number of the outputs
  * read or modify its own internal state
  * read or modify the virtual world state

Components also have a visual representation, consisting of:
  * the main body, either a unique shape or a rectangle with an identifying name
  * optional input terminals on the left side
  * optional output terminals on the right side

### Wires, Terminals, and Connection

Input terminals on a component are numbered from top to bottom, starting with `0`. The output terminals are numbered in the same fashion. Additionally, each terminal can have an identifying label. No two terminals on a component can have the same label.

Components are connected to each other using wires. A directional wire can connect from a single output terminal to any number of input terminals, including those on the same component. Wires carry a value from output terminals to input terminals. That is, whatever the output terminal's value is, all connected input terminals will have the same value.

## Circuit boards

A circuit board is a rectangular grid on which components can be placed. It has variable width and height, which are each a whole number of units. Components can be placed on this grid as long as they fit within the rectangle. Components may not overlap, nor may they extend outside the edges. Each circuit board itself is a component of another circuit board, except for the root circuit board in a tree. The input and output terminals of a circuit board can be modified freely, and are the only way for components on different circuit boards to connect to each other. Thus, when a component is connected to another component on a different circuit board, input and output terminals will be created on those boards as necessary to faciliate the connection.

---

# Low-level desgin
    component
      :input_nodes
        1. -> output_node
        2. -> output_node
        etc.
      :output_nodes
        1. output node
        2. output node
    
    output_node
      v: value in range [-1, +1]
      connections:
        1. -> input_node
        2. -> input_node
    
    input_node
      output: -> output_node


    some example components:
      AND Gate
        

