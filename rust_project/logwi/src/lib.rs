pub mod value;
use value::Value;

pub struct Board {
    components: Vec<Component>,
}

impl Board {
    pub fn new() -> Board {
        Board {
            components: vec![],
        }
    }
}

pub struct Link {
    component_index: usize,
    node_index: usize,
}

pub enum ComponentKind {
    //Board,
    And,
}

pub struct Component {
    kind: ComponentKind,
    inputs: Vec<Value>,
    //inputs: Vec<Option<(usize, usize)>>,
    //outputs: Vec<Value>,
}

impl Component {
    //pub fn new_and(n: usize) -> Component {}

    pub fn input_value(&self, index: usize) -> Value {
        //match inputs[index] {
            //Some((c, i)) => ,
            //Some(link) => ,
            //None => Value::DEFAULT,
        //}
        self.inputs[index].clone()
    }

    pub fn update(&self) {
        use ComponentKind::*;
        match self.kind {
            And => self.update_as_and(),
        }
    }

    fn update_as_and(&self) {
        
    }

    pub fn and(&self) -> Value {
        let mut val:f64;
        let mut maxval = 1.0;
        let mut passthru:&Value = &Value::DEFAULT;
        for v in self.inputs.iter() {
            val = v.clone().into();
            if val <= maxval {
                maxval = val;
                passthru = &v
            }
        }
        passthru.clone()
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(-(std::i32::MIN + 1), std::i32::MAX);
    }
}
