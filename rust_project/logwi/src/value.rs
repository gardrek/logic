type Voltage = i32;
const VOLTAGE_MAX: Voltage = ::std::i32::MAX;

#[derive(Debug, Clone)]
pub struct Value {
    voltage: Voltage,
    error: bool,
}

impl Value {
    pub const DEFAULT: Value = Value {
        voltage: (0.0 * VOLTAGE_MAX as f64) as Voltage,
        error: false,
    };

    pub fn new() -> Value {
        Value::from(0.0)
    }

    pub fn scale(&self, scale:f64) -> f64 {
        (self.voltage as f64) / (VOLTAGE_MAX as f64) * scale
    }

    pub fn test(&self) {
        if self.voltage == 0 && f64::from(self.clone()) != 0.0f64 {
            panic!()
        }
    }

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
            voltage: (n * VOLTAGE_MAX as f64) as Voltage,
            error,
        }
    }
}

impl From<Value> for f64 {
    fn from(v: Value) -> f64 {
        (v.voltage as f64) / (VOLTAGE_MAX as f64)
    }
}

use std::fmt;
impl fmt::Display for Value {
    // This trait requires `fmt` with this exact signature.
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        // Write into the supplied output
        // stream: `f`. Returns `fmt::Result` which indicates whether the
        // operation succeeded or failed. Note that `write!` uses syntax which
        // is very similar to `println!`.
        let n: f64 = self.clone().into();
        write!(f, "{:+1.5}", n)
    }
}

impl ::std::ops::Add<Value> for Value {
    type Output = Value;

    fn add(self, other: Value) -> Value {
        let voltage = self.voltage.saturating_add(other.voltage);
        //let (voltage, error) = Value::internal_clamp(voltage);
        //let error = error | self.error | other.error;
        let error = self.error | other.error;
        Value { voltage, error }
    }
}

impl PartialEq for Value {
    fn eq(&self, other: &Value) -> bool {
        self.voltage == other.voltage
    }
}

impl Eq for Value {}

//#[cfg(test)]
//mod tests {
    //#[test]
    //fn it_works() {
        //assert_eq!(-(std::i32::MIN + 1), std::i32::MAX);
        ////assert_eq!(value:from(1.0).into(), 0.0:f64);
    //}
//}

