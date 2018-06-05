type Internal = i32;
const INTERNAL_MAX:i32 = ::std::i32::MAX;

#[derive(Debug, Clone)]
pub struct Value {
    voltage: Internal,
    error: bool,
}

impl Value {
    pub const DEFAULT: Value = Value {
        voltage: (0.0 * INTERNAL_MAX as f64) as Internal,
        error: false,
    };

    fn new() -> Value {
        Value::from(0.0)
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
impl ::std::ops::Add<Value> for Value {
    type Output = Value;

    fn add(self, other: Value) -> Value {
        let voltage = self.voltage + other.voltage;
        let (voltage, error) = Value::internal_clamp(voltage);
        let error = error | self.error | other.error;
        Value { voltage, error }
    }
}
*/
