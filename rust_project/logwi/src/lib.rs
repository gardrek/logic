type Internal = i32;
const INTERNAL_MAX:i32 = std::i32::MAX;

#[derive(Debug, Clone)]
pub struct Value {
    voltage: Internal,
    error: bool,
}

impl Value {
    /*fn and(&self, &other: Value) -> Value {
        
    },*/
}

impl From<f64> for Value {
    fn from(n: f64) -> Value {
        let mut n = n;
        let mut error = false;
        if n > 1.0 {
            n = 1.0;
            error = true;
        } else if n < -1.0 {
            n = -1.0;
            error = true;
        }
        Value {
            voltage: (n * INTERNAL_MAX as f64) as Internal,
            error,
        }
    }
}

impl Into<f64> for Value {
    fn into(self) -> f64 {
        (self.voltage as f64) / (INTERNAL_MAX as f64)
    }
}

/*
impl std::ops::Add<Value> for Value {
    type Output = Value;

    fn add(self, other: Value) -> Value {
        let voltage = self.voltage + other.voltage;
        let (voltage, error) = Value::internal_clamp(voltage);
        let error = error | self.error | other.error;
        Value { voltage, error }
    }
}
*/



pub struct Component {
    inputs: Vec<Value>,
    //outputs: Vec<Value>,
    default: Value,
}

impl Component {
    pub fn and(&self) -> Value {
        let mut val:f64;
        let mut maxval = 1.0;
        let mut passthru:&Value = &self.default;
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
