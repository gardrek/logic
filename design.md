# High-level design
## Components

The basic unit of logic is a component. Components can be described as a variable number of inputs, a variable number of outputs, an optional internal state, and an update function. When called, the update function can perform any combination of the following tasks:
  * read the value of any number of the input terminals
  * write a value to any number of the output terminals
  * read or modify its own internal state
  * read or modify the virtual world state

Components also have a visual representation, consisting of:
  * the main body, either a unique shape or a rectangle with an identifying name
  * optional input terminals on the left side
  * optional output terminals on the right side

The body of a component is a whole number of units wide and tall, typically two units wide and as many units tall as necessary to fit the input and output terminals, with one terminal in each category per unit. Input and output terminals are typically centered vertically, spaced one unit apart.

### Wires, Terminals, and Connection

Input terminals on a component are numbered from top to bottom, starting with `0`. The output terminals are numbered in the same fashion. Additionally, each terminal can have an identifying label. No two terminals on a component can have the same label.

Components are connected to each other using wires. A directional wire can connect from a single output terminal to any number of input terminals, including those on the same component. Wires carry a value from output terminals to input terminals. That is, whatever the output terminal's value is, all connected input terminals will have the same value.

### Values

A value has a number of features. The main feature is a number referred to as the "voltage." The voltage of a value is a real number in the range [-1, +1] inclusive. Other features that a value has include a color and an error flag. [More features may be added in the future. TODO: enhance this description]

Most of the basic components only operate on the voltage, passing through the other features as-is rather than composing them. For instance, the AND gate will pass through the value whose logic has with the highest absolute value, which will pass through that value's other features as well. The exception to this rule of thumb is the error flag, which is typically set to true on the output if any input has it set to true.

Each output and input terminal may have a value. The value of an output terminal is set by its parent component according to the component's update function. The value of an input terminal is determined by the output terminal connected to it. If no output terminal is connected, an input terminal will have a default value. [TODO: define default value, esp. the scope. Is there more than one, or just one global default?]

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

